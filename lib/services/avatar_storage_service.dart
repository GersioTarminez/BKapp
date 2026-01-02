import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/avatar_profile.dart';

class AvatarStorageService {
  static const _fileName = 'avatar.json';

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    return File('${dir.path}/$_fileName');
  }

  Future<AvatarProfile?> loadProfile() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return null;
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return AvatarProfile.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(AvatarProfile profile) async {
    final file = await _getFile();
    await file.writeAsString(jsonEncode(profile.toJson()), flush: true);
  }
}
