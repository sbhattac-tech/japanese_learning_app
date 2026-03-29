class StudyEntry {
  final int id;
  final String romaji;
  final String kana;
  final String? kanji;
  final String meaning;
  final String category;

  const StudyEntry({
    required this.id,
    required this.romaji,
    required this.kana,
    required this.kanji,
    required this.meaning,
    required this.category,
  });

  factory StudyEntry.fromVocabularyJson(Map<String, dynamic> json) {
    return StudyEntry(
      id: json['id'] as int,
      romaji: json['romaji'] as String? ?? '',
      kana: json['kana'] as String? ?? '',
      kanji: json['kanji'] as String?,
      meaning: json['meaning'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
    );
  }

  factory StudyEntry.fromVerbJson(Map<String, dynamic> json) {
    return StudyEntry(
      id: json['id'] as int,
      romaji: json['romaji'] as String? ?? '',
      kana: json['hiragana'] as String? ?? '',
      kanji: json['kanji'] as String?,
      meaning: json['meaning'] as String? ?? '',
      category: 'verb',
    );
  }

  String get primaryJapanese => kanji != null && kanji!.isNotEmpty ? kanji! : kana;
}
