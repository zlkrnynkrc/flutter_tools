import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

/// Kalıcılık yöneticisi
class PersistenceManager {
  final String storageDirectory;
  final File _storageFile;
  PersistenceManager({required this.storageDirectory})
      : _storageFile =
            File(path.join(storageDirectory, 'scheduler_state.json')) {
    if (!Directory(storageDirectory).existsSync()) {
      Directory(storageDirectory).createSync(recursive: true);
    }
  }

  Future<void> saveState(Map<String, dynamic> state) async {
    try {
      await _storageFile.writeAsString(jsonEncode(state));
    } catch (e) {
      // Burada hata loglanabilir veya bildirilebilir
      throw ('State save failed: $e');
    }
  }

  Future<Map<String, dynamic>> loadState() async {
    if (!await _storageFile.exists()) return {};
    final content = await _storageFile.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }
}
