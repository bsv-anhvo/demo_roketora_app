import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:demo_roketota_app/utils/mp4_capture_time_patcher.dart';
import 'package:native_exif/native_exif.dart';

class MediaMetadataHelper {
  const MediaMetadataHelper._();

  static final DateFormat _exifDateFormat = DateFormat('yyyy:MM:dd HH:mm:ss');
  static final DateFormat _videoLocalClockFormat =
      DateFormat("yyyy-MM-dd'T'HH:mm:ss");
  static final DateFormat _videoLocalSpaceFormat =
      DateFormat('yyyy-MM-dd HH:mm:ss');
  static const String _legacyMetadataSuffix = '.metadata.tmp.mp4';
  static const String _metadataFfmetaSuffix = '.creation.ffmeta';

  static Future<void> _videoMetadataWriteLock = Future<void>.value();

  static String formatExifDateTime(DateTime dateTime) {
    return _exifDateFormat.format(dateTime.toLocal());
  }

  static String formatVideoExifLocalDate(DateTime dateTime) {
    return formatExifDateTime(dateTime);
  }

  /// Device-local wall clock with compact ISO-8601 offset (e.g. +0700).
  static String formatVideoIsoWithDeviceOffset(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();
    final Duration offset = local.timeZoneOffset;
    final String sign = offset.isNegative ? '-' : '+';
    final int totalMinutes = offset.inMinutes;
    final int hours = totalMinutes ~/ 60;
    final int minutes = totalMinutes.abs() % 60;
    final String clock = _videoLocalClockFormat.format(local);
    final String millis = '.${local.millisecond.toString().padLeft(3, '0')}';
    final String offsetLabel =
        '$sign${hours.abs().toString().padLeft(2, '0')}${minutes.toString().padLeft(2, '0')}';
    return '$clock$millis$offsetLabel';
  }

  /// Local wall-clock without timezone suffix; FFmpeg treats this as local time.
  static String formatVideoCreationTimeLocalWallClock(DateTime dateTime) {
    return _videoLocalSpaceFormat.format(dateTime.toLocal());
  }

  /// Local wall-clock with Z suffix so stored digits match device local time.
  static String formatVideoCreationTimeLiteral(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();
    return '${_videoLocalClockFormat.format(local)}.000000Z';
  }

  static String legacyMetadataSidecarPath(String filePath) =>
      '$filePath$_legacyMetadataSuffix';

  static Future<void> deleteLegacyMetadataSidecars(
    Iterable<String> filePaths,
  ) async {
    for (final String filePath in filePaths) {
      await _deleteIfExists(legacyMetadataSidecarPath(filePath));
    }
  }

  static Future<void> deleteOrphanedMetadataSidecarsInDirectory(
    Directory directory,
  ) async {
    if (!await directory.exists()) return;

    await for (final FileSystemEntity entity in directory.list()) {
      if (entity is! File) continue;
      if (entity.path.endsWith(_legacyMetadataSuffix)) {
        await _deleteIfExists(entity.path);
      }
    }
  }

  static Future<void> writePhotoCaptureTimestamp(
    String filePath,
    DateTime capturedAt,
  ) async {
    if (!await File(filePath).exists()) return;

    try {
      final Exif exif = await Exif.fromPath(filePath);
      final String exifDate = formatExifDateTime(capturedAt);

      await exif.writeAttributes(<String, String>{
        'DateTimeOriginal': exifDate,
        'DateTimeDigitized': exifDate,
        'DateTime': exifDate,
      });
      await exif.close();
    } catch (e, stackTrace) {
      debugPrint('Write photo EXIF failed for $filePath: $e\n$stackTrace');
    }
  }

  static Future<void> writeVideoCaptureTimestamp(
    String filePath,
    DateTime capturedAt,
  ) async {
    await _withVideoMetadataWriteLock(() async {
      await _writeVideoCaptureTimestampUnlocked(filePath, capturedAt);
    });
  }

  static Future<void> _withVideoMetadataWriteLock(
    Future<void> Function() action,
  ) async {
    final Completer<void> release = Completer<void>();
    final Future<void> previous = _videoMetadataWriteLock;
    _videoMetadataWriteLock = previous.then((_) => release.future);
    await previous;
    try {
      await action();
    } finally {
      if (!release.isCompleted) {
        release.complete();
      }
    }
  }

  static Future<void> _writeVideoCaptureTimestampUnlocked(
    String filePath,
    DateTime capturedAt,
  ) async {
    final File sourceFile = File(filePath);
    if (!await sourceFile.exists()) return;

    await deleteLegacyMetadataSidecars(<String>[filePath]);

    if (!await _waitForReadableVideoFile(filePath)) {
      debugPrint('Write video metadata skipped: unreadable file $filePath');
      return;
    }

    final String creationLiteral = formatVideoCreationTimeLiteral(capturedAt);
    final String creationWithOffset =
        formatVideoIsoWithDeviceOffset(capturedAt);
    final String creationLocalWallClock =
        formatVideoCreationTimeLocalWallClock(capturedAt);

    final String parentDir = sourceFile.parent.path;
    final String tempPath =
        '$parentDir/video_meta_${DateTime.now().microsecondsSinceEpoch}.mp4';

    try {
      final bool patchedInPlace = await Mp4CaptureTimePatcher.patchCaptureTime(
        filePath,
        capturedAt,
      );
      if (patchedInPlace) return;

      debugPrint(
        'MP4 in-place patch missed headers for $filePath, trying FFmpeg remux',
      );

      final bool remuxed = await _remuxVideoWithCaptureMetadata(
        inputPath: filePath,
        outputPath: tempPath,
        creationLiteral: creationLiteral,
        creationWithOffset: creationWithOffset,
        creationLocalWallClock: creationLocalWallClock,
      );

      if (!remuxed) {
        debugPrint('Write video metadata failed for $filePath');
        return;
      }

      final File tempFile = File(tempPath);
      if (!await tempFile.exists() || await tempFile.length() == 0) return;

      try {
        await sourceFile.delete();
        await tempFile.rename(filePath);
      } catch (_) {
        await tempFile.copy(filePath);
        await tempFile.delete();
      }
    } catch (e, stackTrace) {
      debugPrint('Write video metadata failed for $filePath: $e\n$stackTrace');
    } finally {
      await _deleteIfExists(tempPath);
      await deleteLegacyMetadataSidecars(<String>[filePath]);
    }
  }

  static Future<bool> _waitForReadableVideoFile(String filePath) async {
    int? lastSize;

    for (int attempt = 0; attempt < 12; attempt++) {
      final File file = File(filePath);
      if (!await file.exists()) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        continue;
      }

      final int size = await file.length();
      if (size == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        continue;
      }

      if (lastSize == size) {
        final session = await FFprobeKit.getMediaInformation(filePath);
        final information = session.getMediaInformation();
        if (information != null && information.getDuration() != null) {
          return true;
        }
      }

      lastSize = size;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    final File file = File(filePath);
    return await file.exists() && await file.length() > 0;
  }

  static Future<String?> _writeCreationTimeFfmeta(
    String filePath,
    String creationTime,
  ) async {
    final String ffmetaPath = '$filePath$_metadataFfmetaSuffix';
    final File ffmetaFile = File(ffmetaPath);
    try {
      await ffmetaFile.writeAsString(
        ';FFMETADATA1\n'
        'creation_time=$creationTime\n',
      );
      return ffmetaPath;
    } catch (e, stackTrace) {
      debugPrint('Write ffmeta failed for $filePath: $e\n$stackTrace');
      return null;
    }
  }

  static List<String> _metadataCopyArgs({
    required String inputPath,
    required String outputPath,
    required String creationTime,
    bool useMetadataTags = false,
    bool genPts = false,
  }) {
    return <String>[
      '-y',
      if (genPts) ...<String>['-fflags', '+genpts'],
      '-i',
      inputPath,
      '-map',
      '0:v:0',
      '-map',
      '0:a:0?',
      '-map_metadata',
      '0',
      '-c',
      'copy',
      '-metadata',
      'creation_time=$creationTime',
      if (useMetadataTags) ...<String>[
        '-movflags',
        'use_metadata_tags+faststart',
      ],
      outputPath,
    ];
  }

  static List<String> _metadataFfmetaCopyArgs({
    required String inputPath,
    required String ffmetaPath,
    required String outputPath,
  }) {
    return <String>[
      '-y',
      '-i',
      inputPath,
      '-i',
      ffmetaPath,
      '-map',
      '0:v:0',
      '-map',
      '0:a:0?',
      '-map_metadata',
      '1',
      '-c',
      'copy',
      '-movflags',
      'use_metadata_tags+faststart',
      outputPath,
    ];
  }

  static Future<bool> _remuxVideoWithCaptureMetadata({
    required String inputPath,
    required String outputPath,
    required String creationLiteral,
    required String creationWithOffset,
    required String creationLocalWallClock,
  }) async {
    final List<List<String>> attempts = <List<String>>[
      _metadataCopyArgs(
        inputPath: inputPath,
        outputPath: outputPath,
        creationTime: creationLiteral,
        useMetadataTags: true,
      ),
      _metadataCopyArgs(
        inputPath: inputPath,
        outputPath: outputPath,
        creationTime: creationLocalWallClock,
      ),
      _metadataCopyArgs(
        inputPath: inputPath,
        outputPath: outputPath,
        creationTime: creationWithOffset,
        useMetadataTags: true,
      ),
      _metadataCopyArgs(
        inputPath: inputPath,
        outputPath: outputPath,
        creationTime: creationLiteral,
        genPts: true,
      ),
      _metadataCopyArgs(
        inputPath: inputPath,
        outputPath: outputPath,
        creationTime: creationWithOffset,
      ),
    ];

    final List<String?> ffmetaPaths = <String?>[
      await _writeCreationTimeFfmeta(inputPath, creationLiteral),
      await _writeCreationTimeFfmeta(inputPath, creationWithOffset),
      await _writeCreationTimeFfmeta(inputPath, creationLocalWallClock),
    ];

    for (final String? ffmetaPath in ffmetaPaths) {
      if (ffmetaPath == null) continue;
      attempts.add(
        _metadataFfmetaCopyArgs(
          inputPath: inputPath,
          ffmetaPath: ffmetaPath,
          outputPath: outputPath,
        ),
      );
    }

    try {
      for (int index = 0; index < attempts.length; index++) {
        await _deleteIfExists(outputPath);

        final List<String> args = attempts[index];
        final session = await FFmpegKit.executeWithArguments(args);
        final ReturnCode? returnCode = await session.getReturnCode();

        final File outputFile = File(outputPath);
        if (ReturnCode.isSuccess(returnCode) &&
            await outputFile.exists() &&
            await outputFile.length() > 0) {
          return true;
        }

        final String? output = await session.getOutput();
        final String logs = await session.getAllLogsAsString() ?? '';
        debugPrint(
          'FFmpeg metadata attempt ${index + 1}/${attempts.length} failed '
          'for $inputPath (returnCode=$returnCode)',
        );
        debugPrint('FFmpeg args: $args');
        if (output != null && output.isNotEmpty) {
          debugPrint('FFmpeg output: $output');
        }
        if (logs.isNotEmpty) {
          final String tail = logs.length > 1500
              ? logs.substring(logs.length - 1500)
              : logs;
          debugPrint('FFmpeg logs: $tail');
        }
      }

      return false;
    } finally {
      for (final String? ffmetaPath in ffmetaPaths) {
        if (ffmetaPath != null) {
          await _deleteIfExists(ffmetaPath);
        }
      }
    }
  }

  static Future<void> _deleteIfExists(String path) async {
    final File file = File(path);
    if (!await file.exists()) return;
    await file.delete();
  }
}
