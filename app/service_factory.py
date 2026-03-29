from __future__ import annotations

import os

from app.database_service import DatabaseService
from app.postgres_service import PostgresDatabaseService


def create_database_service() -> DatabaseService | PostgresDatabaseService:
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        return PostgresDatabaseService(database_url)
    return DatabaseService()
