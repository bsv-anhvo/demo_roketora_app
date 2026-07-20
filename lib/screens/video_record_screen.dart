import 'dart:io' show Platform;

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:demo_roketota_app/bases/base_camera_screen.dart';
import 'package:demo_roketota_app/core/extensions/camera_aspect_ratio_extension.dart';
import 'package:demo_roketota_app/core/extensions/logger_extension.dart';
import 'package:demo_roketota_app/core/extensions/snack_bar_extension.dart';
import 'package:demo_roketota_app/core/models/camera_settings.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_actions_mixin.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_state.dart';
import 'package:demo_roketota_app/providers/camera/video_record_notifier.dart';
import 'package:demo_roketota_app/providers/camera/video_record_state.dart';
import 'package:demo_roketota_app/services/media_capture_metadata_service.dart';
import 'package:demo_roketota_app/utils/constants.dart';
import 'package:demo_roketota_app/utils/media_file_helper.dart';
import 'package:demo_roketota_app/utils/strings.dart';
import 'package:demo_roketota_app/utils/video_quality_resolver.dart';
import 'package:demo_roketota_app/widgets/common/app_camera_capture_button.dart';
import 'package:demo_roketota_app/widgets/common/app_loading_overlay.dart';
import 'package:demo_roketota_app/widgets/camera/camera_control_panel.dart';
import 'package:demo_roketota_app/widgets/media/video_record_elapsed_timer.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VideoRecordScreen extends CameraScreenBase {
  const VideoRecordScreen({super.key});

  @override
  ConsumerState<VideoRecordScreen> createState() => _VideoRecordScreenState();
}

class _VideoRecordScreenState extends CameraScreenBaseState<VideoRecordScreen>
    with SingleTickerProviderStateMixin {
  static const double _holdHintHeight = 18;

  String? _processingMessage;
  bool _isHoldRecording = false;
  bool _isHandlingRecordedVideo = false;
  String? _handledVideoStampPath;
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
  String get screenTitle => Strings.labelRecordVideo;

  @override
  Key get cameraWidgetKey => ValueKey(
        'video_${_videoState.videoQuality.index}_'
        '${Platform.isIOS ? _videoState.videoFps.fps : _videoState.videoBitrate.mbps}',
      );

  @override
  CameraPreviewFit get previewFit => CameraPreviewFit.contain;

  @override
  Alignment get previewAlignment => Alignment.center;

  @override
  double? get targetPreviewWidthOverHeight => kVideoRecordAspectRatio.value;

  @override
  CameraAspectRatios get initialAspectRatio => kVideoRecordAspectRatio;

  @override
  SaveConfig buildSaveConfig() {
    return SaveConfig.video(
      pathBuilder: MediaFileHelper.videoPath,
      videoOptions: _buildVideoOptions(),
    );
  }

  VideoOptions _buildVideoOptions() {
    return VideoOptions(
      enableAudio: true,
      quality: _videoState.videoQuality,
      android: AndroidVideoOptions(
        bitrate: _videoState.videoBitrate.bitrate,
        fallbackStrategy: QualityFallbackStrategy.lower,
      ),
      ios: CupertinoVideoOptions(fps: _videoState.videoFps.fps),
    );
  }

  Future<void> pickVideoQuality() async {
    final VideoQualityRange supportedRange =
        await VideoQualityResolver.getSupportedRange();

    'supportedRange: min = ${supportedRange.min} - max = ${supportedRange.max}'.log();

    final List<VideoRecordingQuality> availableQualities =
        supportedRange.filterOptions(kVideoQualities);

    if (!mounted || availableQualities.isEmpty) return;

    final VideoRecordingQuality? picked = await showCameraPickerSheet(
      context: context,
      title: Strings.labelVideoResolution,
      options: availableQualities,
      labelBuilder: (option) => option.label,
      selected: availableQualities.contains(_videoState.videoQuality)
          ? _videoState.videoQuality
          : availableQualities.first,
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

  Future<void> pickVideoBitrate() async {
    final VideoBitrateOption? picked = await showCameraPickerSheet(
      context: context,
      title: Strings.labelVideoBitrate,
      options: kVideoBitrateOptions,
      labelBuilder: (option) => option.label,
      selected: _videoState.videoBitrate,
    );

    if (picked != null && picked.mbps != _videoState.videoBitrate.mbps) {
      _notifier.setVideoBitrate(picked);
    }
  }

  void _setProcessingMessage(String? message) {
    if (_processingMessage == message) return;
    setState(() => _processingMessage = message);
  }

  void _onVideoRecordStop() {
    // Post-record processing overlay is owned by [_openVideoPreview].
  }

  void _stopRecordingIfActive() {
    final CameraState? cameraState = _lastCameraState;
    if (cameraState == null) return;

    cameraState.when(
      onVideoRecordingMode: (recordingState) {
        _onVideoRecordStop();
        recordingState.stopRecording();
      },
      onVideoMode: (_) {},
      onPhotoMode: (_) {},
      onPreviewMode: (_) {},
      onAnalysisOnlyMode: (_) {},
    );

    if (!mounted) return;
    setState(() => _isHoldRecording = false);
    _recordPulseController
      ..stop()
      ..reset();
  }

  void handleHoldRecordStart(CameraState state) {
    state.when(
      onVideoMode: (videoState) => _notifier.prepareAndStartRecording(videoState),
      onPhotoMode: (_) {},
      onVideoRecordingMode: (_) {},
      onPreviewMode: (_) {},
      onAnalysisOnlyMode: (_) {},
    );
  }

  void handleHoldRecordStop(CameraState state) {
    _stopRecordingIfActive();
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

  Future<void> _openVideoPreview(
    String originalStampPath, {
    required DateTime capturedAt,
  }) async {
    if (_isHandlingRecordedVideo ||
        _handledVideoStampPath == originalStampPath ||
        cameraUi.isOpeningPreview) {
      return;
    }

    _isHandlingRecordedVideo = true;
    final AwesomeFilter filter = _notifier.recordingFilterForProcessing();
    _notifier.clearRecordingFilter();

    final bool needsFilterProcessing = filter.id != AwesomeFilter.None.id;
    if (needsFilterProcessing) {
      _setProcessingMessage(Strings.msgProcessingVideo);
    }

    try {
      final String? editedStampPath =
          await MediaFileHelper.createEditedVideoStamp(
        originalStampPath,
        filter,
        fallbackFps: _videoState.videoFps.fps,
      );

      if (!mounted) return;

      if (editedStampPath == null) {
        Strings.msgRecordingFailed('Invalid video paths').showSnackBar(
          context,
          backgroundColor: Colors.red.shade700,
        );
        await MediaFileHelper.deleteIfExists(originalStampPath);
        return;
      }

      await MediaCaptureMetadataService.instance.registerVideoCapture(
        capturedAt: capturedAt,
        editedStampPath: editedStampPath,
        originalStampPath: originalStampPath,
      );

      _setProcessingMessage(null);

      await openMediaPreview(
        filePath: editedStampPath,
        originalFilePath: originalStampPath,
        isVideo: true,
      );

      _handledVideoStampPath = originalStampPath;
    } catch (e) {
      if (!mounted) return;
      Strings.msgRecordingFailed('$e').showSnackBar(
        context,
        backgroundColor: Colors.red.shade700,
      );
    } finally {
      _isHandlingRecordedVideo = false;
      if (mounted) {
        _setProcessingMessage(null);
      }
      await _restoreRecordingFilterIfNeeded();
    }
  }

  CameraState? _lastCameraState;

  @override
  void onCameraReady(CameraState state) {
    _lastCameraState = state;
    _notifier.onCameraReady(state);
  }

  Future<void> _restoreRecordingFilterIfNeeded() async {
    final CameraState? state = _lastCameraState;
    if (state == null) return;
    await _notifier.restorePendingFilter(state);
  }

  @override
  void handleCaptureEvent(BuildContext context, MediaCapture event) {
    switch ((event.status, event.isPicture, event.isVideo)) {
      case (MediaCaptureStatus.capturing, false, true):
        _handledVideoStampPath = null;
        _notifier.startRecordTimer(
          isMounted: () => mounted,
          maxDuration: Constants.videoRecordMaxDuration,
          onMaxDurationReached: _stopRecordingIfActive,
        );
        _syncRecordPulseAnimation();
      case (MediaCaptureStatus.success, false, true):
        final DateTime capturedAt =
            _notifier.consumeRecordingCapturedAt() ?? DateTime.now();
        _notifier.stopRecordTimer();
        if (mounted) {
          setState(() => _isHoldRecording = false);
          _recordPulseController
            ..stop()
            ..reset();
        }
        final String? path = mediaPathFromCapture(event);
        if (path != null &&
            !_isHandlingRecordedVideo &&
            !cameraUi.isOpeningPreview) {
          _openVideoPreview(path, capturedAt: capturedAt);
        }
      case (MediaCaptureStatus.failure, false, true):
        _setProcessingMessage(null);
        _notifier.clearRecordingCapturedAt();
        _notifier.stopRecordTimer();
        if (mounted) {
          setState(() => _isHoldRecording = false);
          _recordPulseController
            ..stop()
            ..reset();
        }
        Strings.msgRecordingFailed('${event.exception}').showSnackBar(
          context,
          backgroundColor: Colors.red.shade700,
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
      mainAxisSize: MainAxisSize.min,
      children: [
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
            showFilterStrip: ui.showFilterStrip,
            showExposureSlider: ui.showExposureSlider,
            resolutionLabel: video.videoQuality.label,
            fpsLabel: Platform.isIOS ? video.videoFps.label : null,
            bitrateLabel: Platform.isAndroid ? video.videoBitrate.label : null,
            onFlashTap: () {
              _notifier.setFlash(ui.flash.next);
              _notifier.applyFlash(state.sensorConfig);
            },
            onToggleFilter: _notifier.toggleFilterStrip,
            onExposureTap: _notifier.toggleExposureSlider,
            onTimerTap: () {},
            onResolutionTap: pickVideoQuality,
            onFpsTap: Platform.isIOS ? pickVideoFps : null,
            onBitrateTap: Platform.isAndroid ? pickVideoBitrate : null,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget? buildOverlay({double topBarHeight = 0}) {
    final bool isRecording = _videoState.isRecording;
    final bool showRecordFx = _isHoldRecording || isRecording;
    final String? processingMessage = _processingMessage;

    if (!showRecordFx && processingMessage == null) return null;

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
              padding: EdgeInsets.fromLTRB(24, 24 + topBarHeight, 24, 0),
              child: isRecording ? VideoRecordElapsedTimer(
                elapsed: _videoState.recordElapsed,
                maxDuration: Constants.videoRecordMaxDuration,
              ) : _RecordingPreparingBadge(),
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
          SizedBox(
            height: _holdHintHeight,
            child: Center(
              child: (!_isHoldRecording && !_videoState.isRecording)
                  ? Text(
                      Strings.labelHoldToRecordVideo,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  : null,
            ),
          ),
          const Gap(8),
          buildCaptureRow(
            state,
            AppCameraCaptureButton(
              state: state,
              isPhotoMode: false,
              enabled: true,
              recordMaxDuration: Constants.videoRecordMaxDuration,
              onPhotoTap: () async {},
              onBeforeVideoRecordStart: _notifier.prepareAndStartRecording,
              onQuickVideoStart: () => handleHoldRecordStart(state),
              onQuickVideoStop: () => handleHoldRecordStop(state),
              onHoldRecordingChanged: _onHoldRecordingChanged,
              onVideoRecordStop: _onVideoRecordStop,
            ),
          ),
          buildExposureSliderSlot(),
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
