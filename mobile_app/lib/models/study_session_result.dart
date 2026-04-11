class StudySessionResult {
  final String mode;
  final String category;
  final int totalItems;
  final int attempts;
  final int correctOnFirstTry;
  final int scorePercent;
  final DateTime completedAt;

  const StudySessionResult({
    required this.mode,
    required this.category,
    required this.totalItems,
    required this.attempts,
    required this.correctOnFirstTry,
    required this.scorePercent,
    required this.completedAt,
  });

  factory StudySessionResult.fromJson(Map<String, dynamic> json) {
    return StudySessionResult(
      mode: json['mode'] as String? ?? '',
      category: json['category'] as String? ?? '',
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      correctOnFirstTry: (json['correctOnFirstTry'] as num?)?.toInt() ?? 0,
      scorePercent: (json['scorePercent'] as num?)?.toInt() ?? 0,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mode': mode,
      'category': category,
      'totalItems': totalItems,
      'attempts': attempts,
      'correctOnFirstTry': correctOnFirstTry,
      'scorePercent': scorePercent,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}
