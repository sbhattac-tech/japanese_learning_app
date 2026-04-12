enum StudyDirection {
  japaneseToEnglish,
  englishToJapanese;

  String get compactLabel {
    switch (this) {
      case StudyDirection.japaneseToEnglish:
        return 'Prompt -> Meaning';
      case StudyDirection.englishToJapanese:
        return 'Meaning -> Answer';
    }
  }

  String get answerLanguageLabel {
    switch (this) {
      case StudyDirection.japaneseToEnglish:
        return 'Meaning';
      case StudyDirection.englishToJapanese:
        return 'Answer';
    }
  }
}
