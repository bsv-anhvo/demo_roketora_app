import 'dart:async';
import 'dart:typed_data';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:demo_roketota_app/core/extensions/context_extension.dart';
import 'package:demo_roketota_app/models/camera_settings.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_actions_mixin.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_state.dart';
import 'package:demo_roketota_app/screens/photo_preview_screen.dart';
import 'package:demo_roketota_app/screens/video_preview_screen.dart';
import 'package:demo_roketota_app/utils/camera_focus_helper.dart';
import 'package:demo_roketota_app/utils/device_requirements.dart';
import 'package:demo_roketota_app/utils/strings.dart';
import 'package:demo_roketota_app/widgets/camera/aspect_ratio_preview_overlay.dart';
import 'package:demo_roketota_app/widgets/camera/camera_filter_strip.dart';
import 'package:demo_roketota_app/widgets/camera/ios_style_zoom_selector.dart';
import 'package:demo_roketota_app/widgets/common/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  double? get portraitViewportHeightOverWidth => null;
  SaveConfig buildSaveConfig();
  VideoOptions buildVideoOptions();
  bool get needsMicrophonePermission => true;

  bool _permissionsReady = false;
  bool _checkingPermissions = true;
  bool _cameraRunning = false;
  bool _pausedForLifecycle = false;
  int _cameraSession = 0;

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
    String? filePath,
    Uint8List? filterBytes,
    Uint8List? originalBytes,
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
          ? VideoPreviewScreen(filePath: filePath!)
          : PhotoPreviewScreen(
              filterBytes: filterBytes!,
              originalBytes: originalBytes,
            ),
    );

    cameraHost.setOpeningPreview(false);
    if (!mounted) return;

    if (!_pausedForLifecycle) {
      _startCamera();
    }

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (saved == true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(isVideo ? Strings.msgVideoSaved : Strings.msgPhotoSaved),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (saved == false) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(Strings.msgDeleted),
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
      range: cameraUi.zoomRange,
      displayZoom: cameraUi.displayZoom,
      onZoomSelected: (zoom) => cameraHost.applyZoom(state.sensorConfig, zoom),
    );
  }

  Widget buildCameraSwitchButton(CameraState state) {
    return IconButton(
      onPressed: () => state.switchCameraSensor(flash: cameraHost.flashMode),
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

  Widget _buildPermissionGate() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _buildIconBackWidget() {
    return IconButton(
      onPressed: () => context.pop(),
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      color: Colors.white,
    );
  }

  Widget _buildIconSettingWidget() {
    bool isActive = cameraUi.showControlPanel;

    return IconButton(
      onPressed: cameraHost.toggleControlPanel,
      icon: Icon(
        isActive ? Icons.tune_rounded : Icons.tune_outlined,
        color: isActive ? Colors.white : Colors.white70,
      ),
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
              child: _checkingPermissions || !_permissionsReady
                  ? _buildPermissionGate()
                  : Stack(
                children: [
                  if (_cameraRunning)
                    KeyedSubtree(
                      key: ValueKey('${cameraWidgetKey}_$_cameraSession'),
                      child: CameraAwesomeBuilder.awesome(
                        saveConfig: buildSaveConfig(),
                        sensorConfig: SensorConfig.single(
                          sensor: Sensor.position(SensorPosition.back),
                          flashMode: cameraHost.flashMode,
                          aspectRatio: initialAspectRatio,
                        ),
                        enablePhysicalButton: true,
                        previewFit: previewFit,
                        previewAlignment: previewAlignment,
                        previewDecoratorBuilder:
                            portraitViewportHeightOverWidth == null
                                ? null
                                : (state, preview) =>
                                    AspectRatioPreviewOverlay(
                                      heightOverWidth:
                                          portraitViewportHeightOverWidth!,
                                    ),
                        theme: AwesomeTheme(
                          bottomActionsBackgroundColor: Colors.transparent,
                        ),
                        availableFilters: awesomePresetFiltersList,
                        onPreviewScaleBuilder: (state) => OnPreviewScale(
                          onScale: (normalized) {
                            final double display = cameraUi.zoomRange
                                .clampDisplayZoom(
                              cameraUi.zoomRange.toDisplay(normalized),
                            );
                            state.sensorConfig.setZoom(normalized);
                            Future.microtask(() {
                              if (!mounted) return;
                              cameraHost.setDisplayZoom(display);
                            });
                          },
                        ),
                        onPreviewTapBuilder: CameraFocusHelper.buildPreviewTap,
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
                        middleContentBuilder: buildMiddleContentWrapper,
                        bottomActionsBuilder: buildBottomBar,
                      ),
                    )
                  else
                    const ColoredBox(color: Colors.black),
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

