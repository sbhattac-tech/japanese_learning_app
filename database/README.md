# Cognita Learning Database

`cognita_database.json` is the organized master database for Cognita.

It is generated from these source files:

- `czech_vocabulary.json`
- `czech_adjectives.json`
- `czech_verbs.json`
- `verbs.json`
- `adjectives.json`
- `vocabulary.json`
- `demonstrative.json`
- `kangi.json`
- `hiragana.json`
- `katakana.json`

Sections inside the generated file:

- `metadata`: versioning and source tracking
- `stats`: entry counts and quick summaries
- `kana`: hiragana and katakana in one consistent shape
- `kanji`: kanji entries from `kangi.json`
- `grammar.demonstratives`: grouped and flattened ko-so-a-do words
- `lexicon`: Japanese and Czech vocabulary, adjectives, and verbs with normalized field names
- `search_index`: a flattened lookup list for app search or filtering

To rebuild the organized database:

```powershell
python scripts/build_database.py
```
