import 'dart:io';
import 'dart:typed_data';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

class MediaFileHelper {
  static Future<bool> deleteIfExists(String path) async {
    final File file = File(path);
    if (!await file.exists()) return false;
    await file.delete();
    return true;
  }

  static Future<Directory> _mediaDirectory() async {
    final Directory baseDir = await getApplicationDocumentsDirectory();
    return Directory('${baseDir.path}/roketora_media').create(recursive: true);
  }

  static Future<Directory> _videoStampDirectory() async {
    final Directory cacheDir = await getApplicationCacheDirectory();
    return Directory('${cacheDir.path}/roketora_media_stamp')
        .create(recursive: true);
  }

  /// Removes leftover stamp videos (e.g. after kill app on preview).
  static Future<void> clearVideoStampDirectory() async {
    try {
      final Directory dir = await _videoStampDirectory();
      if (!await dir.exists()) return;

      await for (final FileSystemEntity entity in dir.list()) {
        await entity.delete(recursive: true);
      }
    } catch (e, stackTrace) {
      debugPrint('Clear video stamp directory failed: $e\n$stackTrace');
    }
  }

  /// Scratch path required by camerawesome for hardware-button capture only.
  /// Dual capture reads bytes and deletes the file immediately.
  static Future<CaptureRequest> photoPath(List<Sensor> sensors) async {
    final Directory scratchDir = await getTemporaryDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String scratchPath = '${scratchDir.path}/photo_$timestamp.jpg';

    if (sensors.length == 1) {
      return SingleCaptureRequest(scratchPath, sensors.first);
    }

    return MultipleCaptureRequest({
      for (final Sensor sensor in sensors)
        sensor:
            '${scratchDir.path}/${sensor.position == SensorPosition.front ? 'front' : 'back'}_$timestamp.jpg',
    });
  }

  /// Returns `true` when the image was saved to the gallery.
  static Future<bool> publishFilterPhotoBytes(
    Uint8List bytes, {
    String? name,
  }) async {
    try {
      final String photoName =
          name ?? 'photo_${DateTime.now().millisecondsSinceEpoch}';
      await Gal.putImageBytes(bytes, album: 'Roketora', name: photoName);
      return true;
    } on GalException catch (e) {
      debugPrint('Gallery publish failed: ${e.type.message}');
      return false;
    } on MissingPluginException catch (e) {
      debugPrint(
        'Gal plugin is not linked ($e). '
            'Stop the app completely, then run: flutter clean && flutter pub get && flutter run',
      );
      return false;
    } on PlatformException catch (e) {
      debugPrint('Gallery publish platform error: $e');
      return false;
    } catch (e, stackTrace) {
      debugPrint('Gallery publish failed: $e\n$stackTrace');
      return false;
    }
  }

  /// Persists the unfiltered original to app documents. Only call on Save.
  static Future<String> saveOriginalPhotoBytes(
    Uint8List bytes, {
    required String timestamp,
  }) async {
    final Directory mediaDir = await _mediaDirectory();
    final String path = '${mediaDir.path}/photo_original_$timestamp.jpg';
    await File(path).writeAsBytes(bytes);
    return path;
  }

  /// Saves filter photo to Gallery and original photo to internal storage.
  static Future<bool> saveConfirmedPhoto({
    required Uint8List filterBytes,
    required Uint8List originalBytes,
  }) async {
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    String? originalPath;

    try {
      originalPath = await saveOriginalPhotoBytes(
        originalBytes,
        timestamp: timestamp,
      );
      final bool gallerySaved = await publishFilterPhotoBytes(
        filterBytes,
        name: 'photo_$timestamp',
      );
      if (!gallerySaved) {
        await deleteIfExists(originalPath);
      }
      return gallerySaved;
    } catch (e, stackTrace) {
      debugPrint('Save confirmed photo failed: $e\n$stackTrace');
      if (originalPath != null) {
        await deleteIfExists(originalPath);
      }
      return false;
    }
  }

  static String? originalPathForFilter(String filterPath) {
    final RegExp match = RegExp(r'photo_(\d+)\.jpg$');
    final RegExpMatch? result = match.firstMatch(filterPath);
    if (result == null) return null;

    final String dir = filterPath.substring(0, filterPath.lastIndexOf('/'));
    return '$dir/photo_original_${result.group(1)}.jpg';
  }

  static Future<CaptureRequest> videoPath(List<Sensor> sensors) async {
    final Directory stampDir = await _videoStampDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    if (sensors.length == 1) {
      final String filePath = '${stampDir.path}/video_$timestamp.mp4';
      return SingleCaptureRequest(filePath, sensors.first);
    }

    return MultipleCaptureRequest({
      for (final Sensor sensor in sensors)
        sensor:
            '${stampDir.path}/${sensor.position == SensorPosition.front ? 'front' : 'back'}_$timestamp.mp4',
    });
  }

  /// Moves stamp video into [roketora_media] and removes the stamp file.
  static Future<bool> saveConfirmedVideo(String stampPath) async {
    try {
      final File source = File(stampPath);
      if (!await source.exists()) {
        debugPrint('Save video skipped: stamp file missing at $stampPath');
        return false;
      }

      final Directory mediaDir = await _mediaDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String destPath = '${mediaDir.path}/video_$timestamp.mp4';

      try {
        await source.rename(destPath);
      } catch (_) {
        await source.copy(destPath);
        await source.delete();
      }
      return true;
    } catch (e, stackTrace) {
      debugPrint('Save confirmed video failed: $e\n$stackTrace');
      return false;
    }
  }

  /// ↧ Publishes filter photos to the device gallery (public).

  /// Returns `true` when the image was saved to the gallery.
  /// Never throws — capture/preview must continue even if gallery fails.
  static Future<bool> publishFilterPhoto(String filePath) async {
    try {
      await Gal.putImage(filePath, album: "Roketora");
      return true;
    } on GalException catch (e) {
      debugPrint('Gallery publish failed: ${e.type.message}');
      return false;
    } on MissingPluginException catch (e) {
      debugPrint(
        'Gal plugin is not linked ($e). '
            'Stop the app completely, then run: flutter clean && flutter pub get && flutter run',
      );
      return false;
    } on PlatformException catch (e) {
      debugPrint('Gallery publish platform error: $e');
      return false;
    } catch (e, stackTrace) {
      debugPrint('Gallery publish failed: $e\n$stackTrace');
      return false;
    }
  }

  /// Removes filter photo(s) from the device gallery by file name.
  /// Never throws — local file deletion should still proceed.
  static Future<void> deleteFilterPhotoFromGallery(String filterFilePath) async {
    try {
      final PermissionState permission =
      await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        debugPrint('Gallery delete skipped: permission denied');
        return;
      }

      final String fileName = filterFilePath.split('/').last;
      final String baseName = fileName.replaceAll(RegExp(r'\.jpe?g$', caseSensitive: false), '');

      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
      );

      final List<String> idsToDelete = <String>[];

      for (final AssetPathEntity album in albums) {
        final int count = await album.assetCountAsync;
        if (count == 0) continue;

        final int end = count > 500 ? 500 : count;
        final List<AssetEntity> assets =
        await album.getAssetListRange(start: 0, end: end);

        for (final AssetEntity asset in assets) {
          final String title = await asset.titleAsync;
          if (title == fileName || title == baseName) {
            idsToDelete.add(asset.id);
          }
        }
      }

      if (idsToDelete.isEmpty) return;

      await PhotoManager.editor.deleteWithIds(idsToDelete);
    } on MissingPluginException catch (e) {
      debugPrint('PhotoManager plugin is not linked: $e');
    } catch (e, stackTrace) {
      debugPrint('Gallery delete failed: $e\n$stackTrace');
    }
  }

  /// ↥ Publishes filter photos to the device gallery (public).
}
