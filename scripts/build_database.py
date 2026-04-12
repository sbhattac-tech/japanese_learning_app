from __future__ import annotations

import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATABASE_DIR = ROOT / "database"
OUTPUT_FILE = DATABASE_DIR / "cognita_database.json"


def load_json(name: str):
    return json.loads((DATABASE_DIR / name).read_text(encoding="utf-8"))


def normalize_japanese_verbs(items: list[dict]) -> list[dict]:
    return [
        {
            "id": item["id"],
            "entry_id": f"japanese-verb-{item['id']}",
            "part_of_speech": "verb",
            "language": "japanese",
            "romaji": item["romaji"],
            "kana": item["hiragana"],
            "kanji": item.get("kanji") or None,
            "meaning": item["meaning"],
            "verb_type": item["type"],
            "verb_group": item["group"],
            "forms": {
                "dictionary": item["hiragana"],
                "masu": item["masu"],
                "masu_past": item["masu_past"],
                "te": item["te"],
                "past": item["past"],
                "nai": item["nai"],
                "nai_past": item["nai_past"],
                "teiru": item["teiru"],
                "request": item["request"],
                "permission": item["permission"],
            },
        }
        for item in items
    ]


def normalize_japanese_adjectives(items: list[dict]) -> list[dict]:
    return [
        {
            "id": item["id"],
            "entry_id": f"japanese-adjective-{item['id']}",
            "part_of_speech": "adjective",
            "language": "japanese",
            "romaji": item["romaji"],
            "kana": item["kana"],
            "meaning": item["meaning"],
            "adjective_type": item["type"],
        }
        for item in items
    ]


def normalize_japanese_vocabulary(items: list[dict]) -> list[dict]:
    return [
        {
            "id": item["id"],
            "entry_id": f"japanese-vocabulary-{item['id']}",
            "part_of_speech": item.get("part_of_speech", "vocabulary"),
            "language": "japanese",
            "romaji": item["romaji"],
            "kana": item["kana"],
            "kanji": item.get("kanji"),
            "meaning": item["meaning"],
            "category": item["category"],
            "set_name": item.get("set_name", ""),
        }
        for item in items
    ]


def normalize_czech_entries(items: list[dict], *, default_part_of_speech: str) -> list[dict]:
    return [
        {
            "id": item["id"],
            "entry_id": f"czech-{default_part_of_speech}-{item['id']}",
            "part_of_speech": item.get("part_of_speech", default_part_of_speech),
            "language": "czech",
            "english": item["english"],
            "czech": item["czech"],
            "notes": item.get("notes", ""),
            "category": item.get("category", "general"),
            "set_name": item.get("set_name", ""),
        }
        for item in items
    ]


def normalize_demonstratives(data: dict) -> dict:
    groups = []
    flat_words = []

    for group in data["groups"]:
        normalized_words = []
        for word in group["words"]:
            normalized_word = {
                "id": word["id"],
                "entry_id": f"demonstrative-{word['id']}",
                "kana": word["jp"],
                "romaji": word["romaji"],
                "meaning": word["en"],
                "prefix": word["prefix"],
                "group_type": group["type"],
            }
            normalized_words.append(normalized_word)
            flat_words.append(normalized_word)

        groups.append(
            {
                "type": group["type"],
                "description": group["description"],
                "words": normalized_words,
            }
        )

    return {
        "category": data["category"],
        "description": data["description"],
        "prefix_meanings": data["prefix_meanings"],
        "groups": groups,
        "all_words": flat_words,
    }


def normalize_kanji(items: list[dict]) -> list[dict]:
    return [
        {
            "id": item["id"],
            "entry_id": f"kanji-{item['id']}",
            "kanji": item["kanji"],
            "meanings": item["meaning"],
            "onyomi": item["onyomi"],
            "kunyomi": item["kunyomi"],
            "notes": item["notes"],
        }
        for item in items
    ]


def normalize_kana(items: list[dict], script: str) -> list[dict]:
    normalized = []
    for index, item in enumerate(items, start=1):
        character = item["character"] if script == "hiragana" else item["katakana"]
        normalized.append(
            {
                "id": index,
                "entry_id": f"{script}-{index}",
                "script": script,
                "character": character,
                "romaji": item["romaji"],
            }
        )
    return normalized


def build_search_index(
    czech_vocabulary: list[dict],
    czech_adjectives: list[dict],
    czech_verbs: list[dict],
    japanese_verbs: list[dict],
    japanese_adjectives: list[dict],
    japanese_vocabulary: list[dict],
    demonstratives: dict,
    kanji: list[dict],
) -> list[dict]:
    index = []

    for item in czech_vocabulary:
        index.append(
            {
                "entry_id": item["entry_id"],
                "section": "lexicon.czech_vocabulary",
                "romaji": None,
                "kana": item["czech"],
                "kanji": None,
                "meaning": item["english"],
                "tags": ["czech", "vocabulary", item["category"]],
            }
        )

    for item in czech_adjectives:
        index.append(
            {
                "entry_id": item["entry_id"],
                "section": "lexicon.czech_adjectives",
                "romaji": None,
                "kana": item["czech"],
                "kanji": None,
                "meaning": item["english"],
                "tags": ["czech", "adjective", item["category"]],
            }
        )

    for item in czech_verbs:
        index.append(
            {
                "entry_id": item["entry_id"],
                "section": "lexicon.czech_verbs",
                "romaji": None,
                "kana": item["czech"],
                "kanji": None,
                "meaning": item["english"],
                "tags": ["czech", "verb", item["category"]],
            }
        )

    for item in japanese_vocabulary:
        index.append(
            {
                "entry_id": item["entry_id"],
                "section": "lexicon.japanese_vocabulary",
                "romaji": item["romaji"],
                "kana": item["kana"],
                "kanji": item["kanji"],
                "meaning": item["meaning"],
                "tags": ["japanese", "vocabulary", item["category"]],
            }
        )

    for item in japanese_adjectives:
        index.append(
            {
                "entry_id": item["entry_id"],
                "section": "lexicon.japanese_adjectives",
                "romaji": item["romaji"],
                "kana": item["kana"],
                "kanji": None,
                "meaning": item["meaning"],
                "tags": ["japanese", "adjective", item["adjective_type"]],
            }
        )

    for item in japanese_verbs:
        index.append(
            {
                "entry_id": item["entry_id"],
                "section": "lexicon.japanese_verbs",
                "romaji": item["romaji"],
                "kana": item["kana"],
                "kanji": item["kanji"],
                "meaning": item["meaning"],
                "tags": ["japanese", "verb", item["verb_type"], item["verb_group"]],
            }
        )

    for item in demonstratives["all_words"]:
        index.append(
            {
                "entry_id": item["entry_id"],
                "section": "grammar.demonstratives",
                "romaji": item["romaji"],
                "kana": item["kana"],
                "kanji": None,
                "meaning": item["meaning"],
                "tags": ["demonstrative", item["prefix"], item["group_type"]],
            }
        )

    for item in kanji:
        index.append(
            {
                "entry_id": item["entry_id"],
                "section": "kanji",
                "romaji": None,
                "kana": None,
                "kanji": item["kanji"],
                "meaning": ", ".join(item["meanings"]),
                "tags": ["kanji"],
            }
        )

    return index


def build_stats(
    czech_vocabulary: list[dict],
    czech_adjectives: list[dict],
    czech_verbs: list[dict],
    japanese_vocabulary: list[dict],
    japanese_adjectives: list[dict],
    japanese_verbs: list[dict],
    demonstratives: dict,
    kanji: list[dict],
    hiragana: list[dict],
    katakana: list[dict],
) -> dict:
    return {
        "totals": {
            "czech_vocabulary": len(czech_vocabulary),
            "czech_adjectives": len(czech_adjectives),
            "czech_verbs": len(czech_verbs),
            "japanese_vocabulary": len(japanese_vocabulary),
            "japanese_adjectives": len(japanese_adjectives),
            "japanese_verbs": len(japanese_verbs),
            "demonstratives": len(demonstratives["all_words"]),
            "kanji": len(kanji),
            "hiragana": len(hiragana),
            "katakana": len(katakana),
        },
        "czech_vocabulary_by_category": dict(sorted(Counter(item["category"] for item in czech_vocabulary).items())),
        "czech_adjectives_by_category": dict(sorted(Counter(item["category"] for item in czech_adjectives).items())),
        "czech_verbs_by_category": dict(sorted(Counter(item["category"] for item in czech_verbs).items())),
        "japanese_vocabulary_by_category": dict(sorted(Counter(item["category"] for item in japanese_vocabulary).items())),
        "japanese_adjectives_by_type": dict(
            sorted(Counter(item["adjective_type"] for item in japanese_adjectives).items())
        ),
        "japanese_verbs_by_group": dict(sorted(Counter(item["verb_group"] for item in japanese_verbs).items())),
        "demonstratives_by_prefix": dict(
            sorted(Counter(item["prefix"] for item in demonstratives["all_words"]).items())
        ),
    }


def build_database_from_sources(
    *,
    czech_vocabulary: dict,
    czech_adjectives: dict,
    czech_verbs: dict,
    japanese_verbs: dict,
    japanese_adjectives: dict,
    japanese_vocabulary: dict,
    demonstratives: dict,
    kanji: list[dict],
    hiragana: dict,
    katakana: dict,
) -> dict:
    normalized_czech_vocabulary = normalize_czech_entries(
        czech_vocabulary["czech_vocabulary"],
        default_part_of_speech="vocabulary",
    )
    normalized_czech_adjectives = normalize_czech_entries(
        czech_adjectives["czech_adjectives"],
        default_part_of_speech="adjective",
    )
    normalized_czech_verbs = normalize_czech_entries(
        czech_verbs["czech_verbs"],
        default_part_of_speech="verb",
    )
    normalized_japanese_verbs = normalize_japanese_verbs(japanese_verbs["japanese_verbs"])
    normalized_japanese_adjectives = normalize_japanese_adjectives(
        japanese_adjectives["japanese_adjectives"]
    )
    normalized_japanese_vocabulary = normalize_japanese_vocabulary(
        japanese_vocabulary["japanese_vocabulary"]
    )
    normalized_demonstratives = normalize_demonstratives(demonstratives)
    normalized_kanji = normalize_kanji(kanji)
    normalized_hiragana = normalize_kana(hiragana["hiragana"], "hiragana")
    normalized_katakana = normalize_kana(katakana["katakana"], "katakana")

    return {
        "metadata": {
            "name": "Cognita Learning Database",
            "version": 2,
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "source_files": [
                "database/czech_vocabulary.json",
                "database/czech_adjectives.json",
                "database/czech_verbs.json",
                "database/vocabulary.json",
                "database/adjectives.json",
                "database/verbs.json",
                "database/demonstrative.json",
                "database/kangi.json",
                "database/hiragana.json",
                "database/katakana.json",
            ],
            "notes": [
                "This file is generated from the source JSON files in the database directory.",
                "The source file named database/kangi.json is exposed here as the kanji section.",
            ],
        },
        "stats": build_stats(
            czech_vocabulary=normalized_czech_vocabulary,
            czech_adjectives=normalized_czech_adjectives,
            czech_verbs=normalized_czech_verbs,
            japanese_vocabulary=normalized_japanese_vocabulary,
            japanese_adjectives=normalized_japanese_adjectives,
            japanese_verbs=normalized_japanese_verbs,
            demonstratives=normalized_demonstratives,
            kanji=normalized_kanji,
            hiragana=normalized_hiragana,
            katakana=normalized_katakana,
        ),
        "kana": {
            "hiragana": normalized_hiragana,
            "katakana": normalized_katakana,
        },
        "kanji": normalized_kanji,
        "grammar": {
            "demonstratives": normalized_demonstratives,
        },
        "lexicon": {
            "czech_vocabulary": normalized_czech_vocabulary,
            "czech_adjectives": normalized_czech_adjectives,
            "czech_verbs": normalized_czech_verbs,
            "japanese_vocabulary": normalized_japanese_vocabulary,
            "japanese_adjectives": normalized_japanese_adjectives,
            "japanese_verbs": normalized_japanese_verbs,
        },
        "search_index": build_search_index(
            czech_vocabulary=normalized_czech_vocabulary,
            czech_adjectives=normalized_czech_adjectives,
            czech_verbs=normalized_czech_verbs,
            japanese_verbs=normalized_japanese_verbs,
            japanese_adjectives=normalized_japanese_adjectives,
            japanese_vocabulary=normalized_japanese_vocabulary,
            demonstratives=normalized_demonstratives,
            kanji=normalized_kanji,
        ),
    }


def main() -> None:
    database = build_database_from_sources(
        czech_vocabulary=load_json("czech_vocabulary.json"),
        czech_adjectives=load_json("czech_adjectives.json"),
        czech_verbs=load_json("czech_verbs.json"),
        japanese_verbs={"japanese_verbs": load_json("verbs.json")["verbs"]},
        japanese_adjectives={"japanese_adjectives": load_json("adjectives.json")["adjectives"]},
        japanese_vocabulary={"japanese_vocabulary": load_json("vocabulary.json")["vocabulary"]},
        demonstratives=load_json("demonstrative.json"),
        kanji=load_json("kangi.json"),
        hiragana=load_json("hiragana.json"),
        katakana=load_json("katakana.json"),
    )

    OUTPUT_FILE.write_text(
        json.dumps(database, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
