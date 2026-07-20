import 'package:camerawesome/camerawesome_plugin.dart';

class PhotoPostProcessInput {
  const PhotoPostProcessInput({
    required this.originalPath,
    required this.filterPath,
    required this.capturedAt,
    required this.activeFilter,
    required this.aspectRatio,
  });

  final String originalPath;
  final String filterPath;
  final DateTime capturedAt;
  final AwesomeFilter activeFilter;
  final CameraAspectRatios aspectRatio;
}
