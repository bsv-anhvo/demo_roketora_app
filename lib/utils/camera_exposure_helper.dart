import 'package:camerawesome/camerawesome_plugin.dart';

class CameraExposureHelper {
  CameraExposureHelper._();

  /// Applies exposure compensation. [normalized] is in [0, 1]; 0.5 is neutral.
  static Future<void> apply(double normalized) {
    final double value = normalized.clamp(0.0, 1.0);
    return CamerawesomePlugin.setBrightness(value);
  }
}
