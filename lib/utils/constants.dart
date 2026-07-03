import 'package:demo_roketota_app/core/models/zoom_range.dart';
import 'package:flutter/material.dart';

class Constants {
  static const Duration quickRecordMaxDuration = Duration(seconds: 10);
  static const Duration videoRecordMaxDuration = Duration(seconds: 20);
  static const Duration focusIndicatorDuration = Duration(milliseconds: 2000);

  static const double defaultExposure = 0.5;
  static const double defaultZoomLevel = 1.0;

  static const double buttonSize = 80;
  static const double ringSize = 96;
  static const double desiredMin = 0.5;
  static const double desiredMax = 3.0;
  static const List<double> presetStops = [0.5, 1.0, 2.0, 3.0];

  static const String formatDateTime1 = 'yyyy:MM:dd HH:mm:ss';
  static const String formatDateTime2 = 'yyyy-MM-dd HH:mm:ss';
  static const String formatDateTime3 = "yyyy-MM-dd'T'HH:mm:ss";

  static const int versionDatabase = 1;

  static const String folderNameFileOriginal = 'roketora_media';
  static const String folderNameFileStamp = 'roketora_media_stamp';
  static const String folderNameOnGallery = 'Roketora';

  static const String databaseName = 'roketora_media.db';
  static const String tableMediaRecords = 'media_records';

  /// Used before native zoom limits are available (camera not ready yet).
  static const ZoomRange fallbackRange = ZoomRange(
    displayMin: 1.0,
    displayMax: 3.0,
    deviceMin: 1.0,
    deviceMax: 3.0,
  );

  static const BoxConstraints topBarIconConstraints = BoxConstraints(
    minWidth: 40,
    minHeight: 40,
  );
}
