class ImportCandidate {
  final String sourceText;
  final String sourceLanguage;
  final String normalizedText;
  final String romaji;
  final String japaneseText;
  final String hiragana;
  final String katakana;
  final String kanji;
  final String meaning;
  final String partOfSpeech;
  final String category;
  final String matchedCategory;
  final String setName;

  const ImportCandidate({
    required this.sourceText,
    required this.sourceLanguage,
    required this.normalizedText,
    required this.romaji,
    required this.japaneseText,
    required this.hiragana,
    required this.katakana,
    required this.kanji,
    required this.meaning,
    required this.partOfSpeech,
    required this.category,
    required this.matchedCategory,
    required this.setName,
  });

  factory ImportCandidate.fromJson(Map<String, dynamic> json) {
    return ImportCandidate(
      sourceText: json['source_text'] as String? ?? '',
      sourceLanguage: json['source_language'] as String? ?? 'unknown',
      normalizedText: json['normalized_text'] as String? ?? '',
      romaji: json['romaji'] as String? ?? '',
      japaneseText: json['japanese_text'] as String? ?? '',
      hiragana: json['hiragana'] as String? ?? '',
      katakana: json['katakana'] as String? ?? '',
      kanji: json['kanji'] as String? ?? '',
      meaning: json['meaning'] as String? ?? '',
      partOfSpeech: json['part_of_speech'] as String? ?? 'vocabulary',
      category: json['category'] as String? ?? 'imported',
      matchedCategory: json['matched_category'] as String? ?? '',
      setName: json['set_name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source_text': sourceText,
      'source_language': sourceLanguage,
      'normalized_text': normalizedText,
      'romaji': romaji,
      'japanese_text': japaneseText,
      'hiragana': hiragana,
      'katakana': katakana,
      'kanji': kanji,
      'meaning': meaning,
      'part_of_speech': partOfSpeech,
      'category': category,
      'matched_category': matchedCategory,
      'set_name': setName,
    };
  }

  ImportCandidate copyWith({
    String? sourceText,
    String? sourceLanguage,
    String? normalizedText,
    String? romaji,
    String? japaneseText,
    String? hiragana,
    String? katakana,
    String? kanji,
    String? meaning,
    String? partOfSpeech,
    String? category,
    String? matchedCategory,
    String? setName,
  }) {
    return ImportCandidate(
      sourceText: sourceText ?? this.sourceText,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      normalizedText: normalizedText ?? this.normalizedText,
      romaji: romaji ?? this.romaji,
      japaneseText: japaneseText ?? this.japaneseText,
      hiragana: hiragana ?? this.hiragana,
      katakana: katakana ?? this.katakana,
      kanji: kanji ?? this.kanji,
      meaning: meaning ?? this.meaning,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      category: category ?? this.category,
      matchedCategory: matchedCategory ?? this.matchedCategory,
      setName: setName ?? this.setName,
    );
  }
}

class ImportExtractResult {
  final List<ImportCandidate> entries;
  final List<String> availableSets;

  const ImportExtractResult({
    required this.entries,
    required this.availableSets,
  });
}
