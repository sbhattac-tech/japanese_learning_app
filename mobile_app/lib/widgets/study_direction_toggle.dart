import 'package:flutter/material.dart';

import '../models/study_direction.dart';

class StudyDirectionToggle extends StatelessWidget {
  final StudyDirection value;
  final ValueChanged<StudyDirection> onChanged;

  const StudyDirectionToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<StudyDirection>(
      segments: StudyDirection.values
          .map(
            (direction) => ButtonSegment<StudyDirection>(
              value: direction,
              label: Text(direction.compactLabel),
            ),
          )
          .toList(),
      selected: {value},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
