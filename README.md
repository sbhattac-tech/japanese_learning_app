# Japanese Learning App API

This project now includes a FastAPI backend for managing the JSON database.

## What it does

- reads entries from the editable source files in `database/`
- supports create, read, update, and delete operations
- rebuilds `database/japanese_database.json` automatically after changes
- exposes interactive API docs at `/docs`

## Install

```powershell
python -m pip install -r requirements.txt
```

## Run

```powershell
uvicorn app.main:app --reload
```

Then open:

- `http://127.0.0.1:8000/docs`
- `http://127.0.0.1:8000/health`

## Categories

- `verbs`
- `adjectives`
- `vocabulary`
- `kanji`
- `hiragana`
- `katakana`
- `demonstratives`

## Example endpoints

- `GET /entries/verbs`
- `GET /entries/verbs/1`
- `POST /entries/vocabulary`
- `PUT /entries/adjectives/3`
- `DELETE /entries/kanji/2`
- `GET /database`
- `POST /imports/image/extract`
- `POST /imports/image/save`

## Notes

- `demonstratives` are stored in grouped form inside `database/demonstrative.json`
- the source file `database/kangi.json` is exposed by the API as the `kanji` category
- after every write operation, the API regenerates `database/japanese_database.json`
- image import currently saves reviewed entries into `database/vocabulary.json`
- OCR requires `pillow`, `pytesseract`, `python-multipart`, and a local Tesseract OCR installation with Japanese language data available

## Deploy API To Vercel

This repository is configured for Vercel with:

- `api/index.py` (serverless entry point)
- `vercel.json` (route all requests to FastAPI)

### One-time setup

```powershell
npm i -g vercel
vercel login
```

### Deploy

Run from the project root:

```powershell
vercel
```

For production:

```powershell
vercel --prod
```

### Important limitation

Vercel Python functions use a read-only filesystem, so JSON file writes are not persistent.
In this project, `POST`, `PUT`, and `DELETE` endpoints return `501` on Vercel.

Use a persistent database (for example Supabase, Neon, or PostgreSQL) if you want write support in production.

### Use deployed API from Flutter

Pass your deployed API URL at runtime:

```powershell
flutter run --dart-define=API_BASE_URL=https://japanese-learning-app-pearl.vercel.app
flutter build apk --release --dart-define=API_BASE_URL=https://japanese-learning-app-pearl.vercel.app
```

## Use Supabase For Persistent Writes

If you want create, update, delete, and image-save changes to persist in production, use Supabase Postgres instead of JSON file storage.

### How it works

- if `DATABASE_URL` is set, FastAPI uses Postgres automatically
- if `DATABASE_URL` is not set, FastAPI falls back to the local JSON files in `database/`
- the API routes stay the same while the storage backend changes underneath

### Set up Supabase

1. Create a Supabase project.
2. Copy the Postgres connection string from your Supabase project settings.
3. Set it as `DATABASE_URL` locally and in Vercel project environment variables.

Example local PowerShell session:

```powershell
$env:DATABASE_URL="postgresql://postgres:<password>@<host>:5432/postgres?sslmode=require"
uvicorn app.main:app --reload
```

### Import existing JSON data into Supabase

Run this from the project root:

```powershell
python scripts/sync_json_to_postgres.py --database-url "postgresql://postgres:<password>@<host>:5432/postgres?sslmode=require"
```

To replace everything already in Postgres:

```powershell
python scripts/sync_json_to_postgres.py --database-url "postgresql://postgres:<password>@<host>:5432/postgres?sslmode=require" --overwrite
```

### Deploy with Supabase on Vercel

1. Add `DATABASE_URL` in your Vercel project environment variables.
2. Redeploy the API.
3. FastAPI will use Postgres-backed persistent CRUD automatically.

### Important OCR note

Supabase solves the persistence problem, but not the OCR runtime problem.
The current image text extraction uses local Tesseract OCR via `pytesseract`, so `POST /imports/image/extract` still requires a host environment where Tesseract and Japanese language data are installed.

supabase2693899890SB.ssj4
postgresql://postgres.dfizmjouwjxiwlaykcpy:supabase2693899890SB.ssj4@aws-1-eu-west-1.pooler.supabase.com:5432/postgres