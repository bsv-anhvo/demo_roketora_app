import 'dart:async';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:demo_roketota_app/core/extensions/context_extension.dart';
import 'package:demo_roketota_app/core/extensions/snack_bar_extension.dart';
import 'package:demo_roketota_app/core/models/camera_settings.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_actions_mixin.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_state.dart';
import 'package:demo_roketota_app/screens/photo_preview_screen.dart';
import 'package:demo_roketota_app/screens/video_preview_screen.dart';
import 'package:demo_roketota_app/utils/app_colors.dart';
import 'package:demo_roketota_app/utils/camera_helper.dart';
import 'package:demo_roketota_app/utils/camera_preview_viewport.dart';
import 'package:demo_roketota_app/utils/camera_preset_filters.dart';
import 'package:demo_roketota_app/providers/locale_provider.dart';
import 'package:demo_roketota_app/utils/device_requirements.dart';
import 'package:demo_roketota_app/utils/strings.dart';
import 'package:demo_roketota_app/widgets/camera/bounded_pinch_zoom_overlay.dart';
import 'package:demo_roketota_app/widgets/camera/camera_filter_strip.dart';
import 'package:demo_roketota_app/widgets/camera/camera_focus_indicator.dart';
import 'package:demo_roketota_app/widgets/camera/ios_style_zoom_selector.dart';
import 'package:demo_roketota_app/widgets/common/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How long the tap-to-focus overlay (frame + exposure handle) stays visible.
const Duration _focusOverlayDuration = Duration(seconds: 4);

/// Base screen for camera experiences (photo / video).
abstract class CameraScreenBase extends ConsumerStatefulWidget {
  const CameraScreenBase({super.key});
}

abstract class CameraScreenBaseState<T extends CameraScreenBase>
    extends ConsumerState<T> with WidgetsBindingObserver {
  CameraUiHost get cameraHost;
  CameraUiState get cameraUi;

  bool get isPhotoMode;
  String get screenTitle;
  Key get cameraWidgetKey;
  CameraAspectRatios get initialAspectRatio => CameraAspectRatios.ratio_4_3;
  CameraPreviewFit get previewFit => CameraPreviewFit.cover;
  Alignment get previewAlignment => Alignment.center;

  /// Portrait width/height for the selected capture ratio (e.g. 3/4 for 4:3).
  /// When set with [previewFit] == [CameraPreviewFit.contain], preview is clipped
  /// to a centered viewport so iOS and Android stay aligned.
  double? get targetPreviewWidthOverHeight => null;

  bool get _usesViewportContain =>
      previewFit == CameraPreviewFit.contain &&
      targetPreviewWidthOverHeight != null;
  SaveConfig buildSaveConfig();
  bool get needsMicrophonePermission => true;

  bool _permissionsReady = false;
  bool _checkingPermissions = true;
  bool _cameraRunning = false;
  bool _pausedForLifecycle = false;
  int _cameraSession = 0;

  /// Latest cover/contain scale from [AnalysisPreview], used to keep the focus
  /// indicator a consistent on-screen size inside InteractiveViewer.
  double _latestPreviewScale = 1.0;

  Alignment get _effectivePreviewAlignment =>
      _usesViewportContain ? Alignment.center : previewAlignment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    applyOrientations();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verifyRequirements());
  }

  Future<void> _verifyRequirements() async {
    final CameraRequirementStatus cameraStatus =
        await DeviceRequirements.ensureCamera(
      needsMicrophone: needsMicrophonePermission,
    );

    if (!mounted) return;

    if (cameraStatus != CameraRequirementStatus.ready) {
      await DeviceRequirements.showCameraIssue(context, cameraStatus);
      if (mounted) context.pop();
      return;
    }

    final LocationRequirementStatus locationStatus =
        await DeviceRequirements.ensureLocation();

    if (!mounted) return;

    if (locationStatus != LocationRequirementStatus.ready) {
      await DeviceRequirements.showLocationIssue(context, locationStatus);
      if (mounted) context.pop();
      return;
    }

    setState(() {
      _checkingPermissions = false;
      _permissionsReady = true;
      _cameraRunning = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        if (_cameraRunning) {
          _stopCamera(pausedForLifecycle: true);
        }
      case AppLifecycleState.resumed:
        if (_pausedForLifecycle &&
            _permissionsReady &&
            !cameraUi.isOpeningPreview) {
          _pausedForLifecycle = false;
          _startCamera();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  void _stopCamera({bool pausedForLifecycle = false}) {
    if (!_cameraRunning) return;
    if (pausedForLifecycle) {
      _pausedForLifecycle = true;
    }
    cameraHost.resetCameraSession();
    setState(() => _cameraRunning = false);
  }

  void _startCamera() {
    if (_cameraRunning || !_permissionsReady) return;
    setState(() {
      _cameraSession++;
      _cameraRunning = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) => applyOrientations());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    onDispose();
    super.dispose();
  }

  @protected
  void onDispose() {}

  void applyOrientations() {
    SystemChrome.setPreferredOrientations(kCameraOrientations);
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
    required String originalFilePath,
    required bool isVideo,
  }) async {
    if (cameraUi.isOpeningPreview || !mounted) return;
    _stopCamera();

    if(cameraUi.showControlPanel) {
      cameraHost.toggleControlPanel();
    }

    cameraHost.setOpeningPreview(true);

    final bool? saved = await context.pushFullscreen<bool>(
      isVideo
          ? VideoPreviewScreen(
              filePath: filePath,
              originalFilePath: originalFilePath,
            )
          : PhotoPreviewScreen(
              filePath: filePath,
              originalFilePath: originalFilePath,
            ),
    );

    cameraHost.setOpeningPreview(false);
    if (!mounted) return;

    if (!_pausedForLifecycle) {
      _startCamera();
    }

    if (saved == true) {
      (isVideo ? Strings.msgVideoSaved : Strings.msgPhotoSaved).showSnackBar(
        context,
        duration: const Duration(seconds: 2),
      );
    } else if (saved == false) {
      Strings.msgDeleted.showSnackBar(
        context,
        duration: const Duration(seconds: 2),
      );
    }
  }

  void onCameraReady(CameraState state);
  void handleCaptureEvent(BuildContext context, MediaCapture event);
  Widget buildMiddleContent(CameraState state);
  Widget buildBottomBar(CameraState state);
  Widget? buildOverlay() => null;

  Widget buildTopBar() {
    return AppTopBar(
      title: screenTitle,
      leading: _buildIconBackWidget(),
      trailing: _buildIconSettingWidget(),
    );
  }

  Widget buildMiddleContentWrapper(CameraState state) {
    if (!cameraUi.showControlPanel) {
      return const Column(children: [Spacer()]);
    }
    return buildMiddleContent(state);
  }

  Widget buildFilterStrip(CameraState state) {
    ref.watch(localeProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: CameraFilterStrip(
        state: state,
        filters: cameraPresetFilters,
      ),
    );
  }

  Widget buildZoomSelector(CameraState state) {
    return IosStyleZoomSelector(
      range: cameraUi.zoomRange,
      displayZoom: cameraUi.displayZoom,
      onZoomSelected: (zoom) => cameraHost.applyZoom(state.sensorConfig, zoom),
    );
  }

  Widget buildCameraSwitchButton(CameraState state) {
    return IconButton(
      onPressed: () => state.switchCameraSensor(flash: cameraHost.flashMode),
      icon: const Icon(Icons.cameraswitch_outlined),
      color: AppColors.white,
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

  Widget _buildPermissionGate() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.white),
    );
  }

  Widget _buildIconBackWidget() {
    return IconButton(
      onPressed: () => context.pop(),
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      color: AppColors.white,
    );
  }

  Widget _buildIconSettingWidget() {
    bool isActive = cameraUi.showControlPanel;

    return IconButton(
      onPressed: cameraHost.toggleControlPanel,
      icon: Icon(
        isActive ? Icons.tune_rounded : Icons.tune_outlined,
        color: isActive ? AppColors.white : AppColors.white70,
      ),
    );
  }

  OnPreviewTap _buildPreviewTap(CameraState state) {
    final OnPreviewTap baseTap = CameraHelper.cameraBuildPreviewTap(state);
    return OnPreviewTap(
      onTap: (position, flutterPreviewSize, pixelPreviewSize) {
        // Re-focusing always resets exposure back to neutral.
        cameraHost.applyExposure(CameraUiState.defaultExposure);
        baseTap.onTap(position, flutterPreviewSize, pixelPreviewSize);
      },
      onTapPainter: (tapPosition) => CameraFocusIndicator(
        position: tapPosition,
        previewScale: _latestPreviewScale,
        exposure: CameraUiState.defaultExposure,
        onExposureChanged: (value) => cameraHost.applyExposure(value),
      ),
      // Longer than the default so the exposure handle stays draggable.
      tapPainterDuration: _focusOverlayDuration,
    );
  }

  Widget _buildPreviewDecorator(CameraState state, AnalysisPreview preview) {
    _latestPreviewScale = preview.scale;
    final bool useViewportMask = _usesViewportContain;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (useViewportMask)
          CameraPreviewViewportOverlay(
            widthOverHeight: targetPreviewWidthOverHeight!,
            alignment: previewAlignment,
          ),
        BoundedPinchZoomOverlay(
          range: cameraUi.zoomRange,
          displayZoom: cameraUi.displayZoom,
          onDisplayZoom: (zoom) =>
              cameraHost.applyZoom(state.sensorConfig, zoom),
        ),
      ],
    );
  }

  Widget _buildCameraAwesome() {
    final bool useViewportMask = _usesViewportContain;
    final CameraPreviewFit effectivePreviewFit =
        useViewportMask ? CameraPreviewFit.cover : previewFit;
    return CameraAwesomeBuilder.awesome(
      saveConfig: buildSaveConfig(),
      sensorConfig: SensorConfig.single(
        sensor: Sensor.position(SensorPosition.back),
        flashMode: cameraHost.flashMode,
        aspectRatio: initialAspectRatio,
      ),
      enablePhysicalButton: true,
      previewFit: effectivePreviewFit,
      previewAlignment: _effectivePreviewAlignment,
      previewDecoratorBuilder: _buildPreviewDecorator,
      theme: AwesomeTheme(
        bottomActionsBackgroundColor: Colors.transparent,
      ),
      availableFilters: cameraPresetFilters,
      onPreviewScaleBuilder: (_) => OnPreviewScale(onScale: (_) {}),
      onPreviewTapBuilder: _buildPreviewTap,
      onMediaCaptureEvent: (event) => handleCaptureEvent(context, event),
      topActionsBuilder: (state) {
        state.when(
          onPhotoMode: onCameraReady,
          onVideoMode: onCameraReady,
          onVideoRecordingMode: onCameraReady,
        );
        return const SizedBox.shrink();
      },
      middleContentBuilder: buildMiddleContentWrapper,
      bottomActionsBuilder: buildBottomBar,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            buildTopBar(),
            Expanded(
              child: _checkingPermissions || !_permissionsReady
                  ? _buildPermissionGate()
                  : Stack(
                children: [
                  if (_cameraRunning)
                    KeyedSubtree(
                      key: ValueKey('${cameraWidgetKey}_$_cameraSession'),
                      child: _buildCameraAwesome(),
                    )
                  else
                    const ColoredBox(color: AppColors.black),
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

