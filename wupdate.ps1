[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "Iniciando atualizacao do Windows Update..." -ForegroundColor Cyan

if (-not (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -Force -Confirm:$false
}

Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
}

Import-Module PSWindowsUpdate -Force

Get-WindowsUpdate -MicrosoftUpdate
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -Install -IgnoreReboot

Write-Host "Tratando aplicativos da Microsoft Store..." -ForegroundColor Cyan
Start-Process "ms-windows-store://downloadsandupdates"

$winget = Get-Command winget.exe -ErrorAction SilentlyContinue
if ($winget) {
    Write-Host "Executando atualizacao de aplicativos via winget/msstore..." -ForegroundColor Yellow
    Start-Process -FilePath $winget.Source -ArgumentList @(
        "upgrade",
        "--all",
        "--source", "msstore",
        "--accept-source-agreements",
        "--accept-package-agreements",
        "--include-unknown"
    ) -Wait -NoNewWindow
} else {
    Write-Host "winget nao encontrado. A pagina de Downloads e atualizacoes da Store foi aberta para complementar a atualizacao." -ForegroundColor Yellow
}

$needsReboot = $false
try {
    $needsReboot = Get-WURebootStatus -Silent
} catch {
    $needsReboot = Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired"
}

if ($needsReboot) {
    Write-Host "Reinicio necessario para continuar as atualizacoes."
    exit 194
}

Write-Host "Atualizacao do Windows e dos apps da Store concluida." -ForegroundColor Green
exit 0
