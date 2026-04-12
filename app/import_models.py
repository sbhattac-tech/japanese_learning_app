from __future__ import annotations

from pydantic import BaseModel, Field


class ImportCandidate(BaseModel):
    source_text: str
    source_language: str = "unknown"
    normalized_text: str = ""
    romaji: str = ""
    japanese_text: str = ""
    hiragana: str = ""
    katakana: str = ""
    kanji: str = ""
    meaning: str = ""
    part_of_speech: str = "vocabulary"
    category: str = "imported"
    matched_category: str = ""
    set_name: str = ""


class ImportExtractResponse(BaseModel):
    entries: list[ImportCandidate]
    available_sets: list[str] = Field(default_factory=list)


class ImportSetSummary(BaseModel):
    name: str
    entry_count: int = 0


class ImportSaveRequest(BaseModel):
    entries: list[ImportCandidate] = Field(default_factory=list)
    set_name: str = ""
