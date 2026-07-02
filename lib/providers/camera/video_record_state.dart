import 'package:camerawesome/pigeon.dart';
import 'package:demo_roketota_app/core/models/camera_settings.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_state.dart';

class VideoRecordState {
  VideoRecordState({
    required this.camera,
    VideoRecordingQuality? videoQuality,
    VideoFpsOption? videoFps,
    VideoBitrateOption? videoBitrate,
    this.recordElapsed = Duration.zero,
    this.isRecording = false,
    this.recordingCapturedAt,
  })  : videoQuality = videoQuality ?? VideoRecordingQuality.fhd,
        videoFps = videoFps ?? kVideoFpsOptions[1],
        videoBitrate = videoBitrate ?? kVideoBitrateOptions[1];

  factory VideoRecordState.initial() => VideoRecordState(
        camera: const CameraUiState(),
      );

  final CameraUiState camera;
  final VideoRecordingQuality videoQuality;
  final VideoFpsOption videoFps;
  final VideoBitrateOption videoBitrate;
  final Duration recordElapsed;
  final bool isRecording;
  final DateTime? recordingCapturedAt;

  VideoRecordState copyWith({
    CameraUiState? camera,
    VideoRecordingQuality? videoQuality,
    VideoFpsOption? videoFps,
    VideoBitrateOption? videoBitrate,
    Duration? recordElapsed,
    bool? isRecording,
    DateTime? recordingCapturedAt,
    bool clearRecordingCapturedAt = false,
  }) {
    return VideoRecordState(
      camera: camera ?? this.camera,
      videoQuality: videoQuality ?? this.videoQuality,
      videoFps: videoFps ?? this.videoFps,
      videoBitrate: videoBitrate ?? this.videoBitrate,
      recordElapsed: recordElapsed ?? this.recordElapsed,
      isRecording: isRecording ?? this.isRecording,
      recordingCapturedAt: clearRecordingCapturedAt
          ? null
          : (recordingCapturedAt ?? this.recordingCapturedAt),
    );
  }
}
