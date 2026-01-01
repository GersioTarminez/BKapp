import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BubbleSessionSummary {
  BubbleSessionSummary({
    required this.sessionId,
    required this.startedAt,
    required this.bubblesPopped,
    required this.missedTaps,
    required this.meanIntervalMs,
  });

  final String sessionId;
  final DateTime startedAt;
  final int bubblesPopped;
  final int missedTaps;
  final double? meanIntervalMs;

  factory BubbleSessionSummary.fromJson(Map<String, dynamic> json) {
    return BubbleSessionSummary(
      sessionId: json['session_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      bubblesPopped: json['bubbles_popped'] as int? ?? 0,
      missedTaps: json['missed_taps'] as int? ?? 0,
      meanIntervalMs: (json['mean_interval_ms'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'started_at': startedAt.toIso8601String(),
      'bubbles_popped': bubblesPopped,
      'missed_taps': missedTaps,
      'mean_interval_ms': meanIntervalMs,
    }..removeWhere((key, value) => value == null);
  }
}

class GardenSessionSummary {
  GardenSessionSummary({
    required this.sessionId,
    required this.startedAt,
    required this.treesPlanted,
    required this.flowersPlanted,
    required this.treesMatured,
    required this.durationSeconds,
  });

  final String sessionId;
  final DateTime startedAt;
  final int treesPlanted;
  final int flowersPlanted;
  final int treesMatured;
  final double durationSeconds;

  factory GardenSessionSummary.fromJson(Map<String, dynamic> json) {
    return GardenSessionSummary(
      sessionId: json['session_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      treesPlanted: json['trees_planted'] as int? ?? 0,
      flowersPlanted: json['flowers_planted'] as int? ?? 0,
      treesMatured: json['trees_matured'] as int? ?? 0,
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'started_at': startedAt.toIso8601String(),
      'trees_planted': treesPlanted,
      'flowers_planted': flowersPlanted,
      'trees_matured': treesMatured,
      'duration_seconds': durationSeconds,
    };
  }
}

class SessionStatsService {
  SessionStatsService._();

  static final SessionStatsService instance = SessionStatsService._();

  static const _bubblePrefsKey = 'bubble_sessions';
  static const _gardenPrefsKey = 'garden_sessions';

  String? _bubbleSessionId;
  DateTime? _bubbleStartTime;
  int _popped = 0;
  int _missed = 0;
  DateTime? _lastPop;
  double _intervalSum = 0;
  int _intervalCount = 0;

  String? _gardenSessionId;
  DateTime? _gardenStartTime;
  int _treesPlanted = 0;
  int _flowersPlanted = 0;
  int _treesMatured = 0;

  void startSession() {
    _bubbleSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _bubbleStartTime = DateTime.now();
    _popped = 0;
    _missed = 0;
    _intervalSum = 0;
    _intervalCount = 0;
    _lastPop = null;
  }

  void recordPop() {
    final now = DateTime.now();
    _popped++;
    if (_lastPop != null) {
      _intervalSum += now.difference(_lastPop!).inMilliseconds;
      _intervalCount++;
    }
    _lastPop = now;
  }

  void recordMiss() {
    _missed++;
  }

  Future<void> endSession() async {
    if (_bubbleSessionId == null || _bubbleStartTime == null) return;
    final mean = _intervalCount == 0 ? null : _intervalSum / _intervalCount;
    final summary = BubbleSessionSummary(
      sessionId: _bubbleSessionId!,
      startedAt: _bubbleStartTime!,
      bubblesPopped: _popped,
      missedTaps: _missed,
      meanIntervalMs: mean,
    );
    final existing = await loadSessions();
    existing.add(summary);
    final prefs = await SharedPreferences.getInstance();
    final encoded = existing.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_bubblePrefsKey, encoded);
    _bubbleSessionId = null;
    _bubbleStartTime = null;
  }

  Future<List<BubbleSessionSummary>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_bubblePrefsKey);
    if (raw == null) return [];
    return raw
        .map((entry) => BubbleSessionSummary.fromJson(
              jsonDecode(entry) as Map<String, dynamic>,
            ))
        .toList();
  }

  void startGardenSession() {
    _gardenSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _gardenStartTime = DateTime.now();
    _treesPlanted = 0;
    _flowersPlanted = 0;
    _treesMatured = 0;
  }

  void recordSeedPlanted() {
    _treesPlanted++;
  }

  void recordFlowerPlanted() {
    _flowersPlanted++;
  }

  void recordTreeMatured() {
    _treesMatured++;
  }

  Future<void> endGardenSession() async {
    if (_gardenSessionId == null || _gardenStartTime == null) return;
    final duration =
        DateTime.now().difference(_gardenStartTime!).inMilliseconds / 1000;
    final summary = GardenSessionSummary(
      sessionId: _gardenSessionId!,
      startedAt: _gardenStartTime!,
      treesPlanted: _treesPlanted,
      flowersPlanted: _flowersPlanted,
      treesMatured: _treesMatured,
      durationSeconds: duration,
    );
    final prefs = await SharedPreferences.getInstance();
    final existing = await loadGardenSessions();
    existing.add(summary);
    final encoded = existing.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_gardenPrefsKey, encoded);
    _gardenSessionId = null;
    _gardenStartTime = null;
  }

  Future<List<GardenSessionSummary>> loadGardenSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_gardenPrefsKey);
    if (raw == null) return [];
    return raw
        .map((entry) => GardenSessionSummary.fromJson(
              jsonDecode(entry) as Map<String, dynamic>,
            ))
        .toList();
  }
}
