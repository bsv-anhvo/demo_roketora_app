import 'package:demo_roketota_app/core/database/database_initializer.dart';
import 'package:demo_roketota_app/core/extensions/logger_extension.dart';
import 'package:demo_roketota_app/core/models/media_record.dart';
import 'package:demo_roketota_app/utils/constants.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class MediaDatabase {
  MediaDatabase._();

  static final MediaDatabase instance = MediaDatabase._();

  Database? _database;
  Future<Database>? _opening;

  Future<Database> get database async {
    final Database? existing = _database;
    if (existing != null && existing.isOpen) {
      return existing;
    }

    final Future<Database>? inFlight = _opening;
    if (inFlight != null) {
      return inFlight;
    }

    final Future<Database> opening = _openDatabase();
    _opening = opening;

    try {
      _database = await opening;
      return _database!;
    } finally {
      _opening = null;
    }
  }

  Future<void> init() async {
    await database;
  }

  /// Closes any cached handle and opens a fresh connection.
  Future<void> reopen() async {
    await _resetConnection();
    await database;
  }

  Future<void> _resetConnection() async {
    final Database? existing = _database;
    _database = null;
    _opening = null;

    if (existing != null && existing.isOpen) {
      try {
        await existing.close();
      } catch (e, stackTrace) {
        'Close media database failed: $e\n$stackTrace'.log();
      }
    }
  }

  Future<Database> _openDatabase() async {
    await ensureSqfliteInitialized();

    final String databasesPath = await getDatabasesPath();
    final String dbPath = p.join(databasesPath, Constants.databaseName);

    return openDatabase(
      dbPath,
      version: Constants.versionDatabase,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE ${Constants.tableMediaRecords} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            captured_at TEXT NOT NULL,
            filter_stamp_path TEXT NOT NULL,
            original_stamp_path TEXT NOT NULL UNIQUE,
            persisted_original_path TEXT,
            saved_at TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_media_original_stamp_path ON ${Constants.tableMediaRecords}(original_stamp_path)',
        );
      },
    );
  }

  Future<T> _withRecovery<T>(Future<T> Function(Database db) action) async {
    try {
      return await action(await database);
    } on DatabaseException catch (e) {
      if (!_isRecoverableDatabaseError(e)) {
        rethrow;
      }

      'Media database stale, reopening: $e'.log();
      await reopen();
      return action(await database);
    }
  }

  bool _isRecoverableDatabaseError(DatabaseException exception) {
    final String message = exception.toString().toUpperCase();
    return message.contains('READONLY') ||
        message.contains('1032') ||
        message.contains('DBMOVED') ||
        message.contains('DATABASE IS CLOSED');
  }

  Future<int> insert(MediaRecord record) {
    return _withRecovery(
      (Database db) => db.insert(
        Constants.tableMediaRecords,
        record.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      ),
    );
  }

  Future<MediaRecord?> findByOriginalStampPath(String originalStampPath) {
    return _withRecovery((Database db) async {
      final List<Map<String, Object?>> rows = await db.query(
        Constants.tableMediaRecords,
        where: 'original_stamp_path = ?',
        whereArgs: <Object?>[originalStampPath],
        limit: 1,
      );

      if (rows.isEmpty) return null;
      return MediaRecord.fromMap(rows.first);
    });
  }

  Future<void> markSaved({
    required String originalStampPath,
    required String persistedOriginalPath,
    required DateTime savedAt,
  }) {
    return _withRecovery(
      (Database db) => db.update(
        Constants.tableMediaRecords,
        <String, Object?>{
          'persisted_original_path': persistedOriginalPath,
          'saved_at': savedAt.toIso8601String(),
        },
        where: 'original_stamp_path = ?',
        whereArgs: <Object?>[originalStampPath],
      ),
    );
  }

  Future<void> deleteByOriginalStampPath(String originalStampPath) {
    return _withRecovery(
      (Database db) => db.delete(
        Constants.tableMediaRecords,
        where: 'original_stamp_path = ?',
        whereArgs: <Object?>[originalStampPath],
      ),
    );
  }

  Future<void> deleteUnsavedCaptures() {
    return _withRecovery(
      (Database db) => db.delete(
        Constants.tableMediaRecords,
        where: 'saved_at IS NULL',
      ),
    );
  }
}
