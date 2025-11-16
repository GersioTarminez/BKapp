class EmotionEntry {
  EmotionEntry({
    required this.date,
    required this.emotion,
    this.note,
  });

  final DateTime date;
  final String emotion;
  final String? note;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'emotion': emotion,
      'note': note,
    };
  }

  static EmotionEntry fromJson(Map<String, dynamic> json) {
    return EmotionEntry(
      date: DateTime.parse(json['date'] as String),
      emotion: json['emotion'] as String,
      note: json['note'] as String?,
    );
  }
}
