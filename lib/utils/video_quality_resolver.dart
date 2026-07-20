import 'package:camerawesome/pigeon.dart';
import 'package:demo_roketota_app/core/models/camera_settings.dart';
import 'package:flutter/services.dart';

class VideoQualityRange {
  const VideoQualityRange({
    required this.min,
    required this.max,
  });

  final VideoRecordingQuality min;
  final VideoRecordingQuality max;

  List<VideoRecordingQuality> filterOptions(
    List<VideoRecordingQuality> options,
  ) {
    return options
        .where(
          (quality) =>
              quality.index == min.index || quality.index == max.index,
        )
        .toList();
  }
}

/// Resolves device-supported video quality bounds for the recording picker.
class VideoQualityResolver {
  VideoQualityResolver._();

  static const MethodChannel _channel = MethodChannel(
    'com.roketota.demo_roketota_app/video_quality',
  );

  static Future<VideoQualityRange> getSupportedRange() async {
    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getVideoQualityRange',
      );
      if (result == null) {
        return _defaultRange();
      }

      final VideoRecordingQuality? min =
          _parseQuality(result['min'] as String?);
      final VideoRecordingQuality? max =
          _parseQuality(result['max'] as String?);
      if (min == null || max == null || min.index > max.index) {
        return _defaultRange();
      }

      return VideoQualityRange(min: min, max: max);
    } on PlatformException {
      return _defaultRange();
    } on MissingPluginException {
      return _defaultRange();
    }
  }

  static VideoQualityRange _defaultRange() {
    return VideoQualityRange(
      min: kVideoQualities.first,
      max: kVideoQualities.last,
    );
  }

  static VideoRecordingQuality? _parseQuality(String? value) {
    return switch (value) {
      'hd' => VideoRecordingQuality.hd,
      'fhd' => VideoRecordingQuality.fhd,
      'uhd' => VideoRecordingQuality.uhd,
      _ => null,
    };
  }
}
