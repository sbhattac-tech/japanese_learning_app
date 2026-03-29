import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/app_config.dart';
import '../models/import_candidate.dart';
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

  Future<List<ImportCandidate>> extractImportCandidates(XFile file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.baseUrl}/imports/image/extract'),
    );
    request.fields['target_category'] = 'vocabulary';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        await file.readAsBytes(),
        filename: file.name,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final entries = data['entries'] as List<dynamic>? ?? const [];
    return entries
        .map((item) => ImportCandidate.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<int> saveImportedEntries(List<ImportCandidate> entries) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/imports/image/save');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'entries': entries.map((entry) => entry.toJson()).toList(),
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(_errorMessage(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  String _errorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['detail'] as String? ?? 'Request failed';
    } catch (_) {
      return 'Request failed';
    }
  }
}
