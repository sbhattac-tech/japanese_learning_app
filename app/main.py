from __future__ import annotations

import os
from typing import Any, Literal

from fastapi import FastAPI, File, Form, HTTPException, Query, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from app.import_models import ImportCandidate, ImportExtractResponse, ImportSaveRequest
from app.ocr_service import OcrDependencyError, OcrService
from app.service_factory import create_database_service


class VerbPayload(BaseModel):
    romaji: str
    hiragana: str
    kanji: str | None = None
    meaning: str
    type: str
    group: str
    masu: str
    masu_past: str
    te: str
    past: str
    nai: str
    nai_past: str
    teiru: str
    request: str
    permission: str


class AdjectivePayload(BaseModel):
    romaji: str
    kana: str
    type: str
    meaning: str


class VocabularyPayload(BaseModel):
    romaji: str
    kana: str
    meaning: str
    category: str


class KanjiPayload(BaseModel):
    kanji: str
    meaning: list[str]
    onyomi: list[str]
    kunyomi: list[str]
    notes: str


class HiraganaPayload(BaseModel):
    character: str
    romaji: str


class KatakanaPayload(BaseModel):
    romaji: str
    katakana: str


class DemonstrativePayload(BaseModel):
    jp: str
    romaji: str
    en: str
    prefix: Literal["ko", "so", "a", "do"]
    group_type: str


service = create_database_service()
ocr_service = OcrService()
IS_VERCEL = bool(os.getenv("VERCEL"))

app = FastAPI(
    title="Japanese Learning App API",
    version="1.0.0",
    description="CRUD API for the Japanese learning JSON database.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
def read_root() -> dict[str, Any]:
    return {
        "message": "Japanese Learning App API",
        "docs": "/docs",
        "categories": service.list_categories(),
    }


@app.get("/health")
def healthcheck() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/categories")
def list_categories() -> dict[str, list[str]]:
    return {"categories": service.list_categories()}


@app.get("/entries/{category}")
def list_entries(
    category: str,
    q: str | None = Query(default=None, description="Optional search string"),
) -> Any:
    try:
        data = service.get_category(category)
    except ValueError as error:
        raise HTTPException(status_code=404, detail=str(error)) from error

    if not q:
        return data

    if category == "demonstratives":
        filtered_groups = []
        needle = q.casefold()
        for group in data["groups"]:
            words = [
                word
                for word in group["words"]
                if needle in str(word).casefold()
            ]
            if words:
                filtered_groups.append(
                    {
                        "type": group["type"],
                        "description": group["description"],
                        "words": words,
                    }
                )
        return {
            "category": data["category"],
            "description": data["description"],
            "prefix_meanings": data["prefix_meanings"],
            "groups": filtered_groups,
        }

    return [entry for entry in data if q.casefold() in str(entry).casefold()]


@app.get("/entries/{category}/{entry_id}")
def get_entry(category: str, entry_id: int) -> dict[str, Any]:
    try:
        entry = service.get_entry(category, entry_id)
    except ValueError as error:
        raise HTTPException(status_code=404, detail=str(error)) from error

    if entry is None:
        raise HTTPException(status_code=404, detail="Entry not found")
    return entry


@app.post("/entries/{category}", status_code=201)
def create_entry(category: str, payload: dict[str, Any]) -> dict[str, Any]:
    _ensure_mutations_supported()
    validated = _validate_payload(category, payload)
    try:
        return service.create_entry(category, validated)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error


@app.put("/entries/{category}/{entry_id}")
def update_entry(category: str, entry_id: int, payload: dict[str, Any]) -> dict[str, Any]:
    _ensure_mutations_supported()
    validated = _validate_payload(category, payload)
    try:
        entry = service.update_entry(category, entry_id, validated)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error

    if entry is None:
        raise HTTPException(status_code=404, detail="Entry not found")
    return entry


@app.delete("/entries/{category}/{entry_id}")
def delete_entry(category: str, entry_id: int) -> dict[str, Any]:
    _ensure_mutations_supported()
    try:
        deleted = service.delete_entry(category, entry_id)
    except ValueError as error:
        raise HTTPException(status_code=404, detail=str(error)) from error

    if not deleted:
        raise HTTPException(status_code=404, detail="Entry not found")
    return {"deleted": True, "category": category, "id": entry_id}


@app.get("/database")
def get_master_database() -> Any:
    try:
        return service.get_master_database()
    except FileNotFoundError as error:
        raise HTTPException(status_code=500, detail="Master database file is missing") from error


@app.post("/imports/image/extract", response_model=ImportExtractResponse)
async def extract_entries_from_image(
    file: UploadFile = File(...),
    target_category: str = Form(default="vocabulary"),
) -> ImportExtractResponse:
    if target_category != "vocabulary":
        raise HTTPException(
            status_code=400,
            detail="Image import currently supports only the vocabulary category.",
        )

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Uploaded image is empty")

    try:
        tokens = ocr_service.extract_candidates(image_bytes)
    except OcrDependencyError as error:
        raise HTTPException(status_code=503, detail=str(error)) from error
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error

    entries = [
        ImportCandidate(
            source_text=token,
            kana=token,
        )
        for token in tokens
    ]
    return ImportExtractResponse(entries=entries)


@app.post("/imports/image/save", status_code=201)
def save_imported_entries(payload: ImportSaveRequest) -> dict[str, Any]:
    _ensure_mutations_supported()

    cleaned_entries = []
    for entry in payload.entries:
        candidate = entry.model_dump()
        validated = _validate_payload(
            "vocabulary",
            {
                "romaji": candidate["romaji"].strip(),
                "kana": candidate["kana"].strip(),
                "meaning": candidate["meaning"].strip(),
                "category": candidate["category"].strip() or "imported",
            },
        )
        cleaned_entries.append(validated)

    if not cleaned_entries:
        raise HTTPException(status_code=400, detail="No entries were provided for import")

    try:
        created = service.create_entries("vocabulary", cleaned_entries)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error

    return {"created": created, "count": len(created)}


def _validate_payload(category: str, payload: dict[str, Any]) -> dict[str, Any]:
    model_map = {
        "verbs": VerbPayload,
        "adjectives": AdjectivePayload,
        "vocabulary": VocabularyPayload,
        "kanji": KanjiPayload,
        "hiragana": HiraganaPayload,
        "katakana": KatakanaPayload,
        "demonstratives": DemonstrativePayload,
    }

    try:
        model = model_map[category]
    except KeyError as error:
        raise HTTPException(status_code=404, detail=f"Unsupported category: {category}") from error

    return model.model_validate(payload).model_dump()


def _ensure_mutations_supported() -> None:
    if IS_VERCEL and getattr(service, "storage_backend", "json") == "json":
        raise HTTPException(
            status_code=501,
            detail=(
                "Write operations are disabled on Vercel because the filesystem is read-only. "
                "Use a persistent database for POST/PUT/DELETE support."
            ),
        )
