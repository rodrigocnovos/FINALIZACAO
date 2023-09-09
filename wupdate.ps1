echo S | powershell Install-Module -Name PSWindowsUpdate | echo A
# Install-Module -Name PSWindowsUpdate -Force
Import-Module PSWindowsUpdate -Force
Install-PackageProvider -Name NuGet -Confirm:$false

Get-WindowsUpdate


Install-WindowsUpdate -acceptall  -ForceInstall -IgnoreUserInput