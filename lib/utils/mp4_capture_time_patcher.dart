import 'dart:io';

import 'package:flutter/foundation.dart';

/// Patches MP4 movie/track header creation times in-place (no re-encode).
class Mp4CaptureTimePatcher {
  const Mp4CaptureTimePatcher._();

  static final DateTime _mp4EpochUtc = DateTime.utc(1904, 1, 1);

  /// Stores device-local wall-clock digits in MP4 epoch fields.
  static int localWallClockToMp4Seconds(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();
    final DateTime pseudoUtc = DateTime.utc(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
      local.second,
      local.millisecond,
    );
    return pseudoUtc.difference(_mp4EpochUtc).inSeconds;
  }

  static Future<bool> patchCaptureTime(
    String filePath,
    DateTime capturedAt,
  ) async {
    final File file = File(filePath);
    if (!await file.exists()) return false;

    try {
      final Uint8List bytes = await file.readAsBytes();
      if (bytes.length < 16) return false;

      final int mp4Seconds = localWallClockToMp4Seconds(capturedAt);
      final int patches = _patchTopLevel(bytes, mp4Seconds);
      if (patches == 0) return false;

      await file.writeAsBytes(bytes, flush: true);
      return true;
    } catch (e, stackTrace) {
      debugPrint('MP4 capture time patch failed for $filePath: $e\n$stackTrace');
      return false;
    }
  }

  static int _patchTopLevel(Uint8List bytes, int mp4Seconds) {
    int patches = 0;
    int position = 0;

    while (position + 8 <= bytes.length) {
      final _Mp4Box? box = _readBox(bytes, position, bytes.length);
      if (box == null) break;

      if (box.type == 'moov') {
        patches += _patchContainer(bytes, box.contentStart, box.end, mp4Seconds);
      }

      position = box.end;
    }

    return patches;
  }

  static int _patchContainer(
    Uint8List bytes,
    int start,
    int end,
    int mp4Seconds,
  ) {
    int patches = 0;
    int position = start;

    while (position + 8 <= end) {
      final _Mp4Box? box = _readBox(bytes, position, end);
      if (box == null) break;

      switch (box.type) {
        case 'mvhd':
        case 'tkhd':
        case 'mdhd':
          if (_patchFullBoxTimes(bytes, box, mp4Seconds)) {
            patches++;
          }
        case 'trak':
        case 'mdia':
          patches += _patchContainer(
            bytes,
            box.contentStart,
            box.end,
            mp4Seconds,
          );
        default:
          break;
      }

      position = box.end;
    }

    return patches;
  }

  static bool _patchFullBoxTimes(
    Uint8List bytes,
    _Mp4Box box,
    int mp4Seconds,
  ) {
    if (box.contentEnd - box.contentStart < 4) return false;

    final int version = bytes[box.contentStart];
    final int creationOffset = box.contentStart + 4;

    if (version == 1) {
      if (box.contentEnd - creationOffset < 16) return false;
      _writeUint64BE(bytes, creationOffset, mp4Seconds);
      _writeUint64BE(bytes, creationOffset + 8, mp4Seconds);
      return true;
    }

    if (box.contentEnd - creationOffset < 8) return false;
    _writeUint32BE(bytes, creationOffset, mp4Seconds);
    _writeUint32BE(bytes, creationOffset + 4, mp4Seconds);
    return true;
  }

  static _Mp4Box? _readBox(Uint8List bytes, int position, int maxEnd) {
    if (position + 8 > maxEnd) return null;

    int size = _readUint32BE(bytes, position);
    final String type = _readType(bytes, position + 4);
    int headerSize = 8;
    int contentStart = position + 8;

    if (size == 1) {
      if (position + 16 > maxEnd) return null;
      size = _readUint64BE(bytes, position + 8);
      headerSize = 16;
      contentStart = position + 16;
    } else if (size == 0) {
      size = maxEnd - position;
    }

    if (size < headerSize || position + size > maxEnd) return null;

    return _Mp4Box(
      start: position,
      end: position + size,
      type: type,
      contentStart: contentStart,
      contentEnd: position + size,
    );
  }

  static int _readUint32BE(Uint8List bytes, int offset) {
    return ByteData.sublistView(bytes, offset, offset + 4).getUint32(0, Endian.big);
  }

  static int _readUint64BE(Uint8List bytes, int offset) {
    return ByteData.sublistView(bytes, offset, offset + 8).getUint64(0, Endian.big);
  }

  static String _readType(Uint8List bytes, int offset) {
    return String.fromCharCodes(bytes.sublist(offset, offset + 4));
  }

  static void _writeUint32BE(Uint8List bytes, int offset, int value) {
    ByteData.sublistView(bytes, offset, offset + 4).setUint32(0, value, Endian.big);
  }

  static void _writeUint64BE(Uint8List bytes, int offset, int value) {
    ByteData.sublistView(bytes, offset, offset + 8).setUint64(0, value, Endian.big);
  }
}

class _Mp4Box {
  const _Mp4Box({
    required this.start,
    required this.end,
    required this.type,
    required this.contentStart,
    required this.contentEnd,
  });

  final int start;
  final int end;
  final String type;
  final int contentStart;
  final int contentEnd;
}
