#Deve-se para o antivírus antes de continuar com a instalação do office
Start-Process "powershell.exe" -ArgumentList ".\defender.ps1" -Wait -NoNewWindow

".\FINALIZACAO\"

$office = ".\softwares\Office 2013-2021 C2R Install - Install Lite 7.3.9\OInstall.exe"
Start-Process -FilePath $office -ArgumentList "/configure Configure.xml","/activate"  -Wait



#Bloqueando atualizações
$regeditPath = Join-Path $env:SystemRoot "regedit.exe"
Start-Process $regeditPath -ArgumentList "/s .\disble_office_updates.reg" -Wait
