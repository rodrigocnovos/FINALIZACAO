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
$runnerForm.StartPosition = "Manual"
$runnerForm.TopMost = $true
$workingArea = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$runnerForm.Location = New-Object System.Drawing.Point(
    [Math]::Max(0, $workingArea.Right - $runnerForm.Width - 20),
    [Math]::Max(0, $workingArea.Bottom - $runnerForm.Height - 20)
)

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

function Set-StateProperty {
    param(
        [Parameter(Mandatory = $true)]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        $Value
    )

    $existingProperty = $Object.PSObject.Properties[$Name]
    if ($existingProperty) {
        $existingProperty.Value = $Value
        return
    }

    $Object | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force
}

function Remove-ResumeRunKey {
    Remove-ItemProperty -Path $runKeyPath -Name $runKeyName -ErrorAction SilentlyContinue
}

function Get-TaskProcessId {
    param($Task)

    $processIdProperty = $Task.PSObject.Properties["processId"]
    if (-not $processIdProperty) {
        return $null
    }

    return $processIdProperty.Value
}

function Get-RunningTaskProcess {
    param($Task)

    $processId = Get-TaskProcessId -Task $Task
    if (-not $processId) {
        return $null
    }

    return Get-Process -Id $processId -ErrorAction SilentlyContinue
}

function Remove-AsyncArtifacts {
    param($Task)

    foreach ($propertyName in @("asyncResultFile", "asyncWrapperFile")) {
        $property = $Task.PSObject.Properties[$propertyName]
        if ($property -and $property.Value -and (Test-Path $property.Value)) {
            Remove-Item -LiteralPath $property.Value -Force -ErrorAction SilentlyContinue
        }
        if ($property) {
            $property.Value = $null
        }
    }
}

function Start-AsyncTaskProcess {
    param(
        [pscustomobject]$State,
        $Task
    )

    $token = [guid]::NewGuid().ToString("N")
    $wrapperPath = Join-Path $stateRoot ("async_" + $token + ".ps1")
    $resultPath = Join-Path $stateRoot ("async_" + $token + ".exitcode")
    $scriptInvocation = "& `"$($Task.scriptPath)`""
    if ($Task.argumentLine) {
        $scriptInvocation += " $($Task.argumentLine)"
    }

    $wrapperContent = @"
$scriptInvocation
`$code = if (`$null -ne `$LASTEXITCODE) { [int]`$LASTEXITCODE } else { 0 }
Set-Content -LiteralPath '$resultPath' -Value `$code -Encoding ASCII
exit `$code
"@

    Set-Content -LiteralPath $wrapperPath -Value $wrapperContent -Encoding UTF8
    Set-StateProperty -Object $Task -Name "asyncWrapperFile" -Value $wrapperPath
    Set-StateProperty -Object $Task -Name "asyncResultFile" -Value $resultPath

    $process = Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$wrapperPath`"" -PassThru
    Set-StateProperty -Object $Task -Name "processId" -Value $process.Id
    Save-State -State $State
}

function Complete-AsyncTask {
    param(
        [pscustomobject]$State,
        $Task
    )

    $process = Get-RunningTaskProcess -Task $Task
    if ($process) {
        return $false
    }

    $resultFileProperty = $Task.PSObject.Properties["asyncResultFile"]
    $resultFilePath = if ($resultFileProperty) { $resultFileProperty.Value } else { $null }
    $exitCode = 0
    if ($resultFilePath -and (Test-Path $resultFilePath)) {
        $rawExitCode = (Get-Content -LiteralPath $resultFilePath -TotalCount 1 -ErrorAction SilentlyContinue).Trim()
        if ($rawExitCode -match '^-?\d+$') {
            $exitCode = [int]$rawExitCode
        }
    }

    Set-StateProperty -Object $Task -Name "lastExitCode" -Value $exitCode
    Set-StateProperty -Object $Task -Name "lastEndAt" -Value ((Get-Date).ToString("o"))
    Set-StateProperty -Object $Task -Name "processId" -Value $null
    Remove-AsyncArtifacts -Task $Task

    if ($exitCode -eq 0) {
        Set-StateProperty -Object $Task -Name "status" -Value "done"
        Save-State -State $State
        return $true
    }

    Set-StateProperty -Object $Task -Name "status" -Value "failed"
    Save-State -State $State
    return $true
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
    $runningTasks = @($state.tasks | Where-Object { $_.status -eq "running" })
    foreach ($runningTask in $runningTasks) {
        [void](Complete-AsyncTask -State $state -Task $runningTask)
    }

    $failedTask = $state.tasks | Where-Object { $_.status -eq "failed" } | Select-Object -First 1
    if ($failedTask) {
        $failedExitCodeProperty = $failedTask.PSObject.Properties["lastExitCode"]
        $failedExitCode = if ($failedExitCodeProperty) { [int]$failedExitCodeProperty.Value } else { 1 }
        Update-RunnerUi -StepText "Falha na execucao" -DetailText "A etapa '$($failedTask.name)' retornou codigo $failedExitCode." -Percent 0
        Start-Sleep -Seconds 1
        $runnerForm.Close()
        Show-RunnerMessage "A etapa '$($failedTask.name)' falhou com codigo $failedExitCode." "Finalizacao" ([System.Windows.Forms.MessageBoxIcon]::Error)
        exit $failedExitCode
    }

    $pendingTask = $state.tasks | Where-Object { $_.status -eq "pending" } | Sort-Object -Property preferredOrder, name | Select-Object -First 1
    $runningTasks = @($state.tasks | Where-Object { $_.status -eq "running" })

    if (-not $pendingTask -and $runningTasks.Count -eq 0) {
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
    if (-not $pendingTask) {
        Update-RunnerUi -StepText "Aguardando tarefas em paralelo" -DetailText "Etapas concluidas: $completedTasks de $totalTasks" -Percent $percent
        Start-Sleep -Seconds 1
        continue
    }

    $waitForCompletionProperty = $pendingTask.PSObject.Properties["waitForCompletion"]
    $waitForCompletion = if ($waitForCompletionProperty) { [bool]$waitForCompletionProperty.Value } else { $true }
    $detailText = if ($waitForCompletion) { "Etapa $($completedTasks + 1) de $totalTasks" } else { "Etapa $($completedTasks + 1) de $totalTasks - iniciando em paralelo" }
    Update-RunnerUi -StepText "Executando: $($pendingTask.name)" -DetailText $detailText -Percent $percent

    Set-StateProperty -Object $pendingTask -Name "status" -Value "running"
    Set-StateProperty -Object $pendingTask -Name "lastStartAt" -Value ((Get-Date).ToString("o"))
    Save-State -State $state

    $psArgs = "-ExecutionPolicy Bypass -File `"$($pendingTask.scriptPath)`""
    if ($pendingTask.argumentLine) {
        $psArgs += " $($pendingTask.argumentLine)"
    }

    Write-Host "Executando etapa: $($pendingTask.name)"
    if (-not $waitForCompletion) {
        Start-AsyncTaskProcess -State $state -Task $pendingTask
        Start-Sleep -Milliseconds 250
        continue
    }

    $process = Start-Process -FilePath "powershell.exe" -ArgumentList $psArgs -Wait -PassThru
    $exitCode = $process.ExitCode
    Set-StateProperty -Object $pendingTask -Name "lastExitCode" -Value $exitCode
    Set-StateProperty -Object $pendingTask -Name "lastEndAt" -Value ((Get-Date).ToString("o"))
    Set-StateProperty -Object $pendingTask -Name "processId" -Value $null

    if ($exitCode -eq 0) {
        Set-StateProperty -Object $pendingTask -Name "status" -Value "done"
        Remove-AsyncArtifacts -Task $pendingTask
        Save-State -State $state
        continue
    }

    if ($rebootExitCodes -contains $exitCode) {
        Set-StateProperty -Object $pendingTask -Name "status" -Value "pending"
        Set-StateProperty -Object $pendingTask -Name "rebootCount" -Value ([int]$pendingTask.rebootCount + 1)
        Save-State -State $state
        Update-RunnerUi -StepText "Reinicio necessario" -DetailText "O computador sera reiniciado para continuar a finalizacao." -Percent $percent
        Start-Sleep -Seconds 2
        $runnerForm.Close()
        Restart-Computer -Force
        exit 0
    }

    Set-StateProperty -Object $pendingTask -Name "status" -Value "failed"
    Remove-AsyncArtifacts -Task $pendingTask
    Save-State -State $state
    Update-RunnerUi -StepText "Falha na execucao" -DetailText "A etapa '$($pendingTask.name)' retornou codigo $exitCode." -Percent $percent
    Start-Sleep -Seconds 1
    $runnerForm.Close()
    Show-RunnerMessage "A etapa '$($pendingTask.name)' falhou com codigo $exitCode." "Finalizacao" ([System.Windows.Forms.MessageBoxIcon]::Error)
    exit $exitCode
}
