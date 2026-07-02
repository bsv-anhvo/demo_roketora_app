import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

bool _sqfliteReady = false;

void _useFfiFactory() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}

/// Ensures [databaseFactory] is configured before any sqflite call.
Future<void> ensureSqfliteInitialized() async {
  if (_sqfliteReady) return;

  if (kIsWeb) {
    throw UnsupportedError('SQLite is not supported on web.');
  }

  final bool isDesktop =
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  if (isDesktop) {
    _useFfiFactory();
  } else {
    // Mobile must use the native sqflite plugin. Falling back to FFI here
    // opens a different database path and stale handles trigger
    // SQLITE_READONLY_DBMOVED after hot reload.
    await getDatabasesPath();
  }

  _sqfliteReady = true;
}

/// Resets the ready flag so the next DB access re-validates the factory.
/// Useful after hot reload during development.
void resetSqfliteInitializationForDevelopment() {
  assert(kDebugMode);
  _sqfliteReady = false;
}
