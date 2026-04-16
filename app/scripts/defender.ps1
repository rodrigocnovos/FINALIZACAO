Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Get-ProtectionState {
    $realTimeEnabled = $false
    try {
        $preference = Get-MpPreference -ErrorAction Stop
        $realTimeEnabled = ($preference.DisableRealtimeMonitoring -eq $false)
    } catch {
        $realTimeEnabled = $false
    }

    $smartAppState = $null
    try {
        $computerStatus = Get-MpComputerStatus -ErrorAction Stop
        $smartAppState = $computerStatus.SmartAppControlState
    } catch {
        $smartAppState = $null
    }

    $smartAppStateText = ""
    if ($null -ne $smartAppState) {
        $smartAppStateText = [string]$smartAppState
    }

    $smartAppDisabled = $true
    if ($smartAppStateText) {
        switch -Regex ($smartAppStateText.Trim()) {
            '^(?i:off|disabled|0)$' { $smartAppDisabled = $true; break }
            default { $smartAppDisabled = $false; break }
        }
    }

    return [PSCustomObject]@{
        RealTimeProtectionEnabled = $realTimeEnabled
        SmartAppControlState      = if ($smartAppStateText) { $smartAppStateText } else { "Indisponivel" }
        SmartAppControlDisabled   = $smartAppDisabled
        RequiresAction            = ($realTimeEnabled -or -not $smartAppDisabled)
    }
}

function Open-ProtectionSettings {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$State
    )

    if ($State.RealTimeProtectionEnabled) {
        Start-Process "explorer.exe" -ArgumentList "windowsdefender://ThreatSettings" -ErrorAction SilentlyContinue | Out-Null
    }

    if (-not $State.SmartAppControlDisabled) {
        Start-Process "explorer.exe" -ArgumentList "windowsdefender://appbrowser" -ErrorAction SilentlyContinue | Out-Null
    }
}

function Get-InstructionText {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$State
    )

    $lines = @(
        "Desative as protecoes abaixo para poder avancar.",
        "",
        ("Protecao em tempo real: " + ($(if ($State.RealTimeProtectionEnabled) { "ATIVADA" } else { "DESATIVADA" }))),
        ("Smart App Control: " + $State.SmartAppControlState)
    )

    if ($State.RealTimeProtectionEnabled) {
        $lines += ""
        $lines += "A tela de Virus e ameacas foi aberta."
    }

    if (-not $State.SmartAppControlDisabled) {
        $lines += ""
        $lines += "A tela App e controle do navegador foi aberta."
        $lines += "Desligue o Smart App Control para continuar."
    }

    if (-not $State.RequiresAction) {
        $lines = @(
            "Protecao em tempo real e Smart App Control ja estao desativados.",
            "",
            "Clique em OK para continuar."
        )
    }

    return ($lines -join [Environment]::NewLine)
}

function Show-ProtectionForm {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$InitialState
    )

    $form = New-Object Windows.Forms.Form
    $form.TopMost = $true
    $form.Size = New-Object Drawing.Size(460, 260)
    $form.StartPosition = "CenterScreen"
    $form.Text = "Configuracao de Antivirus"

    $label = New-Object Windows.Forms.Label
    $label.Location = New-Object Drawing.Point(20, 20)
    $label.Size = New-Object Drawing.Size(400, 130)
    $label.Text = Get-InstructionText -State $InitialState
    $form.Controls.Add($label)

    $buttonOpen = New-Object Windows.Forms.Button
    $buttonOpen.Location = New-Object Drawing.Point(20, 165)
    $buttonOpen.Size = New-Object Drawing.Size(170, 35)
    $buttonOpen.Text = "Abrir configuracoes"
    $buttonOpen.Add_Click({
        $currentState = Get-ProtectionState
        Open-ProtectionSettings -State $currentState
        $label.Text = Get-InstructionText -State $currentState
    })
    $form.Controls.Add($buttonOpen)

    $buttonOK = New-Object Windows.Forms.Button
    $buttonOK.Location = New-Object Drawing.Point(320, 165)
    $buttonOK.Size = New-Object Drawing.Size(100, 35)
    $buttonOK.Text = "OK"
    $buttonOK.Enabled = (-not $InitialState.RequiresAction)
    $buttonOK.Add_Click({
        $form.Close()
    })
    $form.Controls.Add($buttonOK)

    $timer = New-Object Windows.Forms.Timer
    $timer.Interval = 1000
    $timer.Add_Tick({
        $currentState = Get-ProtectionState
        $label.Text = Get-InstructionText -State $currentState
        $buttonOK.Enabled = (-not $currentState.RequiresAction)
    })
    $timer.Start()

    $form.Add_FormClosed({
        $timer.Stop()
        $timer.Dispose()
    })

    [void]$form.ShowDialog()
}

$state = Get-ProtectionState
if ($state.RequiresAction) {
    Open-ProtectionSettings -State $state
    Show-ProtectionForm -InitialState $state
} else {
    Write-Host "Protecao em tempo real e Smart App Control ja estao desativados."
}
