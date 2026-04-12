import 'package:flutter/material.dart';

import '../models/practice_category.dart';
import '../models/study_entry.dart';
import '../services/progress_service.dart';
import 'study_mode_screen.dart';

class SetSelectionScreen extends StatelessWidget {
  final String username;
  final PracticeCategory category;
  final List<StudyEntry> entries;
  final ProgressService progress;

  const SetSelectionScreen({
    super.key,
    required this.username,
    required this.category,
    required this.entries,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final sets = progress.buildStudySets(entries);

    return Scaffold(
      appBar: AppBar(title: Text('${category.label} Sets')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Learn ${category.label.toLowerCase()} in focused sets of 20.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 18),
          ...sets.map(
            (set) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(set.label),
                  subtitle: Text('${set.entries.length} items'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudyModeScreen(
                          username: username,
                          category: category,
                          studySet: set,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
