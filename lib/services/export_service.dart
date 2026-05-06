import 'dart:convert';
import 'dart:html' as html;
import 'package:hive_flutter/hive_flutter.dart';

class ExportService {
  static Future<void> exportToLocalJson() async {
    final usersBox = Hive.box('usersBoxV2');
    final filesBox = Hive.box('filesBox');

    // 1. Collect all users
    final users = usersBox.values.toList();

    // 2. Collect all files
    final files = filesBox.values.toList();

    // 3. Create Master JSON
    final Map<String, dynamic> databaseSnapshot = {
      'export_timestamp': DateTime.now().toIso8601String(),
      'storage_type': 'Local Persistence (Hive/IndexedDB)',
      'users': users,
      'files': files,
    };

    // 4. Convert to Human-Readable String
    final jsonString = const JsonEncoder.withIndent('  ').convert(databaseSnapshot);

    // 5. Trigger Browser Download
    final bytes = utf8.encode(jsonString);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'app_local_db.json')
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
