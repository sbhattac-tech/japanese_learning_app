import 'package:flutter/material.dart';

import 'study_direction.dart';

enum CategoryGroup { words, letters }

class PracticeCategory {
  final String apiName;
  final String label;
  final String description;
  final IconData icon;
  final String quizPrompt;
  final CategoryGroup group;

  const PracticeCategory({
    required this.apiName,
    required this.label,
    required this.description,
    required this.icon,
    required this.quizPrompt,
    required this.group,
  });

  bool get isLetterCategory => group == CategoryGroup.letters;
  bool get isWordCategory => group == CategoryGroup.words;

  String promptForDirection(StudyDirection direction) {
    switch (direction) {
      case StudyDirection.japaneseToEnglish:
        return quizPrompt;
      case StudyDirection.englishToJapanese:
        if (apiName == 'hiragana' || apiName == 'katakana') {
          return 'Which character matches this romaji?';
        }
        if (apiName == 'kanji') {
          return 'Which kanji matches this meaning?';
        }
        return 'Which Japanese answer matches this English prompt?';
    }
  }

  static const vocabulary = PracticeCategory(
    apiName: 'vocabulary',
    label: 'Vocabulary',
    description: 'Everyday words and useful expressions.',
    icon: Icons.menu_book_outlined,
    quizPrompt: 'What does this mean?',
    group: CategoryGroup.words,
  );

  static const verbs = PracticeCategory(
    apiName: 'verbs',
    label: 'Verbs',
    description: 'Core actions and common verb forms.',
    icon: Icons.directions_run_outlined,
    quizPrompt: 'What does this verb mean?',
    group: CategoryGroup.words,
  );

  static const adjectives = PracticeCategory(
    apiName: 'adjectives',
    label: 'Adjectives',
    description: 'Descriptive words for people, things, and places.',
    icon: Icons.auto_awesome_outlined,
    quizPrompt: 'What does this adjective mean?',
    group: CategoryGroup.words,
  );

  static const hiragana = PracticeCategory(
    apiName: 'hiragana',
    label: 'Hiragana',
    description: 'Practice the basic Japanese phonetic script.',
    icon: Icons.edit_outlined,
    quizPrompt: 'Which romaji matches this character?',
    group: CategoryGroup.letters,
  );

  static const katakana = PracticeCategory(
    apiName: 'katakana',
    label: 'Katakana',
    description: 'Train borrowed-word and foreign-name characters.',
    icon: Icons.text_fields_outlined,
    quizPrompt: 'Which romaji matches this character?',
    group: CategoryGroup.letters,
  );

  static const kanji = PracticeCategory(
    apiName: 'kanji',
    label: 'Kanji',
    description: 'Review kanji meanings and readings.',
    icon: Icons.translate_outlined,
    quizPrompt: 'What does this kanji mean?',
    group: CategoryGroup.letters,
  );

  static const values = <PracticeCategory>[
    vocabulary,
    verbs,
    adjectives,
    hiragana,
    katakana,
    kanji,
  ];
}
