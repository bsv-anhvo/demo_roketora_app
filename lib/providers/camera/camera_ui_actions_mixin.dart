import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:demo_roketota_app/models/camera_settings.dart';
import 'package:demo_roketota_app/providers/camera/camera_ui_state.dart';
import 'package:demo_roketota_app/utils/camera_exposure_helper.dart';
import 'package:demo_roketota_app/utils/camera_zoom_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contract for shared camera UI operations.
abstract interface class CameraUiHost {
  CameraUiState get cameraUi;
  FlashMode get flashMode;
  void toggleControlPanel();
  Future<void> applyFlash(SensorConfig sensorConfig);
  Future<void> applyZoom(SensorConfig sensorConfig, double zoom);
  void setDisplayZoom(double zoom);
  void setOpeningPreview(bool value);
  void resetCameraSession();
  void onCameraReadyBase(CameraState state);
  Future<void> refreshZoomRange(CameraState state);
}

/// Shared camera UI mutations for photo and video notifiers.
mixin CameraUiActions<S> on AutoDisposeNotifier<S> implements CameraUiHost {
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
      showFilterStrip: nextVisible ? cameraUi.showFilterStrip : false,
    );
  }

  void setFlash(FlashSetting flash) {
    cameraUi = cameraUi.copyWith(flash: flash);
  }

  void toggleExposureSlider() {
    cameraUi = cameraUi.copyWith(
      showExposureSlider: !cameraUi.showExposureSlider,
    );
  }

  void toggleFilterStrip() {
    cameraUi = cameraUi.copyWith(showFilterStrip: !cameraUi.showFilterStrip);
  }

  void setExposure(double value) {
    cameraUi = cameraUi.copyWith(exposure: value);
  }

  Future<void> applyExposure(double value) async {
    final double clamped = value.clamp(0.0, 1.0);
    setExposure(clamped);
    await CameraExposureHelper.apply(clamped);
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
  Future<void> applyZoom(SensorConfig sensorConfig, double zoom) async {
    final double clamped = cameraUi.zoomRange.clampDisplayZoom(zoom);
    final double normalized = cameraUi.zoomRange.toNormalized(clamped);
    await sensorConfig.setZoom(normalized);
    setDisplayZoom(clamped);
  }

  @override
  Future<void> refreshZoomRange(CameraState state) async {
    final ZoomRange range = await CameraZoomHelper.load();
    final double initialZoom = CameraZoomHelper.defaultDisplayZoom(range);

    cameraUi = cameraUi.copyWith(
      zoomRange: range,
      displayZoom: initialZoom,
    );

    await applyZoom(state.sensorConfig, initialZoom);
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
    CameraExposureHelper.apply(cameraUi.exposure);
  }
}
