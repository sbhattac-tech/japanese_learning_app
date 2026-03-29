from __future__ import annotations

from pydantic import BaseModel, Field


class ImportCandidate(BaseModel):
    source_text: str
    romaji: str = ""
    kana: str = ""
    meaning: str = ""
    category: str = "imported"


class ImportExtractResponse(BaseModel):
    entries: list[ImportCandidate]


class ImportSaveRequest(BaseModel):
    entries: list[ImportCandidate] = Field(default_factory=list)

