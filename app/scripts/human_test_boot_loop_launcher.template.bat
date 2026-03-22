@echo off
setlocal EnableExtensions

set "PROMPT_SCRIPT_PATH=__PROMPT_SCRIPT_PATH__"
set "SCRIPT_PATH=__SCRIPT_PATH__"
set "WINDOW_TITLE=FINALIZACAO - Loop Teste Humano"

title %WINDOW_TITLE%
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PROMPT_SCRIPT_PATH%"

if "%ERRORLEVEL%"=="6" (
    del "%~f0" >nul 2>&1
    exit /b 0
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%"
exit /b %ERRORLEVEL%
