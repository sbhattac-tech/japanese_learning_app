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

if not exist "%APP_DIR%" (
  echo Flutter app folder was not found:
  echo   %APP_DIR%
  exit /b 1
)

pushd "%APP_DIR%"
call "%FLUTTER_BIN%" create .
if errorlevel 1 (
  popd
  exit /b 1
)

call "%FLUTTER_BIN%" pub get
set "EXIT_CODE=%ERRORLEVEL%"
popd

if not "%EXIT_CODE%"=="0" exit /b %EXIT_CODE%

echo.
echo Flutter app setup complete.
echo You can now run:
echo   run_flutter_app.bat
exit /b 0
