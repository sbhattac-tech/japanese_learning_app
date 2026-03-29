import 'package:flutter/material.dart';

class PracticeCategory {
  final String apiName;
  final String label;
  final String description;
  final IconData icon;
  final String quizPrompt;

  const PracticeCategory({
    required this.apiName,
    required this.label,
    required this.description,
    required this.icon,
    required this.quizPrompt,
  });

  static const vocabulary = PracticeCategory(
    apiName: 'vocabulary',
    label: 'Vocabulary',
    description: 'Everyday words and useful expressions.',
    icon: Icons.menu_book_outlined,
    quizPrompt: 'What does this mean?',
  );

  static const verbs = PracticeCategory(
    apiName: 'verbs',
    label: 'Verbs',
    description: 'Core actions and common verb forms.',
    icon: Icons.directions_run_outlined,
    quizPrompt: 'What does this verb mean?',
  );

  static const adjectives = PracticeCategory(
    apiName: 'adjectives',
    label: 'Adjectives',
    description: 'Descriptive words for people, things, and places.',
    icon: Icons.auto_awesome_outlined,
    quizPrompt: 'What does this adjective mean?',
  );

  static const hiragana = PracticeCategory(
    apiName: 'hiragana',
    label: 'Hiragana',
    description: 'Practice the basic Japanese phonetic script.',
    icon: Icons.edit_outlined,
    quizPrompt: 'Which romaji matches this character?',
  );

  static const katakana = PracticeCategory(
    apiName: 'katakana',
    label: 'Katakana',
    description: 'Train borrowed-word and foreign-name characters.',
    icon: Icons.text_fields_outlined,
    quizPrompt: 'Which romaji matches this character?',
  );

  static const kanji = PracticeCategory(
    apiName: 'kanji',
    label: 'Kanji',
    description: 'Review kanji meanings and readings.',
    icon: Icons.translate_outlined,
    quizPrompt: 'What does this kanji mean?',
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
