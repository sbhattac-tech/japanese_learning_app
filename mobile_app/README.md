# Flutter Mobile App

This folder contains the Flutter client for the Japanese learning app.

## Setup

1. Install Flutter.
2. Open a terminal in `mobile_app`.
3. Generate the native project files:

```powershell
flutter create .
```

4. Get packages:

```powershell
flutter pub get
```

5. Start the FastAPI backend from the project root:

```powershell
python -m uvicorn app.main:app --reload
```

6. Run the Flutter app:

```powershell
flutter run
```

## Backend URL

The app uses `http://10.0.2.2:8000` by default for the Android emulator.

If you run on a physical device, update `baseUrl` in `lib/config/app_config.dart` to your computer's local IP address.

## Screens

- Home
- Flashcards
- Quiz
- Matching
