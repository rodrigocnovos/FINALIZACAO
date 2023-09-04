Enable-ComputerRestore -Drive "c:\"

$timestamp = Get-Date -Format "ddMMyyyyHHmmss"
$description = "Ponto Criado em $timestamp"


# Definir o valor do Registro para criar pontos de restauração a cada 1 minuto
$regPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore"
$regName = "SystemRestorePointCreationFrequency"
# $regValueOriginal = (Get-ItemProperty -Path $regPath -Name $regName).$regName
$regValueOriginal = 1440

# Definir o novo valor (1 minuto) temporariamente
$regValueTemp = 1

# Definir o novo valor temporariamente
Set-ItemProperty -Path $regPath -Name $regName -Value $regValueTemp


Checkpoint-Computer -Description $description -RestorePointType MODIFY_SETTINGS
# wmic.exe /Namespace:\\root\default Path SystemRestore Call CreateRestorePoint "$description", 100, 7
Start-Sleep -Seconds 4



# Definir o novo valor temporariamente
Set-ItemProperty -Path $regPath -Name $regName -Value $regValueOriginal
