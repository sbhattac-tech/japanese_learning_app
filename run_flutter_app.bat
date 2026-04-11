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
call "%FLUTTER_BIN%" run
set "EXIT_CODE=%ERRORLEVEL%"
popd

exit /b %EXIT_CODE%
