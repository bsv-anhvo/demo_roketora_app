import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

bool _sqfliteReady = false;

/// Ensures [databaseFactory] is configured before any sqflite call.
Future<void> ensureSqfliteInitialized() async {
  if (_sqfliteReady) return;

  // Mobile must use the native sqflite plugin. Falling back to FFI here
  // opens a different database path and stale handles trigger
  // SQLITE_READONLY_DBMOVED after hot reload.
  await getDatabasesPath();

  _sqfliteReady = true;
}

/// Resets the ready flag so the next DB access re-validates the factory.
/// Useful after hot reload during development.
void resetSqfliteInitializationForDevelopment() {
  assert(kDebugMode);
  _sqfliteReady = false;
}
