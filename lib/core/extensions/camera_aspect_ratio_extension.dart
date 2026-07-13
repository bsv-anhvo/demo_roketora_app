import 'package:camerawesome/camerawesome_plugin.dart';

extension CameraAspectRatioExtension on CameraAspectRatios {
  double get value {
    switch (this) {
      case CameraAspectRatios.ratio_4_3:
        return 4 / 3;

      case CameraAspectRatios.ratio_16_9:
        return 16 / 9;

      case CameraAspectRatios.ratio_1_1:
        return 1;
    }
  }

  // static double widthOverHeight(CameraAspectRatios ratio) {
  //   return switch (ratio) {
  //     CameraAspectRatios.ratio_4_3 => 3 / 4,
  //     CameraAspectRatios.ratio_16_9 => 9 / 16,
  //     CameraAspectRatios.ratio_1_1 => 1,
  //   };
  // }
}
