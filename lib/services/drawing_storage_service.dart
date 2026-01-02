import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DrawingStorageService {
  DrawingStorageService._();

  static final DrawingStorageService instance = DrawingStorageService._();
  static const _webPrefsKey = 'star_path_drawings_web';

  Future<void> saveDrawing({
    required String sessionId,
    required String mode,
    String? word,
    required Uint8List pngBytes,
    Map<String, dynamic>? metrics,
    String? userName,
  }) async {
    if (kIsWeb) {
      await _saveDrawingWeb(
        sessionId: sessionId,
        mode: mode,
        word: word,
        pngBytes: pngBytes,
        metrics: metrics,
        userName: userName,
      );
      return;
    }
    await _saveDrawingIo(
      sessionId: sessionId,
      mode: mode,
      word: word,
      pngBytes: pngBytes,
      metrics: metrics,
      userName: userName,
    );
  }

  Future<void> _saveDrawingIo({
    required String sessionId,
    required String mode,
    String? word,
    required Uint8List pngBytes,
    Map<String, dynamic>? metrics,
    String? userName,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final drawingsDir = Directory('${directory.path}/star_path_drawings');
    await drawingsDir.create(recursive: true);
    final timestamp = DateTime.now().toIso8601String();
    final sanitized = timestamp.replaceAll(':', '-');

    final file = File('${drawingsDir.path}/drawing_$sanitized.png');
    await file.writeAsBytes(pngBytes, flush: true);

    final thumbnailBytes = await _generateThumbnail(pngBytes);
    final thumbFile = File('${drawingsDir.path}/thumb_$sanitized.png');
    await thumbFile.writeAsBytes(thumbnailBytes, flush: true);

    final entry = {
      'session_id': sessionId,
      'mode': mode,
      'word': word,
      'image_path': file.path,
      'thumbnail_path': thumbFile.path,
      'saved_at': timestamp,
      'metrics': metrics,
      'user_name': userName,
    }..removeWhere((key, value) => value == null);

    final indexFile = File('${drawingsDir.path}/drawings_index.json');
    List<dynamic> entries = [];
    if (await indexFile.exists()) {
      final content = await indexFile.readAsString();
      if (content.isNotEmpty) {
        entries = jsonDecode(content) as List<dynamic>;
      }
    }
    entries.add(entry);
    await indexFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(entries),
      flush: true,
    );
  }

  Future<void> _saveDrawingWeb({
    required String sessionId,
    required String mode,
    String? word,
    required Uint8List pngBytes,
    Map<String, dynamic>? metrics,
    String? userName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = DateTime.now().toIso8601String();
    final thumbnailBytes = await _generateThumbnail(pngBytes);
    final entry = {
      'session_id': sessionId,
      'mode': mode,
      'word': word,
      'image_base64': base64Encode(pngBytes),
      'thumb_base64': base64Encode(thumbnailBytes),
      'saved_at': timestamp,
      'metrics': metrics,
      'user_name': userName,
    }..removeWhere((key, value) => value == null);
    final existingRaw = prefs.getString(_webPrefsKey);
    List<dynamic> entries = [];
    if (existingRaw != null && existingRaw.isNotEmpty) {
      entries = jsonDecode(existingRaw) as List<dynamic>;
    }
    entries.add(entry);
    await prefs.setString(_webPrefsKey, jsonEncode(entries));
  }

  Future<List<StarPathRecord>> loadStarPathRecords() async {
    if (kIsWeb) {
      return _loadWebRecords();
    }
    final directory = await getApplicationDocumentsDirectory();
    final indexFile =
        File('${directory.path}/star_path_drawings/drawings_index.json');
    if (!await indexFile.exists()) {
      return [];
    }
    try {
      final content = await indexFile.readAsString();
      if (content.isEmpty) return [];
      final entries = jsonDecode(content) as List<dynamic>;
      return entries
          .map((e) => StarPathRecord.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    } catch (_) {
      return [];
    }
  }

  Future<List<StarPathRecord>> _loadWebRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_webPrefsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final entries = jsonDecode(raw) as List<dynamic>;
      return entries
          .map((e) => StarPathRecord.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    } catch (_) {
      return [];
    }
  }

  Future<Uint8List> _generateThumbnail(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes, targetWidth: 256);
    final frame = await codec.getNextFrame();
    final resized =
        await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return resized!.buffer.asUint8List();
  }
}

class StarPathRecord {
  StarPathRecord({
    required this.sessionId,
    required this.mode,
    required this.word,
    required this.imagePath,
    required this.thumbnailPath,
    required this.savedAt,
    required this.metrics,
    required this.userName,
    this.imageBytes,
    this.thumbnailBytes,
  });

  factory StarPathRecord.fromJson(Map<String, dynamic> json) {
    final imageBase64 = json['image_base64'] as String?;
    final thumbBase64 = json['thumb_base64'] as String?;
    return StarPathRecord(
      sessionId: json['session_id'] as String,
      mode: json['mode'] as String? ?? 'unknown',
      word: json['word'] as String?,
      imagePath: json['image_path'] as String? ?? '',
      thumbnailPath: json['thumbnail_path'] as String? ?? '',
      savedAt: DateTime.parse(json['saved_at'] as String),
      metrics: (json['metrics'] as Map<String, dynamic>?) ?? const {},
      userName: json['user_name'] as String? ?? 'anonymous',
      imageBytes:
          imageBase64 == null ? null : base64Decode(imageBase64),
      thumbnailBytes:
          thumbBase64 == null ? null : base64Decode(thumbBase64),
    );
  }

  final String sessionId;
  final String mode;
  final String? word;
  final String imagePath;
  final String thumbnailPath;
  final DateTime savedAt;
  final Map<String, dynamic> metrics;
  final String userName;
  final Uint8List? imageBytes;
  final Uint8List? thumbnailBytes;
}
