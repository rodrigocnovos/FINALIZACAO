# Limpar cache do Internet Explorer
Clear-DnsClientCache
Clear-TemporaryInternetFiles -Confirm:$false

# Limpar cache do Microsoft Edge
Start-Process msedge.exe -ArgumentList "--clear-activities"

# Limpar histórico de pesquisa no Explorador de Arquivos
Clear-RecycleBin -Force
Remove-Item "$env:USERPROFILE\AppData\Local\Microsoft\Windows\Explorer\thumbcache_*" -Force

# Limpar cache de aplicativos do Windows
$packageCleanupArgs = @('/StartComponentCleanup', '/ResetBase')
Start-Process -Wait -FilePath dism.exe -ArgumentList $packageCleanupArgs

# Limpar cache do Windows Update
Start-Process -Wait -FilePath cleanmgr.exe -ArgumentList "/sagerun:1"

# Limpar cache de execução do PowerShell
$env:TEMP = [System.IO.Path]::GetTempPath()
Remove-Item "$env:TEMP\*" -Force -Recurse

# Limpar histórico do Chrome
$chromeHistoryPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History"
Stop-Process -Name chrome -Force
Remove-Item -Path $chromeHistoryPath -Force -ErrorAction SilentlyContinue

# Limpar histórico do Firefox
$firefoxHistoryPath = "$env:APPDATA\Mozilla\Firefox\Profiles\*.default-release\places.sqlite"
Stop-Process -Name firefox -Force
Remove-Item -Path $firefoxHistoryPath -Force -ErrorAction SilentlyContinue

# "Limpando acesso rapido"
Remove-Item -Path %APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\* -Force -ErrorAction SilentlyContinue
Remove-Item -Path %APPDATA%\Microsoft\Windows\Recent\CustomDestinations\* -Force -ErrorAction SilentlyContinue
Remove-Item -Path %APPDATA%\Microsoft\Windows\Recent\* -Force -ErrorAction SilentlyContinue

#Limpando update
Remove-Item -Path "C:\Windows\SoftwareDistribution" * -Force -Recurse -ErrorAction SilentlyContinue

#Caminho para o desktop do usuário corrente
$desktopPath = [Environment]::GetFolderPath("Desktop")
Remove-Item $desktopPath\* -Force -Recurse

# Excluir arquivos do desktop público
$publicDesktopPath = [System.Environment]::GetFolderPath("CommonDesktopDirectory")
Remove-Item "$publicDesktopPath\*" -Force -Recurse



# Obter o caminho da pasta do usuário que fez login no sistema
$userProfilePath = [System.Environment]::GetEnvironmentVariable('USERPROFILE')

# Limpar a pasta de Downloads do usuário corrente
$downloadsPath = Join-Path $userProfilePath 'Downloads'
Remove-Item -Path $downloadsPath\* -Force -Recurse

# Limpar a pasta de Documentos do usuário corrente
$documentsPath = Join-Path $userProfilePath 'Documents'
Remove-Item -Path $documentsPath\* -Force -Recurse

Clear-Host
Write-Host "Limpeza concluída."
