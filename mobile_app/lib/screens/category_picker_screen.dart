import 'package:flutter/material.dart';

import '../models/practice_category.dart';
import '../widgets/section_card.dart';
import '../widgets/study_header.dart';

class CategoryPickerScreen extends StatelessWidget {
  final String modeTitle;
  final String modeDescription;
  final ValueChanged<PracticeCategory> onSelectCategory;

  const CategoryPickerScreen({
    super.key,
    required this.modeTitle,
    required this.modeDescription,
    required this.onSelectCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(modeTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            StudyHeader(
              title: 'Choose a category',
              subtitle: modeDescription,
            ),
            const SizedBox(height: 24),
            ...PracticeCategory.values.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SectionCard(
                  title: category.label,
                  description: category.description,
                  icon: category.icon,
                  onTap: () => onSelectCategory(category),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
