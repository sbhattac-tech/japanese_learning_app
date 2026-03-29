import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../widgets/section_card.dart';
import '../widgets/study_header.dart';
import 'flashcards_screen.dart';
import 'matching_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const api = ApiService();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const StudyHeader(
              title: 'Japanese Learning',
              subtitle: 'Study vocabulary and verbs with fast practice modes.',
            ),
            const SizedBox(height: 24),
            SectionCard(
              title: 'Flashcards',
              description: 'Flip through entries and reveal meanings one by one.',
              icon: Icons.style_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FlashcardsScreen(api: api),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Quiz',
              description: 'Answer multiple choice questions from live API data.',
              icon: Icons.quiz_outlined,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const QuizScreen(api: api),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Matching',
              description: 'Match Japanese words with their meanings in pairs.',
              icon: Icons.grid_view_rounded,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const MatchingScreen(api: api),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Tip: for the Android emulator, the app is configured to use http://10.0.2.2:8000 to reach your FastAPI server running on the same computer.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
