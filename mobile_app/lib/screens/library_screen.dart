import 'package:flutter/material.dart';

import '../models/practice_category.dart';
import '../models/study_entry.dart';
import '../models/study_item_progress.dart';
import '../services/api_service.dart';
import '../services/progress_service.dart';

class LibraryScreen extends StatefulWidget {
  final String username;
  final ApiService api;
  final ProgressService progress;

  const LibraryScreen({
    super.key,
    required this.username,
    required this.api,
    required this.progress,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  CategoryGroup _selectedGroup = CategoryGroup.words;
  String _query = '';
  late Future<List<_LibraryCategoryData>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<_LibraryCategoryData>> _load() async {
    final categories = PracticeCategory.values
        .where((category) => category.group == _selectedGroup)
        .toList();
    final items = <_LibraryCategoryData>[];
    for (final category in categories) {
      final entries = await widget.api.fetchEntries(category);
      final progress = await widget.progress.loadCategoryProgress(
        username: widget.username,
        category: category,
      );
      items.add(
        _LibraryCategoryData(
          category: category,
          entries: entries,
          progress: progress,
        ),
      );
    }
    return items;
  }

  Future<void> _reload() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Analytics')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              children: [
                SegmentedButton<CategoryGroup>(
                  segments: const [
                    ButtonSegment(
                      value: CategoryGroup.words,
                      label: Text('Words'),
                    ),
                    ButtonSegment(
                      value: CategoryGroup.letters,
                      label: Text('Letters'),
                    ),
                  ],
                  selected: {_selectedGroup},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _selectedGroup = selection.first;
                      _future = _load();
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search items',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _query = value.trim().toLowerCase();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<_LibraryCategoryData>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(child: Text('Could not load the item library.'));
                }

                final groups = snapshot.data!;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: groups.map((group) {
                    final filtered = group.entries.where((entry) {
                      if (_query.isEmpty) return true;
                      return entry.primaryJapanese.toLowerCase().contains(_query) ||
                          entry.kana.toLowerCase().contains(_query) ||
                          entry.romaji.toLowerCase().contains(_query) ||
                          entry.meaning.toLowerCase().contains(_query);
                    }).toList();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.category.label,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          ...filtered.map(
                            (entry) {
                              final itemProgress =
                                  group.progress[entry.id] ?? const StudyItemProgress.initial();
                              return Card(
                                child: SwitchListTile(
                                  value: itemProgress.active,
                                  onChanged: (value) async {
                                    await widget.progress.updateItemProgress(
                                      username: widget.username,
                                      category: group.category,
                                      entryId: entry.id,
                                      active: value,
                                    );
                                    await _reload();
                                  },
                                  title: Text(entry.primaryJapanese),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (entry.kana.isNotEmpty &&
                                          entry.kana != entry.primaryJapanese)
                                        Text(entry.kana),
                                      if (entry.romaji.isNotEmpty) Text(entry.romaji),
                                      Text(entry.meaning),
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: itemProgress.mastery / 100,
                                        minHeight: 8,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Mastery ${itemProgress.mastery.toStringAsFixed(0)}% • '
                                        '${itemProgress.correct}/${itemProgress.attempts} correct',
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryCategoryData {
  final PracticeCategory category;
  final List<StudyEntry> entries;
  final Map<int, StudyItemProgress> progress;

  const _LibraryCategoryData({
    required this.category,
    required this.entries,
    required this.progress,
  });
}
