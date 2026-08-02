import 'package:camerawesome/pigeon.dart';
import 'package:demo_roketota_app/core/models/camera_settings.dart';
import 'package:flutter/services.dart';

/// Resolves the device max supported video FPS for the recording picker.
class VideoFpsResolver {
  VideoFpsResolver._();

  static const MethodChannel _channel = MethodChannel(
    'com.roketota.demo_roketota_app/video_fps',
  );

  static const int _defaultMaxFps = 30;

  /// Returns the highest frame rate the back camera can sustain at [quality].
  ///
  /// When [quality] is set, only formats that meet that resolution are considered
  /// (e.g. 4K@60 is only reported if a 4K format supports 60fps).
  static Future<int> getMaxSupportedFps({
    VideoRecordingQuality? quality,
  }) async {
    try {
      final int? result = await _channel.invokeMethod<int>(
        'getMaxSupportedFps',
        <String, dynamic>{
          if (quality != null) 'quality': _qualityKey(quality),
        },
      );
      if (result == null || result <= 0) {
        return _defaultMaxFps;
      }
      return result;
    } on PlatformException {
      return _defaultMaxFps;
    } on MissingPluginException {
      return _defaultMaxFps;
    }
  }

  /// Keeps only [kVideoFpsOptions] entries the device can actually reach.
  static List<VideoFpsOption> filterOptions(
    List<VideoFpsOption> options,
    int maxFps,
  ) {
    final List<VideoFpsOption> filtered =
        options.where((option) => option.fps <= maxFps).toList();
    if (filtered.isNotEmpty) {
      return filtered;
    }
    return options
        .where((option) => option.fps <= _defaultMaxFps)
        .toList();
  }

  static String _qualityKey(VideoRecordingQuality quality) {
    return switch (quality) {
      VideoRecordingQuality.uhd || VideoRecordingQuality.highest => 'uhd',
      VideoRecordingQuality.fhd => 'fhd',
      VideoRecordingQuality.hd => 'hd',
      VideoRecordingQuality.sd || VideoRecordingQuality.lowest => 'hd',
    };
  }
}
