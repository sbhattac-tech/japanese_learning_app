import 'dart:math';

import 'package:flutter/material.dart';

import '../models/practice_category.dart';
import '../models/study_direction.dart';
import '../models/study_entry.dart';
import '../models/study_session_result.dart';
import '../services/progress_service.dart';
import '../widgets/session_summary_card.dart';

class MatchingScreen extends StatefulWidget {
  final String username;
  final PracticeCategory category;
  final List<StudyEntry> entries;
  final StudyDirection direction;
  final ProgressService progress;

  const MatchingScreen({
    super.key,
    required this.username,
    required this.category,
    required this.entries,
    required this.direction,
    required this.progress,
  });

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  final Random _random = Random();

  List<StudyEntry> _promptEntries = const [];
  List<String> _answers = const [];
  int? _selectedPromptId;
  String? _selectedAnswer;
  int _matches = 0;
  int _attempts = 0;
  StudySessionResult? _summary;
  List<StudySessionResult> _history = const [];

  @override
  void initState() {
    super.initState();
    _resetRound();
  }

  void _resetRound() {
    final sample = List<StudyEntry>.from(widget.entries)..shuffle(_random);
    final chosen = sample.take(4).toList();
    final answers = chosen.map((entry) => entry.answerFor(widget.direction)).toList()..shuffle(_random);

    setState(() {
      _promptEntries = chosen;
      _answers = answers;
      _selectedPromptId = null;
      _selectedAnswer = null;
      _matches = 0;
      _attempts = 0;
      _summary = null;
      _history = const [];
    });
  }

  Future<void> _attemptMatch() async {
    if (_selectedPromptId == null || _selectedAnswer == null) {
      return;
    }

    final selectedEntry = _promptEntries.firstWhere((entry) => entry.id == _selectedPromptId);
    final correct = selectedEntry.answerFor(widget.direction) == _selectedAnswer;
    await widget.progress.updateItemProgress(
      username: widget.username,
      category: widget.category,
      entryId: selectedEntry.id,
      answeredCorrectly: correct,
    );
    if (!mounted) return;

    if (correct) {
      setState(() {
        _promptEntries = _promptEntries.where((entry) => entry.id != selectedEntry.id).toList();
        _answers = _answers.where((answer) => answer != _selectedAnswer).toList();
        _selectedPromptId = null;
        _selectedAnswer = null;
        _matches += 1;
        _attempts += 1;
      });
      if (_promptEntries.isEmpty) {
        await _finishSession();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not a match. Try again.')),
      );
      setState(() {
        _selectedPromptId = null;
        _selectedAnswer = null;
        _attempts += 1;
      });
    }
  }

  Future<void> _finishSession() async {
    final result = StudySessionResult(
      mode: 'matching',
      category: widget.category.apiName,
      totalItems: 4,
      attempts: _attempts,
      correctOnFirstTry: _matches,
      scorePercent: (_matches / 4 * 100).round(),
      completedAt: DateTime.now(),
    );
    await widget.progress.recordSession(widget.username, result);
    final history = await widget.progress.loadHistoryFor(
      username: widget.username,
      mode: 'matching',
      category: widget.category.apiName,
    );
    if (!mounted) return;
    setState(() {
      _summary = result;
      _history = history;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_summary != null) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.category.label} Matching')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SessionSummaryCard(result: _summary!, history: _history),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('${widget.category.label} Matching')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: widget.entries.length < 4
            ? Center(
                child: Text(
                  'Add at least 4 ${widget.category.label.toLowerCase()} entries to play matching.',
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Matches: $_matches/4', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            itemCount: _promptEntries.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final entry = _promptEntries[index];
                              final selected = _selectedPromptId == entry.id;
                              return _ChoiceTile(
                                label: entry.promptFor(widget.direction),
                                selected: selected,
                                onTap: () async {
                                  setState(() {
                                    _selectedPromptId = entry.id;
                                  });
                                  await _attemptMatch();
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ListView.separated(
                            itemCount: _answers.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final answer = _answers[index];
                              final selected = _selectedAnswer == answer;
                              return _ChoiceTile(
                                label: answer,
                                selected: selected,
                                onTap: () async {
                                  setState(() {
                                    _selectedAnswer = answer;
                                  });
                                  await _attemptMatch();
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _resetRound,
                      child: const Text('New Round'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Theme.of(context).colorScheme.primaryContainer : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ),
    );
  }
}
