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