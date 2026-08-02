import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:demo_roketota_app/utils/constants.dart';

class PhotoPostProcessInput {
  const PhotoPostProcessInput({
    required this.originalPath,
    required this.filterPath,
    required this.capturedAt,
    required this.activeFilter,
    required this.aspectRatio,
    this.brightness = Constants.defaultBrightness,
  });

  final String originalPath;
  final String filterPath;
  final DateTime capturedAt;
  final AwesomeFilter activeFilter;
  final CameraAspectRatios aspectRatio;

  /// Normalized pixel brightness in [0, 1]; 0.5 is neutral.
  final double brightness;
}
