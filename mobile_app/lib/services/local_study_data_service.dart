import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/practice_category.dart';
import '../models/study_entry.dart';

class LocalStudyDataService {
  const LocalStudyDataService();

  Future<List<StudyEntry>> fetchEntries(PracticeCategory category) async {
    final assetPath = switch (category.apiName) {
      'hiragana' => 'assets/data/hiragana.json',
      'katakana' => 'assets/data/katakana.json',
      'kanji' => 'assets/data/kanji.json',
      _ => throw UnsupportedError(
          'Local data is not available for ${category.apiName}.',
        ),
    };

    final rawJson = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(rawJson);
    final items = switch (category.apiName) {
      'hiragana' => ((decoded as Map<String, dynamic>)['hiragana'] as List<dynamic>?) ?? const [],
      'katakana' => ((decoded as Map<String, dynamic>)['katakana'] as List<dynamic>?) ?? const [],
      'kanji' => (decoded as List<dynamic>?) ?? const [],
      _ => const <dynamic>[],
    };

    return items
        .asMap()
        .entries
        .map(
          (entry) => StudyEntry.fromCategoryJson(
            category.apiName,
            entry.value as Map<String, dynamic>,
            fallbackId: entry.key + 1,
          ),
        )
        .toList();
  }
}
