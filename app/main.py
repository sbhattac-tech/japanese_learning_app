from __future__ import annotations

import logging
import mimetypes
import os
from contextlib import asynccontextmanager
from typing import Any, Literal

from fastapi import FastAPI, File, Form, HTTPException, Query, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
try:
    from dotenv import load_dotenv
except ImportError:  # pragma: no cover - optional local convenience dependency
    def load_dotenv() -> bool:
        return False

from app.database_service import DatabaseService
from app.gemini_import_service import GeminiImportError, GeminiImportService
from app.import_models import ImportCandidate, ImportExtractResponse, ImportSaveRequest, ImportSetSummary
from app.import_service import ImportService
from app.ocr_service import OcrDependencyError, OcrService
from app.service_factory import create_database_service


load_dotenv()


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
    kanji: str | None = None
    hiragana: str | None = None
    katakana: str | None = None
    part_of_speech: str | None = None
    source_text: str | None = None
    source_language: str | None = None
    set_name: str | None = None


class CzechVocabularyPayload(BaseModel):
    english: str
    czech: str
    notes: str = ""
    part_of_speech: str
    category: str
    set_name: str | None = None


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
gemini_import_service = GeminiImportService()
import_service = ImportService(service)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(_: FastAPI):
    _bootstrap_postgres_if_needed()
    yield

app = FastAPI(
    title="Cognita API",
    version="1.0.0",
    description="Multi-language learning API for Cognita.",
    lifespan=lifespan,
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
        "message": "Cognita API",
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
    target_category: str = Form(default="japanese_vocabulary"),
) -> ImportExtractResponse:
    if target_category != "japanese_vocabulary":
        raise HTTPException(
            status_code=400,
            detail="Image import currently supports only the japanese_vocabulary category.",
        )

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Uploaded image is empty")

    if gemini_import_service.is_configured:
        try:
            mime_type = _resolve_image_mime_type(file.content_type, file.filename)
            entries = gemini_import_service.extract_candidates(
                image_bytes,
                mime_type=mime_type,
            )
        except GeminiImportError as error:
            logger.warning("Gemini import failed, falling back to local OCR: %s", error)
            try:
                tokens = ocr_service.extract_candidates(image_bytes)
            except OcrDependencyError as ocr_error:
                raise HTTPException(
                    status_code=503,
                    detail=(
                        "Image extraction could not complete. Gemini was unavailable and "
                        "local OCR is not configured on the server."
                    ),
                ) from ocr_error
            except ValueError as value_error:
                raise HTTPException(status_code=400, detail=str(value_error)) from value_error

            entries = import_service.build_candidates(tokens)
    else:
        try:
            tokens = ocr_service.extract_candidates(image_bytes)
        except OcrDependencyError as error:
            raise HTTPException(status_code=503, detail=str(error)) from error
        except ValueError as error:
            raise HTTPException(status_code=400, detail=str(error)) from error

        entries = import_service.build_candidates(tokens)

    available_sets = [item["name"] for item in import_service.list_import_sets()]
    return ImportExtractResponse(entries=entries, available_sets=available_sets)


@app.get("/imports/sets", response_model=list[ImportSetSummary])
def list_import_sets() -> list[ImportSetSummary]:
    return [ImportSetSummary.model_validate(item) for item in import_service.list_import_sets()]


@app.post("/imports/image/save", status_code=201)
def save_imported_entries(payload: ImportSaveRequest) -> dict[str, Any]:
    _ensure_mutations_supported()
    set_name = payload.set_name.strip()

    cleaned_entries = []
    for entry in payload.entries:
        candidate = entry.model_dump()
        kana = (
            candidate["hiragana"].strip()
            or candidate["katakana"].strip()
            or candidate["japanese_text"].strip()
            or candidate["kanji"].strip()
        )
        validated = _validate_payload(
            "japanese_vocabulary",
            {
                "romaji": candidate["romaji"].strip(),
                "kana": kana,
                "meaning": candidate["meaning"].strip(),
                "category": candidate["category"].strip() or "imported",
                "kanji": candidate["kanji"].strip() or None,
                "hiragana": candidate["hiragana"].strip() or None,
                "katakana": candidate["katakana"].strip() or None,
                "part_of_speech": candidate["part_of_speech"].strip() or None,
                "source_text": candidate["source_text"].strip() or None,
                "source_language": candidate["source_language"].strip() or None,
                "set_name": entry.set_name.strip() or set_name or None,
            },
        )
        cleaned_entries.append(validated)

    if not cleaned_entries:
        raise HTTPException(status_code=400, detail="No entries were provided for import")

    try:
        created = service.create_entries("japanese_vocabulary", cleaned_entries)
    except ValueError as error:
        raise HTTPException(status_code=400, detail=str(error)) from error

    return {"created": created, "count": len(created)}


def _validate_payload(category: str, payload: dict[str, Any]) -> dict[str, Any]:
    model_map = {
        "czech_vocabulary": CzechVocabularyPayload,
        "czech_adjectives": CzechVocabularyPayload,
        "czech_verbs": CzechVocabularyPayload,
        "japanese_verbs": VerbPayload,
        "japanese_adjectives": AdjectivePayload,
        "japanese_vocabulary": VocabularyPayload,
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


def _resolve_image_mime_type(content_type: str | None, filename: str | None) -> str:
    provided = (content_type or "").strip().lower()
    if provided.startswith("image/") and provided != "image/*":
        return provided

    guessed, _ = mimetypes.guess_type(filename or "")
    if guessed and guessed.startswith("image/"):
        return guessed

    return "image/jpeg"


def _ensure_mutations_supported() -> None:
    return None


def _bootstrap_postgres_if_needed() -> None:
    should_bootstrap = os.getenv("BOOTSTRAP_DATABASE", "true").strip().lower() not in {
        "0",
        "false",
        "no",
    }
    if not should_bootstrap:
        return

    if getattr(service, "storage_backend", "json") != "postgres":
        return

    raw_categories = os.getenv("BOOTSTRAP_CATEGORIES")
    categories = None
    if raw_categories:
        categories = [item.strip() for item in raw_categories.split(",") if item.strip()]

    inserted = service.bootstrap_from_json_service(
        DatabaseService(),
        categories=categories,
    )
    if inserted:
        logger.info("Bootstrapped Postgres from JSON source files: %s", inserted)
