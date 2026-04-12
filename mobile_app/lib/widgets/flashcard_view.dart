import 'package:flutter/material.dart';

import '../models/study_direction.dart';
import '../models/study_entry.dart';

class FlashcardView extends StatelessWidget {
  final StudyEntry entry;
  final bool showAnswer;
  final StudyDirection direction;

  const FlashcardView({
    super.key,
    required this.entry,
    required this.showAnswer,
    required this.direction,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E7C66), Color(0xFF18A07A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            entry.promptFor(direction),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (direction == StudyDirection.japaneseToEnglish &&
              entry.kana.isNotEmpty &&
              entry.kana != entry.primaryText) ...[
            const SizedBox(height: 16),
            Text(
              entry.kana,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            showAnswer
                ? '${direction.answerLanguageLabel}: ${entry.answerFor(direction)}'
                : 'Tap Reveal to see the answer',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          if (entry.subtitleFor(direction).isNotEmpty &&
              entry.subtitleFor(direction) != entry.answerFor(direction)) ...[
            const SizedBox(height: 10),
            Text(
              entry.subtitleFor(direction),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
