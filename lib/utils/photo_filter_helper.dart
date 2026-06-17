import 'dart:io';
import 'dart:typed_data';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:demo_roketota_app/utils/strings.dart';
import 'package:image/image.dart' as img;

class PhotoFilterHelper {
  const PhotoFilterHelper._();

  static Future<img.Image> _decodeOrientedImage(Uint8List bytes) async {
    final img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception(Strings.msgDecodeImageFailed.replaceAll('%s', 'bytes'));
    }
    return image;
  }

  /// Bakes EXIF orientation into pixel data so the image displays upright everywhere.
  static Future<Uint8List> normalizeOrientationBytes(Uint8List bytes) async {
    final img.Image image = await _decodeOrientedImage(bytes);
    return Uint8List.fromList(img.encodeJpg(image, quality: 95));
  }

  static Future<Uint8List> applyFilterToBytes(
    Uint8List bytes,
    AwesomeFilter filter,
  ) async {
    if (filter.id == AwesomeFilter.None.id) {
      return bytes;
    }

    final img.Image image = await _decodeOrientedImage(bytes);
    final Uint8List pixels = image.getBytes();
    filter.output.apply(pixels, image.width, image.height);

    final img.Image output = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: pixels.buffer,
    );

    final List<int> encoded = img.encodeJpg(output, quality: 95);
    return Uint8List.fromList(encoded);
  }

  /// Bakes EXIF orientation into pixel data so the file displays upright everywhere.
  static Future<void> normalizeOrientation(String filePath) async {
    final Uint8List bytes = await File(filePath).readAsBytes();
    final Uint8List normalized = await normalizeOrientationBytes(bytes);
    await File(filePath).writeAsBytes(normalized);
  }

  static Future<void> applyToFile(String filePath, AwesomeFilter filter) async {
    if (filter.id == AwesomeFilter.None.id) return;

    final Uint8List bytes = await File(filePath).readAsBytes();
    final Uint8List filtered = await applyFilterToBytes(bytes, filter);
    await File(filePath).writeAsBytes(filtered);
  }
}
