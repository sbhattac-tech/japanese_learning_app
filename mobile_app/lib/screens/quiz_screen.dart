import 'dart:math';

import 'package:flutter/material.dart';

import '../models/practice_category.dart';
import '../models/study_entry.dart';
import '../services/api_service.dart';

class QuizScreen extends StatefulWidget {
  final ApiService api;
  final PracticeCategory category;

  const QuizScreen({
    super.key,
    required this.api,
    required this.category,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Random _random = Random();

  List<StudyEntry> _entries = const [];
  StudyEntry? _current;
  List<String> _choices = const [];
  String? _selected;
  bool _loading = true;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await widget.api.fetchEntries(widget.category);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
      _nextQuestion();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  void _nextQuestion() {
    if (_entries.length < 4) return;

    final current = _entries[_random.nextInt(_entries.length)];
    final distractors = _entries.where((entry) => entry.id != current.id).toList()
      ..shuffle(_random);

    final choices = <String>[
      current.meaning,
      ...distractors.take(3).map((entry) => entry.meaning),
    ]..shuffle(_random);

    setState(() {
      _current = current;
      _choices = choices;
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.category.label} Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _current == null
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
                              Text(widget.category.quizPrompt),
                              const SizedBox(height: 12),
                              Text(
                                _current!.primaryJapanese,
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              if (_current!.romaji.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(_current!.romaji),
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
                                  : () {
                                      final correct = choice == _current!.meaning;
                                      setState(() {
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
                              _selected == _current!.meaning ? 'Next Question' : 'Try Another',
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
