import 'package:flutter/material.dart';

import '../models/practice_category.dart';
import '../models/study_direction.dart';
import '../models/study_entry.dart';
import '../models/study_session_result.dart';
import '../services/progress_service.dart';
import '../widgets/session_summary_card.dart';

class TypingScreen extends StatefulWidget {
  final String username;
  final PracticeCategory category;
  final List<StudyEntry> entries;
  final StudyDirection direction;
  final ProgressService progress;

  const TypingScreen({
    super.key,
    required this.username,
    required this.category,
    required this.entries,
    required this.direction,
    required this.progress,
  });

  @override
  State<TypingScreen> createState() => _TypingScreenState();
}

class _TypingScreenState extends State<TypingScreen> {
  final _controller = TextEditingController();
  int _index = 0;
  int _correct = 0;
  int _attempts = 0;
  bool _submitted = false;
  bool _isCorrect = false;
  StudySessionResult? _summary;
  List<StudySessionResult> _history = const [];

  StudyEntry get _entry => widget.entries[_index];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    final correct = _entry.matchesTypedAnswer(widget.direction, _controller.text);
    await widget.progress.updateItemProgress(
      username: widget.username,
      category: widget.category,
      entryId: _entry.id,
      answeredCorrectly: correct,
    );
    setState(() {
      _attempts += 1;
      if (correct) {
        _correct += 1;
      }
      _submitted = true;
      _isCorrect = correct;
    });
  }

  Future<void> _next() async {
    if (_index >= widget.entries.length - 1) {
      final result = StudySessionResult(
        mode: 'typing',
        category: widget.category.apiName,
        totalItems: widget.entries.length,
        attempts: _attempts,
        correctOnFirstTry: _correct,
        scorePercent: widget.entries.isEmpty ? 0 : ((_correct / widget.entries.length) * 100).round(),
        completedAt: DateTime.now(),
      );
      await widget.progress.recordSession(widget.username, result);
      final history = await widget.progress.loadHistoryFor(
        username: widget.username,
        mode: 'typing',
        category: widget.category.apiName,
      );
      if (!mounted) return;
      setState(() {
        _summary = result;
        _history = history;
      });
      return;
    }

    setState(() {
      _index += 1;
      _controller.clear();
      _submitted = false;
      _isCorrect = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_summary != null) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.category.label} Typing')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: SessionSummaryCard(
            result: _summary!,
            history: _history,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('${widget.category.label} Typing')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item ${_index + 1}/${widget.entries.length}'),
            const SizedBox(height: 16),
            Text(
              widget.category.promptForDirection(widget.direction),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _entry.promptFor(widget.direction),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_entry.subtitleFor(widget.direction).isNotEmpty)
                      Text(_entry.subtitleFor(widget.direction)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              enabled: !_submitted,
              decoration: InputDecoration(
                labelText: 'Type the ${widget.direction.answerLanguageLabel} answer',
              ),
            ),
            const SizedBox(height: 16),
            if (_submitted)
              Card(
                color: _isCorrect
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _isCorrect
                        ? 'Correct! ${_entry.answerFor(widget.direction)}'
                        : 'Correct answer: ${_entry.answerFor(widget.direction)}',
                  ),
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitted ? _next : _submit,
                child: Text(_submitted ? 'Next' : 'Check Answer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
