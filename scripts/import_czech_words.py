from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = ROOT.parent / "moje_slova" / "english_czech_word_database.json"
DATABASE_DIR = ROOT / "database"
TARGETS = {
    "czech_vocabulary": DATABASE_DIR / "czech_vocabulary.json",
    "czech_adjectives": DATABASE_DIR / "czech_adjectives.json",
    "czech_verbs": DATABASE_DIR / "czech_verbs.json",
}


def load_source(path: Path) -> list[dict[str, Any]]:
    payload = json.loads(path.read_text(encoding="utf-8"))
    return payload.get("vocabulary", [])


def maybe_fix_mojibake(value: str) -> str:
    text = value.strip()
    if not text:
        return ""

    suspicious = ("Ãƒ", "Ã„", "Ã…", "Ã„â€º", "Ã…â„¢", "Ã…Â¾", "ÃƒÂ¡", "ÃƒÂ©", "ÃƒÂ­", "ÃƒÂ³", "ÃƒÂº", "Ã…Â¯")
    if not any(token in text for token in suspicious):
        return text

    try:
        repaired = text.encode("latin-1").decode("utf-8")
    except UnicodeError:
        return text
    return repaired


def build_set_name(index: int, set_size: int = 25) -> str:
    return f"Hanka's Lesson Set {index // set_size + 1}"


def normalize_part_of_speech(raw_value: str) -> str:
    value = raw_value.strip().lower()
    aliases = {
        "noun": "noun",
        "verb": "verb",
        "adjective": "adjective",
        "adverb": "adverb",
        "expression": "expression",
        "phrase": "expression",
    }
    return aliases.get(value, "vocabulary" if not value else value)


def category_for_part_of_speech(part_of_speech: str) -> str:
    if part_of_speech == "verb":
        return "czech_verbs"
    if part_of_speech == "adjective":
        return "czech_adjectives"
    return "czech_vocabulary"


def transform_words(words: list[dict[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    buckets = {
        "czech_vocabulary": [],
        "czech_adjectives": [],
        "czech_verbs": [],
    }

    next_ids = {key: 1 for key in buckets}
    for index, word in enumerate(words):
        part_of_speech = normalize_part_of_speech(str(word.get("category", "")))
        bucket_name = category_for_part_of_speech(part_of_speech)
        buckets[bucket_name].append(
            {
                "id": next_ids[bucket_name],
                "english": maybe_fix_mojibake(str(word.get("english", ""))),
                "czech": maybe_fix_mojibake(str(word.get("czech", ""))),
                "notes": maybe_fix_mojibake(str(word.get("notes", ""))),
                "part_of_speech": part_of_speech,
                "category": "general",
                "set_name": build_set_name(index),
            }
        )
        next_ids[bucket_name] += 1

    return buckets


def write_payloads(payloads: dict[str, list[dict[str, Any]]]) -> None:
    for key, target in TARGETS.items():
        target.write_text(
            json.dumps({key: payloads[key]}, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )


def main() -> None:
    parser = argparse.ArgumentParser(description="Import Czech study data into Cognita database sources.")
    parser.add_argument(
        "--source",
        type=Path,
        default=DEFAULT_SOURCE,
        help="Path to the Moje Slova english_czech_word_database.json file.",
    )
    args = parser.parse_args()

    words = load_source(args.source)
    payloads = transform_words(words)
    write_payloads(payloads)
    for key, items in payloads.items():
        print(f"{key}: {len(items)}")


if __name__ == "__main__":
    main()
