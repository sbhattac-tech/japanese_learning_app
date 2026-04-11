enum StudyDirection {
  japaneseToEnglish,
  englishToJapanese;

  String get compactLabel {
    switch (this) {
      case StudyDirection.japaneseToEnglish:
        return 'JP -> EN';
      case StudyDirection.englishToJapanese:
        return 'EN -> JP';
    }
  }

  String get answerLanguageLabel {
    switch (this) {
      case StudyDirection.japaneseToEnglish:
        return 'English';
      case StudyDirection.englishToJapanese:
        return 'Japanese';
    }
  }
}
