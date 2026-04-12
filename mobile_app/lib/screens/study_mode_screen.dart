import 'package:flutter/material.dart';

import '../models/practice_category.dart';
import '../models/study_direction.dart';
import '../models/study_item_progress.dart';
import '../models/study_set.dart';
import '../services/progress_service.dart';
import '../widgets/study_direction_toggle.dart';
import 'flashcards_screen.dart';
import 'matching_screen.dart';
import 'quiz_screen.dart';
import 'typing_screen.dart';

class StudyModeScreen extends StatefulWidget {
  final String username;
  final PracticeCategory category;
  final StudySet studySet;

  const StudyModeScreen({
    super.key,
    required this.username,
    required this.category,
    required this.studySet,
  });

  @override
  State<StudyModeScreen> createState() => _StudyModeScreenState();
}

class _StudyModeScreenState extends State<StudyModeScreen> {
  final _progress = ProgressService();
  StudyDirection _direction = StudyDirection.japaneseToEnglish;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.category.label} • ${widget.studySet.label}')),
      body: FutureBuilder<Map<int, StudyItemProgress>>(
        future: _progress.loadCategoryProgress(
          username: widget.username,
          category: widget.category,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final progressMap = snapshot.data ?? {};
          final activeEntries = widget.studySet.entries.where((entry) {
            final itemProgress = progressMap[entry.id] ?? const StudyItemProgress.initial();
            return itemProgress.active;
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Choose an exercise and study direction for this set.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              StudyDirectionToggle(
                value: _direction,
                onChanged: (direction) {
                  setState(() {
                    _direction = direction;
                  });
                },
              ),
              const SizedBox(height: 20),
              if (activeEntries.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Every item in this set is currently deactivated. Turn some back on from the analytics screen first.',
                    ),
                  ),
                )
              else ...[
                _ModeTile(
                  title: 'Flashcards',
                  description: 'Warm up with active recall before exercises.',
                  icon: Icons.style_outlined,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FlashcardsScreen(
                          username: widget.username,
                          category: widget.category,
                          entries: activeEntries,
                          direction: _direction,
                          progress: _progress,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ModeTile(
                  title: 'Quiz',
                  description: 'Multiple choice questions with mastery updates.',
                  icon: Icons.quiz_outlined,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => QuizScreen(
                          username: widget.username,
                          category: widget.category,
                          entries: activeEntries,
                          direction: _direction,
                          progress: _progress,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ModeTile(
                  title: 'Matching',
                  description: 'Pair prompts and answers to reinforce recall speed.',
                  icon: Icons.grid_view_rounded,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MatchingScreen(
                          username: widget.username,
                          category: widget.category,
                          entries: activeEntries,
                          direction: _direction,
                          progress: _progress,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _ModeTile(
                  title: 'Typing',
                  description: 'Produce the answer yourself like a Duolingo-style writing drill.',
                  icon: Icons.keyboard_alt_outlined,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TypingScreen(
                          username: widget.username,
                          category: widget.category,
                          entries: activeEntries,
                          direction: _direction,
                          progress: _progress,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _ModeTile({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
