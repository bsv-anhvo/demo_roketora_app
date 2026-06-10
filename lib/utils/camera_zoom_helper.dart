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

  /// Maps optical zoom factor to plugin value [0, 1] using native device range.
  double toNormalized(double displayZoom) {
    if (deviceMax <= deviceMin) return 0;
    return ((displayZoom - deviceMin) / (deviceMax - deviceMin)).clamp(0.0, 1.0);
  }

  /// Maps plugin value [0, 1] to optical zoom factor using native device range.
  double toDisplay(double normalizedZoom) {
    return deviceMin +
        (deviceMax - deviceMin) * normalizedZoom.clamp(0.0, 1.0);
  }

  double clampDisplayZoom(double zoom) {
    return zoom.clamp(displayMin, displayMax);
  }
}

class CameraZoomHelper {
  static const double desiredMin = 0.5;
  static const double desiredMax = 3.0;
  static const List<double> presetStops = [0.5, 1.0, 2.0, 3.0];

  /// Used before native zoom limits are available (camera not ready yet).
  static const ZoomRange fallbackRange = ZoomRange(
    displayMin: 1.0,
    displayMax: 3.0,
    deviceMin: 1.0,
    deviceMax: 3.0,
  );

  static List<double> buildStops(ZoomRange range) {
    final List<double> stops = presetStops
        .where(
          (stop) => stop >= range.displayMin - 0.01 && stop <= range.displayMax + 0.01,
        )
        .toList();

    if (stops.isNotEmpty) return stops;

    if (range.displayMin == range.displayMax) {
      return [range.displayMin];
    }

    return [range.displayMin, range.displayMax];
  }

  static double closestStop(double displayZoom, List<double> stops) {
    return stops.reduce(
      (current, stop) =>
          (stop - displayZoom).abs() < (current - displayZoom).abs()
              ? stop
              : current,
    );
  }

  static double defaultDisplayZoom(ZoomRange range) {
    const double target = 1.0;
    if (target >= range.displayMin && target <= range.displayMax) {
      return target;
    }
    return range.displayMin;
  }

  static String formatZoomLabel(double zoom, {required bool compact}) {
    if ((zoom - zoom.round()).abs() < 0.05) {
      final int rounded = zoom.round();
      return compact ? '$rounded' : '$rounded×';
    }

    final String value = zoom.toStringAsFixed(1);
    return compact ? value : '$value×';
  }

  static Future<ZoomRange> load() async {
    try {
      final double? nativeMin = await CamerawesomePlugin.getMinZoom();
      final double? nativeMax = await CamerawesomePlugin.getMaxZoom();

      if (nativeMin == null || nativeMax == null || nativeMax <= 0) {
        return fallbackRange;
      }

      final double deviceMin = nativeMin;
      final double deviceMax = nativeMax;
      final double displayMin = desiredMin.clamp(deviceMin, deviceMax);
      final double displayMax = desiredMax.clamp(deviceMin, deviceMax);

      return ZoomRange(
        displayMin: displayMin,
        displayMax: displayMax >= displayMin ? displayMax : deviceMax,
        deviceMin: deviceMin,
        deviceMax: deviceMax,
      );
    } catch (_) {
      return fallbackRange;
    }
  }
}
