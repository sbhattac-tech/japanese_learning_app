import 'package:flutter/material.dart';

import '../models/practice_category.dart';
import '../models/study_direction.dart';
import '../models/study_entry.dart';
import '../services/progress_service.dart';
import '../widgets/flashcard_view.dart';

class FlashcardsScreen extends StatefulWidget {
  final String username;
  final PracticeCategory category;
  final List<StudyEntry> entries;
  final StudyDirection direction;
  final ProgressService progress;

  const FlashcardsScreen({
    super.key,
    required this.username,
    required this.category,
    required this.entries,
    required this.direction,
    required this.progress,
  });

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  bool _showAnswer = false;
  int _index = 0;

  Future<void> _record(bool correct) async {
    if (widget.entries.isEmpty) {
      return;
    }
    await widget.progress.updateItemProgress(
      username: widget.username,
      category: widget.category,
      entryId: widget.entries[_index].id,
      answeredCorrectly: correct,
    );
    if (!mounted) return;
    setState(() {
      _index = (_index + 1) % widget.entries.length;
      _showAnswer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entries.isEmpty ? null : widget.entries[_index];

    return Scaffold(
      appBar: AppBar(title: Text('${widget.category.label} Flashcards')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: entry == null
            ? Center(
                child: Text('No ${widget.category.label.toLowerCase()} entries found.'),
              )
            : Column(
                children: [
                  Expanded(
                    child: Center(
                      child: FlashcardView(
                        entry: entry,
                        showAnswer: _showAnswer,
                        direction: widget.direction,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _showAnswer = !_showAnswer;
                            });
                          },
                          child: Text(_showAnswer ? 'Hide' : 'Reveal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _showAnswer ? () => _record(true) : null,
                          child: const Text('I knew it'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _showAnswer ? () => _record(false) : null,
                      child: const Text('Still learning'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
