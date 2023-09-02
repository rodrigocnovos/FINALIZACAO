Install-Module -Name PSWindowsUpdate -Force
Import-Module PSWindowsUpdate -Force

Get-WindowsUpdate


Install-WindowsUpdate -acceptall  -ForceInstall -IgnoreUserInput