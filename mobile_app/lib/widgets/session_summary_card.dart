import 'package:flutter/material.dart';

import '../models/study_session_result.dart';

class SessionSummaryCard extends StatelessWidget {
  final StudySessionResult result;
  final List<StudySessionResult> history;

  const SessionSummaryCard({
    super.key,
    required this.result,
    required this.history,
  });

  @override
  Widget build(BuildContext context) {
    final scores = history.map((item) => item.scorePercent).toList();
    final average = scores.isEmpty
        ? result.scorePercent.toDouble()
        : scores.reduce((a, b) => a + b) / scores.length;
    final best = scores.isEmpty ? result.scorePercent : scores.reduce((a, b) => a > b ? a : b);
    final previous = history.length > 1 ? history[1].scorePercent : null;
    final trend = previous == null ? null : result.scorePercent - previous;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Complete',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text('Score: ${result.scorePercent}%'),
            Text('First-try correct: ${result.correctOnFirstTry}/${result.totalItems}'),
            Text('Attempts: ${result.attempts}'),
            const SizedBox(height: 12),
            Text('Average score: ${average.toStringAsFixed(1)}%'),
            Text('Best score: $best%'),
            Text('Sessions tracked: ${history.length}'),
            if (trend != null)
              Text(
                trend >= 0
                    ? 'Trend vs previous: +$trend%'
                    : 'Trend vs previous: $trend%',
              ),
          ],
        ),
      ),
    );
  }
}
