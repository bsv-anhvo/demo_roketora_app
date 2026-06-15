import 'dart:async';
import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:demo_roketota_app/models/camera_settings.dart';
import 'package:demo_roketota_app/utils/media_path_builder.dart';
import 'package:demo_roketota_app/utils/photo_filter_helper.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_actions_mixin.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_state.dart';
import 'package:demo_roketota_app/providers/camera/take_photo_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final takePhotoProvider =
    NotifierProvider.autoDispose<TakePhotoNotifier, TakePhotoState>(
  TakePhotoNotifier.new,
);

class TakePhotoNotifier extends AutoDisposeNotifier<TakePhotoState>
    with CameraUiActions<TakePhotoState> {
  Timer? _countdownTimer;

  @override
  CameraUiState get cameraUi => state.camera;

  @override
  set cameraUi(CameraUiState value) {
    state = state.copyWith(camera: value);
  }

  @override
  TakePhotoState build() {
    ref.onDispose(() => _countdownTimer?.cancel());
    return TakePhotoState.initial();
  }

  void setTimer(PhotoTimerOption timer) {
    state = state.copyWith(timer: timer);
  }

  void setPortraitEnabled(bool enabled) {
    state = state.copyWith(portraitEnabled: enabled);
  }

  void setSelectedAspectRatio(PhotoAspectRatioOption option) {
    state = state.copyWith(selectedPhotoAspectRatio: option);
  }

  void setPendingQuickVideoStart(bool value) {
    state = state.copyWith(pendingQuickVideoStart: value);
  }

  void setCapturing(bool value) {
    state = state.copyWith(isCapturing: value);
  }

  void setCountdown(int? value) {
    if (value == null) {
      state = state.copyWith(clearCountdown: true);
    } else {
      state = state.copyWith(countdown: value);
    }
  }

  void onCameraReady(CameraState cameraState) {
    Future.microtask(() {
      if (state.pendingQuickVideoStart && cameraState is VideoCameraState) {
        setPendingQuickVideoStart(false);
        cameraState.startRecording();
      }

      applyCameraReadyBaseSync(cameraState);
    });
  }

  Future<void> applyPhotoAspectRatio(SensorConfig sensorConfig) async {
    if (sensorConfig.aspectRatio == state.selectedPhotoAspectRatio.aspectRatio) {
      return;
    }
    await sensorConfig.setAspectRatio(state.selectedPhotoAspectRatio.aspectRatio);
  }

  Future<void> applyPortraitMode(CameraState cameraState) async {
    if (!state.portraitEnabled) return;

    final SensorDeviceData sensors = await cameraState.getSensors();
    final bool isFront = cameraState.sensorConfig.sensors.first.position ==
        SensorPosition.front;

    if (isFront && sensors.trueDepth != null) {
      cameraState.setSensorType(0, SensorType.trueDepth, sensors.trueDepth!.uid);
      return;
    }

    if (!isFront && sensors.telephoto != null) {
      cameraState.setSensorType(0, SensorType.telephoto, sensors.telephoto!.uid);
    }
  }

  Future<void> resetPortraitLens(CameraState cameraState) async {
    if (state.portraitEnabled) return;

    final SensorDeviceData sensors = await cameraState.getSensors();
    final bool isFront = cameraState.sensorConfig.sensors.first.position ==
        SensorPosition.front;

    if (isFront) return;

    if (sensors.wideAngle != null) {
      cameraState.setSensorType(0, SensorType.wideAngle, sensors.wideAngle!.uid);
    }
  }

  Future<({String filterPath, String originalPath})?> captureDualPhoto(
    PhotoCameraState photoState,
  ) async {
    setCapturing(true);
    final AwesomeFilter activeFilter = photoState.filter;
    try {
      final List<Sensor> sensors =
          photoState.sensorConfig.sensors.whereType<Sensor>().toList();
      if (sensors.isEmpty) return null;

      final ({String originalPath, String filterPath}) paths =
          await MediaPathBuilder.photoPairPaths();

      final CaptureRequest captureRequest = SingleCaptureRequest(
        paths.originalPath,
        sensors.first,
      );

      await photoState.setFilter(AwesomeFilter.None);

      final bool succeeded = await CamerawesomePlugin.takePhoto(captureRequest);
      if (!succeeded) return null;

      await PhotoFilterHelper.normalizeOrientation(paths.originalPath);

      await File(paths.originalPath).copy(paths.filterPath);
      await PhotoFilterHelper.applyToFile(paths.filterPath, activeFilter);

      return (
        filterPath: paths.filterPath,
        originalPath: paths.originalPath,
      );
    } finally {
      await photoState.setFilter(activeFilter);
      setCapturing(false);
    }
  }

  void startCountdown({
    required int delay,
    required void Function() onComplete,
    required bool Function() isMounted,
  }) {
    setCountdown(delay);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isMounted()) {
        timer.cancel();
        return;
      }

      final int? current = state.countdown;
      if (current == null || current <= 1) {
        timer.cancel();
        setCountdown(null);
        onComplete();
        return;
      }

      setCountdown(current - 1);
    });
  }

  void cancelCountdown() {
    _countdownTimer?.cancel();
    setCountdown(null);
  }
}
