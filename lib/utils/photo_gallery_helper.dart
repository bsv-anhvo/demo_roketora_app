import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:photo_manager/photo_manager.dart';

/// Publishes filter photos to the device gallery (public).
class PhotoGalleryHelper {
  const PhotoGalleryHelper._();

  static const String albumName = 'Roketota';

  /// Returns `true` when the image was saved to the gallery.
  /// Never throws — capture/preview must continue even if gallery fails.
  static Future<bool> publishFilterPhoto(String filePath) async {
    try {
      await Gal.putImage(filePath, album: albumName);
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
}
