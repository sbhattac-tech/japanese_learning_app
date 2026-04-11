import 'dart:collection';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../models/import_candidate.dart';

class ImageTextImportService {
  final TextRecognizer _latinRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final TextRecognizer _japaneseRecognizer = TextRecognizer(script: TextRecognitionScript.japanese);

  Future<List<ImportCandidate>> extractCandidates(XFile file) async {
    final image = InputImage.fromFilePath(file.path);
    final latinResult = await _latinRecognizer.processImage(image);
    final japaneseResult = await _japaneseRecognizer.processImage(image);

    final orderedTexts = LinkedHashSet<String>();
    orderedTexts.addAll(_extractTokens(latinResult));
    orderedTexts.addAll(_extractTokens(japaneseResult));

    return orderedTexts
        .where((text) => text.trim().isNotEmpty)
        .map(_buildCandidate)
        .toList();
  }

  List<String> _extractTokens(RecognizedText result) {
    final tokens = <String>[];

    for (final block in result.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isEmpty) continue;

        if (_looksLatinOnly(text)) {
          tokens.addAll(
            text
                .split(RegExp(r'\s+'))
                .map((token) => token.trim())
                .where((token) => token.isNotEmpty),
          );
        } else {
          tokens.add(text);
        }
      }
    }

    return tokens;
  }

  ImportCandidate _buildCandidate(String sourceText) {
    final detectedType = _detectType(sourceText);

    switch (detectedType) {
      case 'english':
        return ImportCandidate(
          sourceText: sourceText,
          detectedType: detectedType,
          romaji: '',
          kana: '',
          meaning: sourceText,
          category: 'imported',
        );
      case 'romaji':
        return ImportCandidate(
          sourceText: sourceText,
          detectedType: detectedType,
          romaji: sourceText,
          kana: '',
          meaning: '',
          category: 'imported',
        );
      default:
        return ImportCandidate(
          sourceText: sourceText,
          detectedType: detectedType,
          romaji: '',
          kana: sourceText,
          meaning: '',
          category: 'imported',
        );
    }
  }

  String _detectType(String value) {
    final text = value.trim();
    final hasKanji = RegExp(r'[\u4E00-\u9FFF]').hasMatch(text);
    final hasHiragana = RegExp(r'[\u3040-\u309F]').hasMatch(text);
    final hasKatakana = RegExp(r'[\u30A0-\u30FF]').hasMatch(text);
    final hasLatin = RegExp(r'[A-Za-z]').hasMatch(text);

    if (hasKanji && !hasHiragana && !hasKatakana) return 'kanji';
    if (hasHiragana && !hasKanji && !hasKatakana) return 'hiragana';
    if (hasKatakana && !hasKanji && !hasHiragana) return 'katakana';
    if (hasKanji || hasHiragana || hasKatakana) return 'mixed_japanese';

    if (hasLatin) {
      return _looksLikeRomaji(text) ? 'romaji' : 'english';
    }

    return 'unknown';
  }

  bool _looksLatinOnly(String text) {
    return RegExp(r"^[A-Za-z' -]+$").hasMatch(text);
  }

  bool _looksLikeRomaji(String text) {
    final normalized = text.toLowerCase().replaceAll(RegExp(r"[^a-z]"), '');
    if (normalized.isEmpty) return false;

    const commonEnglishWords = {
      'the',
      'and',
      'with',
      'from',
      'this',
      'that',
      'your',
      'hello',
      'name',
      'please',
      'english',
      'word',
      'study',
      'school',
      'teacher',
      'student',
    };
    if (commonEnglishWords.contains(normalized)) {
      return false;
    }

    return RegExp(
      r'^(kya|kyu|kyo|sha|shu|sho|cha|chu|cho|nya|nyu|nyo|hya|hyu|hyo|mya|myu|myo|rya|ryu|ryo|gya|gyu|gyo|ja|ju|jo|bya|byu|byo|pya|pyu|pyo|tsu|shi|chi|fu|[bcdfghjklmnpqrstvwxyz]?y?[aeiou]|n)+$',
    ).hasMatch(normalized);
  }

  Future<void> dispose() async {
    await _latinRecognizer.close();
    await _japaneseRecognizer.close();
  }
}
