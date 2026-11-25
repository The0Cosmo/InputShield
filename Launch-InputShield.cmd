@echo off
setlocal
set "SCRIPT=%~dp0src\InputShield.App.ps1"
if not exist "%SCRIPT%" (
  echo InputShield application source not found: "%SCRIPT%"
  pause
  exit /b 1
)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -STA -File "%SCRIPT%"
