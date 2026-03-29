from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from scripts.build_database import main as rebuild_database


ROOT = Path(__file__).resolve().parents[1]
DATABASE_DIR = ROOT / "database"


@dataclass(frozen=True)
class CategoryConfig:
    source_file: str
    container_key: str | None
    item_key: str | None = None


CATEGORY_CONFIG: dict[str, CategoryConfig] = {
    "verbs": CategoryConfig(source_file="verbs.json", container_key="verbs"),
    "adjectives": CategoryConfig(source_file="adjectives.json", container_key="adjectives"),
    "vocabulary": CategoryConfig(source_file="vocabulary.json", container_key="vocabulary"),
    "kanji": CategoryConfig(source_file="kangi.json", container_key=None),
    "hiragana": CategoryConfig(source_file="hiragana.json", container_key="hiragana"),
    "katakana": CategoryConfig(source_file="katakana.json", container_key="katakana"),
    "demonstratives": CategoryConfig(
        source_file="demonstrative.json",
        container_key="groups",
        item_key="words",
    ),
}


class DatabaseService:
    storage_backend = "json"

    def list_categories(self) -> list[str]:
        return sorted(CATEGORY_CONFIG.keys())

    def get_category(self, category: str) -> Any:
        config = self._config(category)
        data = self._load(config.source_file)
        if config.item_key:
            return data
        if config.container_key is None:
            return data
        return data[config.container_key]

    def get_entry(self, category: str, entry_id: int) -> dict[str, Any] | None:
        if category == "demonstratives":
            _, word = self._find_demonstrative(entry_id)
            return word

        entries = self._get_entries(category)
        return next((entry for entry in entries if entry.get("id") == entry_id), None)

    def get_master_database(self) -> Any:
        return self._load("japanese_database.json")

    def create_entry(self, category: str, payload: dict[str, Any]) -> dict[str, Any]:
        if category == "demonstratives":
            return self._create_demonstrative(payload)

        config = self._config(category)
        data = self._load(config.source_file)
        entries = self._extract_entries(data, config)

        entry = dict(payload)
        entry["id"] = self._next_id(entries)
        entries.append(entry)

        self._save(config.source_file, data)
        self._rebuild()
        return entry

    def create_entries(self, category: str, payloads: list[dict[str, Any]]) -> list[dict[str, Any]]:
        if category == "demonstratives":
            raise ValueError("Bulk import is not supported for demonstratives")

        config = self._config(category)
        data = self._load(config.source_file)
        entries = self._extract_entries(data, config)

        created: list[dict[str, Any]] = []
        next_id = self._next_id(entries)
        for payload in payloads:
            entry = dict(payload)
            entry["id"] = next_id
            next_id += 1
            entries.append(entry)
            created.append(entry)

        self._save(config.source_file, data)
        self._rebuild()
        return created

    def update_entry(self, category: str, entry_id: int, payload: dict[str, Any]) -> dict[str, Any] | None:
        if category == "demonstratives":
            return self._update_demonstrative(entry_id, payload)

        config = self._config(category)
        data = self._load(config.source_file)
        entries = self._extract_entries(data, config)

        for index, entry in enumerate(entries):
            if entry.get("id") == entry_id:
                updated = dict(payload)
                updated["id"] = entry_id
                entries[index] = updated
                self._save(config.source_file, data)
                self._rebuild()
                return updated
        return None

    def delete_entry(self, category: str, entry_id: int) -> bool:
        if category == "demonstratives":
            return self._delete_demonstrative(entry_id)

        config = self._config(category)
        data = self._load(config.source_file)
        entries = self._extract_entries(data, config)

        original_count = len(entries)
        entries[:] = [entry for entry in entries if entry.get("id") != entry_id]
        if len(entries) == original_count:
            return False

        self._save(config.source_file, data)
        self._rebuild()
        return True

    def _get_entries(self, category: str) -> list[dict[str, Any]]:
        config = self._config(category)
        data = self._load(config.source_file)
        return self._extract_entries(data, config)

    def _extract_entries(self, data: Any, config: CategoryConfig) -> list[dict[str, Any]]:
        if config.container_key is None:
            return data
        return data[config.container_key]

    def _create_demonstrative(self, payload: dict[str, Any]) -> dict[str, Any]:
        data = self._load("demonstrative.json")
        group = self._get_demonstrative_group(data, payload["group_type"])
        words = group["words"]

        entry = {
            "id": self._next_id(self._flatten_demonstratives(data)),
            "jp": payload["jp"],
            "romaji": payload["romaji"],
            "en": payload["en"],
            "prefix": payload["prefix"],
        }
        words.append(entry)

        self._save("demonstrative.json", data)
        self._rebuild()
        return entry

    def _update_demonstrative(self, entry_id: int, payload: dict[str, Any]) -> dict[str, Any] | None:
        data = self._load("demonstrative.json")
        location = self._find_demonstrative(entry_id, data=data)
        if location is None:
            return None

        current_group, current_word = location
        target_group = self._get_demonstrative_group(data, payload["group_type"])

        updated = {
            "id": entry_id,
            "jp": payload["jp"],
            "romaji": payload["romaji"],
            "en": payload["en"],
            "prefix": payload["prefix"],
        }

        if current_group["type"] == target_group["type"]:
            current_word.clear()
            current_word.update(updated)
        else:
            current_group["words"] = [word for word in current_group["words"] if word["id"] != entry_id]
            target_group["words"].append(updated)

        self._save("demonstrative.json", data)
        self._rebuild()
        return updated

    def _delete_demonstrative(self, entry_id: int) -> bool:
        data = self._load("demonstrative.json")
        found = False
        for group in data["groups"]:
            original_count = len(group["words"])
            group["words"] = [word for word in group["words"] if word["id"] != entry_id]
            if len(group["words"]) != original_count:
                found = True
                break

        if not found:
            return False

        self._save("demonstrative.json", data)
        self._rebuild()
        return True

    def _find_demonstrative(
        self,
        entry_id: int,
        *,
        data: dict[str, Any] | None = None,
    ) -> tuple[dict[str, Any], dict[str, Any]] | None:
        data = data or self._load("demonstrative.json")
        for group in data["groups"]:
            for word in group["words"]:
                if word["id"] == entry_id:
                    return group, word
        return None

    def _flatten_demonstratives(self, data: dict[str, Any]) -> list[dict[str, Any]]:
        return [word for group in data["groups"] for word in group["words"]]

    def _get_demonstrative_group(self, data: dict[str, Any], group_type: str) -> dict[str, Any]:
        for group in data["groups"]:
            if group["type"] == group_type:
                return group
        raise ValueError(f"Unknown demonstrative group_type: {group_type}")

    def _next_id(self, entries: list[dict[str, Any]]) -> int:
        if not entries:
            return 1
        return max(int(entry["id"]) for entry in entries) + 1

    def _config(self, category: str) -> CategoryConfig:
        try:
            return CATEGORY_CONFIG[category]
        except KeyError as error:
            raise ValueError(f"Unsupported category: {category}") from error

    def _load(self, filename: str) -> Any:
        return json.loads((DATABASE_DIR / filename).read_text(encoding="utf-8"))

    def _save(self, filename: str, data: Any) -> None:
        (DATABASE_DIR / filename).write_text(
            json.dumps(data, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    def _rebuild(self) -> None:
        rebuild_database()
