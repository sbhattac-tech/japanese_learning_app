import 'package:flutter/material.dart';

import '../models/practice_category.dart';
import '../services/api_service.dart';

class ManualEntryScreen extends StatefulWidget {
  final ApiService api;
  final PracticeCategory category;

  const ManualEntryScreen({
    super.key,
    required this.api,
    required this.category,
  });

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _romajiController = TextEditingController();
  final _kanaController = TextEditingController();
  final _meaningController = TextEditingController();
  final _categoryController = TextEditingController(text: 'general');
  final _setNameController = TextEditingController();
  final _englishController = TextEditingController();
  final _czechController = TextEditingController();
  final _partOfSpeechController = TextEditingController(text: 'vocabulary');
  final _adjectiveTypeController = TextEditingController(text: 'i');
  final _kanjiController = TextEditingController();
  final _hiraganaController = TextEditingController();
  final _verbTypeController = TextEditingController(text: 'ru-verb');
  final _verbGroupController = TextEditingController(text: 'ichidan');
  final _masuController = TextEditingController();
  final _masuPastController = TextEditingController();
  final _teController = TextEditingController();
  final _pastController = TextEditingController();
  final _naiController = TextEditingController();
  final _naiPastController = TextEditingController();
  final _teiruController = TextEditingController();
  final _requestController = TextEditingController();
  final _permissionController = TextEditingController();
  final _kanjiMeaningsController = TextEditingController();
  final _onyomiController = TextEditingController();
  final _kunyomiController = TextEditingController();
  final _notesController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _romajiController.dispose();
    _kanaController.dispose();
    _meaningController.dispose();
    _categoryController.dispose();
    _setNameController.dispose();
    _englishController.dispose();
    _czechController.dispose();
    _partOfSpeechController.dispose();
    _adjectiveTypeController.dispose();
    _kanjiController.dispose();
    _hiraganaController.dispose();
    _verbTypeController.dispose();
    _verbGroupController.dispose();
    _masuController.dispose();
    _masuPastController.dispose();
    _teController.dispose();
    _pastController.dispose();
    _naiController.dispose();
    _naiPastController.dispose();
    _teiruController.dispose();
    _requestController.dispose();
    _permissionController.dispose();
    _kanjiMeaningsController.dispose();
    _onyomiController.dispose();
    _kunyomiController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    try {
      await widget.api.createEntry(widget.category, _buildPayload());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.category.label} entry saved.')),
      );
      _resetForm();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Map<String, dynamic> _buildPayload() {
    switch (widget.category.apiName) {
      case 'japanese_vocabulary':
        return {
          'romaji': _romajiController.text.trim(),
          'kana': _kanaController.text.trim(),
          'meaning': _meaningController.text.trim(),
          'category': _categoryController.text.trim(),
        };
      case 'japanese_adjectives':
        return {
          'romaji': _romajiController.text.trim(),
          'kana': _kanaController.text.trim(),
          'type': _adjectiveTypeController.text.trim(),
          'meaning': _meaningController.text.trim(),
        };
      case 'czech_vocabulary':
      case 'czech_adjectives':
      case 'czech_verbs':
        return {
          'english': _englishController.text.trim(),
          'czech': _czechController.text.trim(),
          'notes': _notesController.text.trim(),
          'part_of_speech': _partOfSpeechController.text.trim(),
          'category': _categoryController.text.trim(),
          'set_name': _setNameController.text.trim(),
        };
      case 'japanese_verbs':
        return {
          'romaji': _romajiController.text.trim(),
          'hiragana': _hiraganaController.text.trim(),
          'kanji': _kanjiController.text.trim().isEmpty ? null : _kanjiController.text.trim(),
          'meaning': _meaningController.text.trim(),
          'type': _verbTypeController.text.trim(),
          'group': _verbGroupController.text.trim(),
          'masu': _masuController.text.trim(),
          'masu_past': _masuPastController.text.trim(),
          'te': _teController.text.trim(),
          'past': _pastController.text.trim(),
          'nai': _naiController.text.trim(),
          'nai_past': _naiPastController.text.trim(),
          'teiru': _teiruController.text.trim(),
          'request': _requestController.text.trim(),
          'permission': _permissionController.text.trim(),
        };
      default:
        throw UnsupportedError('Manual entry is not supported for ${widget.category.apiName}.');
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    for (final controller in [
      _romajiController,
      _kanaController,
      _meaningController,
      _setNameController,
      _englishController,
      _czechController,
      _notesController,
      _kanjiController,
      _hiraganaController,
      _masuController,
      _masuPastController,
      _teController,
      _pastController,
      _naiController,
      _naiPastController,
      _teiruController,
      _requestController,
      _permissionController,
    ]) {
      controller.clear();
    }
    _categoryController.text = 'general';
    _partOfSpeechController.text = 'vocabulary';
    _adjectiveTypeController.text = 'i';
    _verbTypeController.text = 'ru-verb';
    _verbGroupController.text = 'ichidan';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add ${widget.category.label} Entry')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Create a new ${widget.category.label.toLowerCase()} entry',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in the fields below and save the entry to the database.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ..._buildFields(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFields() {
    switch (widget.category.apiName) {
      case 'japanese_vocabulary':
        return [
          _requiredField(_kanaController, 'Kana'),
          _requiredField(_romajiController, 'Romaji'),
          _requiredField(_meaningController, 'Meaning'),
          _requiredField(_categoryController, 'Category'),
        ];
      case 'japanese_adjectives':
        return [
          _requiredField(_kanaController, 'Kana'),
          _requiredField(_romajiController, 'Romaji'),
          _requiredField(_meaningController, 'Meaning'),
          _requiredField(_adjectiveTypeController, 'Adjective type'),
        ];
      case 'czech_vocabulary':
      case 'czech_adjectives':
      case 'czech_verbs':
        return [
          _requiredField(_englishController, 'English'),
          _requiredField(_czechController, 'Czech'),
          _requiredField(_partOfSpeechController, 'Part of speech'),
          _requiredField(_categoryController, 'Category'),
          _textField(_setNameController, 'Set name', required: false),
          _textField(_notesController, 'Notes', required: false),
        ];
      case 'japanese_verbs':
        return [
          _requiredField(_romajiController, 'Romaji'),
          _requiredField(_hiraganaController, 'Hiragana'),
          _textField(_kanjiController, 'Kanji (optional)', required: false),
          _requiredField(_meaningController, 'Meaning'),
          _requiredField(_verbTypeController, 'Verb type'),
          _requiredField(_verbGroupController, 'Verb group'),
          _requiredField(_masuController, 'Masu form'),
          _requiredField(_masuPastController, 'Masu past'),
          _requiredField(_teController, 'Te form'),
          _requiredField(_pastController, 'Past form'),
          _requiredField(_naiController, 'Nai form'),
          _requiredField(_naiPastController, 'Nai past'),
          _requiredField(_teiruController, 'Teiru form'),
          _requiredField(_requestController, 'Request form'),
          _requiredField(_permissionController, 'Permission form'),
        ];
      default:
        return [
          const Text(
            'Manual entry is available for editable vocabulary categories. '
            'Bundled script study data stays offline inside the app.',
          ),
        ];
    }
  }

  Widget _requiredField(TextEditingController controller, String label) {
    return _textField(controller, label);
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter $label';
                }
                return null;
              }
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
