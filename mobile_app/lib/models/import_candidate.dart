class ImportCandidate {
  final String sourceText;
  final String romaji;
  final String kana;
  final String meaning;
  final String category;

  const ImportCandidate({
    required this.sourceText,
    required this.romaji,
    required this.kana,
    required this.meaning,
    required this.category,
  });

  factory ImportCandidate.fromJson(Map<String, dynamic> json) {
    return ImportCandidate(
      sourceText: json['source_text'] as String? ?? '',
      romaji: json['romaji'] as String? ?? '',
      kana: json['kana'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      category: json['category'] as String? ?? 'imported',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source_text': sourceText,
      'romaji': romaji,
      'kana': kana,
      'meaning': meaning,
      'category': category,
    };
  }

  ImportCandidate copyWith({
    String? sourceText,
    String? romaji,
    String? kana,
    String? meaning,
    String? category,
  }) {
    return ImportCandidate(
      sourceText: sourceText ?? this.sourceText,
      romaji: romaji ?? this.romaji,
      kana: kana ?? this.kana,
      meaning: meaning ?? this.meaning,
      category: category ?? this.category,
    );
  }
}
