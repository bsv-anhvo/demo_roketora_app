import 'dart:async';
import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:demo_roketota_app/models/camera_settings.dart';
import 'package:demo_roketota_app/bases/base_camera_screen.dart';
import 'package:demo_roketota_app/utils/media_path_builder.dart';
import 'package:demo_roketota_app/widgets/camera/camera_capture_button.dart';
import 'package:demo_roketota_app/widgets/camera/camera_control_panel.dart';
import 'package:flutter/material.dart';

class TakePhotoScreen extends CameraScreenBase {
  const TakePhotoScreen({super.key});

  @override
  State<TakePhotoScreen> createState() => _TakePhotoScreenState();
}

class _TakePhotoScreenState extends CameraScreenBaseState<TakePhotoScreen> {
  PhotoTimerOption timer = PhotoTimerOption.off;
  bool portraitEnabled = false;
  PhotoAspectRatioOption selectedPhotoAspectRatio = kPhotoAspectRatios.first;

  int? countdown;
  Timer? countdownTimer;
  bool pendingQuickVideoStart = false;
  bool isCapturing = false;

  @override
  bool get isPhotoMode => true;

  @override
  String get screenTitle => 'Photo';

  @override
  Key get cameraWidgetKey => const ValueKey('photo_camera');

  @override
  CameraAspectRatios get initialAspectRatio =>
      selectedPhotoAspectRatio.aspectRatio;

  @override
  CameraPreviewFit get previewFit => CameraPreviewFit.contain;

  @override
  Alignment get previewAlignment => Alignment.topCenter;

  /// CameraX on Android has no 1:1 preview — mask only that case.
  @override
  double? get portraitViewportHeightOverWidth {
    if (!Platform.isAndroid) return null;
    if (selectedPhotoAspectRatio.aspectRatio != CameraAspectRatios.ratio_1_1) {
      return null;
    }
    return 1;
  }

  @override
  void onDispose() {
    countdownTimer?.cancel();
  }

  @override
  SaveConfig buildSaveConfig() {
    return SaveConfig.photoAndVideo(
      initialCaptureMode: CaptureMode.photo,
      photoPathBuilder: MediaPathBuilder.photoPath,
      videoPathBuilder: MediaPathBuilder.videoPath,
      videoOptions: buildVideoOptions(),
    );
  }

  @override
  VideoOptions buildVideoOptions() {
    return VideoOptions(
      enableAudio: true,
      quality: VideoRecordingQuality.fhd,
      android: AndroidVideoOptions(
        bitrate: 6000000,
        fallbackStrategy: QualityFallbackStrategy.lower,
      ),
      ios: CupertinoVideoOptions(fps: 30),
    );
  }

  @override
  void onCameraReady(CameraState state) {
    if (pendingQuickVideoStart && state is VideoCameraState) {
      pendingQuickVideoStart = false;
      state.startRecording();
    }

    onCameraReadyBase(state);
  }

  Future<void> applyPhotoAspectRatio(SensorConfig sensorConfig) async {
    if (sensorConfig.aspectRatio == selectedPhotoAspectRatio.aspectRatio) {
      return;
    }
    await sensorConfig.setAspectRatio(selectedPhotoAspectRatio.aspectRatio);
  }

  Future<void> applyPortraitMode(CameraState state) async {
    if (!portraitEnabled) return;

    final SensorDeviceData sensors = await state.getSensors();
    final bool isFront =
        state.sensorConfig.sensors.first.position == SensorPosition.front;

    if (isFront && sensors.trueDepth != null) {
      state.setSensorType(0, SensorType.trueDepth, sensors.trueDepth!.uid);
      return;
    }

    if (!isFront && sensors.telephoto != null) {
      state.setSensorType(0, SensorType.telephoto, sensors.telephoto!.uid);
    }
  }

  Future<void> resetPortraitLens(CameraState state) async {
    if (portraitEnabled) return;

    final SensorDeviceData sensors = await state.getSensors();
    final bool isFront =
        state.sensorConfig.sensors.first.position == SensorPosition.front;

    if (isFront) return;

    if (sensors.wideAngle != null) {
      state.setSensorType(0, SensorType.wideAngle, sensors.wideAngle!.uid);
    }
  }

  Future<void> handlePhotoCapture(PhotoCameraState photoState) async {
    if (isCapturing || countdown != null) return;

    final int delay = timer.seconds;
    if (delay == 0) {
      await takePhoto(photoState);
      return;
    }

    setState(() => countdown = delay);
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (countdown == null || countdown! <= 1) {
        timer.cancel();
        setState(() => countdown = null);
        takePhoto(photoState);
        return;
      }

      setState(() => countdown = countdown! - 1);
    });
  }

  Future<void> takePhoto(PhotoCameraState photoState) async {
    setState(() => isCapturing = true);
    try {
      await photoState.takePhoto();
    } finally {
      if (mounted) setState(() => isCapturing = false);
    }
  }

  void handleQuickVideoStart(CameraState state) {
    state.when(
      onPhotoMode: (photoState) {
        pendingQuickVideoStart = true;
        photoState.setState(CaptureMode.video);
      },
      onVideoMode: (videoState) {
        if (pendingQuickVideoStart) {
          pendingQuickVideoStart = false;
          videoState.startRecording();
        }
      },
    );
  }

  void handleQuickVideoStop(CameraState state) {
    state.when(
      onVideoRecordingMode: (recordingState) {
        pendingQuickVideoStart = false;
        recordingState.stopRecording();
      },
      onVideoMode: (_) {
        pendingQuickVideoStart = false;
      },
    );
  }

  Future<void> pickPhotoAspectRatio(CameraState state) async {
    final PhotoAspectRatioOption? picked = await showCameraPickerSheet(
      context: context,
      title: 'Photo Resolution',
      options: kPhotoAspectRatios,
      labelBuilder: (option) => option.label,
      selected: selectedPhotoAspectRatio,
    );

    if (picked != null && picked != selectedPhotoAspectRatio) {
      setState(() => selectedPhotoAspectRatio = picked);
      await applyPhotoAspectRatio(state.sensorConfig);
    }
  }

  @override
  void handleCaptureEvent(BuildContext context, MediaCapture event) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    switch ((event.status, event.isPicture, event.isVideo)) {
      case (MediaCaptureStatus.capturing, true, false):
        messenger.showSnackBar(
          const SnackBar(content: Text('Capturing...')),
        );
      case (MediaCaptureStatus.success, true, false):
        final String? path = mediaPathFromCapture(event);
        if (path != null) {
          openMediaPreview(filePath: path, isVideo: false);
        }
      case (MediaCaptureStatus.failure, true, false):
        messenger.showSnackBar(
          SnackBar(
            content: Text('Capture failed: ${event.exception}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      case (MediaCaptureStatus.capturing, false, true):
        messenger.showSnackBar(
          const SnackBar(content: Text('Recording...')),
        );
      case (MediaCaptureStatus.success, false, true):
        final String? path = mediaPathFromCapture(event);
        if (path != null) {
          openMediaPreview(filePath: path, isVideo: true);
        }
      case (MediaCaptureStatus.failure, false, true):
        messenger.showSnackBar(
          SnackBar(
            content: Text('Recording failed: ${event.exception}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      default:
        break;
    }
  }

  @override
  Widget buildMiddleContent(CameraState state) {
    return Column(
      children: [
        const Spacer(),
        if (showFilterStrip) ...[
          buildFilterStrip(state),
          const SizedBox(height: 8),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: CameraControlPanel(
            isPhotoMode: true,
            flash: flash,
            timer: timer,
            portraitEnabled: portraitEnabled,
            exposure: exposure,
            showExposureSlider: showExposureSlider,
            showFilterStrip: showFilterStrip,
            resolutionLabel: selectedPhotoAspectRatio.label,
            onFlashTap: () {
              setState(() => flash = flash.next);
              applyFlash(state.sensorConfig);
            },
            onToggleExposure: () {
              setState(() => showExposureSlider = !showExposureSlider);
            },
            onToggleFilter: () {
              setState(() => showFilterStrip = !showFilterStrip);
            },
            onExposureChanged: (value) {
              setState(() => exposure = value);
              state.sensorConfig.setBrightness(value);
            },
            onTimerTap: () => setState(() => timer = timer.next),
            onPortraitTap: () async {
              setState(() => portraitEnabled = !portraitEnabled);
              if (portraitEnabled) {
                await applyPortraitMode(state);
              } else {
                await resetPortraitLens(state);
              }
            },
            onResolutionTap: () => pickPhotoAspectRatio(state),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget buildBottomBar(CameraState state) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildZoomSelector(state),
          const SizedBox(height: 16),
          buildCaptureRow(
            state,
            CameraCaptureButton(
              state: state,
              isPhotoMode: true,
              enabled: !isCapturing && countdown == null,
              onPhotoTap: () async {
                await state.when(onPhotoMode: handlePhotoCapture);
              },
              onQuickVideoStart: () => handleQuickVideoStart(state),
              onQuickVideoStop: () => handleQuickVideoStop(state),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget? buildOverlay() {
    if (countdown == null) return null;

    return Container(
      color: Colors.black38,
      alignment: Alignment.center,
      child: Text(
        '$countdown',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 96,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
