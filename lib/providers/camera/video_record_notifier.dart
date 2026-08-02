import 'dart:async';
import 'dart:io' show Platform;

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:demo_roketota_app/core/models/camera_settings.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_actions_mixin.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_state.dart';
import 'package:demo_roketota_app/providers/camera/video_record_state.dart';
import 'package:demo_roketota_app/utils/video_fps_resolver.dart';
import 'package:flutter/foundation.dart';
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

  Future<void> setVideoQuality(VideoRecordingQuality quality) async {
    VideoFpsOption nextFps = state.videoFps;
    if (Platform.isIOS) {
      final int maxFps = await VideoFpsResolver.getMaxSupportedFps(
        quality: quality,
      );
      final List<VideoFpsOption> available =
          VideoFpsResolver.filterOptions(kVideoFpsOptions, maxFps);
      if (available.isNotEmpty &&
          !available.any((option) => option.fps == nextFps.fps)) {
        nextFps = available.last;
      }
    }

    state = state.copyWith(videoQuality: quality, videoFps: nextFps);
    resetCameraSession();
  }

  void setVideoFps(VideoFpsOption fps) {
    state = state.copyWith(videoFps: fps);
    resetCameraSession();
  }

  void setVideoBitrate(VideoBitrateOption bitrate) {
    state = state.copyWith(videoBitrate: bitrate);
    resetCameraSession();
  }

  void onCameraReady(CameraState cameraState) {
    onCameraReadyBase(cameraState);
  }

  Future<void> prepareAndStartRecording(VideoCameraState videoState) async {
    await videoState.startRecording();
  }

  void startRecordTimer({
    required bool Function() isMounted,
    required Duration maxDuration,
    VoidCallback? onMaxDurationReached,
  }) {
    _recordTimer?.cancel();
    state = state.copyWith(
      isRecording: true,
      recordElapsed: Duration.zero,
      recordingCapturedAt: DateTime.now(),
    );

    _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!isMounted()) {
        timer.cancel();
        return;
      }

      final Duration next =
          state.recordElapsed + const Duration(milliseconds: 100);
      if (next >= maxDuration) {
        state = state.copyWith(recordElapsed: maxDuration);
        timer.cancel();
        _recordTimer = null;
        onMaxDurationReached?.call();
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

  DateTime? consumeRecordingCapturedAt() {
    final DateTime? capturedAt = state.recordingCapturedAt;
    if (capturedAt == null) return null;

    state = state.copyWith(clearRecordingCapturedAt: true);
    return capturedAt;
  }

  void clearRecordingCapturedAt() {
    if (state.recordingCapturedAt == null) return;
    state = state.copyWith(clearRecordingCapturedAt: true);
  }
}
