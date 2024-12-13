#Deve-se parar o antivírus antes de continuar com a instalação do office
# Start-Process "powershell.exe" -ArgumentList ".\defender.ps1" -Wait -NoNewWindow

".\FINALIZACAO\"


$office = ".\softwares\Office 2013-2024 C2R Install - Lite v7.7.7.7 r25 x64\OInstall_x64.exe"
$ZipInstalador = ".\softwares\Office 2013-2024 C2R Install - Lite v7.7.7.7 r25 x64\OInstall.zip"
$LocalExtracao = ".\softwares\Office 2013-2024 C2R Install - Lite v7.7.7.7 r25 x64\"
if (-Not (Test-Path $office) ) {
    Expand-Archive -Path $ZipInstalador -DestinationPath $LocalExtracao
}
Start-Process -FilePath $office -ArgumentList "/configure Configure.xml","/activate"  -Wait



#Bloqueando atualizações
$regeditPath = Join-Path $env:SystemRoot "regedit.exe"
Start-Process $regeditPath -ArgumentList "/s .\disble_office_updates.reg" -Wait
