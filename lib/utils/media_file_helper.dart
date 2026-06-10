import 'dart:io';

class MediaFileHelper {
  static Future<bool> deleteIfExists(String path) async {
    final File file = File(path);
    if (!await file.exists()) return false;
    await file.delete();
    return true;
  }
}
