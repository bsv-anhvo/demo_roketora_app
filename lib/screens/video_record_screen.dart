import 'dart:async';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:demo_roketota_app/models/camera_settings.dart';
import 'package:demo_roketota_app/bases/base_camera_screen.dart';
import 'package:demo_roketota_app/utils/media_path_builder.dart';
import 'package:demo_roketota_app/widgets/camera/camera_capture_button.dart';
import 'package:demo_roketota_app/widgets/camera/camera_control_panel.dart';
import 'package:demo_roketota_app/widgets/camera/video_record_elapsed_timer.dart';
import 'package:flutter/material.dart';

class VideoRecordScreen extends CameraScreenBase {
  const VideoRecordScreen({super.key});

  @override
  State<VideoRecordScreen> createState() => _VideoRecordScreenState();
}

class _VideoRecordScreenState extends CameraScreenBaseState<VideoRecordScreen> {
  VideoRecordingQuality videoQuality = VideoRecordingQuality.fhd;
  VideoFpsOption videoFps = kVideoFpsOptions[1];

  Timer? _recordTimer;
  Duration _recordElapsed = Duration.zero;
  bool _isRecording = false;

  @override
  bool get isPhotoMode => false;

  @override
  String get screenTitle => 'Video';

  @override
  Key get cameraWidgetKey => ValueKey('video_${videoQuality.index}_${videoFps.fps}');

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
      quality: videoQuality,
      android: AndroidVideoOptions(
        bitrate: 6000000,
        fallbackStrategy: QualityFallbackStrategy.lower,
      ),
      ios: CupertinoVideoOptions(fps: videoFps.fps),
    );
  }

  @override
  void onDispose() {
    _stopRecordTimer();
    super.onDispose();
  }

  @override
  void onCameraReady(CameraState state) {
    onCameraReadyBase(state);
  }

  void _startRecordTimer() {
    _recordTimer?.cancel();
    setState(() {
      _isRecording = true;
      _recordElapsed = Duration.zero;
    });

    _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final Duration next = _recordElapsed + const Duration(milliseconds: 100);
      if (next >= CameraCaptureButton.videoRecordMaxDuration) {
        setState(
          () => _recordElapsed = CameraCaptureButton.videoRecordMaxDuration,
        );
        timer.cancel();
        return;
      }

      setState(() => _recordElapsed = next);
    });
  }

  void _stopRecordTimer() {
    _recordTimer?.cancel();
    _recordTimer = null;
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _recordElapsed = Duration.zero;
    });
  }

  Future<void> pickVideoQuality() async {
    final VideoRecordingQuality? picked = await showCameraPickerSheet(
      context: context,
      title: 'Video Resolution',
      options: kVideoQualities,
      labelBuilder: (option) => option.label,
      selected: videoQuality,
    );

    if (picked != null && picked != videoQuality) {
      setState(() {
        videoQuality = picked;
        resetCameraSession();
      });
    }
  }

  Future<void> pickVideoFps() async {
    final VideoFpsOption? picked = await showCameraPickerSheet(
      context: context,
      title: 'Frame Rate (FPS)',
      options: kVideoFpsOptions,
      labelBuilder: (option) => option.label,
      selected: videoFps,
    );

    if (picked != null && picked.fps != videoFps.fps) {
      setState(() {
        videoFps = picked;
        resetCameraSession();
      });
    }
  }

  @override
  void handleCaptureEvent(BuildContext context, MediaCapture event) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    switch ((event.status, event.isPicture, event.isVideo)) {
      case (MediaCaptureStatus.capturing, false, true):
        _startRecordTimer();
      case (MediaCaptureStatus.success, false, true):
        _stopRecordTimer();
        final String? path = mediaPathFromCapture(event);
        if (path != null) {
          openMediaPreview(filePath: path, isVideo: true);
        }
      case (MediaCaptureStatus.failure, false, true):
        _stopRecordTimer();
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
            isPhotoMode: false,
            flash: flash,
            timer: PhotoTimerOption.off,
            portraitEnabled: false,
            exposure: exposure,
            showExposureSlider: showExposureSlider,
            showFilterStrip: showFilterStrip,
            resolutionLabel: videoQuality.label,
            fpsLabel: videoFps.label,
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
    if (!_isRecording) return null;

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: VideoRecordElapsedTimer(
          elapsed: _recordElapsed,
          maxDuration: CameraCaptureButton.videoRecordMaxDuration,
        ),
      ),
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
              isPhotoMode: false,
              enabled: true,
              recordMaxDuration: CameraCaptureButton.videoRecordMaxDuration,
              onPhotoTap: () async {},
            ),
          ),
        ],
      ),
    );
  }
}
