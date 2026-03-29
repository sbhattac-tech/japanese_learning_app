import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/study_entry.dart';

class ApiService {
  const ApiService();

  Future<List<StudyEntry>> fetchVocabulary() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/entries/vocabulary');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load vocabulary');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => StudyEntry.fromVocabularyJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<StudyEntry>> fetchVerbs() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/entries/verbs');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Failed to load verbs');
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => StudyEntry.fromVerbJson(item as Map<String, dynamic>))
        .toList();
  }
}
