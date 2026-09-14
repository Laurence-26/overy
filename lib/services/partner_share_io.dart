import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Share and import a Cyclus JSON snapshot between two phones with no internet.
class PartnerShareIo {
  PartnerShareIo._();

  static Future<void> shareSnapshot(Map<String, dynamic> snapshot) async {
    final dir = await getTemporaryDirectory();
    final name = snapshot['profile'] is Map
        ? (snapshot['profile'] as Map)['displayName'] ??
            (snapshot['profile'] as Map)['username'] ??
            'cyclus'
        : 'cyclus';
    final safe = name
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final file =
        File('${dir.path}/${safe.isEmpty ? 'cyclus' : safe}-cycle.json');
    await file
        .writeAsString(const JsonEncoder.withIndent('').convert(snapshot));
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Cyclus cycle share',
      text:
          'Open this in Cyclus > Partner view > Import file. No internet needed.',
    );
  }

  static Future<Map<String, dynamic>?> pickSnapshot() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    String raw;
    if (file.bytes != null) {
      raw = utf8.decode(file.bytes!);
    } else if (file.path != null) {
      raw = await File(file.path!).readAsString();
    } else {
      throw Exception('Could not read that file.');
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw Exception('That file is not a Cyclus share.');
    }
    return Map<String, dynamic>.from(decoded);
  }
}
