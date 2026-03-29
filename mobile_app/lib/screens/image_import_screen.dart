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

  XFile? _selectedFile;
  Uint8List? _previewBytes;
  List<_ImportDraft> _drafts = const [];
  bool _extracting = false;
  bool _saving = false;

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
      final entries = await widget.api.extractImportCandidates(file);
      if (!mounted) return;

      setState(() {
        _disposeDrafts();
        _drafts = entries.map(_ImportDraft.fromCandidate).toList();
        _extracting = false;
      });
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
    final entries = _drafts
        .map((draft) => draft.toCandidate())
        .where(
          (entry) =>
              entry.kana.trim().isNotEmpty &&
              entry.meaning.trim().isNotEmpty &&
              entry.romaji.trim().isNotEmpty,
        )
        .toList();

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fill in kana, romaji, and meaning for at least one entry.'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final count = await widget.api.saveImportedEntries(entries);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved $count entries to the vocabulary database.')),
      );
      setState(() {
        _saving = false;
        _selectedFile = null;
        _previewBytes = null;
        _disposeDrafts();
        _drafts = const [];
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
                    'Add vocabulary from a photo',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take a picture or upload one, extract Japanese text, then review the entries before saving them into vocabulary.',
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
                        label: Text(_extracting ? 'Extracting...' : 'Extract Words'),
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
                label: Text(_saving ? 'Saving...' : 'Save To Vocabulary'),
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
  final TextEditingController kanaController;
  final TextEditingController romajiController;
  final TextEditingController meaningController;
  final TextEditingController categoryController;

  _ImportDraft({
    required this.sourceTextController,
    required this.kanaController,
    required this.romajiController,
    required this.meaningController,
    required this.categoryController,
  });

  factory _ImportDraft.fromCandidate(ImportCandidate candidate) {
    return _ImportDraft(
      sourceTextController: TextEditingController(text: candidate.sourceText),
      kanaController: TextEditingController(text: candidate.kana),
      romajiController: TextEditingController(text: candidate.romaji),
      meaningController: TextEditingController(text: candidate.meaning),
      categoryController: TextEditingController(text: candidate.category),
    );
  }

  ImportCandidate toCandidate() {
    return ImportCandidate(
      sourceText: sourceTextController.text,
      kana: kanaController.text,
      romaji: romajiController.text,
      meaning: meaningController.text,
      category: categoryController.text,
    );
  }

  void dispose() {
    sourceTextController.dispose();
    kanaController.dispose();
    romajiController.dispose();
    meaningController.dispose();
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
                    'Detected: ${draft.sourceTextController.text}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                  tooltip: 'Remove entry',
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: draft.kanaController,
              decoration: const InputDecoration(
                labelText: 'Kana or Japanese text',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: draft.romajiController,
              decoration: const InputDecoration(
                labelText: 'Romaji',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: draft.meaningController,
              decoration: const InputDecoration(
                labelText: 'Meaning',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: draft.categoryController,
              decoration: const InputDecoration(
                labelText: 'Vocabulary category',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
