param(
    [string]$SelectionKeysCsv
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$softwareDir = Join-Path $scriptDir "softwares"

$programList = @(
    [PSCustomObject]@{
        Key = "ninite_web"
        Name = "Ninite AnyDesk Chrome Firefox Foxit Reader"
        Path = Join-Path $softwareDir "Ninite AnyDesk Chrome Firefox Foxit Reader Installer.exe"
        Type = "exe"
        Arguments = @()
    },
    [PSCustomObject]@{
        Key = "ninite_tools"
        Name = "Ninite Glary Malwarebytes Revo TeraCopy"
        Path = Join-Path $softwareDir "Ninite Glary Malwarebytes Revo TeraCopy Installer.exe"
        Type = "exe"
        Arguments = @()
    },
    [PSCustomObject]@{
        Key = "rustdesk"
        Name = "RustDesk"
        Path = Join-Path $softwareDir "rustdesk-1.4.6-x86_64.msi"
        Type = "msi"
        Arguments = @("/i", "`"$(Join-Path $softwareDir "rustdesk-1.4.6-x86_64.msi")`"", "/qn")
    }
)

if ($SelectionKeysCsv) {
    $selectedKeys = $SelectionKeysCsv.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.Trim() }
    $programList = $programList | Where-Object { $selectedKeys -contains $_.Key }
}

foreach ($program in $programList) {
    if (-not (Test-Path $program.Path)) {
        Write-Warning "Instalador nao encontrado: $($program.Path)"
        continue
    }

    Write-Host "Executando instalacao: $($program.Name)"

    if ($program.Type -eq "msi") {
        Start-Process -FilePath "msiexec.exe" -ArgumentList $program.Arguments -Wait
        continue
    }

    Start-Process -FilePath $program.Path -ArgumentList $program.Arguments -Wait
}
