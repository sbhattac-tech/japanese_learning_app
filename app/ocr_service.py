from __future__ import annotations

import io
import re
from collections import OrderedDict


JAPANESE_TOKEN_PATTERN = re.compile(r"[一-龯々ぁ-んァ-ヶー]+")


class OcrDependencyError(RuntimeError):
    """Raised when OCR dependencies are not available."""


class OcrService:
    def extract_candidates(self, image_bytes: bytes) -> list[str]:
        text = self._extract_text(image_bytes)
        tokens = JAPANESE_TOKEN_PATTERN.findall(text)
        unique_tokens = list(OrderedDict.fromkeys(token.strip() for token in tokens if token.strip()))
        return unique_tokens

    def _extract_text(self, image_bytes: bytes) -> str:
        try:
            from PIL import Image
            import pytesseract
        except ImportError as error:
            raise OcrDependencyError(
                "OCR dependencies are missing. Install pillow and pytesseract, and ensure "
                "the Tesseract OCR binary is available on your machine."
            ) from error

        try:
            image = Image.open(io.BytesIO(image_bytes))
        except Exception as error:  # pragma: no cover - defensive parsing
            raise ValueError("Uploaded file is not a valid image") from error

        return pytesseract.image_to_string(image, lang="jpn")
