# Start-Process ms-settings:windowsupdate


Start-Process ms-windows-store:

echo S | powershell Install-Module -Name PSWindowsUpdate -Force
Import-Module PSWindowsUpdate -Force
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
Install-PackageProvider -Name NuGet -Confirm:$false

Get-WindowsUpdate


Install-WindowsUpdate -Acceptall -Install -AutoReboot