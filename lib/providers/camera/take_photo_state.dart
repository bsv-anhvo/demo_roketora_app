import 'package:demo_roketota_app/core/models/camera_settings.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_state.dart';

class TakePhotoState {
  TakePhotoState({
    required this.camera,
    this.timer = PhotoTimerOption.off,
    PhotoAspectRatioOption? selectedPhotoAspectRatio,
    this.countdown,
    this.isCapturing = false,
  }) : selectedPhotoAspectRatio =
            selectedPhotoAspectRatio ?? kPhotoAspectRatios[1];

  factory TakePhotoState.initial() => TakePhotoState(
        camera: const CameraUiState(),
      );

  final CameraUiState camera;
  final PhotoTimerOption timer;
  final PhotoAspectRatioOption selectedPhotoAspectRatio;
  final int? countdown;
  final bool isCapturing;

  TakePhotoState copyWith({
    CameraUiState? camera,
    PhotoTimerOption? timer,
    PhotoAspectRatioOption? selectedPhotoAspectRatio,
    int? countdown,
    bool clearCountdown = false,
    bool? isCapturing,
  }) {
    return TakePhotoState(
      camera: camera ?? this.camera,
      timer: timer ?? this.timer,
      selectedPhotoAspectRatio:
          selectedPhotoAspectRatio ?? this.selectedPhotoAspectRatio,
      countdown: clearCountdown ? null : (countdown ?? this.countdown),
      isCapturing: isCapturing ?? this.isCapturing,
    );
  }
}
