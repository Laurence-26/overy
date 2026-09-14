import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Copies a picked photo into app documents so it survives restarts.
class ThemeBackgroundStore {
  ThemeBackgroundStore._();

  static const fileName = 'cyclus_theme_bg.jpg';

  static Future<String?> pickAndSave() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return null;
      final srcPath = result.files.single.path;
      if (srcPath == null || srcPath.isEmpty) return null;

      final dir = await getApplicationDocumentsDirectory();
      final dest = File('${dir.path}/$fileName');
      await File(srcPath).copy(dest.path);
      // Bust image cache so a replacement shows immediately.
      return '${dest.path}?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('Theme background pick failed: $e');
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final dest = File('${dir.path}/$fileName');
      if (await dest.exists()) await dest.delete();
    } catch (e) {
      debugPrint('Theme background clear failed: $e');
    }
  }

  static String? stripCacheBust(String? path) {
    if (path == null) return null;
    final i = path.indexOf('?');
    return i < 0 ? path : path.substring(0, i);
  }

  static bool exists(String? path) {
    final clean = stripCacheBust(path);
    if (clean == null || clean.isEmpty) return false;
    return File(clean).existsSync();
  }
}
