import 'package:flutter/material.dart';

import '../models/practice_category.dart';
import '../models/study_entry.dart';
import '../services/api_service.dart';
import '../widgets/flashcard_view.dart';

class FlashcardsScreen extends StatefulWidget {
  final ApiService api;
  final PracticeCategory category;

  const FlashcardsScreen({
    super.key,
    required this.api,
    required this.category,
  });

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  List<StudyEntry> _entries = const [];
  bool _loading = true;
  bool _showAnswer = false;
  int _index = 0;

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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load ${widget.category.label.toLowerCase()} flashcards.'),
        ),
      );
    }
  }

  void _nextCard() {
    if (_entries.isEmpty) return;
    setState(() {
      _index = (_index + 1) % _entries.length;
      _showAnswer = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final entry = _entries.isEmpty ? null : _entries[_index];

    return Scaffold(
      appBar: AppBar(title: Text('${widget.category.label} Flashcards')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : entry == null
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
                            answerLabel: widget.category.apiName == 'hiragana' ||
                                    widget.category.apiName == 'katakana'
                                ? 'Romaji'
                                : 'Meaning',
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
                              onPressed: _nextCard,
                              child: const Text('Next'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }
}
