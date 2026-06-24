import 'package:demo_roketota_app/core/models/camera_settings.dart';
import 'package:demo_roketota_app/core/models/zoom_range.dart';
import 'package:demo_roketota_app/utils/constants.dart';

class CameraUiState {
  static const double defaultExposure = 0.5;

  const CameraUiState({
    this.flash = FlashSetting.off,
    this.exposure = defaultExposure,
    this.showExposureSlider = false,
    this.showFilterStrip = false,
    this.showControlPanel = false,
    this.isOpeningPreview = false,
    this.zoomRange = Constants.fallbackRange,
    this.displayZoom = 1.0,
    this.cameraReady = false,
    this.zoomRangeLoaded = false,
  });

  final FlashSetting flash;
  final double exposure;
  final bool showExposureSlider;
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
    bool? showExposureSlider,
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
      showExposureSlider: showExposureSlider ?? this.showExposureSlider,
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
