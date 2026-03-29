from __future__ import annotations

import argparse

from app.database_service import DatabaseService
from app.postgres_service import PostgresDatabaseService


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Bootstrap Supabase/Postgres from the local JSON database files.",
    )
    parser.add_argument("--database-url", required=True, help="Supabase/Postgres connection string")
    parser.add_argument(
        "--overwrite",
        action="store_true",
        help="Delete existing rows in the entries table before importing.",
    )
    args = parser.parse_args()

    json_service = DatabaseService()
    postgres_service = PostgresDatabaseService(args.database_url)
    inserted = postgres_service.bootstrap_from_json_service(
        json_service,
        overwrite=args.overwrite,
    )

    if not inserted:
        print("Postgres already contains data. Use --overwrite to replace it.")
        return

    for category, count in inserted.items():
        print(f"{category}: {count}")


if __name__ == "__main__":
    main()
