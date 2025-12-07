import 'dart:ui';

import 'package:flutter/material.dart';

/// Emotional seeds the child can plant in the garden.
enum SeedEmotion { happy, calm, brave, kind, sad }

extension SeedEmotionX on SeedEmotion {
  String get emoji => switch (this) {
        SeedEmotion.happy => '🌼',
        SeedEmotion.calm => '🌿',
        SeedEmotion.brave => '🌻',
        SeedEmotion.kind => '🌸',
        SeedEmotion.sad => '💙',
      };

  String get label => switch (this) {
        SeedEmotion.happy => 'Happy',
        SeedEmotion.calm => 'Calm',
        SeedEmotion.brave => 'Brave',
        SeedEmotion.kind => 'Kind',
        SeedEmotion.sad => 'Gentle',
      };

  Color get color => switch (this) {
        SeedEmotion.happy => const Color(0xFFFFD166),
        SeedEmotion.calm => const Color(0xFF94D2BD),
        SeedEmotion.brave => const Color(0xFFF4978E),
        SeedEmotion.kind => const Color(0xFFE0BBE4),
        SeedEmotion.sad => const Color(0xFF90A4FF),
      };
}

/// Stores a planted seed, its stage and progress so we can persist the garden.
class GardenPlant {
  GardenPlant({
    required this.id,
    required this.emotion,
    required this.position,
    required this.stage,
    required this.progress,
    required this.lastCare,
  });

  static const int maxStage = 3;

  final String id;
  final SeedEmotion emotion;
  final Offset position; // Stored as relative (0-1) coordinates.
  final int stage;
  final double progress;
  final DateTime lastCare;

  GardenPlant copyWith({
    String? id,
    SeedEmotion? emotion,
    Offset? position,
    int? stage,
    double? progress,
    DateTime? lastCare,
  }) {
    return GardenPlant(
      id: id ?? this.id,
      emotion: emotion ?? this.emotion,
      position: position ?? this.position,
      stage: stage ?? this.stage,
      progress: progress ?? this.progress,
      lastCare: lastCare ?? this.lastCare,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'emotion': emotion.name,
      'dx': position.dx,
      'dy': position.dy,
      'stage': stage,
      'progress': progress,
      'lastCare': lastCare.toIso8601String(),
    };
  }

  factory GardenPlant.fromJson(Map<String, dynamic> json) {
    final emotionName = json['emotion'] as String? ?? 'happy';
    final emotion = SeedEmotion.values.firstWhere(
      (e) => e.name == emotionName,
      orElse: () => SeedEmotion.happy,
    );
    return GardenPlant(
      id: json['id'] as String? ?? UniqueKey().toString(),
      emotion: emotion,
      position: Offset(
        (json['dx'] as num?)?.toDouble() ?? 0.5,
        (json['dy'] as num?)?.toDouble() ?? 0.5,
      ),
      stage: json['stage'] as int? ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      lastCare: DateTime.tryParse(json['lastCare'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
