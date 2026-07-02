import 'package:demo_roketota_app/core/database/media_database.dart';
import 'package:demo_roketota_app/core/models/media_record.dart';
import 'package:demo_roketota_app/core/models/media_type.dart';
import 'package:demo_roketota_app/utils/media_metadata_helper.dart';
import 'package:flutter/foundation.dart';

class MediaCaptureMetadataService {
  MediaCaptureMetadataService._();

  static final MediaCaptureMetadataService instance =
      MediaCaptureMetadataService._();

  final MediaDatabase _database = MediaDatabase.instance;
  Future<void>? _initFuture;

  Future<void> init({bool force = false}) {
    if (force) {
      _initFuture = null;
    }
    _initFuture ??= _database.reopen();
    return _initFuture!;
  }

  Future<void> _ensureReady() async {
    try {
      await init();
    } catch (e, stackTrace) {
      debugPrint('Media metadata DB init failed: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> registerPhotoCapture({
    required DateTime capturedAt,
    required String filterStampPath,
    required String originalStampPath,
  }) async {
    await _persistCapture(
      type: MediaType.photo,
      capturedAt: capturedAt,
      filterStampPath: filterStampPath,
      originalStampPath: originalStampPath,
      writeFileMetadata: () async {
        await Future.wait<void>(<Future<void>>[
          MediaMetadataHelper.writePhotoCaptureTimestamp(
            originalStampPath,
            capturedAt,
          ),
          MediaMetadataHelper.writePhotoCaptureTimestamp(
            filterStampPath,
            capturedAt,
          ),
        ]);
      },
    );
  }

  Future<void> registerVideoCapture({
    required DateTime capturedAt,
    required String editedStampPath,
    required String originalStampPath,
  }) async {
    await _persistCapture(
      type: MediaType.video,
      capturedAt: capturedAt,
      filterStampPath: editedStampPath,
      originalStampPath: originalStampPath,
      writeFileMetadata: () async {
        await MediaMetadataHelper.writeVideoCaptureTimestamp(
          originalStampPath,
          capturedAt,
        );
        await MediaMetadataHelper.writeVideoCaptureTimestamp(
          editedStampPath,
          capturedAt,
        );
      },
    );
  }

  Future<void> applyPhotoMetadataBeforePublish({
    required String filePath,
    required String originalStampPath,
  }) async {
    final DateTime? capturedAt = await getCapturedAt(originalStampPath);
    if (capturedAt == null) return;

    await MediaMetadataHelper.writePhotoCaptureTimestamp(filePath, capturedAt);
  }

  Future<void> applyVideoMetadataBeforePublish({
    required String filePath,
    required String originalStampPath,
  }) async {
    final DateTime? capturedAt = await getCapturedAt(originalStampPath);
    if (capturedAt == null) return;

    await MediaMetadataHelper.writeVideoCaptureTimestamp(filePath, capturedAt);
  }

  Future<void> markSaved({
    required String originalStampPath,
    required String persistedOriginalPath,
    DateTime? savedAt,
  }) async {
    try {
      await _ensureReady();
      await _database.markSaved(
        originalStampPath: originalStampPath,
        persistedOriginalPath: persistedOriginalPath,
        savedAt: savedAt ?? DateTime.now(),
      );
    } catch (e, stackTrace) {
      debugPrint('Mark media saved failed: $e\n$stackTrace');
    }
  }

  Future<void> deleteCapture(String originalStampPath) async {
    try {
      await _ensureReady();
      await _database.deleteByOriginalStampPath(originalStampPath);
    } catch (e, stackTrace) {
      debugPrint('Delete media capture failed: $e\n$stackTrace');
    }
  }

  Future<void> clearUnsavedCaptures() async {
    try {
      await _ensureReady();
      await _database.deleteUnsavedCaptures();
    } catch (e, stackTrace) {
      debugPrint('Clear unsaved media captures failed: $e\n$stackTrace');
    }
  }

  Future<DateTime?> getCapturedAt(String originalStampPath) async {
    try {
      await _ensureReady();
      final MediaRecord? record =
          await _database.findByOriginalStampPath(originalStampPath);
      return record?.capturedAt;
    } catch (e, stackTrace) {
      debugPrint('Get captured at failed: $e\n$stackTrace');
      return null;
    }
  }

  Future<void> _persistCapture({
    required MediaType type,
    required DateTime capturedAt,
    required String filterStampPath,
    required String originalStampPath,
    required Future<void> Function() writeFileMetadata,
  }) async {
    try {
      await _ensureReady();

      await _database.insert(
        MediaRecord(
          type: type,
          capturedAt: capturedAt,
          filterStampPath: filterStampPath,
          originalStampPath: originalStampPath,
          createdAt: DateTime.now(),
        ),
      );

      await writeFileMetadata();
    } catch (e, stackTrace) {
      debugPrint('Register media capture failed: $e\n$stackTrace');
    }
  }
}
