import 'study_entry.dart';

class StudySet {
  final int index;
  final String label;
  final List<StudyEntry> entries;

  const StudySet({
    required this.index,
    required this.label,
    required this.entries,
  });
}
