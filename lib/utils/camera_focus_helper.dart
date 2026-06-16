import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:demo_roketota_app/widgets/camera/camera_focus_indicator.dart';
import 'package:flutter/material.dart';

class CameraFocusHelper {
  CameraFocusHelper._();

  static const Duration focusIndicatorDuration = Duration(milliseconds: 2000);

  static Future<void> focusAtTap({
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

  static OnPreviewTap buildPreviewTap(CameraState state) {
    return OnPreviewTap(
      onTap: (position, flutterPreviewSize, pixelPreviewSize) {
        focusAtTap(
          state: state,
          position: position,
          flutterPreviewSize: flutterPreviewSize,
          pixelPreviewSize: pixelPreviewSize,
        );
      },
      onTapPainter: (tapPosition) =>
          CameraFocusIndicator(position: tapPosition),
      tapPainterDuration: focusIndicatorDuration,
    );
  }
}
