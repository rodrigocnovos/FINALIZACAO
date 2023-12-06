$programList = @()

$programList +=[PSCustomObject]@{
    programa = ".\softwares\Anydesk.exe";
    param1 = "--install";
    param2 = "`"C:\Program Files (x86)\AnyDesk`"";
    param3 = "--start-with-win";
    param4 = "--create-desktop-icon"
}

# $programList +=[PSCustomObject]@{
#     programa = ".\softwares\ninite.exe";
#     param1 = " ";
#     param2 = " ";
#     param3 = " ";
#     param4 = " "
# }

$programList

foreach ($program in $programList) {
    if ($program.programa -like "*.exe") {
        Start-Process -FilePath $program.programa -ArgumentList $program.param1,$program.param2,$program.param3,$program.param4 -Wait
    }
    elseif ($program -like "*.msi") {
        Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$program`" /qn" -Wait
    }
    else {
        choco install $program -y
    }
}

$process_instala = Start-Process -FilePath powershell.exe -ArgumentList ".\softwares\ninite.exe" -NoNewWindow
$process_instala.WaitForExit()

$informacoesDoProcesso = Get-Process -Id $process_instala.Id
               
if (Get-Process -Id $process_instala.Id -ErrorAction SilentlyContinue) {
    Stop-Process -Name $process_instala -Force 
}