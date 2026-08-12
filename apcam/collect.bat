@echo off
rem APCAM - collect.bat
rem
rem Thin wrapper so refresh.ps1 (running on another machine, over ssh) can
rem trigger a collect.ps1 run here without any of PowerShell's -Command /
rem cmd.exe quoting hazards - a bare path to this file is the whole remote
rem command, nothing for either shell to misparse. %~dp0 resolves collect.ps1
rem next to wherever this batch file itself was deployed, so this works
rem unmodified on any machine apcam is copied to.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0collect.ps1"
