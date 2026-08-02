import 'dart:io';
import 'dart:typed_data';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:demo_roketota_app/utils/strings.dart';
import 'package:image/image.dart' as img;

class PhotoFilterHelper {
  const PhotoFilterHelper._();

  static Future<img.Image> _decodeOrientedImage(String filePath) async {
    final Uint8List bytes = await File(filePath).readAsBytes();
    final img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception(Strings.msgDecodeImageFailed(filePath));
    }
    return image;
  }

  /// Bakes EXIF orientation into pixel data so the file displays upright everywhere.
  static Future<void> normalizeOrientation(String filePath) async {
    final img.Image image = await _decodeOrientedImage(filePath);
    await File(filePath).writeAsBytes(
      img.encodeJpg(image, quality: 88),
      flush: true,
    );
  }

  /// Center-crops to the target portrait width/height ratio.
  static Future<void> centerCropToPortraitRatio(
    String filePath,
    double portraitWidthOverHeight,
  ) async {
    final img.Image image = await _decodeOrientedImage(filePath);
    final double currentRatio = image.width / image.height;
    if ((currentRatio - portraitWidthOverHeight).abs() < 0.01) {
      return;
    }

    final int cropWidth;
    final int cropHeight;
    if (currentRatio > portraitWidthOverHeight) {
      cropHeight = image.height;
      cropWidth = (cropHeight * portraitWidthOverHeight).round();
    } else {
      cropWidth = image.width;
      cropHeight = (cropWidth / portraitWidthOverHeight).round();
    }

    final img.Image cropped = img.copyCrop(
      image,
      x: (image.width - cropWidth) ~/ 2,
      y: (image.height - cropHeight) ~/ 2,
      width: cropWidth,
      height: cropHeight,
    );

    await File(filePath).writeAsBytes(
      img.encodeJpg(cropped, quality: 88),
      flush: true,
    );
  }

  static Future<void> applyToFile(String filePath, AwesomeFilter filter) async {
    if (filter.id == AwesomeFilter.None.id) return;

    final img.Image image = await _decodeOrientedImage(filePath);
    final Uint8List pixels = image.getBytes();
    filter.output.apply(pixels, image.width, image.height);

    final img.Image output = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: pixels.buffer,
    );

    final List<int>? encoded = img.encodeNamedImage(filePath, output);
    if (encoded == null) {
      throw Exception(Strings.msgDecodeImageFailed(filePath));
    }

    await File(filePath).writeAsBytes(encoded, flush: true);
  }

  /// Applies pixel brightness adj in [-1, 1] (0 = unchanged).
  static Future<void> applyBrightnessToFile(
    String filePath,
    double adj,
  ) async {
    final double clamped = adj.clamp(-1.0, 1.0);
    if (clamped.abs() < 1e-6) return;

    final img.Image image = await _decodeOrientedImage(filePath);
    final Uint8List pixels = image.getBytes();
    final int delta = (255 * clamped).round();
    for (int i = 0; i < pixels.length; i += 4) {
      pixels[i] = _clampByte(pixels[i] + delta);
      pixels[i + 1] = _clampByte(pixels[i + 1] + delta);
      pixels[i + 2] = _clampByte(pixels[i + 2] + delta);
    }

    final img.Image output = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: pixels.buffer,
    );

    final List<int>? encoded = img.encodeNamedImage(filePath, output);
    if (encoded == null) {
      throw Exception(Strings.msgDecodeImageFailed(filePath));
    }

    await File(filePath).writeAsBytes(encoded, flush: true);
  }

  static int _clampByte(int value) => value.clamp(0, 255);
}
