import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/import_candidate.dart';
import '../services/api_service.dart';

class ImageImportScreen extends StatefulWidget {
  final ApiService api;

  const ImageImportScreen({
    super.key,
    required this.api,
  });

  @override
  State<ImageImportScreen> createState() => _ImageImportScreenState();
}

class _ImageImportScreenState extends State<ImageImportScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _setNameController = TextEditingController();

  XFile? _selectedFile;
  Uint8List? _previewBytes;
  List<_ImportDraft> _drafts = const [];
  List<String> _availableSets = const [];
  bool _loadingSets = true;
  bool _extracting = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    try {
      final sets = await widget.api.fetchImportSets();
      if (!mounted) return;
      setState(() {
        _availableSets = sets;
        _loadingSets = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingSets = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (file == null) return;

    final previewBytes = await file.readAsBytes();
    if (!mounted) return;

    setState(() {
      _selectedFile = file;
      _previewBytes = previewBytes;
      _disposeDrafts();
      _drafts = const [];
    });
  }

  Future<void> _extractWords() async {
    final file = _selectedFile;
    if (file == null) return;

    setState(() {
      _extracting = true;
    });

    try {
      final result = await widget.api.extractImportCandidates(file);
      if (!mounted) return;

      final drafts = result.entries.map(_ImportDraft.fromCandidate).toList();
      setState(() {
        _disposeDrafts();
        _drafts = drafts;
        _availableSets = result.availableSets;
        _extracting = false;
      });
      if (drafts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No study words were found. Try a clearer photo with larger text and good lighting.',
            ),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _extracting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _saveEntries() async {
    final setName = _setNameController.text.trim();
    if (setName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose an existing set or enter a new set name.')),
      );
      return;
    }

    final entries = _drafts
        .map((draft) => draft.toCandidate(setName: setName))
        .where((entry) => _isReadyToSave(entry))
        .toList();

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fill in Japanese text, romaji, and meaning for at least one entry.'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final count = await widget.api.saveImportedEntries(entries, setName: setName);
      if (!mounted) return;
      List<String> refreshedSets;
      try {
        refreshedSets = await widget.api.fetchImportSets();
      } catch (_) {
        refreshedSets = [..._availableSets];
        if (!refreshedSets.contains(setName)) {
          refreshedSets.add(setName);
          refreshedSets.sort((a, b) => a.compareTo(b));
        }
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved $count entries to "$setName".')),
      );
      setState(() {
        _saving = false;
        _selectedFile = null;
        _previewBytes = null;
        _disposeDrafts();
        _drafts = const [];
        _availableSets = refreshedSets;
        _setNameController.text = setName;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  bool _isReadyToSave(ImportCandidate entry) {
    final hasJapanese = entry.japaneseText.trim().isNotEmpty ||
        entry.hiragana.trim().isNotEmpty ||
        entry.katakana.trim().isNotEmpty ||
        entry.kanji.trim().isNotEmpty;
    return hasJapanese && entry.meaning.trim().isNotEmpty && entry.romaji.trim().isNotEmpty;
  }

  void _removeDraft(_ImportDraft draft) {
    setState(() {
      draft.dispose();
      _drafts = _drafts.where((item) => item != draft).toList();
    });
  }

  void _disposeDrafts() {
    for (final draft in _drafts) {
      draft.dispose();
    }
  }

  @override
  void dispose() {
    _setNameController.dispose();
    _disposeDrafts();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import From Image')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add study words from notes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take a photo of handwritten or typed Japanese and English notes. Tango will extract the words, look up translations and Japanese forms, then let you verify everything before saving.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _extracting || _saving
                              ? null
                              : () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _extracting || _saving
                              ? null
                              : () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Upload'),
                        ),
                      ),
                    ],
                  ),
                  if (_previewBytes != null) ...[
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.memory(
                        _previewBytes!,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _extracting || _saving ? null : _extractWords,
                        icon: _extracting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.document_scanner_outlined),
                        label: Text(_extracting ? 'Extracting...' : 'Extract And Review'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_drafts.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Review before saving',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Destination set',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _setNameController,
                      decoration: const InputDecoration(
                        labelText: 'Existing set or new set name',
                        hintText: 'Examples: Lesson 4 Notes, Cafe Vocabulary',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (_loadingSets) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ] else if (_availableSets.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableSets
                            .map(
                              (set) => ActionChip(
                                label: Text(set),
                                onPressed: () {
                                  _setNameController.text = set;
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ..._drafts.map(
              (draft) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ImportDraftCard(
                  draft: draft,
                  onRemove: () => _removeDraft(draft),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveEntries,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Saving...' : 'Save Reviewed Entries'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImportDraft {
  final TextEditingController sourceTextController;
  final TextEditingController sourceLanguageController;
  final TextEditingController japaneseTextController;
  final TextEditingController hiraganaController;
  final TextEditingController katakanaController;
  final TextEditingController kanjiController;
  final TextEditingController romajiController;
  final TextEditingController meaningController;
  final TextEditingController partOfSpeechController;
  final TextEditingController categoryController;
  final String matchedCategory;

  _ImportDraft({
    required this.sourceTextController,
    required this.sourceLanguageController,
    required this.japaneseTextController,
    required this.hiraganaController,
    required this.katakanaController,
    required this.kanjiController,
    required this.romajiController,
    required this.meaningController,
    required this.partOfSpeechController,
    required this.categoryController,
    required this.matchedCategory,
  });

  factory _ImportDraft.fromCandidate(ImportCandidate candidate) {
    return _ImportDraft(
      sourceTextController: TextEditingController(text: candidate.sourceText),
      sourceLanguageController: TextEditingController(text: candidate.sourceLanguage),
      japaneseTextController: TextEditingController(text: candidate.japaneseText),
      hiraganaController: TextEditingController(text: candidate.hiragana),
      katakanaController: TextEditingController(text: candidate.katakana),
      kanjiController: TextEditingController(text: candidate.kanji),
      romajiController: TextEditingController(text: candidate.romaji),
      meaningController: TextEditingController(text: candidate.meaning),
      partOfSpeechController: TextEditingController(text: candidate.partOfSpeech),
      categoryController: TextEditingController(text: candidate.category),
      matchedCategory: candidate.matchedCategory,
    );
  }

  ImportCandidate toCandidate({required String setName}) {
    return ImportCandidate(
      sourceText: sourceTextController.text.trim(),
      sourceLanguage: sourceLanguageController.text.trim(),
      normalizedText: '',
      romaji: romajiController.text.trim(),
      japaneseText: japaneseTextController.text.trim(),
      hiragana: hiraganaController.text.trim(),
      katakana: katakanaController.text.trim(),
      kanji: kanjiController.text.trim(),
      meaning: meaningController.text.trim(),
      partOfSpeech: partOfSpeechController.text.trim(),
      category: categoryController.text.trim(),
      matchedCategory: matchedCategory,
      setName: setName,
    );
  }

  void dispose() {
    sourceTextController.dispose();
    sourceLanguageController.dispose();
    japaneseTextController.dispose();
    hiraganaController.dispose();
    katakanaController.dispose();
    kanjiController.dispose();
    romajiController.dispose();
    meaningController.dispose();
    partOfSpeechController.dispose();
    categoryController.dispose();
  }
}

class _ImportDraftCard extends StatelessWidget {
  final _ImportDraft draft;
  final VoidCallback onRemove;

  const _ImportDraftCard({
    required this.draft,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    draft.sourceTextController.text.trim().isEmpty
                        ? 'Imported word'
                        : draft.sourceTextController.text.trim(),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                  tooltip: 'Remove entry',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaPill(label: 'Source: ${draft.sourceLanguageController.text.trim().isEmpty ? 'unknown' : draft.sourceLanguageController.text.trim()}'),
                if (draft.matchedCategory.trim().isNotEmpty)
                  _MetaPill(label: 'Matched: ${draft.matchedCategory.trim()}'),
              ],
            ),
            const SizedBox(height: 12),
            _draftField(
              controller: draft.sourceTextController,
              label: 'Detected text',
            ),
            const SizedBox(height: 12),
            _draftField(
              controller: draft.japaneseTextController,
              label: 'Japanese text',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _draftField(
                    controller: draft.hiraganaController,
                    label: 'Hiragana',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _draftField(
                    controller: draft.katakanaController,
                    label: 'Katakana',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _draftField(
              controller: draft.kanjiController,
              label: 'Kanji',
            ),
            const SizedBox(height: 12),
            _draftField(
              controller: draft.romajiController,
              label: 'Romaji',
            ),
            const SizedBox(height: 12),
            _draftField(
              controller: draft.meaningController,
              label: 'English meaning / translation',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _draftField(
                    controller: draft.partOfSpeechController,
                    label: 'Word type',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _draftField(
                    controller: draft.categoryController,
                    label: 'Topic category',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _draftField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final String label;

  const _MetaPill({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label),
    );
  }
}
