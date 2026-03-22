$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appRoot = Split-Path -Parent $scriptDir
$wubPath = Join-Path $appRoot "softwares\Wub_v1.8\Wub\Wub_x64.exe"

Start-Process -FilePath $wubPath -Wait
