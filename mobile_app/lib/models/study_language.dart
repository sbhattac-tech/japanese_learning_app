enum StudyLanguage {
  japanese,
  czech;

  String get label {
    switch (this) {
      case StudyLanguage.japanese:
        return 'Japanese';
      case StudyLanguage.czech:
        return 'Czech';
    }
  }

  String get greeting {
    switch (this) {
      case StudyLanguage.japanese:
        return 'Konnichiwa';
      case StudyLanguage.czech:
        return 'Ahoj';
    }
  }
}
