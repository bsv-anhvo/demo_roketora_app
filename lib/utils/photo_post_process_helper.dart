import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:demo_roketota_app/core/extensions/camera_aspect_ratio_extension.dart';
import 'package:demo_roketota_app/core/models/photo_post_process_input.dart';
import 'package:demo_roketota_app/services/media_capture_metadata_service.dart';
import 'package:demo_roketota_app/utils/photo_filter_helper.dart';
import 'package:demo_roketota_app/utils/camera_helper.dart';
import 'package:flutter/foundation.dart';

class PhotoPostProcessTask {
  const PhotoPostProcessTask({
    required this.originalPath,
    required this.filterPath,
    required this.filterId,
    required this.needsSoftwareCrop,
    required this.portraitWidthOverHeight,
    this.brightnessAdj = 0,
  });

  final String originalPath;
  final String filterPath;
  final String filterId;
  final bool needsSoftwareCrop;
  final double portraitWidthOverHeight;
  final double brightnessAdj;

  factory PhotoPostProcessTask.fromInput(PhotoPostProcessInput input) {
    return PhotoPostProcessTask(
      originalPath: input.originalPath,
      filterPath: input.filterPath,
      filterId: input.activeFilter.id,
      needsSoftwareCrop: input.aspectRatio.needsSoftwareCrop,
      portraitWidthOverHeight: input.aspectRatio.portraitWidthOverHeight,
      brightnessAdj: CameraHelper.brightnessAdjFromNormalized(input.brightness),
    );
  }
}

AwesomeFilter _filterForId(String filterId) {
  for (final AwesomeFilter filter in awesomePresetFiltersList) {
    if (filter.id == filterId) {
      return filter;
    }
  }
  return AwesomeFilter.None;
}

Future<void> photoPostProcessInBackground(PhotoPostProcessTask task) async {
  await PhotoFilterHelper.normalizeOrientation(task.originalPath);

  if (task.needsSoftwareCrop) {
    await PhotoFilterHelper.centerCropToPortraitRatio(
      task.originalPath,
      task.portraitWidthOverHeight,
    );
  }

  await File(task.originalPath).copy(task.filterPath);
  await PhotoFilterHelper.applyToFile(
    task.filterPath,
    _filterForId(task.filterId),
  );
  await PhotoFilterHelper.applyBrightnessToFile(
    task.filterPath,
    task.brightnessAdj,
  );
}

class PhotoPostProcessHelper {
  const PhotoPostProcessHelper._();

  static Future<void> processAfterCapture(PhotoPostProcessInput input) async {
    await compute(
      photoPostProcessInBackground,
      PhotoPostProcessTask.fromInput(input),
    );

    await MediaCaptureMetadataService.instance.registerPhotoCapture(
      capturedAt: input.capturedAt,
      filterStampPath: input.filterPath,
      originalStampPath: input.originalPath,
    );
  }
}
