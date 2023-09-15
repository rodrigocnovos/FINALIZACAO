# # Limpar cache do Internet Explorer
# Clear-DnsClientCache
# Clear-TemporaryInternetFiles -Confirm:$false

# # Limpar cache do Microsoft Edge
# Start-Process msedge.exe -ArgumentList "--clear-activities"

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

# # Limpar histórico do Chrome
# $chromeHistoryPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History"
# Stop-Process -Name chrome -Force
# Remove-Item -Path $chromeHistoryPath -Force -ErrorAction SilentlyContinue

### CLEAN CHROME
# Fecha todas as instâncias abertas do Google Chrome
Get-Process -Name chrome | ForEach-Object { $_.CloseMainWindow() }

# Aguarda alguns segundos para garantir que todas as instâncias sejam encerradas
Start-Sleep -Seconds 5

# Limpa o cache de navegação do Chrome
$cachePath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData) + "\Google\Chrome\User Data\Default\Cache"
Remove-Item -Path $cachePath\* -Force -Recurse

# Limpa os cookies do Chrome
$cookiesPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData) + "\Google\Chrome\User Data\Default\Cookies"
Remove-Item -Path $cookiesPath -Force

# Limpa o histórico de navegação do Chrome
$historyPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData) + "\Google\Chrome\User Data\Default\History"
Remove-Item -Path $historyPath -Force

# Limpa os downloads
$downloadsPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments) + "\Downloads"
Remove-Item -Path $downloadsPath\* -Force -Recurse

# Reinicia o Google Chrome
#Start-Process chrome

#Write-Host "Limpeza de dados de navegação do Google Chrome concluída com sucesso."

######


### CLEAN EDGE
# Fecha todas as instâncias abertas do Microsoft Edge
Get-Process -Name MicrosoftEdge | ForEach-Object { $_.CloseMainWindow() }

# Aguarda alguns segundos para garantir que todas as instâncias sejam encerradas
Start-Sleep -Seconds 5

# Limpa o cache de navegação
$cachePath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::InternetCache)
Remove-Item -Path $cachePath\* -Force -Recurse

# Limpa os cookies do Microsoft Edge
$cookiesPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Cookies)
Remove-Item -Path $cookiesPath\* -Force -Recurse

# Limpa o histórico de navegação
$historyPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::History)
Remove-Item -Path $historyPath\* -Force -Recurse

# Limpa os downloads
$downloadsPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments) + "\Downloads"
Remove-Item -Path $downloadsPath\* -Force -Recurse

# Reinicia o Microsoft Edge
#Start-Process microsoft-edge

#Write-Host "Limpeza de dados de navegação do Microsoft Edge concluída com sucesso."

####



# # Limpar histórico do Firefox
# $firefoxHistoryPath = "$env:APPDATA\Mozilla\Firefox\Profiles\*.default-release\places.sqlite"
# Stop-Process -Name firefox -Force
# Remove-Item -Path $firefoxHistoryPath -Force -ErrorAction SilentlyContinue


####CLENA FIREFOX
# Fecha todas as instâncias abertas do Mozilla Firefox
Get-Process -Name firefox | ForEach-Object { $_.CloseMainWindow() }

# Aguarda alguns segundos para garantir que todas as instâncias sejam encerradas
Start-Sleep -Seconds 5

# Limpa o cache de navegação do Firefox
$cachePath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData) + "\Mozilla\Firefox\Profiles"
$profiles = Get-ChildItem -Path $cachePath -Directory
foreach ($profile in $profiles) {
    $cacheFolder = Join-Path -Path $profile.FullName -ChildPath "cache2"
    if (Test-Path -Path $cacheFolder) {
        Remove-Item -Path $cacheFolder\* -Force -Recurse
    }
}

# Limpa os cookies do Firefox
$cookiesPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData) + "\Mozilla\Firefox\Profiles"
$profiles | ForEach-Object {
    $cookieFile = Join-Path -Path $_.FullName -ChildPath "cookies.sqlite"
    if (Test-Path -Path $cookieFile) {
        Remove-Item -Path $cookieFile -Force
    }
}

# Limpa o histórico de navegação do Firefox
$historyPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::LocalApplicationData) + "\Mozilla\Firefox\Profiles"
$profiles | ForEach-Object {
    $historyFile = Join-Path -Path $_.FullName -ChildPath "places.sqlite"
    if (Test-Path -Path $historyFile) {
        Remove-Item -Path $historyFile -Force
    }
}

# Limpa os downloads
$downloadsPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyDocuments) + "\Downloads"
Remove-Item -Path $downloadsPath\* -Force -Recurse

# Reinicia o Mozilla Firefox
#Start-Process firefox

#Write-Host "Limpeza de dados de navegação do Mozilla Firefox concluída com sucesso."




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
