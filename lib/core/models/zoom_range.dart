/// How camerawesome maps plugin zoom [0, 1] to optical zoom on the device.
///
/// iOS: optical = norm * (max - 1) + 1  (min optical is always 1x)
/// Android (CameraX linear): optical = min + (max - min) * norm
class ZoomRange {
  const ZoomRange({
    required this.displayMin,
    required this.displayMax,
    required this.deviceMin,
    required this.deviceMax,
    this.useIosZoomCurve = false,
  });

  final double displayMin;
  final double displayMax;
  /// Achievable optical zoom at plugin value 0 (Android) or 1x (iOS).
  final double deviceMin;
  /// Achievable optical zoom at plugin value 1.
  final double deviceMax;
  final bool useIosZoomCurve;

  /// Maps optical zoom factor to plugin value [0, 1].
  double toNormalized(double displayZoom) {
    final double optical = clampDisplayZoom(displayZoom);

    if (useIosZoomCurve) {
      if (deviceMax <= 1.0) return 0;
      return ((optical - 1.0) / (deviceMax - 1.0)).clamp(0.0, 1.0);
    }

    if (deviceMax <= deviceMin) return 0;
    return ((optical - deviceMin) / (deviceMax - deviceMin)).clamp(0.0, 1.0);
  }

  /// Maps plugin value [0, 1] to optical zoom factor.
  double toDisplay(double normalizedZoom) {
    final double norm = normalizedZoom.clamp(0.0, 1.0);

    if (useIosZoomCurve) {
      return 1.0 + (deviceMax - 1.0) * norm;
    }

    return deviceMin + (deviceMax - deviceMin) * norm;
  }

  double clampDisplayZoom(double zoom) {
    return zoom.clamp(displayMin, displayMax);
  }

  /// Clamps plugin zoom [0, 1] to the allowed display range.
  double clampNormalized(double normalized) {
    return normalized.clamp(
      toNormalized(displayMin),
      toNormalized(displayMax),
    );
  }
}
