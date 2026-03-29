from __future__ import annotations

import json
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DATABASE_DIR = ROOT / "database"
OUTPUT_FILE = DATABASE_DIR / "japanese_database.json"


def load_json(name: str):
    return json.loads((DATABASE_DIR / name).read_text(encoding="utf-8"))


def normalize_verbs(items: list[dict]) -> list[dict]:
    normalized = []
    for item in items:
        normalized.append(
            {
                "id": item["id"],
                "entry_id": f"verb-{item['id']}",
                "part_of_speech": "verb",
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
        )
    return normalized


def normalize_adjectives(items: list[dict]) -> list[dict]:
    normalized = []
    for item in items:
        normalized.append(
            {
                "id": item["id"],
                "entry_id": f"adjective-{item['id']}",
                "part_of_speech": "adjective",
                "romaji": item["romaji"],
                "kana": item["kana"],
                "meaning": item["meaning"],
                "adjective_type": item["type"],
            }
        )
    return normalized


def normalize_vocabulary(items: list[dict]) -> list[dict]:
    normalized = []
    for item in items:
        normalized.append(
            {
                "id": item["id"],
                "entry_id": f"vocabulary-{item['id']}",
                "part_of_speech": "vocabulary",
                "romaji": item["romaji"],
                "kana": item["kana"],
                "meaning": item["meaning"],
                "category": item["category"],
            }
        )
    return normalized


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
    normalized = []
    for item in items:
        normalized.append(
            {
                "id": item["id"],
                "entry_id": f"kanji-{item['id']}",
                "kanji": item["kanji"],
                "meanings": item["meaning"],
                "onyomi": item["onyomi"],
                "kunyomi": item["kunyomi"],
                "notes": item["notes"],
            }
        )
    return normalized


def normalize_kana(items: list[dict], script: str) -> list[dict]:
    normalized = []
    for index, item in enumerate(items, start=1):
        if script == "hiragana":
            character = item["character"]
        else:
            character = item["katakana"]

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
    verbs: list[dict],
    adjectives: list[dict],
    vocabulary: list[dict],
    demonstratives: dict,
    kanji: list[dict],
) -> list[dict]:
    index = []

    for item in verbs:
        index.append(
            {
                "entry_id": item["entry_id"],
                "section": "lexicon.verbs",
                "romaji": item["romaji"],
                "kana": item["kana"],
                "kanji": item["kanji"],
                "meaning": item["meaning"],
                "tags": ["verb", item["verb_type"], item["verb_group"]],
            }
        )

    for item in adjectives:
        index.append(
            {
                "entry_id": item["entry_id"],
                "section": "lexicon.adjectives",
                "romaji": item["romaji"],
                "kana": item["kana"],
                "kanji": None,
                "meaning": item["meaning"],
                "tags": ["adjective", item["adjective_type"]],
            }
        )

    for item in vocabulary:
        index.append(
            {
                "entry_id": item["entry_id"],
                "section": "lexicon.vocabulary",
                "romaji": item["romaji"],
                "kana": item["kana"],
                "kanji": None,
                "meaning": item["meaning"],
                "tags": ["vocabulary", item["category"]],
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
    verbs: list[dict],
    adjectives: list[dict],
    vocabulary: list[dict],
    demonstratives: dict,
    kanji: list[dict],
    hiragana: list[dict],
    katakana: list[dict],
) -> dict:
    return {
        "totals": {
            "verbs": len(verbs),
            "adjectives": len(adjectives),
            "vocabulary": len(vocabulary),
            "demonstratives": len(demonstratives["all_words"]),
            "kanji": len(kanji),
            "hiragana": len(hiragana),
            "katakana": len(katakana),
        },
        "verbs_by_group": dict(sorted(Counter(item["verb_group"] for item in verbs).items())),
        "adjectives_by_type": dict(sorted(Counter(item["adjective_type"] for item in adjectives).items())),
        "vocabulary_by_category": dict(sorted(Counter(item["category"] for item in vocabulary).items())),
        "demonstratives_by_prefix": dict(
            sorted(Counter(item["prefix"] for item in demonstratives["all_words"]).items())
        ),
    }


def main() -> None:
    verbs = normalize_verbs(load_json("verbs.json")["verbs"])
    adjectives = normalize_adjectives(load_json("adjectives.json")["adjectives"])
    vocabulary = normalize_vocabulary(load_json("vocabulary.json")["vocabulary"])
    demonstratives = normalize_demonstratives(load_json("demonstrative.json"))
    kanji = normalize_kanji(load_json("kangi.json"))
    hiragana = normalize_kana(load_json("hiragana.json")["hiragana"], "hiragana")
    katakana = normalize_kana(load_json("katakana.json")["katakana"], "katakana")

    database = {
        "metadata": {
            "name": "Japanese Learning App Database",
            "version": 1,
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "source_files": [
                "database/verbs.json",
                "database/adjectives.json",
                "database/vocabulary.json",
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
            verbs=verbs,
            adjectives=adjectives,
            vocabulary=vocabulary,
            demonstratives=demonstratives,
            kanji=kanji,
            hiragana=hiragana,
            katakana=katakana,
        ),
        "kana": {
            "hiragana": hiragana,
            "katakana": katakana,
        },
        "kanji": kanji,
        "grammar": {
            "demonstratives": demonstratives,
        },
        "lexicon": {
            "verbs": verbs,
            "adjectives": adjectives,
            "vocabulary": vocabulary,
        },
        "search_index": build_search_index(
            verbs=verbs,
            adjectives=adjectives,
            vocabulary=vocabulary,
            demonstratives=demonstratives,
            kanji=kanji,
        ),
    }

    OUTPUT_FILE.write_text(
        json.dumps(database, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    main()
