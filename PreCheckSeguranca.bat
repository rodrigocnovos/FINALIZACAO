@echo off
setlocal EnableExtensions
set "ROOT_DIR=%~dp0"
for %%I in ("%ROOT_DIR%.") do set "ROOT_DIR=%%~fI"
if "%ROOT_DIR:~-1%"=="\" set "ROOT_DIR=%ROOT_DIR:~0,-1%"

PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT_DIR%\PreCheckSeguranca.ps1"
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
    echo.
    echo Falha ao iniciar o pre-check de seguranca. Codigo: %EXIT_CODE%
    pause
)

exit /b %EXIT_CODE%
