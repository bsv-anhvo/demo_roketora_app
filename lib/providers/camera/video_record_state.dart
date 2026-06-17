import 'package:camerawesome/pigeon.dart';
import 'package:demo_roketota_app/core/models/camera_settings.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_state.dart';

class VideoRecordState {
  VideoRecordState({
    required this.camera,
    VideoRecordingQuality? videoQuality,
    VideoFpsOption? videoFps,
    this.recordElapsed = Duration.zero,
    this.isRecording = false,
  })  : videoQuality = videoQuality ?? VideoRecordingQuality.fhd,
        videoFps = videoFps ?? kVideoFpsOptions[1];

  factory VideoRecordState.initial() => VideoRecordState(
        camera: const CameraUiState(),
      );

  final CameraUiState camera;
  final VideoRecordingQuality videoQuality;
  final VideoFpsOption videoFps;
  final Duration recordElapsed;
  final bool isRecording;

  VideoRecordState copyWith({
    CameraUiState? camera,
    VideoRecordingQuality? videoQuality,
    VideoFpsOption? videoFps,
    Duration? recordElapsed,
    bool? isRecording,
  }) {
    return VideoRecordState(
      camera: camera ?? this.camera,
      videoQuality: videoQuality ?? this.videoQuality,
      videoFps: videoFps ?? this.videoFps,
      recordElapsed: recordElapsed ?? this.recordElapsed,
      isRecording: isRecording ?? this.isRecording,
    );
  }
}
