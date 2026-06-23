import 'dart:io' show Platform;

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:demo_roketota_app/core/extensions/logger_extension.dart';
import 'package:demo_roketota_app/core/models/zoom_range.dart';
import 'package:demo_roketota_app/utils/constants.dart';
import 'package:demo_roketota_app/widgets/camera/camera_focus_indicator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Applies relative pinch deltas on top of the current zoom instead of using
/// camerawesome's absolute [0, 1] gesture value (which drifts after UI zoom).
class BoundedPinchZoomHandler {
  BoundedPinchZoomHandler({
    this.gestureIdleTimeout = const Duration(milliseconds: 150),
  });

  final Duration gestureIdleTimeout;

  double? _lastDetectorNormalized;
  double _currentDisplayZoom = 1.0;
  DateTime? _lastPinchAt;

  void reset() {
    _lastDetectorNormalized = null;
    _lastPinchAt = null;
  }

  /// Returns clamped display zoom to apply, or null when unchanged.
  double? handleScale({
    required ZoomRange range,
    required double detectorNormalized,
    required double currentDisplayZoom,
  }) {
    final DateTime now = DateTime.now();
    final bool isNewGesture = _lastPinchAt == null ||
        now.difference(_lastPinchAt!) > gestureIdleTimeout;

    _lastPinchAt = now;

    if (isNewGesture || _lastDetectorNormalized == null) {
      _currentDisplayZoom = range.clampDisplayZoom(currentDisplayZoom);
      _lastDetectorNormalized = detectorNormalized;
      return null;
    }

    final double delta = detectorNormalized - _lastDetectorNormalized!;
    _lastDetectorNormalized = detectorNormalized;

    if (delta.abs() < 0.0001) return null;

    final double displaySpan = range.displayMax - range.displayMin;
    _currentDisplayZoom = range.clampDisplayZoom(
      _currentDisplayZoom + delta * displaySpan,
    );
    return _currentDisplayZoom;
  }
}

class CameraHelper {
  CameraHelper._();

  /// Clamps [displayZoom] to [range] and maps it to the plugin value [0, 1].
  static ({double display, double normalized}) resolveDisplayZoom(
    ZoomRange range,
    double displayZoom,
  ) {
    final double display = range.clampDisplayZoom(displayZoom);
    final double normalized = range.toNormalized(display);
    'Apply zoom display=$display normalized=$normalized '
            'range=[${range.displayMin}, ${range.displayMax}] '
            'device=[${range.deviceMin}, ${range.deviceMax}] '
            'iosCurve=${range.useIosZoomCurve}'
        .log();
    return (display: display, normalized: normalized);
  }

  static Future<double> applyDisplayZoom({
    required SensorConfig sensorConfig,
    required ZoomRange range,
    required double displayZoom,
  }) async {
    final ({double display, double normalized}) resolved =
        resolveDisplayZoom(range, displayZoom);
    await sensorConfig.setZoom(resolved.normalized);
    return resolved.display;
  }

  /// Applies exposure compensation. [normalized] is in [0,1]; 0.5 is neutral.
  static Future<void> applyExposureValue(double normalized) {
    final double value = normalized.clamp(0.0, 1.0);
    return CamerawesomePlugin.setBrightness(value);
  }

  static Future<void> cameraFocusAtTap({
    required CameraState state,
    required Offset position,
    required PreviewSize flutterPreviewSize,
    required PreviewSize pixelPreviewSize,
  }) {
    Future<void>? focusFuture;

    state.when(
      onPhotoMode: (photoState) {
        focusFuture = photoState.focusOnPoint(
          flutterPosition: position,
          pixelPreviewSize: pixelPreviewSize,
          flutterPreviewSize: flutterPreviewSize,
        );
      },
      onVideoMode: (videoState) {
        focusFuture = videoState.focusOnPoint(
          flutterPosition: position,
          pixelPreviewSize: pixelPreviewSize,
          flutterPreviewSize: flutterPreviewSize,
        );
      },
      onVideoRecordingMode: (recordingState) {
        focusFuture = recordingState.focusOnPoint(
          flutterPosition: position,
          pixelPreviewSize: pixelPreviewSize,
          flutterPreviewSize: flutterPreviewSize,
        );
      },
      onPreviewMode: (previewState) {
        focusFuture = previewState.focusOnPoint(
          flutterPosition: position,
          pixelPreviewSize: pixelPreviewSize,
          flutterPreviewSize: flutterPreviewSize,
        );
      },
    );

    return focusFuture ?? Future<void>.value();
  }

  static OnPreviewTap cameraBuildPreviewTap(CameraState state) {
    return OnPreviewTap(
      onTap: (position, flutterPreviewSize, pixelPreviewSize) {
        cameraFocusAtTap(
          state: state,
          position: position,
          flutterPreviewSize: flutterPreviewSize,
          pixelPreviewSize: pixelPreviewSize,
        );
      },
      onTapPainter: (tapPosition) =>
          CameraFocusIndicator(position: tapPosition),
      tapPainterDuration: Constants.focusIndicatorDuration,
    );
  }

  static List<double> cameraZoomBuildStops(ZoomRange range) {
    if (range.displayMin == range.displayMax) {
      return [range.displayMin];
    }

    const double epsilon = 0.01;
    const List<double> candidates = [1.0, 2.0];
    final List<double> stops = [range.displayMin];

    for (final double value in candidates) {
      if (value < range.displayMin - epsilon || value > range.displayMax + epsilon) {
        continue;
      }
      if (stops.any((stop) => (stop - value).abs() < epsilon)) {
        continue;
      }
      stops.add(value);
    }

    if (!stops.any((stop) => (stop - range.displayMax).abs() < epsilon)) {
      stops.add(range.displayMax);
    }

    return stops;
  }

  static double cameraZoomClosestStop(double displayZoom, List<double> stops) {
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

  static Future<ZoomRange> cameraZoomLoad() async {
    try {
      final double? nativeMin = await CamerawesomePlugin.getMinZoom();
      final double? nativeMaxZoom = await CamerawesomePlugin.getMaxZoom();

      'Camera zoom native range: $nativeMin - $nativeMaxZoom'.log();

      if (nativeMin == null || nativeMaxZoom == null || nativeMaxZoom <= 0) {
        return Constants.fallbackRange;
      }

      final bool useIosZoomCurve = !kIsWeb && Platform.isIOS;
      // iOS getMinZoom() returns 0 but optical min is 1x; Android uses minZoomRatio.
      final double opticalMin = useIosZoomCurve
          ? 1.0
          : (nativeMin <= 0 ? 1.0 : nativeMin);
      final double opticalMax = nativeMaxZoom;
      final double displayMin =
          Constants.desiredMin.clamp(opticalMin, opticalMax);
      final double displayMax =
          Constants.desiredMax.clamp(opticalMin, opticalMax);

      'Camera zoom optical range: $opticalMin - $opticalMax, '
              'display: $displayMin - $displayMax, iosCurve: $useIosZoomCurve'
          .log();

      return ZoomRange(
        displayMin: displayMin,
        displayMax: displayMax >= displayMin ? displayMax : opticalMax,
        deviceMin: opticalMin,
        deviceMax: opticalMax,
        useIosZoomCurve: useIosZoomCurve,
      );
    } catch (_) {
      return Constants.fallbackRange;
    }
  }
}