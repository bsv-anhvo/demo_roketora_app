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

class _VideoRecordScreenState extends CameraScreenBaseState<VideoRecordScreen>
    with SingleTickerProviderStateMixin {
  String? _processingMessage;
  bool _isHoldRecording = false;
  late final AnimationController _recordPulseController;

  VideoRecordNotifier get _notifier => ref.read(videoRecordProvider.notifier);

  VideoRecordState get _videoState => ref.watch(videoRecordProvider);

  @override
  void initState() {
    super.initState();
    _recordPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void onDispose() {
    _recordPulseController.dispose();
  }

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

  void handleHoldRecordStart(CameraState state) {
    state.when(
      onVideoMode: (videoState) => videoState.startRecording(),
      onPhotoMode: (_) {},
      onVideoRecordingMode: (_) {},
      onPreviewMode: (_) {},
      onAnalysisOnlyMode: (_) {},
    );
  }

  void handleHoldRecordStop(CameraState state) {
    state.when(
      onVideoRecordingMode: (recordingState) {
        _onVideoRecordStop();
        recordingState.stopRecording();
      },
      onVideoMode: (_) {},
      onPhotoMode: (_) {},
      onPreviewMode: (_) {},
      onAnalysisOnlyMode: (_) {},
    );
  }

  void _onHoldRecordingChanged(bool isHolding) {
    if (_isHoldRecording == isHolding) return;
    setState(() => _isHoldRecording = isHolding);
    if (isHolding) {
      _recordPulseController.repeat(reverse: true);
    } else if (!_videoState.isRecording) {
      _recordPulseController
        ..stop()
        ..reset();
    }
  }

  void _syncRecordPulseAnimation() {
    final bool shouldPulse = _isHoldRecording || _videoState.isRecording;
    if (shouldPulse && !_recordPulseController.isAnimating) {
      _recordPulseController.repeat(reverse: true);
    } else if (!shouldPulse && _recordPulseController.isAnimating) {
      _recordPulseController
        ..stop()
        ..reset();
    }
  }

  @override
  void handleCaptureEvent(BuildContext context, MediaCapture event) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    switch ((event.status, event.isPicture, event.isVideo)) {
      case (MediaCaptureStatus.capturing, false, true):
        _notifier.startRecordTimer(isMounted: () => mounted);
        _syncRecordPulseAnimation();
      case (MediaCaptureStatus.success, false, true):
        _setProcessingMessage(null);
        _notifier.stopRecordTimer();
        if (mounted) {
          setState(() => _isHoldRecording = false);
          _recordPulseController
            ..stop()
            ..reset();
        }
        final String? path = mediaPathFromCapture(event);
        if (path != null) {
          openMediaPreview(filePath: path, isVideo: true);
        }
      case (MediaCaptureStatus.failure, false, true):
        _setProcessingMessage(null);
        _notifier.stopRecordTimer();
        if (mounted) {
          setState(() => _isHoldRecording = false);
          _recordPulseController
            ..stop()
            ..reset();
        }
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
            onExposureChanged: (value) => _notifier.applyExposure(value),
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
    final bool showRecordFx = _isHoldRecording || isRecording;
    final String? processingMessage = _processingMessage;

    if (!showRecordFx && processingMessage == null) return null;

    final Duration maxDuration = CameraCaptureButton.videoRecordMaxDuration;
    final double progress = isRecording
        ? (_videoState.recordElapsed.inMilliseconds / maxDuration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    return Stack(
      children: [
        if (showRecordFx)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _recordPulseController,
                builder: (context, _) {
                  final double pulse = _recordPulseController.value;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.35 + pulse * 0.55),
                        width: 3 + pulse * 2,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        if (processingMessage != null)
          AppLoadingOverlay(message: processingMessage),
        if (showRecordFx)
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isRecording)
                    VideoRecordElapsedTimer(
                      elapsed: _videoState.recordElapsed,
                      maxDuration: maxDuration,
                    )
                  else
                    _RecordingPreparingBadge(),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: isRecording ? progress : null,
                      minHeight: 4,
                      backgroundColor: Colors.white24,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
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
          const Gap(8),
          if (!_isHoldRecording && !_videoState.isRecording)
            Text(
              Strings.labelHoldToRecordVideo,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          const Gap(8),
          buildCaptureRow(
            state,
            CameraCaptureButton(
              state: state,
              isPhotoMode: false,
              enabled: true,
              recordMaxDuration: CameraCaptureButton.videoRecordMaxDuration,
              onPhotoTap: () async {},
              onQuickVideoStart: () => handleHoldRecordStart(state),
              onQuickVideoStop: () => handleHoldRecordStop(state),
              onHoldRecordingChanged: _onHoldRecordingChanged,
              onVideoRecordStop: _onVideoRecordStop,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingPreparingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              Strings.labelRecording,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
