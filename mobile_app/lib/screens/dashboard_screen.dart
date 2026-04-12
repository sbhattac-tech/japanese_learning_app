import 'package:flutter/material.dart';

import '../models/category_analytics.dart';
import '../models/practice_category.dart';
import '../models/study_entry.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/progress_service.dart';
import '../widgets/study_header.dart';
import 'landing_screen.dart';
import 'library_screen.dart';
import 'set_selection_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String username;

  const DashboardScreen({
    super.key,
    required this.username,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const _api = ApiService();
  static final _auth = AuthService();
  final _progress = ProgressService();

  late Future<List<_DashboardCategoryData>> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  Future<List<_DashboardCategoryData>> _loadDashboard() async {
    final items = <_DashboardCategoryData>[];
    for (final category in PracticeCategory.values) {
      final entries = await _api.fetchEntries(category);
      final analytics = await _progress.buildAnalytics(
        username: widget.username,
        category: category,
        entries: entries,
      );
      items.add(
        _DashboardCategoryData(
          category: category,
          entries: entries,
          analytics: analytics,
        ),
      );
    }
    return items;
  }

  Future<void> _refresh() async {
    final next = _loadDashboard();
    setState(() {
      _dashboardFuture = next;
    });
    await next;
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tango App'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<List<_DashboardCategoryData>>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Could not load your learning dashboard.'));
          }

          final data = snapshot.data!;
          final words = data.where((item) => item.category.isWordCategory).toList();
          final letters = data.where((item) => item.category.isLetterCategory).toList();
          final totalItems = data.fold<int>(0, (sum, item) => sum + item.analytics.totalItems);
          final mastered = data.fold<int>(0, (sum, item) => sum + item.analytics.masteredItems);
          final active = data.fold<int>(0, (sum, item) => sum + item.analytics.activeItems);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                StudyHeader(
                  title: 'Konnichiwa, ${widget.username}',
                  subtitle: 'Track progress across words and letters, then study one set at a time.',
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Tracked items',
                        value: '$totalItems',
                        helper: 'Across every category',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Mastered',
                        value: '$mastered',
                        helper: '80% mastery or higher',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Active',
                        value: '$active',
                        helper: 'Included in exercises',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LibraryScreen(
                            username: widget.username,
                            api: _api,
                            progress: _progress,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('Open Learning Analytics'),
                  ),
                ),
                const SizedBox(height: 24),
                _CategorySection(
                  title: 'Words',
                  subtitle: 'Vocabulary, verbs, and adjectives with editable online study data.',
                  items: words,
                  username: widget.username,
                ),
                const SizedBox(height: 24),
                _CategorySection(
                  title: 'Letters',
                  subtitle: 'Hiragana, katakana, and kanji bundled inside the app for offline study.',
                  items: letters,
                  username: widget.username,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_DashboardCategoryData> items;
  final String username;

  const _CategorySection({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(subtitle),
        const SizedBox(height: 16),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SetSelectionScreen(
                        username: username,
                        category: item.category,
                        entries: item.entries,
                        progress: ProgressService(),
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(item.category.icon),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.category.label,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Text('${item.analytics.totalSets} sets'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: item.analytics.totalItems == 0
                            ? 0
                            : item.analytics.masteredItems / item.analytics.totalItems,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${item.analytics.masteredItems}/${item.analytics.totalItems} mastered • '
                        '${item.analytics.activeItems} active • '
                        '${item.analytics.averageMastery.toStringAsFixed(0)}% average mastery',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String helper;

  const _StatCard({
    required this.label,
    required this.value,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(helper, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _DashboardCategoryData {
  final PracticeCategory category;
  final List<StudyEntry> entries;
  final CategoryAnalytics analytics;

  const _DashboardCategoryData({
    required this.category,
    required this.entries,
    required this.analytics,
  });
}
