#$ErrorActionPreference = "Stop"

Clear-RecycleBin -Force

#Set-Location "C:\Windows\Temp"
#Remove-Item * -recurse -force

Set-Location "C:\Windows\SoftwareDistribution"
Remove-Item * -recurse -force

#Set-Location "C:\Windows\Prefetch"
#Remove-Item * -recurse -force

#Set-Location "C:\Documents and Settings"
#Remove-Item ".\*\Local Settings\temp\*" -recurse -force

#Set-Location "C:\Users"
#Remove-Item ".\*\Appdata\Local\Temp\*" -recurse -force

Set-Location "$env:USERPROFILE\Downloads"
Remove-Item * -recurse -force

#limpeza google chrome

$Items = @('Archived History',
            'Cache\*',
            'Cookies',
            'History',
            'Login Data',
            'Top Sites',
            'Visited Links',
            'Web Data')
$Folder = "$($env:LOCALAPPDATA)\Google\Chrome\User Data\Default"
$Items | % { 
    if (Test-Path "$Folder\$_") {
        Remove-Item "$Folder\$_" 
    }
}

#Limpeza Edge
$Items = @('Archived History',
            'Cache\*',
            'Cookies',
            'History',
            'Login Data',
            'Top Sites',
            'Visited Links',
            'Web Data')
$Folder = "$($env:LOCALAPPDATA)\Microsoft\Edge\User Data\Default"
$Items | % { 
    if (Test-Path "$Folder\$_") {
        Remove-Item "$Folder\$_" 
    }
}


