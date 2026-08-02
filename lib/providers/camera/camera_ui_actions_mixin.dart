import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:demo_roketota_app/core/models/camera_settings.dart';
import 'package:demo_roketota_app/core/models/zoom_range.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_state.dart';
import 'package:demo_roketota_app/utils/camera_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contract for shared camera UI operations.
abstract interface class CameraUiHost {
  CameraUiState get cameraUi;
  FlashMode get flashMode;
  void toggleControlPanel();
  void toggleExposureSlider();
  void toggleBrightnessSlider();
  Future<void> applyFlash(SensorConfig sensorConfig);
  Future<void> applyExposure(double value);
  void applyBrightness(CameraState state, double value);
  Future<void> applyZoom(CameraState cameraState, double zoom);
  void setDisplayZoom(double zoom);
  void setOpeningPreview(bool value);
  void resetCameraSession();
  void onCameraReadyBase(CameraState state);
  Future<void> refreshZoomRange(CameraState state);
}

/// Shared camera UI mutations for photo and video notifiers.
mixin CameraUiActions<S> on AutoDisposeNotifier<S> implements CameraUiHost {
  double? _pendingZoom;
  CameraState? _pendingZoomState;
  bool _zoomProcessing = false;

  @override
  CameraUiState get cameraUi;
  set cameraUi(CameraUiState value);

  @override
  FlashMode get flashMode => switch (cameraUi.flash) {
        FlashSetting.off => FlashMode.none,
        FlashSetting.on => FlashMode.on,
        FlashSetting.auto => FlashMode.auto,
      };

  @override
  void toggleControlPanel() {
    final bool nextVisible = !cameraUi.showControlPanel;
    cameraUi = cameraUi.copyWith(
      showControlPanel: nextVisible,
      showExposureSlider: nextVisible ? cameraUi.showExposureSlider : false,
      showBrightnessSlider: nextVisible ? cameraUi.showBrightnessSlider : false,
      showFilterStrip: nextVisible ? cameraUi.showFilterStrip : false,
    );
  }

  void setFlash(FlashSetting flash) {
    cameraUi = cameraUi.copyWith(flash: flash);
  }

  @override
  void toggleExposureSlider() {
    final bool next = !cameraUi.showExposureSlider;
    cameraUi = cameraUi.copyWith(
      showExposureSlider: next,
      showBrightnessSlider: next ? false : cameraUi.showBrightnessSlider,
    );
  }

  @override
  void toggleBrightnessSlider() {
    final bool next = !cameraUi.showBrightnessSlider;
    cameraUi = cameraUi.copyWith(
      showBrightnessSlider: next,
      showExposureSlider: next ? false : cameraUi.showExposureSlider,
    );
  }

  void toggleFilterStrip() {
    cameraUi = cameraUi.copyWith(showFilterStrip: !cameraUi.showFilterStrip);
  }

  void setExposure(double value) {
    cameraUi = cameraUi.copyWith(exposure: value);
  }

  void setBrightness(double value) {
    cameraUi = cameraUi.copyWith(brightness: value);
  }

  @override
  Future<void> applyExposure(double value) async {
    final double clamped = value.clamp(0.0, 1.0);
    setExposure(clamped);
    await CameraHelper.applyExposureValue(clamped);
  }

  @override
  void applyBrightness(CameraState state, double value) {
    final double clamped = value.clamp(0.0, 1.0);
    setBrightness(clamped);
    CameraHelper.applyPixelBrightness(state, clamped);
  }

  @override
  void setDisplayZoom(double zoom) {
    cameraUi = cameraUi.copyWith(displayZoom: zoom);
  }

  @override
  void setOpeningPreview(bool value) {
    cameraUi = cameraUi.copyWith(isOpeningPreview: value);
  }

  @override
  void resetCameraSession() {
    cameraUi = cameraUi.copyWith(
      cameraReady: false,
      zoomRangeLoaded: false,
    );
  }

  @override
  Future<void> applyFlash(SensorConfig sensorConfig) async {
    await sensorConfig.setFlashMode(flashMode);
  }

  @override
  Future<void> applyZoom(CameraState cameraState, double zoom) async {
    // Coalesce rapid pinch updates: keep only the latest target so a slow
    // native op (e.g. lens switch) never causes a backlog of stale frames.
    _pendingZoom = zoom;
    _pendingZoomState = cameraState;
    if (_zoomProcessing) return;

    _zoomProcessing = true;
    try {
      while (_pendingZoom != null) {
        final double target = _pendingZoom!;
        final CameraState state = _pendingZoomState!;
        _pendingZoom = null;
        _pendingZoomState = null;

        final double clamped = await CameraHelper.applyDisplayZoom(
          cameraState: state,
          range: cameraUi.zoomRange,
          displayZoom: target,
        );
        setDisplayZoom(clamped);
      }
    } finally {
      _zoomProcessing = false;
    }
  }

  @override
  Future<void> refreshZoomRange(CameraState state) async {
    final ZoomRange range = await CameraHelper.cameraZoomLoad();
    final double zoomToApply = range.clampDisplayZoom(cameraUi.displayZoom);

    cameraUi = cameraUi.copyWith(
      zoomRange: range,
      displayZoom: zoomToApply,
    );

    await applyZoom(state, zoomToApply);
  }

  @override
  void onCameraReadyBase(CameraState state) {
    Future.microtask(() => applyCameraReadyBaseSync(state));
  }

  void applyCameraReadyBaseSync(CameraState state) {
    if (!cameraUi.zoomRangeLoaded) {
      cameraUi = cameraUi.copyWith(zoomRangeLoaded: true);
      refreshZoomRange(state);
    }

    if (cameraUi.cameraReady) return;
    cameraUi = cameraUi.copyWith(cameraReady: true);
    CameraHelper.applyExposureValue(cameraUi.exposure);
    CameraHelper.applyPixelBrightness(state, cameraUi.brightness);
  }
}
