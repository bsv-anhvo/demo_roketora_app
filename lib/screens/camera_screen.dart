import 'dart:async';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:demo_roketota_app/models/camera_settings.dart';
import 'package:demo_roketota_app/utils/camera_zoom_helper.dart';
import 'package:demo_roketota_app/utils/media_path_builder.dart';
import 'package:demo_roketota_app/widgets/camera/camera_capture_button.dart';
import 'package:demo_roketota_app/widgets/camera/camera_control_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum CameraDemoMode { photo, video }

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
    required this.mode,
  });

  final CameraDemoMode mode;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final GlobalKey _cameraKey = GlobalKey();

  FlashSetting _flash = FlashSetting.off;
  PhotoTimerOption _timer = PhotoTimerOption.off;
  bool _portraitEnabled = false;
  double _exposure = 0.5;
  bool _showExposureSlider = false;
  ZoomRange? _zoomRange;
  double _displayZoom = 1.0;

  List<PhotoResolutionOption> _photoResolutions = [];
  PhotoResolutionOption? _selectedPhotoResolution;

  VideoRecordingQuality _videoQuality = VideoRecordingQuality.fhd;
  VideoFpsOption _videoFps = kVideoFpsOptions[1];

  int? _countdown;
  Timer? _countdownTimer;
  bool _pendingQuickVideoStart = false;
  bool _isCapturing = false;
  bool _cameraReady = false;

  bool get _isPhotoMode => widget.mode == CameraDemoMode.photo;

  @override
  void initState() {
    super.initState();
    _applyOrientations();
    _loadZoomRange();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => _applyOrientations());
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _loadZoomRange() async {
    final ZoomRange range = await CameraZoomHelper.load();
    if (!mounted) return;
    setState(() {
      _zoomRange = range;
      _displayZoom = range.displayMin.clamp(range.displayMin, range.displayMax);
    });
  }

  void _applyOrientations() {
    SystemChrome.setPreferredOrientations(kCameraOrientations);
  }

  FlashMode get _flashMode => switch (_flash) {
        FlashSetting.off => FlashMode.none,
        FlashSetting.on => FlashMode.on,
        FlashSetting.auto => FlashMode.auto,
      };

  SaveConfig _buildSaveConfig() {
    if (_isPhotoMode) {
      return SaveConfig.photoAndVideo(
        initialCaptureMode: CaptureMode.photo,
        photoPathBuilder: MediaPathBuilder.photoPath,
        videoPathBuilder: MediaPathBuilder.videoPath,
        videoOptions: _buildVideoOptions(),
      );
    }

    return SaveConfig.video(
      pathBuilder: MediaPathBuilder.videoPath,
      videoOptions: _buildVideoOptions(),
    );
  }

  VideoOptions _buildVideoOptions() {
    return VideoOptions(
      enableAudio: true,
      quality: _videoQuality,
      android: AndroidVideoOptions(
        bitrate: 6000000,
        fallbackStrategy: QualityFallbackStrategy.lower,
      ),
      ios: CupertinoVideoOptions(fps: _videoFps.fps),
    );
  }

  Future<void> _loadPhotoResolutions() async {
    final List<Size> sizes = await CamerawesomePlugin.getSizes();
    if (!mounted || sizes.isEmpty) return;

    final List<PhotoResolutionOption> options = sizes
        .map(
          (size) => PhotoResolutionOption(
            width: size.width.round(),
            height: size.height.round(),
          ),
        )
        .toSet()
        .toList()
      ..sort((a, b) => (b.width * b.height).compareTo(a.width * a.height));

    setState(() {
      _photoResolutions = options;
      _selectedPhotoResolution ??= options.first;
    });
  }

  Future<void> _applyPhotoResolution(PhotoResolutionOption option) async {
    await CamerawesomePlugin.setPhotoSize(option.width, option.height);
    setState(() => _selectedPhotoResolution = option);
  }

  Future<void> _applyFlash(SensorConfig sensorConfig) async {
    await sensorConfig.setFlashMode(_flashMode);
  }

  Future<void> _applyZoom(SensorConfig sensorConfig, double displayZoom) async {
    final ZoomRange? range = _zoomRange;
    if (range == null) return;
    final double normalized = range.toNormalized(displayZoom);
    await sensorConfig.setZoom(normalized);
    setState(() => _displayZoom = displayZoom);
  }

  Future<void> _applyPortraitMode(CameraState state) async {
    if (!_portraitEnabled) return;

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

  Future<void> _resetPortraitLens(CameraState state) async {
    if (_portraitEnabled) return;

    final SensorDeviceData sensors = await state.getSensors();
    final bool isFront =
        state.sensorConfig.sensors.first.position == SensorPosition.front;

    if (isFront) return;

    if (sensors.wideAngle != null) {
      state.setSensorType(0, SensorType.wideAngle, sensors.wideAngle!.uid);
    }
  }

  Future<void> _handlePhotoCapture(PhotoCameraState photoState) async {
    if (_isCapturing || _countdown != null) return;

    final int delay = _timer.seconds;
    if (delay == 0) {
      await _takePhoto(photoState);
      return;
    }

    setState(() => _countdown = delay);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdown == null || _countdown! <= 1) {
        timer.cancel();
        setState(() => _countdown = null);
        _takePhoto(photoState);
        return;
      }

      setState(() => _countdown = _countdown! - 1);
    });
  }

  Future<void> _takePhoto(PhotoCameraState photoState) async {
    setState(() => _isCapturing = true);
    try {
      await photoState.takePhoto();
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  void _handleQuickVideoStart(CameraState state) {
    if (!_isPhotoMode) return;

    state.when(
      onPhotoMode: (photoState) {
        _pendingQuickVideoStart = true;
        photoState.setState(CaptureMode.video);
      },
      onVideoMode: (videoState) {
        if (_pendingQuickVideoStart) {
          _pendingQuickVideoStart = false;
          videoState.startRecording();
        }
      },
    );
  }

  void _handleQuickVideoStop(CameraState state) {
    state.when(
      onVideoRecordingMode: (recordingState) {
        _pendingQuickVideoStart = false;
        recordingState.stopRecording();
      },
      onVideoMode: (_) {
        _pendingQuickVideoStart = false;
      },
    );
  }

  void _onCameraReady(CameraState state) {
    if (_pendingQuickVideoStart && state is VideoCameraState) {
      _pendingQuickVideoStart = false;
      state.startRecording();
    }

    if (_cameraReady) return;
    _cameraReady = true;

    if (_isPhotoMode && _photoResolutions.isEmpty) {
      _loadPhotoResolutions();
    }

    state.sensorConfig.setBrightness(_exposure);
    if (_zoomRange != null) {
      _applyZoom(state.sensorConfig, _displayZoom);
    }
  }

  Future<void> _pickPhotoResolution() async {
    if (_photoResolutions.isEmpty) return;

    final PhotoResolutionOption? picked = await showCameraPickerSheet(
      context: context,
      title: 'Photo Resolution',
      options: _photoResolutions,
      labelBuilder: (option) => '${option.label} (~${option.megapixels}MP)',
      selected: _selectedPhotoResolution ?? _photoResolutions.first,
    );

    if (picked != null) {
      await _applyPhotoResolution(picked);
    }
  }

  Future<void> _pickVideoQuality() async {
    final VideoRecordingQuality? picked = await showCameraPickerSheet(
      context: context,
      title: 'Video Resolution',
      options: kVideoQualities,
      labelBuilder: (option) => option.label,
      selected: _videoQuality,
    );

    if (picked != null && picked != _videoQuality) {
      setState(() {
        _videoQuality = picked;
        _cameraReady = false;
      });
    }
  }

  Future<void> _pickVideoFps() async {
    final VideoFpsOption? picked = await showCameraPickerSheet(
      context: context,
      title: 'Frame Rate (FPS)',
      options: kVideoFpsOptions,
      labelBuilder: (option) => option.label,
      selected: _videoFps,
    );

    if (picked != null && picked.fps != _videoFps.fps) {
      setState(() {
        _videoFps = picked;
        _cameraReady = false;
      });
    }
  }

  void _handleCaptureEvent(BuildContext context, MediaCapture event) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    switch ((event.status, event.isPicture, event.isVideo)) {
      case (MediaCaptureStatus.capturing, true, false):
        messenger.showSnackBar(
          const SnackBar(content: Text('Đang chụp ảnh...')),
        );
      case (MediaCaptureStatus.success, true, false):
        event.captureRequest.when(
          single: (single) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Ảnh đã lưu: ${single.file?.path ?? 'N/A'}'),
                duration: const Duration(seconds: 4),
              ),
            );
          },
          multiple: (_) {},
        );
      case (MediaCaptureStatus.failure, true, false):
        messenger.showSnackBar(
          SnackBar(
            content: Text('Chụp ảnh thất bại: ${event.exception}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      case (MediaCaptureStatus.capturing, false, true):
        messenger.showSnackBar(
          const SnackBar(content: Text('Đang ghi video...')),
        );
      case (MediaCaptureStatus.success, false, true):
        event.captureRequest.when(
          single: (single) {
            messenger.showSnackBar(
              SnackBar(
                content: Text('Video đã lưu: ${single.file?.path ?? 'N/A'}'),
                duration: const Duration(seconds: 4),
              ),
            );
          },
          multiple: (_) {},
        );
      case (MediaCaptureStatus.failure, false, true):
        messenger.showSnackBar(
          SnackBar(
            content: Text('Ghi video thất bại: ${event.exception}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          KeyedSubtree(
            key: _isPhotoMode
                ? _cameraKey
                : ValueKey('video_${_videoQuality.index}_${_videoFps.fps}'),
            child: CameraAwesomeBuilder.awesome(
            saveConfig: _buildSaveConfig(),
            sensorConfig: SensorConfig.single(
              sensor: Sensor.position(SensorPosition.back),
              flashMode: _flashMode,
              aspectRatio: CameraAspectRatios.ratio_4_3,
            ),
            enablePhysicalButton: true,
            previewFit: CameraPreviewFit.cover,
            availableFilters: null,
            onMediaCaptureEvent: (event) => _handleCaptureEvent(context, event),
            topActionsBuilder: (state) {
              state.when(
                onPhotoMode: _onCameraReady,
                onVideoMode: _onCameraReady,
                onVideoRecordingMode: _onCameraReady,
              );
              return _buildTopBar(state);
            },
            middleContentBuilder: (state) => _buildMiddleContent(state),
            bottomActionsBuilder: (state) => _buildBottomBar(state),
          ),
          ),
          if (_countdown != null) _buildCountdownOverlay(),
        ],
      ),
    );
  }

  Widget _buildTopBar(CameraState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: Colors.white,
          ),
          Expanded(
            child: Text(
              _isPhotoMode ? 'Chụp ảnh' : 'Quay video',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => state.switchCameraSensor(flash: _flashMode),
            icon: const Icon(Icons.cameraswitch_outlined),
            color: Colors.white,
            tooltip: 'Đổi camera',
          ),
        ],
      ),
    );
  }

  Widget _buildMiddleContent(CameraState state) {
    return Column(
      children: [
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: CameraControlPanel(
            isPhotoMode: _isPhotoMode,
            flash: _flash,
            timer: _timer,
            portraitEnabled: _portraitEnabled,
            exposure: _exposure,
            zoomRange: _zoomRange,
            displayZoom: _displayZoom,
            showExposureSlider: _showExposureSlider,
            resolutionLabel: _isPhotoMode
                ? (_selectedPhotoResolution?.label ?? 'Resolution')
                : _videoQuality.label,
            fpsLabel: _videoFps.label,
            onFlashTap: () {
              setState(() => _flash = _flash.next);
              _applyFlash(state.sensorConfig);
            },
            onToggleExposure: () {
              setState(() => _showExposureSlider = !_showExposureSlider);
            },
            onExposureChanged: (value) {
              setState(() => _exposure = value);
              state.sensorConfig.setBrightness(value);
            },
            onZoomChanged: (value) => _applyZoom(state.sensorConfig, value),
            onTimerTap: () => setState(() => _timer = _timer.next),
            onPortraitTap: () async {
              setState(() => _portraitEnabled = !_portraitEnabled);
              if (_portraitEnabled) {
                await _applyPortraitMode(state);
              } else {
                await _resetPortraitLens(state);
              }
            },
            onResolutionTap: () {
              if (_isPhotoMode) {
                _pickPhotoResolution();
              } else {
                _pickVideoQuality();
              }
            },
            onFpsTap: _isPhotoMode ? null : _pickVideoFps,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildBottomBar(CameraState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: CameraCaptureButton(
        state: state,
        isPhotoMode: _isPhotoMode,
        enabled: !_isCapturing && _countdown == null,
        onPhotoTap: () async {
          await state.when(onPhotoMode: _handlePhotoCapture);
        },
        onQuickVideoStart: () => _handleQuickVideoStart(state),
        onQuickVideoStop: () => _handleQuickVideoStop(state),
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return Container(
      color: Colors.black38,
      alignment: Alignment.center,
      child: Text(
        '$_countdown',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 96,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
