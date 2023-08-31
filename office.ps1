
$office = ".\softwares\Office 2013-2021 C2R Install - Install Lite 7.3.9\OInstall.exe"

# Start-Process -FilePath $office -ArgumentList "/configure Configure.xml","/activate"  -Wait

$regeditPath = Join-Path $env:SystemRoot "regedit.exe"
Write-Host $regeditPath

# @echo "Desativando update do Office"
Start-Process $regeditPath -ArgumentList "/s .\disble_office_updates.reg" -Wait
