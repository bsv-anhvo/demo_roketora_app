import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:demo_roketota_app/bases/base_camera_screen.dart';
import 'package:demo_roketota_app/models/camera_settings.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_actions_mixin.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_state.dart';
import 'package:demo_roketota_app/providers/camera/video_record_notifier.dart';
import 'package:demo_roketota_app/providers/camera/video_record_state.dart';
import 'package:demo_roketota_app/utils/media_path_builder.dart';
import 'package:demo_roketota_app/utils/strings.dart';
import 'package:demo_roketota_app/widgets/other/app_loading_overlay.dart';
import 'package:demo_roketota_app/widgets/camera/camera_capture_button.dart';
import 'package:demo_roketota_app/widgets/camera/camera_control_panel.dart';
import 'package:demo_roketota_app/widgets/camera/video_record_elapsed_timer.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprintf/sprintf.dart';

class VideoRecordScreen extends CameraScreenBase {
  const VideoRecordScreen({super.key});

  @override
  ConsumerState<VideoRecordScreen> createState() => _VideoRecordScreenState();
}

class _VideoRecordScreenState extends CameraScreenBaseState<VideoRecordScreen> {
  String? _processingMessage;

  VideoRecordNotifier get _notifier => ref.read(videoRecordProvider.notifier);

  VideoRecordState get _videoState => ref.watch(videoRecordProvider);

  @override
  CameraUiHost get cameraHost => _notifier;

  @override
  CameraUiState get cameraUi => _videoState.camera;

  @override
  bool get isPhotoMode => false;

  @override
  String get screenTitle => 'Video';

  @override
  Key get cameraWidgetKey =>
      ValueKey('video_${_videoState.videoQuality.index}_${_videoState.videoFps.fps}');

  @override
  SaveConfig buildSaveConfig() {
    return SaveConfig.video(
      pathBuilder: MediaPathBuilder.videoPath,
      videoOptions: buildVideoOptions(),
    );
  }

  @override
  VideoOptions buildVideoOptions() {
    return VideoOptions(
      enableAudio: true,
      quality: _videoState.videoQuality,
      android: AndroidVideoOptions(
        bitrate: 6000000,
        fallbackStrategy: QualityFallbackStrategy.lower,
      ),
      ios: CupertinoVideoOptions(fps: _videoState.videoFps.fps),
    );
  }

  @override
  void onCameraReady(CameraState state) {
    _notifier.onCameraReady(state);
  }

  Future<void> pickVideoQuality() async {
    final VideoRecordingQuality? picked = await showCameraPickerSheet(
      context: context,
      title: Strings.labelVideoResolution,
      options: kVideoQualities,
      labelBuilder: (option) => option.label,
      selected: _videoState.videoQuality,
    );

    if (picked != null && picked != _videoState.videoQuality) {
      _notifier.setVideoQuality(picked);
    }
  }

  Future<void> pickVideoFps() async {
    final VideoFpsOption? picked = await showCameraPickerSheet(
      context: context,
      title: Strings.labelFrameRate,
      options: kVideoFpsOptions,
      labelBuilder: (option) => option.label,
      selected: _videoState.videoFps,
    );

    if (picked != null && picked.fps != _videoState.videoFps.fps) {
      _notifier.setVideoFps(picked);
    }
  }

  void _setProcessingMessage(String? message) {
    if (_processingMessage == message) return;
    setState(() => _processingMessage = message);
  }

  void _onVideoRecordStop() {
    _setProcessingMessage(Strings.msgProcessingVideo);
  }

  @override
  void handleCaptureEvent(BuildContext context, MediaCapture event) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    switch ((event.status, event.isPicture, event.isVideo)) {
      case (MediaCaptureStatus.capturing, false, true):
        _notifier.startRecordTimer(isMounted: () => mounted);
      case (MediaCaptureStatus.success, false, true):
        _setProcessingMessage(null);
        _notifier.stopRecordTimer();
        final String? path = mediaPathFromCapture(event);
        if (path != null) {
          openMediaPreview(filePath: path, isVideo: true);
        }
      case (MediaCaptureStatus.failure, false, true):
        _setProcessingMessage(null);
        _notifier.stopRecordTimer();
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
    final VideoRecordState video = _videoState;
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
            isPhotoMode: false,
            flash: ui.flash,
            timer: PhotoTimerOption.off,
            portraitEnabled: false,
            exposure: ui.exposure,
            showExposureSlider: ui.showExposureSlider,
            showFilterStrip: ui.showFilterStrip,
            resolutionLabel: video.videoQuality.label,
            fpsLabel: video.videoFps.label,
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
            onTimerTap: () {},
            onPortraitTap: () {},
            onResolutionTap: pickVideoQuality,
            onFpsTap: pickVideoFps,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget? buildOverlay() {
    final bool isRecording = _videoState.isRecording;
    final String? processingMessage = _processingMessage;

    if (!isRecording && processingMessage == null) return null;

    return Stack(
      children: [
        if (processingMessage != null)
          AppLoadingOverlay(message: processingMessage),
        if (isRecording)
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: VideoRecordElapsedTimer(
                elapsed: _videoState.recordElapsed,
                maxDuration: CameraCaptureButton.videoRecordMaxDuration,
              ),
            ),
          ),
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
          const Gap(16),
          buildCaptureRow(
            state,
            CameraCaptureButton(
              state: state,
              isPhotoMode: false,
              enabled: true,
              recordMaxDuration: CameraCaptureButton.videoRecordMaxDuration,
              onPhotoTap: () async {},
              onVideoRecordStop: _onVideoRecordStop,
            ),
          ),
        ],
      ),
    );
  }
}
