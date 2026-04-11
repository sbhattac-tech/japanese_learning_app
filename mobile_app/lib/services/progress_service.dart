import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/study_session_result.dart';

class ProgressService {
  static const _storageKey = 'study_session_results';

  Future<void> recordSession(StudySessionResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await loadHistory();
    history.insert(0, result);
    final trimmed = history.take(50).map((item) => item.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(trimmed));
  }

  Future<List<StudySessionResult>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final data = jsonDecode(raw) as List<dynamic>;
    return data
        .map((item) => StudySessionResult.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<StudySessionResult>> loadHistoryFor({
    required String mode,
    required String category,
  }) async {
    final history = await loadHistory();
    return history
        .where((item) => item.mode == mode && item.category == category)
        .toList();
  }
}
