import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/practice_category.dart';
import '../models/study_entry.dart';

class ApiService {
  const ApiService();

  Future<List<StudyEntry>> fetchEntries(PracticeCategory category) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/entries/${category.apiName}');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load ${category.label.toLowerCase()}');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .asMap()
        .entries
        .map(
          (entry) => StudyEntry.fromCategoryJson(
            category.apiName,
            entry.value as Map<String, dynamic>,
            fallbackId: entry.key + 1,
          ),
        )
        .toList();
  }
}
