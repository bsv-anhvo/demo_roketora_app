import 'package:demo_roketota_app/core/models/camera_settings.dart';
import 'package:demo_roketota_app/core/models/zoom_range.dart';
import 'package:demo_roketota_app/utils/constants.dart';

class CameraUiState {
  const CameraUiState({
    this.flash = FlashSetting.off,
    this.exposure = Constants.defaultExposure,
    this.brightness = Constants.defaultBrightness,
    this.showExposureSlider = false,
    this.showBrightnessSlider = false,
    this.showFilterStrip = false,
    this.showControlPanel = false,
    this.isOpeningPreview = false,
    this.zoomRange = Constants.fallbackRange,
    this.displayZoom = Constants.defaultZoomLevel,
    this.cameraReady = false,
    this.zoomRangeLoaded = false,
  });

  final FlashSetting flash;
  final double exposure;

  /// Normalized pixel brightness in [0, 1]; 0.5 is neutral.
  final double brightness;
  final bool showExposureSlider;
  final bool showBrightnessSlider;
  final bool showFilterStrip;
  final bool showControlPanel;
  final bool isOpeningPreview;
  final ZoomRange zoomRange;
  final double displayZoom;
  final bool cameraReady;
  final bool zoomRangeLoaded;

  CameraUiState copyWith({
    FlashSetting? flash,
    double? exposure,
    double? brightness,
    bool? showExposureSlider,
    bool? showBrightnessSlider,
    bool? showFilterStrip,
    bool? showControlPanel,
    bool? isOpeningPreview,
    ZoomRange? zoomRange,
    double? displayZoom,
    bool? cameraReady,
    bool? zoomRangeLoaded,
  }) {
    return CameraUiState(
      flash: flash ?? this.flash,
      exposure: exposure ?? this.exposure,
      brightness: brightness ?? this.brightness,
      showExposureSlider: showExposureSlider ?? this.showExposureSlider,
      showBrightnessSlider: showBrightnessSlider ?? this.showBrightnessSlider,
      showFilterStrip: showFilterStrip ?? this.showFilterStrip,
      showControlPanel: showControlPanel ?? this.showControlPanel,
      isOpeningPreview: isOpeningPreview ?? this.isOpeningPreview,
      zoomRange: zoomRange ?? this.zoomRange,
      displayZoom: displayZoom ?? this.displayZoom,
      cameraReady: cameraReady ?? this.cameraReady,
      zoomRangeLoaded: zoomRangeLoaded ?? this.zoomRangeLoaded,
    );
  }
}
