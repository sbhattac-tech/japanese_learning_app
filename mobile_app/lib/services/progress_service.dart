import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/category_analytics.dart';
import '../models/practice_category.dart';
import '../models/study_entry.dart';
import '../models/study_item_progress.dart';
import '../models/study_set.dart';
import '../models/study_session_result.dart';

class ProgressService {
  static const _historyPrefix = 'study_session_results';
  static const _itemProgressPrefix = 'study_item_progress';

  Future<void> recordSession(String username, StudySessionResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await loadHistory(username);
    history.insert(0, result);
    final trimmed = history.take(50).map((item) => item.toJson()).toList();
    await prefs.setString(_historyKey(username), jsonEncode(trimmed));
  }

  Future<List<StudySessionResult>> loadHistory(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey(username));
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final data = jsonDecode(raw) as List<dynamic>;
    return data
        .map((item) => StudySessionResult.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<StudySessionResult>> loadHistoryFor({
    required String username,
    required String mode,
    required String category,
  }) async {
    final history = await loadHistory(username);
    return history
        .where((item) => item.mode == mode && item.category == category)
        .toList();
  }

  Future<Map<int, StudyItemProgress>> loadCategoryProgress({
    required String username,
    required PracticeCategory category,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_itemProgressKey(username, category.apiName));
    if (raw == null || raw.isEmpty) {
      return {};
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(
        int.parse(key),
        StudyItemProgress.fromJson(value as Map<String, dynamic>),
      ),
    );
  }

  Future<void> updateItemProgress({
    required String username,
    required PracticeCategory category,
    required int entryId,
    bool? active,
    bool? answeredCorrectly,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final progress = await loadCategoryProgress(username: username, category: category);
    final current = progress[entryId] ?? const StudyItemProgress.initial();
    final updated = current.copyWith(
      active: active ?? current.active,
      attempts: answeredCorrectly == null ? current.attempts : current.attempts + 1,
      correct: answeredCorrectly == true ? current.correct + 1 : current.correct,
      streak: answeredCorrectly == null
          ? current.streak
          : answeredCorrectly
              ? current.streak + 1
              : 0,
      lastReviewedAt: answeredCorrectly == null ? current.lastReviewedAt : DateTime.now(),
    );
    progress[entryId] = updated;
    await prefs.setString(
      _itemProgressKey(username, category.apiName),
      jsonEncode(
        progress.map((key, value) => MapEntry(key.toString(), value.toJson())),
      ),
    );
  }

  Future<CategoryAnalytics> buildAnalytics({
    required String username,
    required PracticeCategory category,
    required List<StudyEntry> entries,
  }) async {
    final progress = await loadCategoryProgress(username: username, category: category);
    var activeItems = 0;
    var masteredItems = 0;
    var studiedItems = 0;
    var masteryTotal = 0.0;

    for (final entry in entries) {
      final itemProgress = progress[entry.id] ?? const StudyItemProgress.initial();
      if (itemProgress.active) {
        activeItems += 1;
      }
      if (itemProgress.attempts > 0) {
        studiedItems += 1;
      }
      if (itemProgress.mastery >= 80) {
        masteredItems += 1;
      }
      masteryTotal += itemProgress.mastery;
    }

    return CategoryAnalytics(
      totalItems: entries.length,
      activeItems: activeItems,
      masteredItems: masteredItems,
      averageMastery: entries.isEmpty ? 0 : masteryTotal / entries.length,
      studiedItems: studiedItems,
      totalSets: buildStudySets(entries).length,
    );
  }

  List<StudySet> buildStudySets(List<StudyEntry> entries) {
    final sets = <StudySet>[];
    for (var start = 0; start < entries.length; start += 20) {
      final index = (start ~/ 20) + 1;
      final chunk = entries.skip(start).take(20).toList();
      sets.add(
        StudySet(
          index: index,
          label: 'Set $index',
          entries: chunk,
        ),
      );
    }
    return sets;
  }

  String _historyKey(String username) => '$_historyPrefix:$username';

  String _itemProgressKey(String username, String category) => '$_itemProgressPrefix:$username:$category';
}
