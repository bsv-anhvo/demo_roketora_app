import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:demo_roketota_app/core/extensions/logger_extension.dart';
import 'package:demo_roketota_app/utils/photo_filter_helper.dart';
import 'package:demo_roketota_app/utils/strings.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/stream_information.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class VideoFilterHelper {
  const VideoFilterHelper._();

  static const int _frameBatchSize = 6;
  static const int _maxFilterHeight = 1080;

  static Future<void> applyToFile(
    String filePath,
    AwesomeFilter filter, {
    int? fallbackFps,
  }) async {
    if (filter.id == AwesomeFilter.None.id) return;

    final Directory workDir = Directory(
      '${(await getTemporaryDirectory()).path}/video_filter_${DateTime.now().millisecondsSinceEpoch}',
    );
    await workDir.create(recursive: true);

    final String framesPattern = '${workDir.path}/frame_%06d.jpg';
    final String outputPath = '${workDir.path}/filtered.mp4';

    try {
      final double fps = fallbackFps?.toDouble() ??
          await _probeVideoFps(filePath) ??
          30;

      final extractSession = await FFmpegKit.executeWithArguments(<String>[
        '-y',
        '-i',
        filePath,
        '-vf',
        'fps=$fps,scale=-2:$_maxFilterHeight',
        '-qscale:v',
        '4',
        framesPattern,
      ]);
      if (!ReturnCode.isSuccess(await extractSession.getReturnCode())) {
        throw Exception(Strings.msgFailedToExtractVideoFrames);
      }

      final List<File> frames = workDir
          .listSync()
          .whereType<File>()
          .where((File file) => file.path.endsWith('.jpg'))
          .toList()
        ..sort(
          (File a, File b) => a.path.compareTo(b.path),
        );

      if (frames.isEmpty) {
        throw Exception(Strings.msgNoFramesExtractedFromVideo);
      }

      for (int index = 0; index < frames.length; index += _frameBatchSize) {
        final int end = (index + _frameBatchSize).clamp(0, frames.length);
        final List<File> batch = frames.sublist(index, end);
        await Future.wait<void>(
          batch.map(
            (File frame) => PhotoFilterHelper.applyToFile(frame.path, filter),
          ),
        );
      }

      final List<String> muxArgs = <String>[
        '-y',
        '-framerate',
        fps.toStringAsFixed(3),
        '-i',
        framesPattern,
        '-i',
        filePath,
        '-map',
        '0:v:0',
        '-map',
        '1:a:0?',
        '-c:v',
        'libx264',
        '-preset',
        'ultrafast',
        '-crf',
        '23',
        '-pix_fmt',
        'yuv420p',
        '-shortest',
        outputPath,
      ];

      final muxSession = await FFmpegKit.executeWithArguments(muxArgs);
      if (!ReturnCode.isSuccess(await muxSession.getReturnCode())) {
        throw Exception(Strings.msgFailedToEncodeFilteredVideo);
      }

      await File(outputPath).copy(filePath);
    } catch (e, stackTrace) {
      'Video filter apply failed: $e\n$stackTrace'.log();
      rethrow;
    } finally {
      if (await workDir.exists()) {
        await workDir.delete(recursive: true);
      }
    }
  }

  static Future<double?> _probeVideoFps(String filePath) async {
    try {
      final session = await FFprobeKit.getMediaInformation(filePath);
      final streams =
          session.getMediaInformation()?.getStreams() ?? <StreamInformation>[];

      for (final StreamInformation stream in streams) {
        if (stream.getType() != 'video') continue;

        return _parseFrameRate(
          stream.getAverageFrameRate() ?? stream.getRealFrameRate(),
        );
      }
    } catch (e, stackTrace) {
      'Video fps probe failed: $e\n$stackTrace'.log();
    }
    return null;
  }

  static double? _parseFrameRate(String? value) {
    if (value == null || value.isEmpty || value == '0/0') return null;

    final List<String> parts = value.split('/');
    if (parts.length == 2) {
      final double? numerator = double.tryParse(parts[0]);
      final double? denominator = double.tryParse(parts[1]);
      if (numerator != null && denominator != null && denominator != 0) {
        return numerator / denominator;
      }
    }

    return double.tryParse(value);
  }
}
