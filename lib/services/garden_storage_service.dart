import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/garden_plant.dart';

/// Persists the emotional garden so the child sees their plants across sessions.
class GardenStorageService {
  static const _fileName = 'garden.json';

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    return File('${dir.path}/$_fileName');
  }

  Future<List<GardenPlant>> loadGarden() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];
      final jsonList = jsonDecode(await file.readAsString()) as List<dynamic>;
      return jsonList
          .map((item) => GardenPlant.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveGarden(List<GardenPlant> plants) async {
    final file = await _getFile();
    final data = plants.map((e) => e.toJson()).toList();
    await file.writeAsString(jsonEncode(data), flush: true);
  }
}
