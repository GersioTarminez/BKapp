import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/emotion_entry.dart';

class StorageService {
  static const _fileName = 'emotions.json';
  static const _webKey = 'emotions_entries_web';

  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    await directory.create(recursive: true);
    return File('${directory.path}/$_fileName');
  }

  Future<List<EmotionEntry>> loadEntries() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_webKey);
        if (raw == null || raw.isEmpty) return [];
        final data = jsonDecode(raw) as List<dynamic>;
        return data
            .map((item) => EmotionEntry.fromJson(item as Map<String, dynamic>))
            .toList();
      }

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
    final serialized = jsonEncode(entries.map((e) => e.toJson()).toList());
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_webKey, serialized);
    } else {
      final file = await _getLocalFile();
      await file.writeAsString(serialized, flush: true);
    }
  }

  Future<void> addEntry(EmotionEntry entry) async {
    final entries = await loadEntries();
    entries.add(entry);
    await saveEntries(entries);
  }
}
