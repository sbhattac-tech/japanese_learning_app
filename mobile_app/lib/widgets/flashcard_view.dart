import 'package:flutter/material.dart';

import '../models/study_entry.dart';

class FlashcardView extends StatelessWidget {
  final StudyEntry entry;
  final bool showAnswer;
  final String answerLabel;

  const FlashcardView({
    super.key,
    required this.entry,
    required this.showAnswer,
    required this.answerLabel,
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
            entry.primaryJapanese,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (entry.kana.isNotEmpty && entry.kana != entry.primaryJapanese) ...[
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
            showAnswer ? '$answerLabel: ${entry.meaning}' : 'Tap reveal to see the answer',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          if (entry.romaji.isNotEmpty && entry.romaji != entry.meaning) ...[
            const SizedBox(height: 10),
            Text(
              entry.romaji,
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
