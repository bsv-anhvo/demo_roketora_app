import 'package:flutter/foundation.dart';

extension LoggerExtension on Object? {
  void log() {
    if (!kDebugMode) return;
    debugPrint('BSV: $this');
  }
}