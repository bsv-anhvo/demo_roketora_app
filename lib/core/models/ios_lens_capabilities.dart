import 'package:camerawesome/camerawesome_plugin.dart';

/// Back-camera lens UIDs discovered via [CamerawesomePlugin.getSensors] on iOS.
class IosLensCapabilities {
  const IosLensCapabilities({
    required this.ultraWide,
    required this.wide,
  });

  final SensorTypeDevice ultraWide;
  final SensorTypeDevice wide;

  /// Ultra-wide native 1.0x maps to this display factor relative to wide 1.0x.
  static const double ultraWideDisplayFactor = 0.5;
}
