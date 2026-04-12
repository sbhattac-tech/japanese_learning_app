import 'package:flutter/material.dart';

import '../models/practice_category.dart';
import '../models/study_entry.dart';
import '../services/api_service.dart';

class AllWordsScreen extends StatefulWidget {
  final ApiService api;

  const AllWordsScreen({
    super.key,
    required this.api,
  });

  @override
  State<AllWordsScreen> createState() => _AllWordsScreenState();
}

class _AllWordsScreenState extends State<AllWordsScreen> {
  PracticeCategory _selectedCategory = PracticeCategory.japaneseVocabulary;
  List<StudyEntry> _entries = const [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _loading = true;
    });

    try {
      final entries = await widget.api.fetchEntries(_selectedCategory);
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
          content: Text('Could not load ${_selectedCategory.label.toLowerCase()} entries.'),
        ),
      );
    }
  }

  List<StudyEntry> get _filteredEntries {
    if (_query.trim().isEmpty) {
      return _entries;
    }

    final needle = _query.trim().toLowerCase();
    return _entries.where((entry) {
      return entry.primaryText.toLowerCase().contains(needle) ||
          entry.kana.toLowerCase().contains(needle) ||
          entry.romaji.toLowerCase().contains(needle) ||
          entry.meaning.toLowerCase().contains(needle) ||
          (entry.setName?.toLowerCase().contains(needle) ?? false);
    }).toList();
  }

  void _changeCategory(PracticeCategory category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _query = '';
    });
    _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEntries = _filteredEntries;

    return Scaffold(
      appBar: AppBar(title: const Text('All Words')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Browse your study content',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Switch categories and search through Japanese and Czech study content in one place.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: PracticeCategory.values
                    .map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category.label),
                          selected: _selectedCategory == category,
                          onSelected: (_) => _changeCategory(category),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search words, readings, meanings, or set names',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  _selectedCategory.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text('${filteredEntries.length} items'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredEntries.isEmpty
                      ? const Center(
                          child: Text('No entries found for this category or search.'),
                        )
                      : ListView.separated(
                          itemCount: filteredEntries.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final entry = filteredEntries[index];
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.primaryText,
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    if (entry.kana.isNotEmpty && entry.kana != entry.primaryText) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        entry.kana,
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                    if (entry.romaji.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        entry.romaji,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              color: const Color(0xFF51625C),
                                            ),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    Text(
                                      entry.meaning,
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                    if (entry.setName != null && entry.setName!.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        entry.setName!,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: const Color(0xFF51625C),
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
