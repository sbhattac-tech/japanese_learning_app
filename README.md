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

## Notes

- `demonstratives` are stored in grouped form inside `database/demonstrative.json`
- the source file `database/kangi.json` is exposed by the API as the `kanji` category
- after every write operation, the API regenerates `database/japanese_database.json`

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
flutter run --dart-define=API_BASE_URL=https://your-project.vercel.app
```
