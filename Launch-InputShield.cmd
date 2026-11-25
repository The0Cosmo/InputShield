@echo off
setlocal
set "SCRIPT=%~dp0src\InputShield.Modern.ps1"
if not exist "%SCRIPT%" (echo Missing: "%SCRIPT%" & pause & exit /b 1)
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -STA -File "%SCRIPT%"
