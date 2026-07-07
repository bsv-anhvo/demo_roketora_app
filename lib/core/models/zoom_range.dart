import 'package:demo_roketota_app/core/models/ios_lens_capabilities.dart';

/// How camerawesome maps plugin zoom [0, 1] to optical zoom on the device.
///
/// iOS single-lens: optical = norm * (max - 1) + 1
/// iOS multi-lens: ultra-wide below 1x display, wide at/above 1x (see [iosLenses])
/// Android (CameraX linear): optical = min + (max - min) * norm
class ZoomRange {
  const ZoomRange({
    required this.displayMin,
    required this.displayMax,
    required this.deviceMin,
    required this.deviceMax,
    this.useIosZoomCurve = false,
    this.iosLenses,
  });

  final double displayMin;
  final double displayMax;
  /// Achievable optical zoom at plugin value 0 (Android) or 1x (iOS).
  final double deviceMin;
  /// Achievable optical zoom at plugin value 1.
  final double deviceMax;
  final bool useIosZoomCurve;
  /// Non-null when the back camera exposes separate ultra-wide and wide lenses.
  final IosLensCapabilities? iosLenses;

  /// Maps optical zoom factor to plugin value [0, 1].
  double toNormalized(double displayZoom) {
    final double optical = clampDisplayZoom(displayZoom);

    if (useIosZoomCurve && iosLenses != null) {
      return iosMultiLensToNormalized(optical, deviceMax);
    }

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

  /// Display zoom below this uses the ultra-wide lens when [iosLenses] is set.
  static const double iosWideLensThreshold = 1.0;

  bool iosLensWantsUltraWide(double displayZoom) {
    return displayZoom < iosWideLensThreshold;
  }

  static double iosMultiLensToNormalized(double displayZoom, double maxZoom) {
    if (maxZoom <= 1.0) return 0;

    final double nativeZoom = displayZoom < iosWideLensThreshold
        ? displayZoom / IosLensCapabilities.ultraWideDisplayFactor
        : displayZoom;

    return ((nativeZoom - 1.0) / (maxZoom - 1.0)).clamp(0.0, 1.0);
  }
}
