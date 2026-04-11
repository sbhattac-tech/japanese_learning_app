@echo off
setlocal

set "ROOT=%~dp0"
set "FLUTTER_BIN=C:\Users\sbssj\Downloads\flutter\bin\flutter.bat"
set "APP_DIR=%ROOT%mobile_app"

if not exist "%FLUTTER_BIN%" (
  echo Flutter was not found at:
  echo   %FLUTTER_BIN%
  echo.
  echo Update FLUTTER_BIN inside this file if your Flutter path changes.
  exit /b 1
)

pushd "%APP_DIR%"
call "%FLUTTER_BIN%" pub get
if errorlevel 1 (
  popd
  exit /b 1
)

call "%FLUTTER_BIN%" build apk
set "EXIT_CODE=%ERRORLEVEL%"
popd

if not "%EXIT_CODE%"=="0" exit /b %EXIT_CODE%

echo.
echo APK build complete.
echo Output:
echo   %ROOT%mobile_app\build\app\outputs\flutter-apk\app-release.apk
exit /b 0
