Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$stateRoot = Join-Path $env:ProgramData "FINALIZACAO"
$stateFile = Join-Path $stateRoot "state.json"
$runKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$runKeyName = "FINALIZACAOResume"
$rebootExitCodes = @(194, 3010)

$runnerForm = New-Object System.Windows.Forms.Form
$runnerForm.Text = "Retomando finalizacao"
$runnerForm.Size = New-Object System.Drawing.Size(560, 220)
$runnerForm.StartPosition = "CenterScreen"
$runnerForm.TopMost = $true

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Processo de finalizacao em andamento"
$titleLabel.Location = New-Object System.Drawing.Point(20, 20)
$titleLabel.Size = New-Object System.Drawing.Size(500, 24)
$runnerForm.Controls.Add($titleLabel)

$stepLabel = New-Object System.Windows.Forms.Label
$stepLabel.Text = "Preparando..."
$stepLabel.Location = New-Object System.Drawing.Point(20, 60)
$stepLabel.Size = New-Object System.Drawing.Size(500, 24)
$runnerForm.Controls.Add($stepLabel)

$detailLabel = New-Object System.Windows.Forms.Label
$detailLabel.Text = "Aguarde."
$detailLabel.Location = New-Object System.Drawing.Point(20, 90)
$detailLabel.Size = New-Object System.Drawing.Size(500, 36)
$runnerForm.Controls.Add($detailLabel)

$runnerProgressBar = New-Object System.Windows.Forms.ProgressBar
$runnerProgressBar.Location = New-Object System.Drawing.Point(20, 140)
$runnerProgressBar.Size = New-Object System.Drawing.Size(500, 20)
$runnerProgressBar.Minimum = 0
$runnerProgressBar.Maximum = 100
$runnerProgressBar.Value = 0
$runnerForm.Controls.Add($runnerProgressBar)

function Update-RunnerUi {
    param(
        [string]$StepText,
        [string]$DetailText,
        [int]$Percent
    )

    $safePercent = [Math]::Max(0, [Math]::Min(100, $Percent))
    $stepLabel.Text = $StepText
    $detailLabel.Text = $DetailText
    $runnerProgressBar.Value = $safePercent
    $runnerForm.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
}

function Save-State {
    param([pscustomobject]$State)

    if (-not (Test-Path $stateRoot)) {
        New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
    }

    $State | ConvertTo-Json -Depth 8 | Set-Content -Path $stateFile -Encoding UTF8
}

function Remove-ResumeRunKey {
    Remove-ItemProperty -Path $runKeyPath -Name $runKeyName -ErrorAction SilentlyContinue
}

function Show-RunnerMessage {
    param(
        [string]$Message,
        [string]$Title = "Finalizacao",
        [System.Windows.Forms.MessageBoxIcon]$Icon = [System.Windows.Forms.MessageBoxIcon]::Information
    )

    [System.Windows.Forms.MessageBox]::Show(
        $Message,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        $Icon
    ) | Out-Null
}

if (-not (Test-Path $stateFile)) {
    Remove-ResumeRunKey
    $runnerForm.Close()
    Show-RunnerMessage "Nenhum estado de execucao foi encontrado." "Finalizacao" ([System.Windows.Forms.MessageBoxIcon]::Warning)
    exit 1
}

$state = Get-Content -Path $stateFile -Raw | ConvertFrom-Json
$totalTasks = @($state.tasks).Count
$runnerForm.Show()

while ($true) {
    $pendingTask = $state.tasks | Where-Object { $_.status -ne "done" } | Select-Object -First 1
    if (-not $pendingTask) {
        Remove-ResumeRunKey
        Remove-Item -Path $stateFile -Force -ErrorAction SilentlyContinue
        Update-RunnerUi -StepText "Concluido" -DetailText "Todas as etapas foram executadas." -Percent 100
        Start-Sleep -Seconds 1
        $runnerForm.Close()
        Show-RunnerMessage "Execucao concluida com sucesso."
        exit 0
    }

    $completedTasks = @($state.tasks | Where-Object { $_.status -eq "done" }).Count
    $percent = if ($totalTasks -gt 0) { [int](($completedTasks / $totalTasks) * 100) } else { 0 }
    Update-RunnerUi -StepText "Executando: $($pendingTask.name)" -DetailText "Etapa $($completedTasks + 1) de $totalTasks" -Percent $percent

    $pendingTask.status = "running"
    $pendingTask.lastStartAt = (Get-Date).ToString("o")
    Save-State -State $state

    $psArgs = "-ExecutionPolicy Bypass -File `"$($pendingTask.scriptPath)`""
    if ($pendingTask.argumentLine) {
        $psArgs += " $($pendingTask.argumentLine)"
    }

    Write-Host "Executando etapa: $($pendingTask.name)"
    $process = Start-Process -FilePath "powershell.exe" -ArgumentList $psArgs -Wait -PassThru
    $exitCode = $process.ExitCode
    $pendingTask.lastExitCode = $exitCode
    $pendingTask.lastEndAt = (Get-Date).ToString("o")

    if ($exitCode -eq 0) {
        $pendingTask.status = "done"
        Save-State -State $state
        continue
    }

    if ($rebootExitCodes -contains $exitCode) {
        $pendingTask.status = "pending"
        $pendingTask.rebootCount = [int]$pendingTask.rebootCount + 1
        Save-State -State $state
        Update-RunnerUi -StepText "Reinicio necessario" -DetailText "O computador sera reiniciado para continuar a finalizacao." -Percent $percent
        Start-Sleep -Seconds 2
        $runnerForm.Close()
        Restart-Computer -Force
        exit 0
    }

    $pendingTask.status = "failed"
    Save-State -State $state
    Update-RunnerUi -StepText "Falha na execucao" -DetailText "A etapa '$($pendingTask.name)' retornou codigo $exitCode." -Percent $percent
    Start-Sleep -Seconds 1
    $runnerForm.Close()
    Show-RunnerMessage "A etapa '$($pendingTask.name)' falhou com codigo $exitCode." "Finalizacao" ([System.Windows.Forms.MessageBoxIcon]::Error)
    exit $exitCode
}
