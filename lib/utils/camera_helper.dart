import 'dart:io' show Platform;

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:demo_roketota_app/core/extensions/logger_extension.dart';
import 'package:demo_roketota_app/core/extensions/snack_bar_extension.dart';
import 'package:demo_roketota_app/core/models/ios_lens_capabilities.dart';
import 'package:demo_roketota_app/core/models/zoom_range.dart';
import 'package:demo_roketota_app/utils/constants.dart';
import 'package:demo_roketota_app/widgets/camera/camera_focus_indicator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class CameraHelper {
  CameraHelper._();

  /// Clamps [displayZoom] to [range] and maps it to the plugin value [0, 1].
  static ({double display, double normalized}) resolveDisplayZoom(
    ZoomRange range,
    double displayZoom,
  ) {
    final double display = range.clampDisplayZoom(displayZoom);
    final double normalized = range.toNormalized(display);
    return (display: display, normalized: normalized);
  }

  static Future<double> applyDisplayZoom({
    required CameraState cameraState,
    required ZoomRange range,
    required double displayZoom,
  }) async {
    final SensorConfig sensorConfig = cameraState.sensorConfig;
    final Sensor? activeSensor = sensorConfig.sensors.firstOrNull;
    final double clamped = range.clampDisplayZoom(displayZoom);

    if (range.iosLenses != null &&
        activeSensor?.position != SensorPosition.front) {
      return _applyIosMultiLensZoom(
        cameraState: cameraState,
        range: range,
        displayZoom: clamped,
      );
    }

    final ({double display, double normalized}) resolved =
        resolveDisplayZoom(range, clamped);
    await sensorConfig.setZoom(resolved.normalized);
    return resolved.display;
  }

  static Future<double> _applyIosMultiLensZoom({
    required CameraState cameraState,
    required ZoomRange range,
    required double displayZoom,
  }) async {
    final IosLensCapabilities lenses = range.iosLenses!;
    final bool useUltraWide = range.iosLensWantsUltraWide(displayZoom);
    final SensorType targetType =
        useUltraWide ? SensorType.ultraWideAngle : SensorType.wideAngle;
    final String deviceId =
        useUltraWide ? lenses.ultraWide.uid : lenses.wide.uid;

    final Sensor? currentSensor = cameraState.sensorConfig.sensors.firstOrNull;
    if (currentSensor?.type != targetType) {
      cameraState.setSensorType(0, targetType, deviceId);
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    final SensorConfig sensorConfig = cameraState.sensorConfig;
    final double deviceMax =
        (await CamerawesomePlugin.getMaxZoom()) ?? range.deviceMax;
    final double normalized = ZoomRange.iosMultiLensToNormalized(
      displayZoom,
      deviceMax,
    );

    await sensorConfig.setZoom(normalized);
    return displayZoom;
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
      onTapPainter: (tapPosition) => CameraFocusIndicator(
        key: ValueKey(
          'focus_${tapPosition.dx}_${tapPosition.dy}',
        ),
        position: tapPosition,
      ),
      tapPainterDuration: Constants.focusIndicatorDuration,
    );
  }

  static List<double> cameraZoomBuildStops(ZoomRange range) {
    const double epsilon = 0.01;
    // Stops only go up to the preset cap; pinch beyond it is reflected on the
    // active stop label instead of adding more stops.
    final double stopMax = range.displayMax < Constants.desiredMax
        ? range.displayMax
        : Constants.desiredMax;

    if (range.displayMin >= stopMax - epsilon) {
      return [range.displayMin];
    }

    const List<double> candidates = [1.0, 2.0];
    final List<double> stops = [range.displayMin];

    for (final double value in candidates) {
      if (value < range.displayMin - epsilon || value > stopMax + epsilon) {
        continue;
      }
      if (stops.any((stop) => (stop - value).abs() < epsilon)) {
        continue;
      }
      stops.add(value);
    }

    if (!stops.any((stop) => (stop - stopMax).abs() < epsilon)) {
      stops.add(stopMax);
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

  /// Returns the stop that should appear active for [displayZoom] using floor
  /// semantics: 1.x belongs to the 1x stop, 2.x to the 2x stop, and >=3.0 to
  /// the 3x stop. Falls back to the first stop when [displayZoom] is below it.
  static double cameraZoomActiveStop(double displayZoom, List<double> stops) {
    const double epsilon = 0.001;
    double active = stops.first;
    for (final double stop in stops) {
      if (displayZoom >= stop - epsilon) {
        active = stop;
      } else {
        break;
      }
    }
    return active;
  }

  static double defaultDisplayZoom(ZoomRange range) {
    const double target = 1.0;
    if (target >= range.displayMin && target <= range.displayMax) {
      return target;
    }
    return range.displayMin;
  }

  static String formatZoomLabel(double zoom, double displayZoom, {required bool compact}) {
    const double epsilon = 0.001;
    final double value =
        (zoom - displayZoom).abs() < epsilon ? zoom : displayZoom;

    if ((value - value.round()).abs() < 0.05) {
      final int rounded = value.round();
      return compact ? '$rounded' : '$rounded×';
    }

    final String formatted = value.toStringAsFixed(1);
    return compact ? formatted : '$formatted×';
  }

  static Future<ZoomRange> cameraZoomLoad() async {
    final bool useIosZoomCurve = Platform.isIOS;
    try {
      final double? nativeMaxZoom = await CamerawesomePlugin.getMaxZoom();

      IosLensCapabilities? iosLenses;
      if (useIosZoomCurve) {
        final SensorDeviceData sensors = await CamerawesomePlugin.getSensors();
        if (sensors.ultraWideAngle != null && sensors.wideAngle != null) {
          iosLenses = IosLensCapabilities(
            ultraWide: sensors.ultraWideAngle!,
            wide: sensors.wideAngle!,
          );
        }
      }

      // iOS getMinZoom() always returns 0 (hard-coded in the plugin) and can
      // throw on pigeon cast; Android reports the real minZoomRatio.
      final double? nativeMin =
          useIosZoomCurve ? null : await CamerawesomePlugin.getMinZoom();

      'Camera zoom native range: $nativeMin - $nativeMaxZoom, '
              'iosLenses: ${iosLenses != null}'
          .log();

      if (nativeMaxZoom == null || nativeMaxZoom <= 0) {
        return Constants.fallbackRange;
      }
      if (!useIosZoomCurve && nativeMin == null) {
        return Constants.fallbackRange;
      }

      final double opticalMin = useIosZoomCurve
          ? (iosLenses != null
              ? IosLensCapabilities.ultraWideDisplayFactor
              : 1.0)
          : (nativeMin! <= 0 ? 1.0 : nativeMin);
      final double opticalMax = nativeMaxZoom;
      final double displayMin =
          Constants.desiredMin.clamp(opticalMin, opticalMax);
      final double displayMax = opticalMax;

      'Camera zoom optical range: $opticalMin - $opticalMax, '
              'display: $displayMin - $displayMax, iosCurve: $useIosZoomCurve'
          .log();

      return ZoomRange(
        displayMin: displayMin,
        displayMax: displayMax >= displayMin ? displayMax : opticalMax,
        deviceMin: opticalMin,
        deviceMax: opticalMax,
        useIosZoomCurve: useIosZoomCurve,
        iosLenses: iosLenses,
      );
    } catch (e) {
      'Camera zoom load failed: $e'.log();
      return Constants.fallbackRange;
    }
  }
}