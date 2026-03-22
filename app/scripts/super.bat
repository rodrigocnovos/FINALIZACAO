
@echo off
setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "APP_DIR=%SCRIPT_DIR%\.."
for %%I in ("%APP_DIR%") do set "APP_DIR=%%~fI"
set "CONFIG_DIR=%APP_DIR%\config"
set "SCRIPTS_DIR=%APP_DIR%\scripts"
set "PROJECT_ROOT=%APP_DIR%\.."
for %%I in ("%PROJECT_ROOT%") do set "PROJECT_ROOT=%%~fI"
set "REPO_NAME=FINALIZACAO"
set "DEFAULT_BRANCH=main"
set "UPDATE_BRANCH=%DEFAULT_BRANCH%"
set "BRANCH_OVERRIDE_FILE=%CONFIG_DIR%\branch_update.ini"
set "VERSION_FILE_REL=app/config/launcher.version"
set "VERSION_FILE_PATH=%CONFIG_DIR%\launcher.version"
set "WINDOW_TITLE=Launcher FINALIZACAO"

cd /d "%PROJECT_ROOT%"
title %WINDOW_TITLE% - Iniciando
echo [1/5] Iniciando launcher...

call :read_update_branch
set "ZIP_URL=https://github.com/rodrigocnovos/FINALIZACAO/archive/refs/heads/%UPDATE_BRANCH%.zip"
set "RAW_VERSION_URL=https://raw.githubusercontent.com/rodrigocnovos/FINALIZACAO/%UPDATE_BRANCH%/%VERSION_FILE_REL%"
 
set "GIT_EXE=git"
if exist "%APP_DIR%\softwares\PortableGit\bin\git.exe" set "GIT_EXE=%APP_DIR%\softwares\PortableGit\bin\git.exe"

call :read_local_version

if exist "%PROJECT_ROOT%\.git" (
    set "CURRENT_BRANCH=%UPDATE_BRANCH%"
    set "CURRENT_REMOTE="
    set "REMOTE_VERSION="
    title %WINDOW_TITLE% - Verificando Git
    echo [2/5] Verificando versao remota no Git...

    "%GIT_EXE%" -C "%PROJECT_ROOT%" rev-parse --is-inside-work-tree >nul 2>&1
    if errorlevel 1 (
        echo Repositorio Git invalido. Tentando atualizacao por ZIP...
        goto update_from_zip
    )

    for /f "delims=" %%i in ('"%GIT_EXE%" -C "%PROJECT_ROOT%" config --get branch.!CURRENT_BRANCH!.remote 2^>nul') do set "CURRENT_REMOTE=%%i"
    if not defined CURRENT_REMOTE set "CURRENT_REMOTE=origin"

    "%GIT_EXE%" -C "%PROJECT_ROOT%" ls-remote --exit-code "!CURRENT_REMOTE!" >nul 2>&1
    if errorlevel 1 (
        echo Remoto "!CURRENT_REMOTE!" indisponivel. Continuando sem update...
        goto run_script
    )

    "%GIT_EXE%" -C "%PROJECT_ROOT%" fetch "!CURRENT_REMOTE!" --prune >nul 2>&1
    if errorlevel 1 (
        echo Falha ao consultar atualizacoes. Continuando...
        goto run_script
    )

    for /f "usebackq delims=" %%i in (`"%GIT_EXE%" -C "%PROJECT_ROOT%" show "!CURRENT_REMOTE!/!CURRENT_BRANCH!:%VERSION_FILE_REL%" 2^>nul`) do (
        if not defined REMOTE_VERSION set "REMOTE_VERSION=%%i"
    )

    if not defined REMOTE_VERSION (
        echo Arquivo de versao remoto nao encontrado. Continuando sem update...
        goto run_script
    )

    call :normalize_version "!LOCAL_VERSION!" NORMALIZED_LOCAL_VERSION
    call :normalize_version "!REMOTE_VERSION!" NORMALIZED_REMOTE_VERSION
    call :show_versions

    call :is_remote_newer "!NORMALIZED_LOCAL_VERSION!" "!NORMALIZED_REMOTE_VERSION!"
    if errorlevel 1 (
        title %WINDOW_TITLE% - Atualizado
        echo [4/5] Projeto ja esta atualizado.
    ) else (
        title %WINDOW_TITLE% - Aplicando atualizacao Git
        echo [4/5] Nova versao encontrada. Aplicando via Git, aguarde...
        "%GIT_EXE%" -C "%PROJECT_ROOT%" pull --rebase --autostash "!CURRENT_REMOTE!" "!CURRENT_BRANCH!"
        if errorlevel 1 (
            echo Falha ao aplicar atualizacao automatica.
        ) else (
            echo Atualizacao aplicada com sucesso.
        )
    )
) else (
    title %WINDOW_TITLE% - Modo ZIP
    echo [2/5] Pasta sem repositorio Git. Tentando atualizacao por ZIP...
    goto update_from_zip
)

goto run_script

:update_from_zip
set "TEMP_ROOT=%TEMP%\%REPO_NAME%_update_%RANDOM%%RANDOM%"
set "ZIP_FILE=%TEMP_ROOT%\update.zip"
set "EXTRACT_DIR=%TEMP_ROOT%\extract"
set "REMOTE_VERSION_FILE=%TEMP_ROOT%\remote.version"
set "ZIP_ROOT="
set "REMOTE_VERSION="

mkdir "%TEMP_ROOT%" >nul 2>&1
mkdir "%EXTRACT_DIR%" >nul 2>&1

title %WINDOW_TITLE% - Consultando versao remota
echo [2/5] Consultando versao remota, aguarde...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -UseBasicParsing -Uri '%RAW_VERSION_URL%' -OutFile '%REMOTE_VERSION_FILE%' } catch { exit 1 }"
if errorlevel 1 (
    echo Falha ao consultar versao remota. Continuando...
    goto cleanup_and_run
)

for /f "usebackq delims=" %%i in ("%REMOTE_VERSION_FILE%") do (
    if not defined REMOTE_VERSION set "REMOTE_VERSION=%%i"
)

if not defined REMOTE_VERSION (
    echo Arquivo de versao remoto invalido. Continuando...
    goto cleanup_and_run
)

call :normalize_version "!LOCAL_VERSION!" NORMALIZED_LOCAL_VERSION
call :normalize_version "!REMOTE_VERSION!" NORMALIZED_REMOTE_VERSION
call :show_versions

call :is_remote_newer "!NORMALIZED_LOCAL_VERSION!" "!NORMALIZED_REMOTE_VERSION!"
if errorlevel 1 (
    title %WINDOW_TITLE% - Atualizado
    echo [4/5] Projeto ja esta atualizado.
    goto cleanup_and_run
)

title %WINDOW_TITLE% - Baixando atualizacao ZIP
echo [3/5] Nova versao encontrada. Baixando atualizacao por ZIP, aguarde...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -UseBasicParsing -Uri '%ZIP_URL%' -OutFile '%ZIP_FILE%' } catch { exit 1 }"
if errorlevel 1 (
    echo Falha ao baixar atualizacao ZIP. Continuando...
    goto cleanup_and_run
)

title %WINDOW_TITLE% - Extraindo atualizacao ZIP
echo [4/5] Extraindo arquivos da atualizacao...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -Command "try { Expand-Archive -LiteralPath '%ZIP_FILE%' -DestinationPath '%EXTRACT_DIR%' -Force } catch { exit 1 }"
if errorlevel 1 (
    echo Falha ao extrair atualizacao ZIP. Continuando...
    goto cleanup_and_run
)

for /d %%i in ("%EXTRACT_DIR%\*") do if not defined ZIP_ROOT set "ZIP_ROOT=%%~fi"
if not defined ZIP_ROOT (
    echo Conteudo ZIP invalido. Continuando...
    goto cleanup_and_run
)

title %WINDOW_TITLE% - Aplicando atualizacao ZIP
echo [5/5] Aplicando atualizacao por ZIP, aguarde...
robocopy "%ZIP_ROOT%" "%PROJECT_ROOT%" /E /R:2 /W:1 /NFL /NDL /NJH /NJS /NP /XD ".git" >nul
if errorlevel 8 (
    echo Falha ao copiar arquivos da atualizacao ZIP. Continuando...
) else (
    echo Atualizacao ZIP aplicada com sucesso.
)

:cleanup_and_run
if exist "%TEMP_ROOT%" rmdir /s /q "%TEMP_ROOT%" >nul 2>&1

:run_script
title %WINDOW_TITLE% - Executando script principal
echo Executando rotina principal...
PowerShell.exe -ExecutionPolicy Unrestricted -File "%SCRIPTS_DIR%\ENDER.ps1"
goto :eof

:read_local_version
set "LOCAL_VERSION=0.0.0"
if not exist "%VERSION_FILE_PATH%" goto :eof
for /f "usebackq delims=" %%i in ("%VERSION_FILE_PATH%") do (
    if not defined LOCAL_VERSION_FOUND (
        set "LOCAL_VERSION=%%i"
        set "LOCAL_VERSION_FOUND=1"
    )
)
set "LOCAL_VERSION_FOUND="
goto :eof

:read_update_branch
if not exist "%BRANCH_OVERRIDE_FILE%" goto :eof
for /f "usebackq tokens=* delims=" %%i in ("%BRANCH_OVERRIDE_FILE%") do (
    set "BRANCH_OVERRIDE_CANDIDATE=%%i"
    if defined BRANCH_OVERRIDE_CANDIDATE (
        set "BRANCH_OVERRIDE_FIRST_CHAR=!BRANCH_OVERRIDE_CANDIDATE:~0,1!"
        if not "!BRANCH_OVERRIDE_FIRST_CHAR!"=="#" if not "!BRANCH_OVERRIDE_FIRST_CHAR!"==";" if not defined BRANCH_OVERRIDE_LINE (
            set "BRANCH_OVERRIDE_LINE=!BRANCH_OVERRIDE_CANDIDATE!"
        )
    )
)
if not defined BRANCH_OVERRIDE_LINE goto :eof
set "BRANCH_OVERRIDE_LINE=!BRANCH_OVERRIDE_LINE: =!"
if /i "!BRANCH_OVERRIDE_LINE:~0,7!"=="branch=" (
    set "UPDATE_BRANCH=!BRANCH_OVERRIDE_LINE:~7!"
) else (
    set "UPDATE_BRANCH=!BRANCH_OVERRIDE_LINE!"
)
set "BRANCH_OVERRIDE_LINE="
set "BRANCH_OVERRIDE_CANDIDATE="
set "BRANCH_OVERRIDE_FIRST_CHAR="
goto :eof

:normalize_version
set "%~2=%~1"
if not defined %~2 set "%~2=0.0.0"
goto :eof

:show_versions
echo [3/5] Versao local: !LOCAL_VERSION! ^| versao remota: !REMOTE_VERSION!
goto :eof

:is_remote_newer
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$local='%~1'; $remote='%~2'; try { if ([version]$remote -gt [version]$local) { exit 0 } else { exit 1 } } catch { exit 1 }"
goto :eof
