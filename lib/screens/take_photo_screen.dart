import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:demo_roketota_app/bases/base_camera_screen.dart';
import 'package:demo_roketota_app/models/camera_settings.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_actions_mixin.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_state.dart';
import 'package:demo_roketota_app/providers/camera/take_photo_notifier.dart';
import 'package:demo_roketota_app/providers/camera/take_photo_state.dart';
import 'package:demo_roketota_app/utils/media_path_builder.dart';
import 'package:demo_roketota_app/utils/strings.dart';
import 'package:demo_roketota_app/widgets/other/app_loading_overlay.dart';
import 'package:demo_roketota_app/widgets/camera/camera_capture_button.dart';
import 'package:demo_roketota_app/widgets/camera/camera_control_panel.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprintf/sprintf.dart';

class TakePhotoScreen extends CameraScreenBase {
  const TakePhotoScreen({super.key});

  @override
  ConsumerState<TakePhotoScreen> createState() => _TakePhotoScreenState();
}

class _TakePhotoScreenState extends CameraScreenBaseState<TakePhotoScreen> {
  String? _processingMessage;

  TakePhotoNotifier get _notifier => ref.read(takePhotoProvider.notifier);

  TakePhotoState get _photoState => ref.watch(takePhotoProvider);

  @override
  CameraUiHost get cameraHost => _notifier;

  @override
  CameraUiState get cameraUi => _photoState.camera;

  @override
  bool get isPhotoMode => true;

  @override
  String get screenTitle => 'Photo';

  @override
  Key get cameraWidgetKey => const ValueKey('photo_camera');

  @override
  CameraAspectRatios get initialAspectRatio =>
      _photoState.selectedPhotoAspectRatio.aspectRatio;

  @override
  CameraPreviewFit get previewFit => CameraPreviewFit.contain;

  @override
  Alignment get previewAlignment => Alignment.topCenter;

  @override
  double? get portraitViewportHeightOverWidth {
    if (!Platform.isAndroid) return null;
    if (_photoState.selectedPhotoAspectRatio.aspectRatio !=
        CameraAspectRatios.ratio_1_1) {
      return null;
    }
    return 1;
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
    _notifier.onCameraReady(state);
  }

  Future<void> handlePhotoCapture(PhotoCameraState photoState) async {
    final TakePhotoState photo = _photoState;
    if (photo.isCapturing || photo.countdown != null) return;

    final int delay = photo.timer.seconds;
    if (delay == 0) {
      await _capturePhoto(photoState);
      return;
    }

    _notifier.startCountdown(
      delay: delay,
      isMounted: () => mounted,
      onComplete: () => _capturePhoto(photoState),
    );
  }

  Future<void> _capturePhoto(PhotoCameraState photoState) async {
    _setProcessingMessage(Strings.msgCapturing);
    try {
      final ({String filterPath, String originalPath})? result =
          await _notifier.captureDualPhoto(photoState);
      if (!mounted) return;
      _setProcessingMessage(null);
      if (result != null) {
        await openMediaPreview(
          filePath: result.filterPath,
          originalFilePath: result.originalPath,
          isVideo: false,
        );
      }
    } catch (e) {
      _setProcessingMessage(null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sprintf(Strings.msgCaptureFailed, [e])),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  void handleQuickVideoStart(CameraState state) {
    state.when(
      onPhotoMode: (photoState) {
        _notifier.setPendingQuickVideoStart(true);
        photoState.setState(CaptureMode.video);
      },
      onVideoMode: (videoState) {
        if (_photoState.pendingQuickVideoStart) {
          _notifier.setPendingQuickVideoStart(false);
          videoState.startRecording();
        }
      },
    );
  }

  void handleQuickVideoStop(CameraState state) {
    state.when(
      onVideoRecordingMode: (recordingState) {
        _notifier.setPendingQuickVideoStart(false);
        _setProcessingMessage(Strings.msgProcessingVideo);
        recordingState.stopRecording();
      },
      onVideoMode: (_) {
        _notifier.setPendingQuickVideoStart(false);
      },
    );
  }

  void _setProcessingMessage(String? message) {
    if (_processingMessage == message) return;
    setState(() => _processingMessage = message);
  }

  Future<void> pickPhotoAspectRatio(CameraState state) async {
    final PhotoAspectRatioOption? picked = await showCameraPickerSheet(
      context: context,
      title: Strings.labelPhotoResolution,
      options: kPhotoAspectRatios,
      labelBuilder: (option) => option.label,
      selected: _photoState.selectedPhotoAspectRatio,
    );

    if (picked != null && picked != _photoState.selectedPhotoAspectRatio) {
      _notifier.setSelectedAspectRatio(picked);
      await _notifier.applyPhotoAspectRatio(state.sensorConfig);
    }
  }

  @override
  void handleCaptureEvent(BuildContext context, MediaCapture event) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    switch ((event.status, event.isPicture, event.isVideo)) {
      case (MediaCaptureStatus.failure, true, false):
        _setProcessingMessage(null);
        messenger.showSnackBar(
          SnackBar(
            content: Text(sprintf(Strings.msgCaptureFailed, [event.exception])),
            backgroundColor: Colors.red.shade700,
          ),
        );
      case (MediaCaptureStatus.success, false, true):
        _setProcessingMessage(null);
        final String? path = mediaPathFromCapture(event);
        if (path != null) {
          openMediaPreview(filePath: path, isVideo: true);
        }
      case (MediaCaptureStatus.failure, false, true):
        _setProcessingMessage(null);
        messenger.showSnackBar(
          SnackBar(
            content: Text(sprintf(Strings.msgRecordingFailed, [event.exception])),
            backgroundColor: Colors.red.shade700,
          ),
        );
      default:
        break;
    }
  }

  @override
  Widget buildMiddleContent(CameraState state) {
    final TakePhotoState photo = _photoState;
    final CameraUiState ui = cameraUi;

    return Column(
      children: [
        const Spacer(),
        if (ui.showFilterStrip) ...[
          buildFilterStrip(state),
          const SizedBox(height: 8),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: CameraControlPanel(
            isPhotoMode: true,
            flash: ui.flash,
            timer: photo.timer,
            portraitEnabled: photo.portraitEnabled,
            exposure: ui.exposure,
            showExposureSlider: ui.showExposureSlider,
            showFilterStrip: ui.showFilterStrip,
            resolutionLabel: photo.selectedPhotoAspectRatio.label,
            onFlashTap: () {
              _notifier.setFlash(ui.flash.next);
              _notifier.applyFlash(state.sensorConfig);
            },
            onToggleExposure: _notifier.toggleExposureSlider,
            onToggleFilter: _notifier.toggleFilterStrip,
            onExposureChanged: (value) {
              _notifier.setExposure(value);
              state.sensorConfig.setBrightness(value);
            },
            onTimerTap: () => _notifier.setTimer(photo.timer.next),
            onPortraitTap: () async {
              _notifier.setPortraitEnabled(!photo.portraitEnabled);
              if (_photoState.portraitEnabled) {
                await _notifier.applyPortraitMode(state);
              } else {
                await _notifier.resetPortraitLens(state);
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
    final TakePhotoState photo = _photoState;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildZoomSelector(state),
          const Gap(16),
          buildCaptureRow(
            state,
            CameraCaptureButton(
              state: state,
              isPhotoMode: true,
              enabled: !photo.isCapturing && photo.countdown == null,
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
    final int? countdown = _photoState.countdown;
    final String? processingMessage = _processingMessage;

    if (countdown == null && processingMessage == null) return null;

    return Stack(
      children: [
        if (processingMessage != null)
          AppLoadingOverlay(message: processingMessage),
        if (countdown != null)
          Container(
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
          ),
      ],
    );
  }
}
