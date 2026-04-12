from __future__ import annotations

import base64
import json
import os
from typing import Any
from urllib import error, request

from app.import_models import ImportCandidate


class GeminiImportError(RuntimeError):
    """Raised when Gemini extraction fails."""


class GeminiImportService:
    def __init__(self, api_key: str | None = None, model: str = "gemini-2.5-flash") -> None:
        self._api_key = (api_key or os.getenv("GEMINI_API_KEY", "")).strip()
        self._model = os.getenv("GEMINI_MODEL", model).strip() or model

    @property
    def is_configured(self) -> bool:
        return bool(self._api_key)

    def extract_candidates(self, image_bytes: bytes, mime_type: str = "image/jpeg") -> list[ImportCandidate]:
        if not self.is_configured:
            raise GeminiImportError("Gemini import is not configured.")

        payload = {
            "contents": [
                {
                    "parts": [
                        {"text": self._prompt()},
                        {
                            "inline_data": {
                                "mime_type": mime_type,
                                "data": base64.b64encode(image_bytes).decode("ascii"),
                            }
                        },
                    ]
                }
            ],
            "generationConfig": {
                "response_mime_type": "application/json",
                "response_json_schema": self._schema(),
            },
        }

        endpoint = (
            "https://generativelanguage.googleapis.com/v1beta/models/"
            f"{self._model}:generateContent?key={self._api_key}"
        )
        req = request.Request(
            endpoint,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )

        try:
            with request.urlopen(req, timeout=60) as response:
                raw = json.loads(response.read().decode("utf-8"))
        except error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")
            raise GeminiImportError(f"Gemini request failed: {detail}") from exc
        except error.URLError as exc:
            raise GeminiImportError(f"Gemini request failed: {exc.reason}") from exc

        text = self._extract_text_response(raw)
        try:
            parsed = json.loads(text)
        except json.JSONDecodeError as exc:
            raise GeminiImportError("Gemini returned invalid JSON.") from exc

        entries = parsed.get("entries", [])
        return [ImportCandidate.model_validate(item) for item in entries]

    def _extract_text_response(self, payload: dict[str, Any]) -> str:
        candidates = payload.get("candidates", [])
        if not candidates:
            raise GeminiImportError("Gemini returned no candidates.")

        parts = candidates[0].get("content", {}).get("parts", [])
        text_parts = [part.get("text", "") for part in parts if isinstance(part, dict)]
        text = "".join(text_parts).strip()
        if not text:
            raise GeminiImportError("Gemini returned an empty response.")
        return text

    def _prompt(self) -> str:
        return (
            "Extract study words or short phrases from this notes photo. The notes may contain handwritten "
            "or typed Japanese and/or English. Return only real visible study items from the image, deduplicated. "
            "For each item, provide source_text, source_language (english, japanese, romaji, mixed, unknown), "
            "normalized_text, japanese_text, hiragana, katakana, kanji, romaji, meaning, part_of_speech "
            "(verb, adjective, vocabulary, adverb, expression, etc.), category (topic like food, school, weather, "
            "imported), matched_category (leave empty if unknown), and set_name as an empty string. "
            "If a field is not applicable, return an empty string. Prefer accurate Japanese readings and translations."
        )

    def _schema(self) -> dict[str, Any]:
        string_field = {"type": "string"}
        return {
            "type": "object",
            "properties": {
                "entries": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "source_text": string_field,
                            "source_language": string_field,
                            "normalized_text": string_field,
                            "romaji": string_field,
                            "japanese_text": string_field,
                            "hiragana": string_field,
                            "katakana": string_field,
                            "kanji": string_field,
                            "meaning": string_field,
                            "part_of_speech": string_field,
                            "category": string_field,
                            "matched_category": string_field,
                            "set_name": string_field,
                        },
                        "required": [
                            "source_text",
                            "source_language",
                            "normalized_text",
                            "romaji",
                            "japanese_text",
                            "hiragana",
                            "katakana",
                            "kanji",
                            "meaning",
                            "part_of_speech",
                            "category",
                            "matched_category",
                            "set_name",
                        ],
                    },
                }
            },
            "required": ["entries"],
        }
