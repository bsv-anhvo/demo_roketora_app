import 'dart:io';

import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:demo_roketota_app/utils/video_filter_helper.dart';
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

  static Future<({String originalPath, String filterPath})> photoPairPaths() async {
    final Directory stampDir = await _mediaStampDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return (
      originalPath: '${stampDir.path}/photo_original_$timestamp.jpg',
      filterPath: '${stampDir.path}/photo_$timestamp.jpg',
    );
  }

  static Future<Directory> _mediaStampDirectory() async {
    final Directory cacheDir = await getApplicationCacheDirectory();
    return Directory('${cacheDir.path}/roketora_media_stamp')
        .create(recursive: true);
  }

  static Future<Directory> mediaStampDirectoryForWrite() =>
      _mediaStampDirectory();

  /// Removes leftover stamp videos/images (e.g. after kill app on preview).
  static Future<void> clearMediaStampDirectory() async {
    try {
      final Directory dir = await _mediaStampDirectory();
      if (!await dir.exists()) return;

      await for (final FileSystemEntity entity in dir.list()) {
        await entity.delete(recursive: true);
      }
    } catch (e, stackTrace) {
      debugPrint('Clear media stamp directory failed: $e\n$stackTrace');
    }
  }

  static Future<CaptureRequest> photoPath(List<Sensor> sensors) async {
    final ({String originalPath, String filterPath}) paths =
        await photoPairPaths();

    if (sensors.length == 1) {
      return SingleCaptureRequest(paths.originalPath, sensors.first);
    }

    final Directory stampDir = await _mediaStampDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    return MultipleCaptureRequest({
      for (final Sensor sensor in sensors)
        sensor:
            '${stampDir.path}/${sensor.position == SensorPosition.front ? 'front' : 'back'}_$timestamp.jpg',
    });
  }

  static Future<void> deletePhotoStampPair({
    required String filterStampPath,
    String? originalStampPath,
    Iterable<String> extraPaths = const <String>[],
  }) async {
    await deleteIfExists(filterStampPath);
    if (originalStampPath != null) {
      await deleteIfExists(originalStampPath);
    }
    for (final String path in extraPaths) {
      await deleteIfExists(path);
    }
  }

  /// Publishes filter stamp to Gallery, moves original stamp to [roketora_media].
  static Future<bool> saveConfirmedPhoto({
    required String filterStampPath,
    required String originalStampPath,
  }) async {
    String? persistedOriginalPath;

    try {
      final bool gallerySaved = await publishFilterPhoto(filterStampPath);
      if (!gallerySaved) return false;

      final Directory mediaDir = await _mediaDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      persistedOriginalPath =
          '${mediaDir.path}/photo_original_$timestamp.jpg';

      final File originalFile = File(originalStampPath);
      try {
        await originalFile.rename(persistedOriginalPath);
      } catch (_) {
        await originalFile.copy(persistedOriginalPath);
        await originalFile.delete();
      }

      await deleteIfExists(filterStampPath);
      return true;
    } catch (e, stackTrace) {
      debugPrint('Save confirmed photo failed: $e\n$stackTrace');
      if (persistedOriginalPath != null) {
        await deleteIfExists(persistedOriginalPath);
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

  static Future<({String originalPath, String editedPath})> videoPairPaths() async {
    final Directory stampDir = await _mediaStampDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return (
      originalPath: '${stampDir.path}/video_original_$timestamp.mp4',
      editedPath: '${stampDir.path}/video_$timestamp.mp4',
    );
  }

  static String? editedPathForOriginal(String originalPath) {
    final RegExp match = RegExp(r'video_original_(\d+)\.mp4$');
    final RegExpMatch? result = match.firstMatch(originalPath);
    if (result == null) return null;

    final String dir = originalPath.substring(0, originalPath.lastIndexOf('/'));
    return '$dir/video_${result.group(1)}.mp4';
  }

  static String? originalPathForEdited(String editedPath) {
    final RegExp match = RegExp(r'video_(\d+)\.mp4$');
    final RegExpMatch? result = match.firstMatch(editedPath);
    if (result == null) return null;

    final String dir = editedPath.substring(0, editedPath.lastIndexOf('/'));
    return '$dir/video_original_${result.group(1)}.mp4';
  }

  /// Copies original stamp, then bakes [filter] into the edited stamp file.
  static Future<String?> createEditedVideoStamp(
    String originalStampPath,
    AwesomeFilter filter, {
    int? fallbackFps,
  }) async {
    final String? editedPath = editedPathForOriginal(originalStampPath);
    if (editedPath == null) return null;

    await File(originalStampPath).copy(editedPath);
    if (filter.id != AwesomeFilter.None.id) {
      await VideoFilterHelper.applyToFile(
        editedPath,
        filter,
        fallbackFps: fallbackFps,
      );
    }
    return editedPath;
  }

  static Future<CaptureRequest> videoPath(List<Sensor> sensors) async {
    final ({String originalPath, String editedPath}) paths =
        await videoPairPaths();

    if (sensors.length == 1) {
      return SingleCaptureRequest(paths.originalPath, sensors.first);
    }

    final Directory stampDir = await _mediaStampDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    return MultipleCaptureRequest({
      for (final Sensor sensor in sensors)
        sensor:
            '${stampDir.path}/${sensor.position == SensorPosition.front ? 'front' : 'back'}_original_$timestamp.mp4',
    });
  }

  static Future<void> deleteVideoStampPair({
    required String editedStampPath,
    String? originalStampPath,
    Iterable<String> extraPaths = const <String>[],
  }) async {
    await deleteIfExists(editedStampPath);
    if (originalStampPath != null) {
      await deleteIfExists(originalStampPath);
    }
    for (final String path in extraPaths) {
      await deleteIfExists(path);
    }
  }

  /// Publishes edited stamp to Gallery, moves original stamp to [roketora_media].
  static Future<bool> saveConfirmedVideo({
    required String editedStampPath,
    required String originalStampPath,
  }) async {
    String? persistedOriginalPath;

    try {
      final bool gallerySaved = await publishVideo(editedStampPath);
      if (!gallerySaved) return false;

      final File originalFile = File(originalStampPath);
      if (!await originalFile.exists()) {
        debugPrint(
          'Save video skipped: original stamp missing at $originalStampPath',
        );
        return false;
      }

      final Directory mediaDir = await _mediaDirectory();
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      persistedOriginalPath =
          '${mediaDir.path}/video_original_$timestamp.mp4';

      try {
        await originalFile.rename(persistedOriginalPath);
      } catch (_) {
        await originalFile.copy(persistedOriginalPath);
        await originalFile.delete();
      }

      await deleteIfExists(editedStampPath);
      return true;
    } catch (e, stackTrace) {
      debugPrint('Save confirmed video failed: $e\n$stackTrace');
      if (persistedOriginalPath != null) {
        await deleteIfExists(persistedOriginalPath);
      }
      return false;
    }
  }

  /// ↧ Publishes media to the device gallery (public).

  /// Returns `true` when the video was saved to the gallery.
  static Future<bool> publishVideo(String filePath) async {
    try {
      await Gal.putVideo(filePath, album: 'Roketora');
      return true;
    } on GalException catch (e) {
      debugPrint('Gallery video publish failed: ${e.type.message}');
      return false;
    } on MissingPluginException catch (e) {
      debugPrint(
        'Gal plugin is not linked ($e). '
            'Stop the app completely, then run: flutter clean && flutter pub get && flutter run',
      );
      return false;
    } on PlatformException catch (e) {
      debugPrint('Gallery video publish platform error: $e');
      return false;
    } catch (e, stackTrace) {
      debugPrint('Gallery video publish failed: $e\n$stackTrace');
      return false;
    }
  }

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
