import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:path_provider/path_provider.dart';

class MediaPathBuilder {
  static Future<Directory> _mediaDirectory() async {
    final Directory baseDir = await getApplicationDocumentsDirectory();
    return Directory('${baseDir.path}/roketota_media').create(recursive: true);
  }

  static Future<CaptureRequest> photoPath(List<Sensor> sensors) async {
    final Directory mediaDir = await _mediaDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    if (sensors.length == 1) {
      final String filePath = '${mediaDir.path}/photo_$timestamp.jpg';
      return SingleCaptureRequest(filePath, sensors.first);
    }

    return MultipleCaptureRequest({
      for (final sensor in sensors)
        sensor:
            '${mediaDir.path}/${sensor.position == SensorPosition.front ? 'front' : 'back'}_$timestamp.jpg',
    });
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
