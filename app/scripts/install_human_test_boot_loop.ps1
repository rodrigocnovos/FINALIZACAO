param(
    [switch]$Remove
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$templatePath = Join-Path $scriptDir "human_test_boot_loop_launcher.template.bat"
$promptScriptPath = Join-Path $scriptDir "human_test_boot_loop_prompt.ps1"
$testScriptPath = Join-Path $scriptDir "Testes_simulador_humano.ps1"
$startupDir = [Environment]::GetFolderPath("Startup")
$startupLauncherPath = Join-Path $startupDir "FINALIZACAO_HumanTestLoop.bat"

if ($Remove) {
    if (Test-Path -LiteralPath $startupLauncherPath) {
        Remove-Item -LiteralPath $startupLauncherPath -Force
        Write-Output "Launcher removido de: $startupLauncherPath"
    } else {
        Write-Output "Nenhum launcher encontrado em: $startupLauncherPath"
    }
    return
}

if (-not (Test-Path -LiteralPath $templatePath)) {
    throw "Template do launcher nao encontrado em $templatePath"
}

if (-not (Test-Path -LiteralPath $promptScriptPath)) {
    throw "Script de prompt do launcher nao encontrado em $promptScriptPath"
}

if (-not (Test-Path -LiteralPath $testScriptPath)) {
    throw "Script de teste humano nao encontrado em $testScriptPath"
}

if (-not (Test-Path -LiteralPath $startupDir)) {
    New-Item -ItemType Directory -Path $startupDir -Force | Out-Null
}

$templateContent = Get-Content -LiteralPath $templatePath -Raw
$templateContent = $templateContent.Replace("__PROMPT_SCRIPT_PATH__", $promptScriptPath)
$launcherContent = $templateContent.Replace("__SCRIPT_PATH__", $testScriptPath)

if (Test-Path -LiteralPath $startupLauncherPath) {
    $existingContent = Get-Content -LiteralPath $startupLauncherPath -Raw -ErrorAction SilentlyContinue
    if ($existingContent -eq $launcherContent) {
        Write-Output "Launcher ja instalado em: $startupLauncherPath"
        Write-Output "No proximo boot sera exibido um prompt de 10 segundos para remover o loop automatico."
        return
    }
}

[System.IO.File]::WriteAllText($startupLauncherPath, $launcherContent, [System.Text.Encoding]::ASCII)

Write-Output "Launcher instalado em: $startupLauncherPath"
Write-Output "No proximo boot sera exibido um prompt de 10 segundos para cancelar e remover o inicio automatico."
