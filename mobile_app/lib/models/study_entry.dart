import 'study_direction.dart';

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

  factory StudyEntry.fromCategoryJson(
    String category,
    Map<String, dynamic> json, {
    required int fallbackId,
  }) {
    switch (category) {
      case 'vocabulary':
        return StudyEntry.fromVocabularyJson(json);
      case 'verbs':
        return StudyEntry.fromVerbJson(json);
      case 'adjectives':
        return StudyEntry(
          id: (json['id'] as num?)?.toInt() ?? fallbackId,
          romaji: json['romaji'] as String? ?? '',
          kana: json['kana'] as String? ?? '',
          kanji: json['kanji'] as String?,
          meaning: json['meaning'] as String? ?? '',
          category: 'adjective',
        );
      case 'hiragana':
        final character = json['character'] as String? ?? '';
        final romaji = json['romaji'] as String? ?? '';
        return StudyEntry(
          id: fallbackId,
          romaji: romaji,
          kana: character,
          kanji: null,
          meaning: romaji,
          category: 'hiragana',
        );
      case 'katakana':
        final character = json['katakana'] as String? ?? '';
        final romaji = json['romaji'] as String? ?? '';
        return StudyEntry(
          id: fallbackId,
          romaji: romaji,
          kana: character,
          kanji: null,
          meaning: romaji,
          category: 'katakana',
        );
      case 'kanji':
        final meaning = (json['meaning'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .join(', ');
        final kunyomi = (json['kunyomi'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .join(' / ');
        final onyomi = (json['onyomi'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .join(' / ');
        final reading = kunyomi.isNotEmpty ? kunyomi : onyomi;
        return StudyEntry(
          id: (json['id'] as num?)?.toInt() ?? fallbackId,
          romaji: reading,
          kana: reading,
          kanji: json['kanji'] as String?,
          meaning: meaning,
          category: 'kanji',
        );
      default:
        throw UnsupportedError('Unsupported practice category: $category');
    }
  }

  String get primaryJapanese => kanji != null && kanji!.isNotEmpty ? kanji! : kana;

  String promptFor(StudyDirection direction) {
    switch (direction) {
      case StudyDirection.japaneseToEnglish:
        return primaryJapanese;
      case StudyDirection.englishToJapanese:
        return meaning;
    }
  }

  String answerFor(StudyDirection direction) {
    switch (direction) {
      case StudyDirection.japaneseToEnglish:
        return meaning;
      case StudyDirection.englishToJapanese:
        return primaryJapanese;
    }
  }

  String subtitleFor(StudyDirection direction) {
    switch (direction) {
      case StudyDirection.japaneseToEnglish:
        return romaji;
      case StudyDirection.englishToJapanese:
        return romaji.isNotEmpty ? romaji : kana;
    }
  }

  bool matchesTypedAnswer(StudyDirection direction, String value) {
    final normalized = _normalize(value);
    if (normalized.isEmpty) {
      return false;
    }

    switch (direction) {
      case StudyDirection.japaneseToEnglish:
        final accepted = meaning
            .split(RegExp(r'[,/;]'))
            .map(_normalize)
            .where((item) => item.isNotEmpty);
        return accepted.any((item) => item == normalized);
      case StudyDirection.englishToJapanese:
        final candidates = {
          _normalize(primaryJapanese),
          _normalize(kana),
          _normalize(romaji),
          if (kanji != null) _normalize(kanji!),
        };
        return candidates.contains(normalized);
    }
  }

  static String _normalize(String value) {
    return value.trim().toLowerCase();
  }
}
