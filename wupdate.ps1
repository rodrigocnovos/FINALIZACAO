Start-Process ms-windows-store:

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Install-PackageProvider -Name NuGet -Force -Confirm:$false
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted

if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
    Install-Module -Name PSWindowsUpdate -Force -Confirm:$false
}

Import-Module PSWindowsUpdate -Force

Get-WindowsUpdate -MicrosoftUpdate
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -Install -IgnoreReboot

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

exit 0
