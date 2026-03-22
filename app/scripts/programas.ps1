param(
    [string]$SelectionKeysCsv
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appRoot = Split-Path -Parent $scriptDir
$softwareDir = Join-Path $appRoot "softwares"

function Resolve-InstallerPath {
    param(
        [string]$BaseDirectory,
        [string]$ExpectedName,
        [string[]]$FallbackPatterns
    )

    $expectedPath = Join-Path $BaseDirectory $ExpectedName
    if (Test-Path $expectedPath) {
        return $expectedPath
    }

    foreach ($pattern in $FallbackPatterns) {
        $candidate = Get-ChildItem -Path $BaseDirectory -Filter $pattern -File -ErrorAction SilentlyContinue |
            Sort-Object -Property Name |
            Select-Object -First 1
        if ($candidate) {
            return $candidate.FullName
        }
    }

    return $expectedPath
}

$programList = @(
    [PSCustomObject]@{
        Key = "ninite_web"
        Name = "Ninite AnyDesk Chrome Firefox Foxit Reader"
        Path = Resolve-InstallerPath -BaseDirectory $softwareDir -ExpectedName "Ninite AnyDeskChromeFirefoxFoxitReaderInstaller.exe" -FallbackPatterns @(
            "Ninite*AnyDeskChromeFirefoxFoxitReaderInstaller.exe",
            "Ninite*AnyDesk*Chrome*Firefox*Foxit*Installer.exe",
            "Ninite*AnyDeskChrome*Firefox*Foxit*Installer.exe",
            "Ninite*Chrome*Firefox*Foxit*Installer.exe",
            "Ninite*AnyDesk*Installer.exe"
        )
        Type = "exe"
        Arguments = @()
    },
    [PSCustomObject]@{
        Key = "ninite_tools"
        Name = "Ninite Glary Malwarebytes Revo TeraCopy"
        Path = Resolve-InstallerPath -BaseDirectory $softwareDir -ExpectedName "NiniteGlaryMalwarebytesRevoTeraCopyInstaller.exe" -FallbackPatterns @(
            "NiniteGlaryMalwarebytesRevoTeraCopyInstaller.exe",
            "Ninite*Glary*Malwarebytes*Revo*TeraCopy*Installer.exe",
            "Ninite*GlaryMalwarebytesRevoTeraCopy*Installer.exe",
            "Ninite*Malwarebytes*Revo*TeraCopy*Installer.exe",
            "Ninite*Glary*Installer.exe"
        )
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

Write-Host "Pacotes solicitados: $SelectionKeysCsv"

if ($SelectionKeysCsv) {
    $selectedKeys = $SelectionKeysCsv.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.Trim() }
    $programList = $programList | Where-Object { $selectedKeys -contains $_.Key }
}

$missingInstallers = @()

if ($SelectionKeysCsv -and @($programList).Count -eq 0) {
    Write-Error "Nenhum instalador corresponde a selecao recebida: $SelectionKeysCsv"
    exit 1
}

foreach ($program in $programList) {
    Write-Host "Caminho resolvido para $($program.Name): $($program.Path)"

    if (-not (Test-Path $program.Path)) {
        $missingInstallers += $program.Path
        Write-Error "Instalador nao encontrado: $($program.Path)"
        continue
    }

    Unblock-File -LiteralPath $program.Path -ErrorAction SilentlyContinue
    Write-Host "Executando instalacao: $($program.Name)"

    if ($program.Type -eq "msi") {
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $program.Arguments -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            Write-Error "A instalacao MSI falhou para $($program.Name) com codigo $($process.ExitCode)."
            exit $process.ExitCode
        }
        continue
    }

    if ($program.Key -match "ninite") {
        Write-Host "Iniciando $($program.Name) com automacao de fechamento..."
        $process = Start-Process -FilePath $program.Path -PassThru
        
        Add-Type -AssemblyName UIAutomationClient
        $root = [System.Windows.Automation.AutomationElement]::RootElement
        $condProcess = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, $process.Id)
        
        $niniteFinished = $false
        while (-not $process.HasExited) {
            Start-Sleep -Seconds 5
            $window = $root.FindFirst([System.Windows.Automation.TreeScope]::Children, $condProcess)
            if ($window) {
                $allElements = $window.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
                foreach ($el in $allElements) {
                    $elName = $el.Current.Name
                    if ($elName -match "(?i)(Close|Fechar|OK|Finished|Finalizado)") {
                        Write-Host "Instalacao do Ninite concluida (Texto/Botao identificado: $elName). Encerrando..."
                        $process | Stop-Process -Force -ErrorAction SilentlyContinue
                        $niniteFinished = $true
                        break
                    }
                }
                if ($niniteFinished) { break }
            }
        }
    } else {
        if ($program.Arguments -and $program.Arguments.Count -gt 0) {
            $process = Start-Process -FilePath $program.Path -ArgumentList $program.Arguments -Wait -PassThru
        } else {
            $process = Start-Process -FilePath $program.Path -Wait -PassThru
        }
    }
    if ($process.ExitCode -ne 0) {
        Write-Error "A instalacao falhou para $($program.Name) com codigo $($process.ExitCode)."
        exit $process.ExitCode
    }
}

if ($missingInstallers.Count -gt 0) {
    exit 1
}
