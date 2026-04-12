import 'package:flutter/material.dart';

import 'study_language.dart';
import 'study_direction.dart';

enum CategoryGroup { words, letters }

class PracticeCategory {
  final String apiName;
  final String label;
  final String description;
  final IconData icon;
  final String quizPrompt;
  final CategoryGroup group;
  final StudyLanguage studyLanguage;

  const PracticeCategory({
    required this.apiName,
    required this.label,
    required this.description,
    required this.icon,
    required this.quizPrompt,
    required this.group,
    required this.studyLanguage,
  });

  bool get isLetterCategory => group == CategoryGroup.letters;
  bool get isWordCategory => group == CategoryGroup.words;
  bool supportsLanguage(StudyLanguage language) => studyLanguage == language;

  String promptForDirection(StudyDirection direction) {
    switch (direction) {
      case StudyDirection.japaneseToEnglish:
        return quizPrompt;
      case StudyDirection.englishToJapanese:
        if (apiName == 'czech_vocabulary' ||
            apiName == 'czech_adjectives' ||
            apiName == 'czech_verbs') {
          return 'Which Czech answer matches this English prompt?';
        }
        if (apiName == 'hiragana' || apiName == 'katakana') {
          return 'Which character matches this romaji?';
        }
        if (apiName == 'kanji') {
          return 'Which kanji matches this meaning?';
        }
        return 'Which Japanese answer matches this English prompt?';
    }
  }

  static const japaneseVocabulary = PracticeCategory(
    apiName: 'japanese_vocabulary',
    label: 'Japanese Vocabulary',
    description: 'Everyday Japanese words and useful expressions.',
    icon: Icons.menu_book_outlined,
    quizPrompt: 'What does this mean?',
    group: CategoryGroup.words,
    studyLanguage: StudyLanguage.japanese,
  );

  static const japaneseVerbs = PracticeCategory(
    apiName: 'japanese_verbs',
    label: 'Japanese Verbs',
    description: 'Core Japanese actions and common verb forms.',
    icon: Icons.directions_run_outlined,
    quizPrompt: 'What does this verb mean?',
    group: CategoryGroup.words,
    studyLanguage: StudyLanguage.japanese,
  );

  static const japaneseAdjectives = PracticeCategory(
    apiName: 'japanese_adjectives',
    label: 'Japanese Adjectives',
    description: 'Descriptive Japanese words for people, things, and places.',
    icon: Icons.auto_awesome_outlined,
    quizPrompt: 'What does this adjective mean?',
    group: CategoryGroup.words,
    studyLanguage: StudyLanguage.japanese,
  );

  static const czechVocabulary = PracticeCategory(
    apiName: 'czech_vocabulary',
    label: 'Czech Vocabulary',
    description: 'English to Czech vocabulary with topic labels and named sets.',
    icon: Icons.travel_explore_outlined,
    quizPrompt: 'What is the English meaning of this Czech word?',
    group: CategoryGroup.words,
    studyLanguage: StudyLanguage.czech,
  );

  static const czechAdjectives = PracticeCategory(
    apiName: 'czech_adjectives',
    label: 'Czech Adjectives',
    description: 'English to Czech adjective study with set-based review.',
    icon: Icons.format_paint_outlined,
    quizPrompt: 'What is the English meaning of this Czech adjective?',
    group: CategoryGroup.words,
    studyLanguage: StudyLanguage.czech,
  );

  static const czechVerbs = PracticeCategory(
    apiName: 'czech_verbs',
    label: 'Czech Verbs',
    description: 'English to Czech verb study with set-based review.',
    icon: Icons.hiking_outlined,
    quizPrompt: 'What is the English meaning of this Czech verb?',
    group: CategoryGroup.words,
    studyLanguage: StudyLanguage.czech,
  );

  static const hiragana = PracticeCategory(
    apiName: 'hiragana',
    label: 'Hiragana',
    description: 'Practice the basic Japanese phonetic script.',
    icon: Icons.edit_outlined,
    quizPrompt: 'Which romaji matches this character?',
    group: CategoryGroup.letters,
    studyLanguage: StudyLanguage.japanese,
  );

  static const katakana = PracticeCategory(
    apiName: 'katakana',
    label: 'Katakana',
    description: 'Train borrowed-word and foreign-name characters.',
    icon: Icons.text_fields_outlined,
    quizPrompt: 'Which romaji matches this character?',
    group: CategoryGroup.letters,
    studyLanguage: StudyLanguage.japanese,
  );

  static const kanji = PracticeCategory(
    apiName: 'kanji',
    label: 'Kanji',
    description: 'Review kanji meanings and readings.',
    icon: Icons.translate_outlined,
    quizPrompt: 'What does this kanji mean?',
    group: CategoryGroup.letters,
    studyLanguage: StudyLanguage.japanese,
  );

  static const values = <PracticeCategory>[
    japaneseVocabulary,
    japaneseVerbs,
    japaneseAdjectives,
    czechVocabulary,
    czechAdjectives,
    czechVerbs,
    hiragana,
    katakana,
    kanji,
  ];
}
