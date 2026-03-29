import 'package:flutter/material.dart';

import '../models/practice_category.dart';
import '../services/api_service.dart';
import '../widgets/section_card.dart';
import '../widgets/study_header.dart';
import 'category_picker_screen.dart';
import 'flashcards_screen.dart';
import 'matching_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openCategoryPicker(
    BuildContext context, {
    required String modeTitle,
    required String modeDescription,
    required Widget Function(BuildContext, ApiService, PracticeCategory) builder,
  }) {
    const api = ApiService();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryPickerScreen(
          modeTitle: modeTitle,
          modeDescription: modeDescription,
          onSelectCategory: (category) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => builder(context, api, category),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const StudyHeader(
              title: 'Japanese Learning',
              subtitle: 'Choose a mode, then pick what you want to practice.',
            ),
            const SizedBox(height: 24),
            SectionCard(
              title: 'Flashcards',
              description: 'Flip through entries and reveal meanings one by one.',
              icon: Icons.style_outlined,
              onTap: () {
                _openCategoryPicker(
                  context,
                  modeTitle: 'Flashcards',
                  modeDescription: 'Pick a topic to study with quick swipe-free cards.',
                  builder: (_, api, category) => FlashcardsScreen(
                    api: api,
                    category: category,
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
                _openCategoryPicker(
                  context,
                  modeTitle: 'Quiz',
                  modeDescription: 'Pick a topic and answer multiple choice questions.',
                  builder: (_, api, category) => QuizScreen(
                    api: api,
                    category: category,
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
                _openCategoryPicker(
                  context,
                  modeTitle: 'Matching',
                  modeDescription: 'Pick a topic and pair the Japanese side with the answer side.',
                  builder: (_, api, category) => MatchingScreen(
                    api: api,
                    category: category,
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
