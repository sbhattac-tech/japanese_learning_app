class StudyItemProgress {
  final bool active;
  final int attempts;
  final int correct;
  final int streak;
  final DateTime? lastReviewedAt;

  const StudyItemProgress({
    required this.active,
    required this.attempts,
    required this.correct,
    required this.streak,
    required this.lastReviewedAt,
  });

  const StudyItemProgress.initial()
      : active = true,
        attempts = 0,
        correct = 0,
        streak = 0,
        lastReviewedAt = null;

  double get mastery {
    if (attempts == 0) {
      return 0;
    }
    final accuracy = correct / attempts;
    final streakBonus = streak >= 5 ? 0.15 : streak * 0.03;
    final score = (accuracy + streakBonus).clamp(0, 1);
    return score * 100;
  }

  StudyItemProgress copyWith({
    bool? active,
    int? attempts,
    int? correct,
    int? streak,
    DateTime? lastReviewedAt,
  }) {
    return StudyItemProgress(
      active: active ?? this.active,
      attempts: attempts ?? this.attempts,
      correct: correct ?? this.correct,
      streak: streak ?? this.streak,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  factory StudyItemProgress.fromJson(Map<String, dynamic> json) {
    return StudyItemProgress(
      active: json['active'] as bool? ?? true,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      lastReviewedAt: json['lastReviewedAt'] == null
          ? null
          : DateTime.tryParse(json['lastReviewedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'active': active,
      'attempts': attempts,
      'correct': correct,
      'streak': streak,
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
    };
  }
}
