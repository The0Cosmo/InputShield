@echo off
setlocal
set "SCRIPT=%~dp0Install-InputShield.ps1"
if not exist "%SCRIPT%" (echo Installer script missing: "%SCRIPT%" & pause & exit /b 1)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
if errorlevel 1 pause
