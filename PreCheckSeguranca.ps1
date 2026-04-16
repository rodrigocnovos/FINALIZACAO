$ErrorActionPreference = "Stop"

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$targetScript = Join-Path $rootDir "app\scripts\security_precheck_prompt.ps1"

if (-not (Test-Path -LiteralPath $targetScript)) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        "Nao foi possivel localizar o script de pre-check:`n$targetScript",
        "Pre-check de Seguranca",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}

Unblock-File -LiteralPath $targetScript -ErrorAction SilentlyContinue

& $targetScript
exit $LASTEXITCODE
