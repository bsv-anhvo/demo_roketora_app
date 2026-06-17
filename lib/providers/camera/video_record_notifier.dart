import 'dart:async';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:demo_roketota_app/core/models/camera_settings.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_actions_mixin.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_state.dart';
import 'package:demo_roketota_app/providers/camera/video_record_state.dart';
import 'package:demo_roketota_app/utils/constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final videoRecordProvider =
    NotifierProvider.autoDispose<VideoRecordNotifier, VideoRecordState>(
  VideoRecordNotifier.new,
);

class VideoRecordNotifier extends AutoDisposeNotifier<VideoRecordState>
    with CameraUiActions<VideoRecordState> {
  Timer? _recordTimer;

  @override
  CameraUiState get cameraUi => state.camera;

  @override
  set cameraUi(CameraUiState value) {
    state = state.copyWith(camera: value);
  }

  @override
  VideoRecordState build() {
    ref.onDispose(() => _stopRecordTimer());
    return VideoRecordState.initial();
  }

  void setVideoQuality(VideoRecordingQuality quality) {
    state = state.copyWith(videoQuality: quality);
    resetCameraSession();
  }

  void setVideoFps(VideoFpsOption fps) {
    state = state.copyWith(videoFps: fps);
    resetCameraSession();
  }

  void onCameraReady(CameraState cameraState) {
    onCameraReadyBase(cameraState);
  }

  void startRecordTimer({required bool Function() isMounted}) {
    _recordTimer?.cancel();
    state = state.copyWith(
      isRecording: true,
      recordElapsed: Duration.zero,
    );

    _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!isMounted()) {
        timer.cancel();
        return;
      }

      final Duration next =
          state.recordElapsed + const Duration(milliseconds: 100);
      if (next >= Constants.videoRecordMaxDuration) {
        state = state.copyWith(
          recordElapsed: Constants.videoRecordMaxDuration,
        );
        timer.cancel();
        return;
      }

      state = state.copyWith(recordElapsed: next);
    });
  }

  void _stopRecordTimer() {
    _recordTimer?.cancel();
    _recordTimer = null;
    state = state.copyWith(
      isRecording: false,
      recordElapsed: Duration.zero,
    );
  }

  void stopRecordTimer() => _stopRecordTimer();
}
