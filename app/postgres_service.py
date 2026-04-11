from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from itertools import groupby
from typing import Any

from sqlalchemy import (
    JSON,
    DateTime,
    Integer,
    MetaData,
    String,
    Table,
    UniqueConstraint,
    create_engine,
    delete,
    func,
    select,
)
from sqlalchemy.dialects.postgresql import JSONB

from app.database_service import CATEGORY_CONFIG, CategoryConfig
from scripts.build_database import build_database_from_sources

POSTGRES_CATEGORIES = ("vocabulary", "adjectives", "verbs")

DEMONSTRATIVE_CATEGORY = "ko-so-a-do"
DEMONSTRATIVE_DESCRIPTION = (
    "Japanese demonstrative system covering location, objects, direction, description, "
    "manner, and extended forms"
)
DEMONSTRATIVE_PREFIX_MEANINGS = {
    "ko": "near speaker",
    "so": "near listener",
    "a": "far from both",
    "do": "question word",
}
DEMONSTRATIVE_GROUP_DESCRIPTIONS = {
    "place": "Locations",
    "thing": "Standalone objects",
    "noun_modifier": "Used before nouns",
    "polite_direction_person": "Polite direction or person reference",
    "casual_direction": "Casual direction",
    "manner": "How / in what way",
    "kind_type": "Type/kind of thing",
    "formal_written": "More formal/literary variants",
    "compound_pronouns": "Plural or grouped references",
}
DEMONSTRATIVE_GROUP_ORDER = list(DEMONSTRATIVE_GROUP_DESCRIPTIONS)


@dataclass(frozen=True)
class StoredEntry:
    entry_id: int
    sort_order: int
    group_type: str | None
    payload: dict[str, Any]


class PostgresDatabaseService:
    storage_backend = "postgres"

    def __init__(self, database_url: str) -> None:
        self._engine = create_engine(
            _normalize_database_url(database_url),
            future=True,
            pool_pre_ping=True,
        )
        self._metadata = MetaData()
        payload_type = JSONB().with_variant(JSON(), "sqlite")
        self._entries = Table(
            "entries",
            self._metadata,
            sqlalchemy_column("id", Integer, primary_key=True, autoincrement=True),
            sqlalchemy_column("category", String(50), nullable=False, index=True),
            sqlalchemy_column("entry_id", Integer, nullable=False),
            sqlalchemy_column("sort_order", Integer, nullable=False),
            sqlalchemy_column("group_type", String(100), nullable=True),
            sqlalchemy_column("payload", payload_type, nullable=False),
            sqlalchemy_column(
                "created_at",
                DateTime(timezone=True),
                nullable=False,
                default=_utcnow,
            ),
            sqlalchemy_column(
                "updated_at",
                DateTime(timezone=True),
                nullable=False,
                default=_utcnow,
                onupdate=_utcnow,
            ),
            UniqueConstraint("category", "entry_id", name="uq_entries_category_entry_id"),
        )
        self._metadata.create_all(self._engine)

    def list_categories(self) -> list[str]:
        return list(POSTGRES_CATEGORIES)

    def get_category(self, category: str) -> Any:
        self._config(category)
        rows = self._fetch_category_rows(category)
        if category == "demonstratives":
            return self._serialize_demonstratives(rows)
        return [self._materialize_payload(category, row) for row in rows]

    def get_entry(self, category: str, entry_id: int) -> dict[str, Any] | None:
        self._config(category)
        row = self._fetch_entry_row(category, entry_id)
        if row is None:
            return None
        return self._materialize_payload(category, row)

    def get_master_database(self) -> Any:
        return build_database_from_sources(
            verbs={"verbs": self.get_category("verbs")},
            adjectives={"adjectives": self.get_category("adjectives")},
            vocabulary={"vocabulary": self.get_category("vocabulary")},
            demonstratives={
                "category": DEMONSTRATIVE_CATEGORY,
                "description": DEMONSTRATIVE_DESCRIPTION,
                "prefix_meanings": DEMONSTRATIVE_PREFIX_MEANINGS,
                "groups": [],
            },
            kanji=[],
            hiragana={"hiragana": []},
            katakana={"katakana": []},
        )

    def create_entry(self, category: str, payload: dict[str, Any]) -> dict[str, Any]:
        self._config(category)
        created = self.create_entries(category, [payload])
        return created[0]

    def create_entries(self, category: str, payloads: list[dict[str, Any]]) -> list[dict[str, Any]]:
        self._config(category)
        rows = self._fetch_category_rows(category)
        next_entry_id = max((row.entry_id for row in rows), default=0) + 1
        next_sort_order = max((row.sort_order for row in rows), default=0) + 1

        created_rows: list[StoredEntry] = []
        for payload in payloads:
            entry_payload, group_type = self._prepare_payload_for_storage(category, payload)
            created_rows.append(
                StoredEntry(
                    entry_id=next_entry_id,
                    sort_order=next_sort_order,
                    group_type=group_type,
                    payload=entry_payload,
                )
            )
            next_entry_id += 1
            next_sort_order += 1

        with self._engine.begin() as connection:
            connection.execute(
                self._entries.insert(),
                [
                    {
                        "category": category,
                        "entry_id": row.entry_id,
                        "sort_order": row.sort_order,
                        "group_type": row.group_type,
                        "payload": row.payload,
                        "created_at": _utcnow(),
                        "updated_at": _utcnow(),
                    }
                    for row in created_rows
                ],
            )

        return [self._materialize_payload(category, row) for row in created_rows]

    def update_entry(self, category: str, entry_id: int, payload: dict[str, Any]) -> dict[str, Any] | None:
        self._config(category)
        current = self._fetch_entry_row(category, entry_id)
        if current is None:
            return None

        entry_payload, group_type = self._prepare_payload_for_storage(category, payload)
        with self._engine.begin() as connection:
            connection.execute(
                self._entries.update()
                .where(
                    self._entries.c.category == category,
                    self._entries.c.entry_id == entry_id,
                )
                .values(
                    payload=entry_payload,
                    group_type=group_type,
                    updated_at=_utcnow(),
                )
            )

        updated = StoredEntry(
            entry_id=entry_id,
            sort_order=current.sort_order,
            group_type=group_type,
            payload=entry_payload,
        )
        return self._materialize_payload(category, updated)

    def delete_entry(self, category: str, entry_id: int) -> bool:
        self._config(category)
        with self._engine.begin() as connection:
            result = connection.execute(
                delete(self._entries).where(
                    self._entries.c.category == category,
                    self._entries.c.entry_id == entry_id,
                )
            )
        return bool(result.rowcount)

    def bootstrap_from_json_service(
        self,
        json_service: Any,
        *,
        overwrite: bool = False,
        categories: list[str] | None = None,
    ) -> dict[str, int]:
        inserted_counts: dict[str, int] = {}
        selected_categories = categories or self.list_categories()
        for category in selected_categories:
            self._config(category)
        with self._engine.begin() as connection:
            if overwrite:
                connection.execute(delete(self._entries))
            else:
                existing_rows = connection.execute(select(func.count()).select_from(self._entries)).scalar_one()
                if existing_rows:
                    return {}

            for category in selected_categories:
                payloads = self._category_payloads_for_bootstrap(json_service, category)
                sort_order = 1
                rows = []
                for payload in payloads:
                    entry_payload, group_type = self._prepare_payload_for_storage(category, payload)
                    entry_id = self._payload_entry_id(category, payload, sort_order)
                    rows.append(
                        {
                            "category": category,
                            "entry_id": entry_id,
                            "sort_order": sort_order,
                            "group_type": group_type,
                            "payload": entry_payload,
                            "created_at": _utcnow(),
                            "updated_at": _utcnow(),
                        }
                    )
                    sort_order += 1

                if rows:
                    connection.execute(self._entries.insert(), rows)
                inserted_counts[category] = len(rows)

        return inserted_counts

    def _category_payloads_for_bootstrap(self, json_service: Any, category: str) -> list[dict[str, Any]]:
        data = json_service.get_category(category)
        return list(data)

    def _payload_entry_id(self, category: str, payload: dict[str, Any], fallback: int) -> int:
        existing_id = payload.get("id")
        if isinstance(existing_id, int):
            return existing_id
        return fallback

    def _prepare_payload_for_storage(
        self,
        category: str,
        payload: dict[str, Any],
    ) -> tuple[dict[str, Any], str | None]:
        stored_payload = dict(payload)
        group_type = None
        stored_payload.pop("id", None)
        return stored_payload, group_type

    def _materialize_payload(self, category: str, row: StoredEntry) -> dict[str, Any]:
        payload = dict(row.payload)
        if category in {"verbs", "adjectives", "vocabulary"}:
            payload["id"] = row.entry_id
        return payload

    def _fetch_category_rows(self, category: str) -> list[StoredEntry]:
        with self._engine.begin() as connection:
            result = connection.execute(
                select(
                    self._entries.c.entry_id,
                    self._entries.c.sort_order,
                    self._entries.c.group_type,
                    self._entries.c.payload,
                )
                .where(self._entries.c.category == category)
                .order_by(self._entries.c.sort_order, self._entries.c.entry_id)
            )
            return [
                StoredEntry(
                    entry_id=row.entry_id,
                    sort_order=row.sort_order,
                    group_type=row.group_type,
                    payload=dict(row.payload),
                )
                for row in result
            ]

    def _fetch_entry_row(self, category: str, entry_id: int) -> StoredEntry | None:
        with self._engine.begin() as connection:
            row = connection.execute(
                select(
                    self._entries.c.entry_id,
                    self._entries.c.sort_order,
                    self._entries.c.group_type,
                    self._entries.c.payload,
                ).where(
                    self._entries.c.category == category,
                    self._entries.c.entry_id == entry_id,
                )
            ).first()
        if row is None:
            return None
        return StoredEntry(
            entry_id=row.entry_id,
            sort_order=row.sort_order,
            group_type=row.group_type,
            payload=dict(row.payload),
        )

    def _config(self, category: str) -> CategoryConfig:
        if category not in POSTGRES_CATEGORIES:
            raise ValueError(
                f"Unsupported Postgres category: {category}. "
                f"Supported categories: {', '.join(POSTGRES_CATEGORIES)}"
            )
        try:
            return CATEGORY_CONFIG[category]
        except KeyError as error:
            raise ValueError(f"Unsupported category: {category}") from error


def sqlalchemy_column(name: str, type_: Any, **kwargs: Any) -> Any:
    from sqlalchemy import Column

    return Column(name, type_, **kwargs)


def _normalize_database_url(database_url: str) -> str:
    if database_url.startswith("postgresql://"):
        return "postgresql+psycopg://" + database_url.removeprefix("postgresql://")
    if database_url.startswith("postgres://"):
        return "postgresql+psycopg://" + database_url.removeprefix("postgres://")
    return database_url


def _utcnow() -> datetime:
    return datetime.now(timezone.utc)
