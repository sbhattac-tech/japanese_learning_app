import 'dart:math';

import 'package:flutter/material.dart';

import '../models/practice_category.dart';
import '../models/study_entry.dart';
import '../services/api_service.dart';

class MatchingScreen extends StatefulWidget {
  final ApiService api;
  final PracticeCategory category;

  const MatchingScreen({
    super.key,
    required this.api,
    required this.category,
  });

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  final Random _random = Random();

  List<StudyEntry> _entries = const [];
  List<StudyEntry> _promptEntries = const [];
  List<String> _answers = const [];
  int? _selectedPromptId;
  String? _selectedAnswer;
  int _matches = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await widget.api.fetchEntries(widget.category);
      final sample = List<StudyEntry>.from(entries)..shuffle(_random);
      final chosen = sample.take(4).toList();
      final answers = chosen.map((entry) => entry.meaning).toList()..shuffle(_random);
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _promptEntries = chosen;
        _answers = answers;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  void _resetRound() {
    final sample = List<StudyEntry>.from(_entries)..shuffle(_random);
    final chosen = sample.take(4).toList();
    final answers = chosen.map((entry) => entry.meaning).toList()..shuffle(_random);

    setState(() {
      _promptEntries = chosen;
      _answers = answers;
      _selectedPromptId = null;
      _selectedAnswer = null;
      _matches = 0;
    });
  }

  void _attemptMatch() {
    if (_selectedPromptId == null || _selectedAnswer == null) return;
    final selectedEntry = _promptEntries.firstWhere((entry) => entry.id == _selectedPromptId);
    final correct = selectedEntry.meaning == _selectedAnswer;

    if (correct) {
      setState(() {
        _promptEntries = _promptEntries.where((entry) => entry.id != selectedEntry.id).toList();
        _answers = _answers.where((answer) => answer != _selectedAnswer).toList();
        _selectedPromptId = null;
        _selectedAnswer = null;
        _matches += 1;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not a match. Try again.')),
      );
      setState(() {
        _selectedPromptId = null;
        _selectedAnswer = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.category.label} Matching')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _entries.length < 4
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
                                    label: entry.primaryJapanese,
                                    selected: selected,
                                    onTap: () {
                                      setState(() {
                                        _selectedPromptId = entry.id;
                                      });
                                      _attemptMatch();
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
                                    onTap: () {
                                      setState(() {
                                        _selectedAnswer = answer;
                                      });
                                      _attemptMatch();
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
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : Colors.white,
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
