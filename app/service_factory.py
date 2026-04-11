from __future__ import annotations

import os

from app.database_service import DatabaseService


def create_database_service() -> DatabaseService:
    database_url = os.getenv("DATABASE_URL")
    if database_url:
        from app.postgres_service import PostgresDatabaseService

        return PostgresDatabaseService(database_url)
    return DatabaseService()
