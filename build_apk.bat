@echo off
setlocal

set "ROOT=%~dp0"
set "FLUTTER_BIN=C:\Users\sbssj\Downloads\flutter\bin\flutter.bat"
set "APP_DIR=%ROOT%mobile_app"
set "TEMP_BUILD_ROOT=C:\temp\tango_mobile_app_build"
set "JBR_DIR=C:\Program Files\Android\Android Studio\jbr"
set "API_BASE_URL=%~1"
set "BUILD_MODE=%~2"

if "%API_BASE_URL%"=="" set "API_BASE_URL=https://sourcecode-production.up.railway.app"

if not exist "%FLUTTER_BIN%" (
  echo Flutter was not found at:
  echo   %FLUTTER_BIN%
  echo.
  echo Update FLUTTER_BIN inside this file if your Flutter path changes.
  exit /b 1
)

if not exist "%JBR_DIR%\bin\java.exe" (
  echo Java 17+ runtime was not found at:
  echo   %JBR_DIR%
  echo.
  echo Install Android Studio or update JBR_DIR inside this file.
  exit /b 1
)

set "JAVA_HOME=%JBR_DIR%"
set "PATH=%JAVA_HOME%\bin;%PATH%"

if /I "%BUILD_MODE%"=="--clean" (
  if exist "%TEMP_BUILD_ROOT%" rmdir /s /q "%TEMP_BUILD_ROOT%"
)

if not exist "%TEMP_BUILD_ROOT%" mkdir "%TEMP_BUILD_ROOT%"

robocopy "%APP_DIR%" "%TEMP_BUILD_ROOT%" /MIR /XD build .dart_tool .idea >nul
set "ROBOCOPY_EXIT=%ERRORLEVEL%"
if %ROBOCOPY_EXIT% GEQ 8 (
  echo Failed to mirror project to temp build directory.
  echo Robocopy exit code: %ROBOCOPY_EXIT%
  exit /b %ROBOCOPY_EXIT%
)

pushd "%TEMP_BUILD_ROOT%"
call "%FLUTTER_BIN%" pub get
if errorlevel 1 (
  popd
  exit /b 1
)

call "%FLUTTER_BIN%" build apk --release --dart-define=API_BASE_URL=%API_BASE_URL%
set "EXIT_CODE=%ERRORLEVEL%"
popd

if not "%EXIT_CODE%"=="0" exit /b %EXIT_CODE%

if not exist "%ROOT%mobile_app\release_artifacts" mkdir "%ROOT%mobile_app\release_artifacts"
copy /Y "%TEMP_BUILD_ROOT%\build\app\outputs\flutter-apk\app-release.apk" "%ROOT%mobile_app\release_artifacts\app-release.apk" >nul
if errorlevel 1 (
  echo Build succeeded but failed to copy APK to workspace.
  exit /b 1
)

echo.
echo APK build complete.
echo Output:
echo   %ROOT%mobile_app\release_artifacts\app-release.apk
echo API_BASE_URL used:
echo   %API_BASE_URL%
if /I "%BUILD_MODE%"=="--clean" (
  echo Temp build cache reset:
  echo   yes
)
exit /b 0
