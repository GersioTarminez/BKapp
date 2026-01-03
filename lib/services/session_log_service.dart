import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preferences_service.dart';

enum SessionGame { bubbleCalm, seedGarden, emotions }

class SessionRecord {
  SessionRecord({
    required this.id,
    required this.game,
    required this.startedAt,
    required this.endedAt,
    required this.durationSeconds,
    required this.metrics,
    required this.userName,
  });

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      id: json['id'] as String,
      game: SessionGame.values.firstWhere(
        (g) => g.name == json['game'],
        orElse: () => SessionGame.bubbleCalm,
      ),
      startedAt: DateTime.parse(json['started_at'] as String),
      endedAt: DateTime.parse(json['ended_at'] as String),
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0,
      metrics: Map<String, dynamic>.from(json['metrics'] as Map? ?? const {}),
      userName: json['user_name'] as String? ?? 'anonymous',
    );
  }

  final String id;
  final SessionGame game;
  final DateTime startedAt;
  final DateTime endedAt;
  final double durationSeconds;
  final Map<String, dynamic> metrics;
  final String userName;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'game': game.name,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
      'duration_seconds': durationSeconds,
      'metrics': metrics,
      'user_name': userName,
    };
  }
}

class SessionLogService {
  SessionLogService._();

  static final SessionLogService instance = SessionLogService._();

  static const _fileName = 'sessions_log.json';
  static const _webPrefsKey = 'sessions_log_web';

  _BubbleSession? _bubbleSession;
  _GardenSession? _gardenSession;

  Future<void> startBubbleSession() async {
    _bubbleSession = _BubbleSession(
      id: _newId(),
      startedAt: DateTime.now(),
      userName: PreferencesService.instance.cachedUserName,
    );
  }

  void recordBubblePop() {
    final session = _bubbleSession;
    if (session == null) return;
    session.bubblesPopped++;
    final now = DateTime.now();
    if (session.lastPop != null) {
      session.intervalSum += now.difference(session.lastPop!).inMilliseconds;
      session.intervalCount++;
    }
    session.lastPop = now;
  }

  void recordBubbleMiss() {
    final session = _bubbleSession;
    if (session == null) return;
    session.missedTaps++;
  }

  Future<void> endBubbleSession() async {
    final session = _bubbleSession;
    if (session == null) return;
    final endedAt = DateTime.now();
    final duration =
        endedAt.difference(session.startedAt).inMilliseconds / 1000;
    final mean = session.intervalCount == 0
        ? null
        : session.intervalSum / session.intervalCount;
    final record = SessionRecord(
      id: session.id,
      game: SessionGame.bubbleCalm,
      startedAt: session.startedAt,
      endedAt: endedAt,
      durationSeconds: duration,
      metrics: {
        'bubbles_popped': session.bubblesPopped,
        'missed_taps': session.missedTaps,
        'mean_tap_interval_ms': mean,
      }..removeWhere((key, value) => value == null),
      userName: session.userName,
    );
    await _persist(record);
    _bubbleSession = null;
  }

  Future<void> startGardenSession() async {
    _gardenSession = _GardenSession(
      id: _newId(),
      startedAt: DateTime.now(),
      userName: PreferencesService.instance.cachedUserName,
    );
  }

  void recordTreePlanted() {
    _gardenSession?.treesPlanted++;
  }

  void recordFlowerPlanted() {
    _gardenSession?.flowersPlanted++;
  }

  void recordTreeMatured() {
    _gardenSession?.treesMatured++;
  }

  Future<void> endGardenSession() async {
    final session = _gardenSession;
    if (session == null) return;
    final endedAt = DateTime.now();
    final duration =
        endedAt.difference(session.startedAt).inMilliseconds / 1000;
    final record = SessionRecord(
      id: session.id,
      game: SessionGame.seedGarden,
      startedAt: session.startedAt,
      endedAt: endedAt,
      durationSeconds: duration,
      metrics: {
        'trees_planted': session.treesPlanted,
        'flowers_planted': session.flowersPlanted,
        'trees_matured': session.treesMatured,
      },
      userName: session.userName,
    );
    await _persist(record);
    _gardenSession = null;
  }

  Future<void> logEmotionEntry({
    required String emotion,
    String? note,
  }) async {
    final now = DateTime.now();
    final record = SessionRecord(
      id: _newId(),
      game: SessionGame.emotions,
      startedAt: now,
      endedAt: now,
      durationSeconds: 0,
      metrics: {
        'emotion': emotion,
        'note': note,
      }..removeWhere((key, value) => value == null || (value is String && value.isEmpty)),
      userName: PreferencesService.instance.cachedUserName,
    );
    await _persist(record);
  }

  Future<List<SessionRecord>> loadSessions({SessionGame? game}) async {
    final entries = await _readAll();
    if (game == null) return entries;
    return entries.where((entry) => entry.game == game).toList();
  }

  Future<List<SessionRecord>> _readAll() async {
    try {
      final raw = kIsWeb ? await _readWeb() : await _readFile();
      if (raw == null || raw.isEmpty) {
        return [];
      }
      final data = jsonDecode(raw) as List<dynamic>;
      final sessions = data
          .map((item) => SessionRecord.fromJson(item as Map<String, dynamic>))
          .toList();
      sessions.sort((a, b) => a.startedAt.compareTo(b.startedAt));
      return sessions;
    } catch (_) {
      return [];
    }
  }

  Future<String?> _readFile() async {
    final file = await _ensureFile();
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  Future<String?> _readWeb() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_webPrefsKey);
  }

  Future<void> _persist(SessionRecord record) async {
    final entries = await _readAll();
    entries.add(record);
    final serialized = jsonEncode(entries.map((e) => e.toJson()).toList());
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_webPrefsKey, serialized);
    } else {
      final file = await _ensureFile();
      await file.writeAsString(serialized, flush: true);
    }
  }

  Future<File> _ensureFile() async {
    final dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true);
    return File('${dir.path}/$_fileName');
  }

  String _newId() => DateTime.now().millisecondsSinceEpoch.toString();
}

class _BubbleSession {
  _BubbleSession({
    required this.id,
    required this.startedAt,
    required this.userName,
  });

  final String id;
  final DateTime startedAt;
  final String userName;
  int bubblesPopped = 0;
  int missedTaps = 0;
  int intervalSum = 0;
  int intervalCount = 0;
  DateTime? lastPop;
}

class _GardenSession {
  _GardenSession({
    required this.id,
    required this.startedAt,
    required this.userName,
  });

  final String id;
  final DateTime startedAt;
  final String userName;
  int treesPlanted = 0;
  int flowersPlanted = 0;
  int treesMatured = 0;
}
