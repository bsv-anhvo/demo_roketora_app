import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:demo_roketota_app/core/models/zoom_range.dart';
import 'package:demo_roketota_app/utils/constants.dart';
import 'package:demo_roketota_app/widgets/camera/camera_focus_indicator.dart';
import 'package:flutter/material.dart';

class CameraHelper {
  CameraHelper._();

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
    final List<double> stops = Constants.presetStops
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
      final double? nativeMax = await CamerawesomePlugin.getMaxZoom();

      if (nativeMin == null || nativeMax == null || nativeMax <= 0) {
        return Constants.fallbackRange;
      }

      final double deviceMin = nativeMin;
      final double deviceMax = nativeMax;
      final double displayMin = Constants.desiredMin.clamp(deviceMin, deviceMax);
      final double displayMax = Constants.desiredMax.clamp(deviceMin, deviceMax);

      return ZoomRange(
        displayMin: displayMin,
        displayMax: displayMax >= displayMin ? displayMax : deviceMax,
        deviceMin: deviceMin,
        deviceMax: deviceMax,
      );
    } catch (_) {
      return Constants.fallbackRange;
    }
  }
}