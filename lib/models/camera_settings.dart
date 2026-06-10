import 'package:camerawesome/pigeon.dart';
import 'package:flutter/services.dart';

enum FlashSetting { off, on, auto }

enum PhotoTimerOption { off, three, five, ten }

enum PhotoCaptureStyle { normal, portrait }

extension FlashSettingX on FlashSetting {
  String get label => switch (this) {
        FlashSetting.off => 'Off',
        FlashSetting.on => 'On',
        FlashSetting.auto => 'Auto',
      };

  FlashSetting get next => switch (this) {
        FlashSetting.off => FlashSetting.on,
        FlashSetting.on => FlashSetting.auto,
        FlashSetting.auto => FlashSetting.off,
      };
}

extension PhotoTimerOptionX on PhotoTimerOption {
  int get seconds => switch (this) {
        PhotoTimerOption.off => 0,
        PhotoTimerOption.three => 3,
        PhotoTimerOption.five => 5,
        PhotoTimerOption.ten => 10,
      };

  String get label => switch (this) {
        PhotoTimerOption.off => 'Off',
        PhotoTimerOption.three => '3s',
        PhotoTimerOption.five => '5s',
        PhotoTimerOption.ten => '10s',
      };

  PhotoTimerOption get next => switch (this) {
        PhotoTimerOption.off => PhotoTimerOption.three,
        PhotoTimerOption.three => PhotoTimerOption.five,
        PhotoTimerOption.five => PhotoTimerOption.ten,
        PhotoTimerOption.ten => PhotoTimerOption.off,
      };
}

extension VideoRecordingQualityX on VideoRecordingQuality {
  String get label => switch (this) {
        VideoRecordingQuality.lowest => 'Lowest',
        VideoRecordingQuality.sd => 'SD',
        VideoRecordingQuality.hd => 'HD',
        VideoRecordingQuality.fhd => 'FHD',
        VideoRecordingQuality.uhd => '4K',
        VideoRecordingQuality.highest => 'Highest',
      };
}

class PhotoResolutionOption {
  const PhotoResolutionOption({
    required this.width,
    required this.height,
  });

  final int width;
  final int height;

  String get label => '${width}x$height';

  int get megapixels => ((width * height) / 1000000).round();
}

class VideoFpsOption {
  const VideoFpsOption(this.fps);

  final int fps;

  String get label => '$fps FPS';
}

const List<VideoRecordingQuality> kVideoQualities = [
  VideoRecordingQuality.sd,
  VideoRecordingQuality.hd,
  VideoRecordingQuality.fhd,
  VideoRecordingQuality.uhd,
];

const List<VideoFpsOption> kVideoFpsOptions = [
  VideoFpsOption(24),
  VideoFpsOption(30),
  VideoFpsOption(60),
];

const List<DeviceOrientation> kCameraOrientations = [
  DeviceOrientation.portraitUp,
  DeviceOrientation.portraitDown,
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];
