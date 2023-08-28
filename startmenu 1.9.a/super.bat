
cd %curpath%


REM @echo "Desativando o UAC temporariamente"

REM "elevate.exe -c reg ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f"


@echo "Adicionando informações do suporte"

elevate.exe -c reg import logowin10.reg
copy oemlogo.bmp %SYSTEMDRIVE%\Users\Public\Pictures  /Y

REM PERCORRE O ARQUIVO block_programas.txt PARA BARRAR COMUNICAÇÃO
for /F "tokens=*" %%i in (block_programas.txt) do elevate.exe -c netsh advfirewall firewall add rule name="FechaAtivacao" dir=out action=block  enable=yes program=%%i

@echo "Desativando update do Office"
elevate.exe -c reg import disble_office_updates.reg

REM @echo "Reativando o UAC"

REM "elevate.exe -c reg ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 1 /f"

@echo "Limpando acesso rapido"
del /F /Q %APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\*
del /F /Q %APPDATA%\Microsoft\Windows\Recent\CustomDestinations\*
del /F /Q %APPDATA%\Microsoft\Windows\Recent\*

@echo "Adicionando EXCLUSOES DEFENDER"
PowerShell.exe -ExecutionPolicy Unrestricted -File seu_block.ps1
PowerShell.exe -ExecutionPolicy Unrestricted -File limpeza.ps1
Powershell.exe -ExecutionPolicy Unrestricted -File defender_exclusion.ps1
Powershell.exe -ExecutionPolicy Unrestricted -File restorepoint.ps1