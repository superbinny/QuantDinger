@echo off
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -File ".\start-quantdinger.ps1" %*
pause
