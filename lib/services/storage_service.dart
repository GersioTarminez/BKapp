import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/emotion_entry.dart';

class StorageService {
  static const _fileName = 'emotions.json';

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<List<EmotionEntry>> loadEntries() async {
    try {
      final file = await _getLocalFile();
      if (!await file.exists()) {
        return [];
      }

      final raw = await file.readAsString();
      if (raw.isEmpty) {
        return [];
      }

      final data = jsonDecode(raw) as List<dynamic>;
      return data
          .map((item) => EmotionEntry.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEntries(List<EmotionEntry> entries) async {
    final file = await _getLocalFile();
    final serialized = jsonEncode(entries.map((e) => e.toJson()).toList());
    await file.writeAsString(serialized);
  }

  Future<void> addEntry(EmotionEntry entry) async {
    final entries = await loadEntries();
    entries.add(entry);
    await saveEntries(entries);
  }
}
