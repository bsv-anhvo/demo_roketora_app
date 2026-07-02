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
  AwesomeFilter? _recordingFilter;
  AwesomeFilter? _filterToRestore;

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

  void setVideoBitrate(VideoBitrateOption bitrate) {
    state = state.copyWith(videoBitrate: bitrate);
    resetCameraSession();
  }

  void onCameraReady(CameraState cameraState) {
    onCameraReadyBase(cameraState);
    Future.microtask(() => _restorePendingFilter(cameraState));
  }

  AwesomeFilter recordingFilterForProcessing() =>
      _recordingFilter ?? AwesomeFilter.None;

  Future<void> prepareAndStartRecording(VideoCameraState videoState) async {
    final AwesomeFilter selected = videoState.filter;
    _recordingFilter = selected;
    _filterToRestore = selected;
    if (selected.id != AwesomeFilter.None.id) {
      await videoState.setFilter(AwesomeFilter.None);
    }
    await videoState.startRecording();
  }

  void clearRecordingFilter() {
    _recordingFilter = null;
  }

  Future<void> restorePendingFilter(CameraState state) =>
      _restorePendingFilter(state);

  Future<void> _restorePendingFilter(CameraState state) async {
    final AwesomeFilter? filter = _filterToRestore;
    if (filter == null || filter.id == AwesomeFilter.None.id) return;

    await state.when(
      onVideoMode: (VideoCameraState videoState) => videoState.setFilter(filter),
      onPhotoMode: (_) async {},
      onVideoRecordingMode: (VideoRecordingCameraState videoState) =>
          videoState.setFilter(filter),
      onPreviewMode: (_) async {},
      onAnalysisOnlyMode: (_) async {},
    );
    _filterToRestore = null;
  }

  void clearPendingFilterRestore() {
    _filterToRestore = null;
  }

  void startRecordTimer({required bool Function() isMounted}) {
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
