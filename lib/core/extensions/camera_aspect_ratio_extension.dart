import 'dart:io';

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

  /// Portrait width / height (e.g. 3/4 for 4:3, 1 for 1:1).
  double get portraitWidthOverHeight {
    switch (this) {
      case CameraAspectRatios.ratio_4_3:
        return 3 / 4;
      case CameraAspectRatios.ratio_16_9:
        return 9 / 16;
      case CameraAspectRatios.ratio_1_1:
        return 1;
    }
  }

  /// Whether the native sensor preset is unavailable on the current platform.
  bool get needsSoftwareCrop {
    if (this != CameraAspectRatios.ratio_1_1) return false;
    return Platform.isAndroid;
  }
}
