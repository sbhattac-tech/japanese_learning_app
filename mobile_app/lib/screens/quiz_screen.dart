import 'dart:math';

import 'package:flutter/material.dart';

import '../models/practice_category.dart';
import '../models/study_direction.dart';
import '../models/study_entry.dart';
import '../models/study_session_result.dart';
import '../services/progress_service.dart';
import '../widgets/session_summary_card.dart';

class QuizScreen extends StatefulWidget {
  final String username;
  final PracticeCategory category;
  final List<StudyEntry> entries;
  final StudyDirection direction;
  final ProgressService progress;

  const QuizScreen({
    super.key,
    required this.username,
    required this.category,
    required this.entries,
    required this.direction,
    required this.progress,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Random _random = Random();

  StudyEntry? _current;
  List<String> _choices = const [];
  String? _selected;
  int _score = 0;
  int _attempts = 0;
  int _asked = 0;
  StudySessionResult? _summary;
  List<StudySessionResult> _history = const [];

  @override
  void initState() {
    super.initState();
    _nextQuestion();
  }

  void _nextQuestion() {
    if (widget.entries.length < 4) {
      return;
    }
    if (_asked >= widget.entries.length) {
      _finishSession();
      return;
    }

    final current = widget.entries[_random.nextInt(widget.entries.length)];
    final distractors = widget.entries.where((entry) => entry.id != current.id).toList()
      ..shuffle(_random);

    final choices = <String>[
      current.answerFor(widget.direction),
      ...distractors.take(3).map((entry) => entry.answerFor(widget.direction)),
    ]..shuffle(_random);

    setState(() {
      _current = current;
      _choices = choices;
      _selected = null;
      _asked += 1;
    });
  }

  Future<void> _finishSession() async {
    final result = StudySessionResult(
      mode: 'quiz',
      category: widget.category.apiName,
      totalItems: widget.entries.length,
      attempts: _attempts,
      correctOnFirstTry: _score,
      scorePercent: widget.entries.isEmpty ? 0 : ((_score / widget.entries.length) * 100).round(),
      completedAt: DateTime.now(),
    );
    await widget.progress.recordSession(widget.username, result);
    final history = await widget.progress.loadHistoryFor(
      username: widget.username,
      mode: 'quiz',
      category: widget.category.apiName,
    );
    if (!mounted) return;
    setState(() {
      _summary = result;
      _history = history;
      _current = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_summary != null) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.category.label} Quiz')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SessionSummaryCard(result: _summary!, history: _history),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('${widget.category.label} Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _current == null
            ? Center(
                child: Text(
                  'Not enough ${widget.category.label.toLowerCase()} entries to build a quiz yet.',
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Score: $_score', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.category.promptForDirection(widget.direction)),
                          const SizedBox(height: 12),
                          Text(
                            _current!.promptFor(widget.direction),
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          if (!widget.category.isLetterCategory &&
                              _current!.subtitleFor(widget.direction).isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(_current!.subtitleFor(widget.direction)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ..._choices.map(
                    (choice) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonal(
                          onPressed: _selected != null
                              ? null
                              : () async {
                                  final correct = choice == _current!.answerFor(widget.direction);
                                  await widget.progress.updateItemProgress(
                                    username: widget.username,
                                    category: widget.category,
                                    entryId: _current!.id,
                                    answeredCorrectly: correct,
                                  );
                                  if (!mounted) return;
                                  setState(() {
                                    _attempts += 1;
                                    _selected = choice;
                                    if (correct) {
                                      _score += 1;
                                    }
                                  });
                                },
                          child: Text(choice),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_selected != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _nextQuestion,
                        child: Text(
                          _selected == _current!.answerFor(widget.direction)
                              ? 'Next Question'
                              : 'Try Another',
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
