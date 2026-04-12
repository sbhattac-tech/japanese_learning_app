from __future__ import annotations

import re
from collections import OrderedDict
from dataclasses import dataclass
from typing import Any

from app.database_service import DatabaseService
from app.import_models import ImportCandidate

PUNCTUATION_PATTERN = re.compile(r"[^\w\u4E00-\u9FFF\u3005\u3040-\u309F\u30A0-\u30FF]+", re.UNICODE)


@dataclass(frozen=True)
class LexiconEntry:
    category: str
    payload: dict[str, Any]
    search_terms: tuple[str, ...]


class ImportService:
    def __init__(self, database_service: DatabaseService) -> None:
        self._database_service = database_service

    def build_candidates(self, raw_tokens: list[str]) -> list[ImportCandidate]:
        lexicon = self._build_lexicon()
        candidates: list[ImportCandidate] = []
        seen: set[str] = set()

        for raw_token in raw_tokens:
            token = self._clean_token(raw_token)
            if not token:
                continue

            key = token.casefold()
            if key in seen:
                continue

            seen.add(key)
            candidates.append(self._build_candidate(token, lexicon))

        return candidates

    def list_import_sets(self) -> list[dict[str, Any]]:
        try:
            vocabulary_entries = self._database_service.get_category("japanese_vocabulary")
        except ValueError:
            return []

        counts: dict[str, int] = {}
        for entry in vocabulary_entries:
            set_name = str(entry.get("set_name", "")).strip()
            if not set_name:
                continue
            counts[set_name] = counts.get(set_name, 0) + 1

        return [
            {"name": name, "entry_count": count}
            for name, count in sorted(counts.items(), key=lambda item: item[0].casefold())
        ]

    def _build_candidate(self, token: str, lexicon: list[LexiconEntry]) -> ImportCandidate:
        language = self._detect_language(token)
        matched = self._find_best_match(token, language, lexicon)
        if matched is None:
            return self._build_unmatched_candidate(token, language)
        return self._build_matched_candidate(token, language, matched)

    def _build_matched_candidate(
        self,
        token: str,
        language: str,
        matched: LexiconEntry,
    ) -> ImportCandidate:
        payload = matched.payload
        return ImportCandidate(
            source_text=token,
            source_language=language,
            normalized_text=self._normalize_lookup_value(token),
            romaji=str(payload.get("romaji", "")).strip(),
            japanese_text=self._extract_japanese_text(matched.category, payload),
            hiragana=self._extract_hiragana(matched.category, payload),
            katakana=self._extract_katakana(matched.category, payload),
            kanji=self._extract_kanji(matched.category, payload, fallback=token),
            meaning=self._extract_meaning(matched.category, payload),
            part_of_speech=self._part_of_speech_for_category(matched.category, payload),
            category=self._extract_topic_category(matched.category, payload),
            matched_category=matched.category,
        )

    def _build_unmatched_candidate(self, token: str, language: str) -> ImportCandidate:
        japanese_text = token if language in {"japanese", "mixed"} else ""
        hiragana = token if self._is_hiragana(token) else self._to_hiragana(token) if self._is_katakana(token) else ""
        katakana = token if self._is_katakana(token) else self._to_katakana(token) if self._is_hiragana(token) else ""
        kanji = token if self._has_kanji(token) else ""

        return ImportCandidate(
            source_text=token,
            source_language=language,
            normalized_text=self._normalize_lookup_value(token),
            romaji=token if language == "romaji" else "",
            japanese_text=japanese_text,
            hiragana=hiragana,
            katakana=katakana,
            kanji=kanji,
            meaning=token if language == "english" else "",
            part_of_speech="vocabulary",
            category="imported",
        )

    def _build_lexicon(self) -> list[LexiconEntry]:
        entries: list[LexiconEntry] = []
        for category in ("japanese_vocabulary", "japanese_adjectives", "japanese_verbs"):
            try:
                rows = self._database_service.get_category(category)
            except ValueError:
                continue

            for payload in rows:
                entries.append(
                    LexiconEntry(
                        category=category,
                        payload=payload,
                        search_terms=self._search_terms_for_entry(category, payload),
                    )
                )

        return entries

    def _find_best_match(
        self,
        token: str,
        language: str,
        lexicon: list[LexiconEntry],
    ) -> LexiconEntry | None:
        normalized = self._normalize_lookup_value(token)
        if not normalized:
            return None

        exact_match: LexiconEntry | None = None
        partial_match: LexiconEntry | None = None
        for entry in lexicon:
            if normalized in entry.search_terms:
                if language == "english" and entry.category == "japanese_vocabulary":
                    return entry
                if exact_match is None:
                    exact_match = entry

            if partial_match is None and any(normalized in term for term in entry.search_terms):
                partial_match = entry

        return exact_match or partial_match

    def _search_terms_for_entry(self, category: str, payload: dict[str, Any]) -> tuple[str, ...]:
        values = [
            str(payload.get("romaji", "")),
            self._extract_meaning(category, payload),
            str(payload.get("kana", "")),
            str(payload.get("kanji", "")),
            str(payload.get("hiragana", "")),
            str(payload.get("katakana", "")),
        ]
        terms: list[str] = []
        for value in values:
            for part in [value, *re.split(r"[,/;()]+", value)]:
                normalized = self._normalize_lookup_value(part)
                if normalized:
                    terms.append(normalized)

        return tuple(OrderedDict.fromkeys(terms))

    def _extract_japanese_text(self, category: str, payload: dict[str, Any]) -> str:
        if category == "japanese_verbs":
            return str(payload.get("kanji") or payload.get("hiragana") or "").strip()
        return str(
            payload.get("kanji")
            or payload.get("kana")
            or payload.get("hiragana")
            or payload.get("katakana")
            or ""
        ).strip()

    def _extract_hiragana(self, category: str, payload: dict[str, Any]) -> str:
        if category == "japanese_verbs":
            return str(payload.get("hiragana", "")).strip()
        value = str(payload.get("hiragana") or payload.get("kana") or "").strip()
        return self._to_hiragana(value) if self._is_katakana(value) else value

    def _extract_katakana(self, category: str, payload: dict[str, Any]) -> str:
        if category == "japanese_verbs":
            return self._to_katakana(str(payload.get("hiragana", "")).strip())
        value = str(payload.get("katakana") or payload.get("kana") or "").strip()
        return self._to_katakana(value) if self._is_hiragana(value) else value

    def _extract_kanji(self, category: str, payload: dict[str, Any], *, fallback: str = "") -> str:
        value = str(payload.get("kanji", "")).strip()
        if value:
            return value
        if category == "japanese_vocabulary":
            kana = str(payload.get("kana", "")).strip()
            if self._has_kanji(kana):
                return kana
        return fallback if self._has_kanji(fallback) else ""

    def _extract_meaning(self, category: str, payload: dict[str, Any]) -> str:
        raw = payload.get("meaning", "")
        if isinstance(raw, list):
            return ", ".join(str(item).strip() for item in raw if str(item).strip())
        return str(raw).strip()

    def _extract_topic_category(self, category: str, payload: dict[str, Any]) -> str:
        if category == "japanese_vocabulary":
            return str(payload.get("category", "")).strip() or "imported"
        if category == "japanese_adjectives":
            adjective_type = str(payload.get("type", "")).strip()
            return f"{adjective_type}-adjective" if adjective_type else "adjective"
        if category == "japanese_verbs":
            return str(payload.get("group", "")).strip() or "verb"
        return "imported"

    def _part_of_speech_for_category(self, category: str, payload: dict[str, Any]) -> str:
        if category == "japanese_verbs":
            return "verb"
        if category == "japanese_adjectives":
            adjective_type = str(payload.get("type", "")).strip()
            return f"{adjective_type}-adjective" if adjective_type else "adjective"
        return str(payload.get("part_of_speech", "")).strip() or "vocabulary"

    def _clean_token(self, token: str) -> str:
        collapsed = " ".join(token.strip().split())
        return collapsed.strip(" ,.;:!?()[]{}\"'")

    def _normalize_lookup_value(self, value: str) -> str:
        lowered = value.strip().casefold()
        lowered = PUNCTUATION_PATTERN.sub(" ", lowered)
        return " ".join(lowered.split())

    def _detect_language(self, value: str) -> str:
        has_japanese = bool(re.search(r"[\u4E00-\u9FFF\u3040-\u309F\u30A0-\u30FF]", value))
        has_latin = bool(re.search(r"[A-Za-z]", value))
        if has_japanese and has_latin:
            return "mixed"
        if has_japanese:
            return "japanese"
        if has_latin:
            return "romaji" if self._looks_like_romaji(value) else "english"
        return "unknown"

    def _looks_like_romaji(self, value: str) -> bool:
        normalized = re.sub(r"[^a-z]", "", value.casefold())
        if not normalized:
            return False
        if normalized in {"the", "and", "with", "from", "this", "that", "notes", "study"}:
            return False
        return bool(
            re.fullmatch(
                r"(kya|kyu|kyo|sha|shu|sho|cha|chu|cho|nya|nyu|nyo|hya|hyu|hyo|mya|myu|myo|rya|ryu|ryo|gya|gyu|gyo|ja|ju|jo|bya|byu|byo|pya|pyu|pyo|tsu|shi|chi|fu|[bcdfghjklmnpqrstvwxyz]?y?[aeiou]|n)+",
                normalized,
            )
        )

    def _has_kanji(self, value: str) -> bool:
        return bool(re.search(r"[\u4E00-\u9FFF]", value))

    def _is_hiragana(self, value: str) -> bool:
        return bool(value) and bool(re.fullmatch(r"[\u3041-\u309F\u30FC]+", value))

    def _is_katakana(self, value: str) -> bool:
        return bool(value) and bool(re.fullmatch(r"[\u30A1-\u30FF\u30FC]+", value))

    def _to_katakana(self, value: str) -> str:
        chars: list[str] = []
        for char in value:
            code = ord(char)
            chars.append(chr(code + 0x60) if 0x3041 <= code <= 0x3096 else char)
        return "".join(chars)

    def _to_hiragana(self, value: str) -> str:
        chars: list[str] = []
        for char in value:
            code = ord(char)
            chars.append(chr(code - 0x60) if 0x30A1 <= code <= 0x30F6 else char)
        return "".join(chars)
