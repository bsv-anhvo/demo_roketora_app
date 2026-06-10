import 'dart:async';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:demo_roketota_app/models/camera_settings.dart';
import 'package:demo_roketota_app/screens/media_preview_screen.dart';
import 'package:demo_roketota_app/utils/camera_zoom_helper.dart';
import 'package:demo_roketota_app/widgets/camera/aspect_ratio_preview_overlay.dart';
import 'package:demo_roketota_app/widgets/camera/camera_filter_strip.dart';
import 'package:demo_roketota_app/widgets/camera/ios_style_zoom_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Base screen for camera experiences (photo / video).
abstract class CameraScreenBase extends StatefulWidget {
  const CameraScreenBase({super.key});
}

abstract class CameraScreenBaseState<T extends CameraScreenBase> extends State<T> {
  FlashSetting flash = FlashSetting.off;
  double exposure = 0.5;
  bool showExposureSlider = false;
  bool showFilterStrip = false;
  bool isOpeningPreview = false;
  ZoomRange zoomRange = CameraZoomHelper.fallbackRange;
  double displayZoom = 1.0;
  bool cameraReady = false;
  bool zoomRangeLoaded = false;

  bool get isPhotoMode;
  String get screenTitle;
  Key get cameraWidgetKey;
  CameraAspectRatios get initialAspectRatio => CameraAspectRatios.ratio_4_3;
  CameraPreviewFit get previewFit => CameraPreviewFit.cover;
  Alignment get previewAlignment => Alignment.center;
  double? get portraitViewportHeightOverWidth => null;
  SaveConfig buildSaveConfig();
  VideoOptions buildVideoOptions();

  @override
  void initState() {
    super.initState();
    applyOrientations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => applyOrientations());
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    onDispose();
    super.dispose();
  }

  @protected
  void onDispose() {}

  void applyOrientations() {
    SystemChrome.setPreferredOrientations(kCameraOrientations);
  }

  FlashMode get flashMode => switch (flash) {
        FlashSetting.off => FlashMode.none,
        FlashSetting.on => FlashMode.on,
        FlashSetting.auto => FlashMode.auto,
      };

  Future<void> refreshZoomRange(CameraState state) async {
    final ZoomRange range = await CameraZoomHelper.load();
    if (!mounted) return;

    final double initialZoom = CameraZoomHelper.defaultDisplayZoom(range);

    setState(() {
      zoomRange = range;
      displayZoom = initialZoom;
    });

    await applyZoom(state.sensorConfig, initialZoom);
  }

  Future<void> applyFlash(SensorConfig sensorConfig) async {
    await sensorConfig.setFlashMode(flashMode);
  }

  Future<void> applyZoom(SensorConfig sensorConfig, double zoom) async {
    final double clamped = zoomRange.clampDisplayZoom(zoom);
    final double normalized = zoomRange.toNormalized(clamped);
    await sensorConfig.setZoom(normalized);
    if (mounted) setState(() => displayZoom = clamped);
  }

  void onCameraReadyBase(CameraState state) {
    if (!zoomRangeLoaded) {
      zoomRangeLoaded = true;
      unawaited(refreshZoomRange(state));
    }

    if (cameraReady) return;
    cameraReady = true;
    state.sensorConfig.setBrightness(exposure);
  }

  void resetCameraSession() {
    setState(() {
      cameraReady = false;
      zoomRangeLoaded = false;
    });
  }

  String? mediaPathFromCapture(MediaCapture event) {
    return event.captureRequest.when(
      single: (single) => single.file?.path,
      multiple: (multiple) {
        for (final file in multiple.fileBySensor.values) {
          if (file != null) return file.path;
        }
        return null;
      },
    );
  }

  Future<void> openMediaPreview({
    required String filePath,
    required bool isVideo,
  }) async {
    if (isOpeningPreview || !mounted) return;
    isOpeningPreview = true;

    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => MediaPreviewScreen(
          filePath: filePath,
          isVideo: isVideo,
        ),
      ),
    );

    isOpeningPreview = false;
    if (!mounted) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (saved == true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(isVideo ? 'Video saved' : 'Photo saved'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (saved == false) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void onCameraReady(CameraState state);
  void handleCaptureEvent(BuildContext context, MediaCapture event);
  Widget buildMiddleContent(CameraState state);
  Widget buildBottomBar(CameraState state);
  Widget? buildOverlay() => null;

  Widget buildTopBar() {
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
              screenTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget buildFilterStrip(CameraState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: CameraFilterStrip(
        state: state,
        filters: awesomePresetFiltersList,
      ),
    );
  }

  Widget buildZoomSelector(CameraState state) {
    return IosStyleZoomSelector(
      range: zoomRange,
      displayZoom: displayZoom,
      onZoomSelected: (zoom) => applyZoom(state.sensorConfig, zoom),
    );
  }

  Widget buildCameraSwitchButton(CameraState state) {
    return IconButton(
      onPressed: () => state.switchCameraSensor(flash: flashMode),
      icon: const Icon(Icons.cameraswitch_outlined),
      color: Colors.white,
      iconSize: 32,
      tooltip: 'Switch camera',
    );
  }

  Widget buildCaptureRow(CameraState state, Widget captureButton) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(child: SizedBox.shrink()),
        captureButton,
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24),
              child: buildCameraSwitchButton(state),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            buildTopBar(),
            Expanded(
              child: Stack(
                children: [
                  KeyedSubtree(
                    key: cameraWidgetKey,
                    child: CameraAwesomeBuilder.awesome(
                      saveConfig: buildSaveConfig(),
                      sensorConfig: SensorConfig.single(
                        sensor: Sensor.position(SensorPosition.back),
                        flashMode: flashMode,
                        aspectRatio: initialAspectRatio,
                      ),
                      enablePhysicalButton: true,
                      previewFit: previewFit,
                      previewAlignment: previewAlignment,
                      previewDecoratorBuilder:
                          portraitViewportHeightOverWidth == null
                              ? null
                              : (state, preview) => AspectRatioPreviewOverlay(
                                    heightOverWidth:
                                        portraitViewportHeightOverWidth!,
                                  ),
                      theme: AwesomeTheme(
                        bottomActionsBackgroundColor: Colors.transparent,
                      ),
                      availableFilters: awesomePresetFiltersList,
                      onPreviewScaleBuilder: (state) => OnPreviewScale(
                        onScale: (normalized) {
                          final double display = zoomRange.clampDisplayZoom(
                            zoomRange.toDisplay(normalized),
                          );
                          setState(() => displayZoom = display);
                          state.sensorConfig.setZoom(normalized);
                        },
                      ),
                      onMediaCaptureEvent: (event) =>
                          handleCaptureEvent(context, event),
                      topActionsBuilder: (state) {
                        state.when(
                          onPhotoMode: onCameraReady,
                          onVideoMode: onCameraReady,
                          onVideoRecordingMode: onCameraReady,
                        );
                        return const SizedBox.shrink();
                      },
                      middleContentBuilder: buildMiddleContent,
                      bottomActionsBuilder: buildBottomBar,
                    ),
                  ),
                  if (buildOverlay() != null) buildOverlay()!,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
