import 'package:camerawesome/camerawesome_plugin.dart';

class ZoomRange {
  const ZoomRange({
    required this.displayMin,
    required this.displayMax,
    required this.deviceMin,
    required this.deviceMax,
  });

  final double displayMin;
  final double displayMax;
  final double deviceMin;
  final double deviceMax;

  double toNormalized(double displayZoom) {
    if (displayMax <= displayMin) return 0;
    return ((displayZoom - displayMin) / (displayMax - displayMin)).clamp(0.0, 1.0);
  }

  double toDisplay(double normalizedZoom) {
    return displayMin + (displayMax - displayMin) * normalizedZoom.clamp(0.0, 1.0);
  }
}

class CameraZoomHelper {
  static const double desiredMin = 0.5;
  static const double desiredMax = 3.0;

  static Future<ZoomRange> load() async {
    final double deviceMin = await CamerawesomePlugin.getMinZoom() ?? 1.0;
    final double deviceMax = await CamerawesomePlugin.getMaxZoom() ?? 1.0;

    final double displayMin = desiredMin.clamp(deviceMin, deviceMax);
    final double displayMax = desiredMax.clamp(deviceMin, deviceMax);

    return ZoomRange(
      displayMin: displayMin,
      displayMax: displayMax >= displayMin ? displayMax : deviceMax,
      deviceMin: deviceMin,
      deviceMax: deviceMax,
    );
  }
}
