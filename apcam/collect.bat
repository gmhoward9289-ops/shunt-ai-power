@echo off
rem APCAM - collect.bat
rem
rem Thin wrapper so refresh.ps1 (running on another machine, over ssh) can
rem trigger a collect.ps1 run here without any of PowerShell's -Command /
rem cmd.exe quoting hazards - a bare path to this file is the whole remote
rem command, nothing for either shell to misparse. %~dp0 resolves collect.ps1
rem next to wherever this batch file itself was deployed, so this works
rem unmodified on any machine apcam is copied to.
rem
rem Extra arguments pass straight through to collect.ps1, so a caller can say
rem e.g. "collect.bat -LogDir Z:\ollama\logs" when the machine's ollama serve
rem logs somewhere other than the desktop-app default. Keep such arguments
rem free of spaces and quotes - they cross the same two shells the bare path
rem was designed to survive.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0collect.ps1" %*
