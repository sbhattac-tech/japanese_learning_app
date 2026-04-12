# Tango Backend

This project uses a split architecture:

- `vocabulary`, `adjectives`, and `verbs` are served by FastAPI and stored in PostgreSQL
- `kanji`, `hiragana`, and `katakana` are bundled into the Flutter app as offline assets

That means the Android APK/AAB can use kana and kanji study modes without internet, while editable study content lives in Postgres.

## Backend categories

The Postgres-backed API supports these categories:

- `vocabulary`
- `adjectives`
- `verbs`

## Local run

Install dependencies:

```powershell
python -m pip install -r requirements.txt
```

Start the API:

```powershell
uvicorn app.main:app --reload
```

Then open:

- `http://127.0.0.1:8000/docs`
- `http://127.0.0.1:8000/health`

## Railway deployment

The root [Dockerfile](./Dockerfile) deploys the FastAPI backend to Railway.

Create a Railway project with:

- one app service from this repo
- one PostgreSQL service

Set these variables on the app service:

```text
DATABASE_URL=${{Postgres.DATABASE_URL}}
BOOTSTRAP_DATABASE=true
BOOTSTRAP_CATEGORIES=vocabulary,adjectives,verbs
GEMINI_API_KEY=your_gemini_api_key
GEMINI_MODEL=gemini-2.5-flash
```

`GEMINI_API_KEY` enables Gemini-based image import extraction at `POST /imports/image/extract`.
If the key is not set, the backend falls back to local OCR.

On the first deploy, Railway Postgres will be seeded from:

- `database/vocabulary.json`
- `database/adjectives.json`
- `database/verbs.json`

## Manual Postgres import

You can import the three JSON datasets manually with:

```powershell
python scripts/sync_json_to_postgres.py --database-url "YOUR_DATABASE_URL" --categories vocabulary adjectives verbs
```

To replace existing data:

```powershell
python scripts/sync_json_to_postgres.py --database-url "YOUR_DATABASE_URL" --categories vocabulary adjectives verbs --overwrite
```

## Mobile app

The Flutter app bundles these files into the APK/AAB:

- `mobile_app/assets/data/hiragana.json`
- `mobile_app/assets/data/katakana.json`
- `mobile_app/assets/data/kanji.json`

Those are loaded locally for offline study.

Build Android against the Railway API with:

```powershell
cd mobile_app
flutter build apk --release --dart-define=API_BASE_URL=https://your-service.up.railway.app
```

Or run the root script (uses Android Studio JBR automatically and defaults to production API URL):

```powershell
./build_apk.bat
```

Pass a custom API URL:

```powershell
./build_apk.bat https://your-service.up.railway.app
```

Optional clean build:

```powershell
./build_apk.bat https://your-service.up.railway.app --clean
```

or:

```powershell
cd mobile_app
flutter build appbundle --release --dart-define=API_BASE_URL=https://your-service.up.railway.app
```
