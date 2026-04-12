@echo off
setlocal

set "ROOT_SCRIPT=%~dp0..\build_apk.bat"
if not exist "%ROOT_SCRIPT%" (
  echo Could not find root build script:
  echo   %ROOT_SCRIPT%
  exit /b 1
)

call "%ROOT_SCRIPT%" %*
exit /b %ERRORLEVEL%
