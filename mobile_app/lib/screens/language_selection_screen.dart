import 'package:flutter/material.dart';

import '../models/study_language.dart';
import 'dashboard_screen.dart';

class LanguageSelectionScreen extends StatelessWidget {
  final String username;

  const LanguageSelectionScreen({
    super.key,
    required this.username,
  });

  void _openDashboard(BuildContext context, StudyLanguage language) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => DashboardScreen(
          username: username,
          learningLanguage: language,
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Language')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pick what you want to study today',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a language first, then Cognita will take you to the matching dashboard.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 28),
              _LanguageCard(
                language: StudyLanguage.japanese,
                description: 'Vocabulary, verbs, adjectives, kana, kanji, and image import.',
                icon: Icons.auto_stories_outlined,
                onTap: () => _openDashboard(context, StudyLanguage.japanese),
              ),
              const SizedBox(height: 16),
              _LanguageCard(
                language: StudyLanguage.czech,
                description: 'Vocabulary, adjectives, and verbs organized into named lesson sets.',
                icon: Icons.travel_explore_outlined,
                onTap: () => _openDashboard(context, StudyLanguage.czech),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final StudyLanguage language;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.language,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F2EC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: const Color(0xFF0E7C66)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.label,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(description),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
