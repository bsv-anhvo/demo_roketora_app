import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:path_provider/path_provider.dart';

class MediaPathBuilder {
  static Future<Directory> _mediaDirectory() async {
    final Directory baseDir = await getApplicationDocumentsDirectory();
    return Directory('${baseDir.path}/roketota_media').create(recursive: true);
  }

  static Future<CaptureRequest> photoPath(List<Sensor> sensors) async {
    final String filterPath = (await photoPairPaths()).filterPath;

    if (sensors.length == 1) {
      return SingleCaptureRequest(filterPath, sensors.first);
    }

    final Directory mediaDir = await _mediaDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    return MultipleCaptureRequest({
      for (final sensor in sensors)
        sensor:
            '${mediaDir.path}/${sensor.position == SensorPosition.front ? 'front' : 'back'}_$timestamp.jpg',
    });
  }

  static Future<({String originalPath, String filterPath})> photoPairPaths() async {
    final Directory mediaDir = await _mediaDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return (
      originalPath: '${mediaDir.path}/photo_original_$timestamp.jpg',
      filterPath: '${mediaDir.path}/photo_$timestamp.jpg',
    );
  }

  static String? originalPathForFilter(String filterPath) {
    final RegExp match = RegExp(r'photo_(\d+)\.jpg$');
    final RegExpMatch? result = match.firstMatch(filterPath);
    if (result == null) return null;

    final String dir = filterPath.substring(0, filterPath.lastIndexOf('/'));
    return '$dir/photo_original_${result.group(1)}.jpg';
  }

  static Future<CaptureRequest> videoPath(List<Sensor> sensors) async {
    final Directory mediaDir = await _mediaDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    if (sensors.length == 1) {
      final String filePath = '${mediaDir.path}/video_$timestamp.mp4';
      return SingleCaptureRequest(filePath, sensors.first);
    }

    return MultipleCaptureRequest({
      for (final sensor in sensors)
        sensor:
            '${mediaDir.path}/${sensor.position == SensorPosition.front ? 'front' : 'back'}_$timestamp.mp4',
    });
  }
}
