Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Show-ForegroundMessageBox {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        [Parameter(Mandatory = $true)]
        [string]$Title,
        [System.Windows.Forms.MessageBoxButtons]$Buttons = [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]$Icon = [System.Windows.Forms.MessageBoxIcon]::Information
    )

    $owner = New-Object System.Windows.Forms.Form
    $owner.StartPosition = "Manual"
    $owner.Location = [System.Drawing.Point]::new(-32000, -32000)
    $owner.Size = [System.Drawing.Size]::new(1, 1)
    $owner.ShowInTaskbar = $false
    $owner.TopMost = $true
    $owner.Opacity = 0

    try {
        $null = $owner.Show()
        $owner.Activate()
        return [System.Windows.Forms.MessageBox]::Show($owner, $Message, $Title, $Buttons, $Icon)
    } finally {
        $owner.Close()
        $owner.Dispose()
    }
}

function Get-ProtectionState {
    $realTimeEnabled = $null
    try {
        $preference = Get-MpPreference -ErrorAction Stop
        $realTimeEnabled = ($preference.DisableRealtimeMonitoring -eq $false)
    } catch {
        $realTimeEnabled = $null
    }

    $smartAppStateText = ""
    try {
        $computerStatus = Get-MpComputerStatus -ErrorAction Stop
        if ($null -ne $computerStatus.SmartAppControlState) {
            $smartAppStateText = [string]$computerStatus.SmartAppControlState
        }
    } catch {
        $smartAppStateText = ""
    }

    $smartAppDisabled = $false
    $smartAppKnown = $false
    if ($smartAppStateText) {
        $smartAppKnown = $true
        switch -Regex ($smartAppStateText.Trim()) {
            '^(?i:off|disabled|0)$' { $smartAppDisabled = $true; break }
            default { $smartAppDisabled = $false; break }
        }
    }

    return [PSCustomObject]@{
        RealTimeKnown            = ($null -ne $realTimeEnabled)
        RealTimeProtectionEnabled = [bool]$realTimeEnabled
        SmartAppControlKnown     = $smartAppKnown
        SmartAppControlState     = if ($smartAppStateText) { $smartAppStateText } else { "Indisponivel" }
        SmartAppControlDisabled  = $smartAppDisabled
    }
}

function Open-AntivirusSettings {
    Start-Process "explorer.exe" -ArgumentList "windowsdefender://ThreatSettings" -ErrorAction SilentlyContinue | Out-Null
}

function Open-SmartAppSettings {
    Start-Process "explorer.exe" -ArgumentList "windowsdefender://smartapp/" -ErrorAction SilentlyContinue | Out-Null
    Start-Sleep -Milliseconds 600
    Start-Process "explorer.exe" -ArgumentList "windowsdefender://appbrowser" -ErrorAction SilentlyContinue | Out-Null
}

function Close-WindowsSecurityUi {
    Get-Process -Name "SecHealthUI" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

function Test-WindowsSecurityUiOpen {
    return (@(Get-Process -Name "SecHealthUI" -ErrorAction SilentlyContinue).Count -gt 0)
}

function Show-PhaseReminder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Phase
    )

    $message = switch ($Phase) {
        "Antivirus" {
            @(
                "Desative a Protecao em tempo real para concluir esta etapa.",
                "",
                "A tela do antivirus foi reaberta automaticamente."
            ) -join [Environment]::NewLine
        }
        "SmartApp" {
            @(
                "Desative o Smart App Control para concluir esta etapa.",
                "",
                "Se nao abrir direto na tela correta, use:",
                "Controle de aplicativos e navegador > Smart App Control > Off"
            ) -join [Environment]::NewLine
        }
        default {
            "Conclua a etapa de seguranca pendente."
        }
    }

    Show-ForegroundMessageBox -Message $message -Title "Pre-check de Seguranca" -Buttons OK -Icon Warning | Out-Null
}

function Open-PhaseUi {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Phase,
        [bool]$ShowReminder = $false
    )

    switch ($Phase) {
        "Antivirus" { Open-AntivirusSettings }
        "SmartApp" { Open-SmartAppSettings }
    }

    $script:LastUiLaunchAt = Get-Date

    if ($ShowReminder) {
        Show-PhaseReminder -Phase $Phase
    }
}

function Get-StatusText {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$State,
        [Parameter(Mandatory = $true)]
        [string]$Phase
    )

    $realTimeLabel = if (-not $State.RealTimeKnown) {
        "Indisponivel"
    } elseif ($State.RealTimeProtectionEnabled) {
        "ATIVADA"
    } else {
        "DESATIVADA"
    }

    $smartAppLabel = if ($State.SmartAppControlKnown) {
        $State.SmartAppControlState
    } else {
        "Indisponivel"
    }

    $phaseText = switch ($Phase) {
        "Antivirus" { "Monitorando Protecao em tempo real. Quando ficar DESATIVADA, esta janela sera fechada e o Smart App sera aberto automaticamente." }
        "SmartApp" { "Monitorando Smart App Control. Quando ficar OFF, o script sera encerrado automaticamente." }
        "Concluido" { "Concluido. Encerrando..." }
        default { "Siga as etapas abaixo." }
    }

    $lines = @(
        $phaseText,
        "",
        "1. Protecao em tempo real do antivirus",
        "2. Smart App Control",
        "",
        "Este script nao altera nada sozinho.",
        "Ele apenas abre as telas do Windows Security para o tecnico fazer a mudanca.",
        "",
        ("Protecao em tempo real: " + $realTimeLabel),
        ("Smart App Control: " + $smartAppLabel),
        "",
        "Caminhos esperados:",
        "Virus e ameacas > Gerenciar configuracoes > Protecao em tempo real",
        "Controle de aplicativos e navegador > Smart App Control > Off"
    )

    if ($Phase -eq "Concluido") {
        $lines += ""
        $lines += "Tudo certo. Nenhuma acao adicional sera solicitada."
    } else {
        $lines += ""
        $lines += "Se a janela do Windows Security for fechada antes da hora, ela sera aberta novamente."
    }

    return ($lines -join [Environment]::NewLine)
}

function Test-CanContinue {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$State,
        [bool]$ManualSmartAppOverride = $false
    )

    return (
        $State.RealTimeKnown -and
        -not $State.RealTimeProtectionEnabled -and
        (
            ($State.SmartAppControlKnown -and $State.SmartAppControlDisabled) -or
            ((-not $State.SmartAppControlKnown) -and $ManualSmartAppOverride)
        )
    )
}

function Get-WorkflowPhase {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$State,
        [bool]$ManualSmartAppOverride = $false
    )

    if (-not ($State.RealTimeKnown -and -not $State.RealTimeProtectionEnabled)) {
        return "Antivirus"
    }

    if (Test-CanContinue -State $State -ManualSmartAppOverride $ManualSmartAppOverride) {
        return "Concluido"
    }

    return "SmartApp"
}

$initialState = Get-ProtectionState

$alertMessage = @(
    "ALERTA DE PREPARACAO",
    "",
    "Antes de iniciar a finalizacao, sera necessario desativar manualmente:",
    "1. Protecao em tempo real do antivirus",
    "2. Smart App Control",
    "",
    "As telas do Windows Security serao abertas em seguida.",
    "Este script nao eleva permissao e nao altera essas configuracoes sozinho.",
    "",
    "Clique em OK para abrir as telas e iniciar a validacao.",
    "Clique em Cancelar para sair."
) -join [Environment]::NewLine

$alertResult = Show-ForegroundMessageBox -Message $alertMessage -Title "Pre-check de Seguranca" -Buttons OKCancel -Icon Warning

if ($alertResult -ne [System.Windows.Forms.DialogResult]::OK) {
    exit
}

$form = New-Object Windows.Forms.Form
$form.Text = "Pre-check de Seguranca"
$form.StartPosition = "Manual"
$form.TopMost = $false
$form.ClientSize = New-Object Drawing.Size(560, 300)

$script:CurrentPhase = Get-WorkflowPhase -State $initialState
$script:LastUiLaunchAt = [datetime]::MinValue
$script:Completed = $false

$label = New-Object Windows.Forms.Label
$label.Location = New-Object Drawing.Point(20, 20)
$label.Size = New-Object Drawing.Size(520, 180)
$label.Text = Get-StatusText -State $initialState -Phase $script:CurrentPhase
$form.Controls.Add($label)

$checkManualSmartApp = New-Object Windows.Forms.CheckBox
$checkManualSmartApp.Location = New-Object Drawing.Point(20, 210)
$checkManualSmartApp.Size = New-Object Drawing.Size(520, 24)
$checkManualSmartApp.Text = "Se o estado do Smart App nao puder ser lido, confirmo que desliguei manualmente."
$checkManualSmartApp.Visible = ($script:CurrentPhase -ne "Antivirus" -and -not $initialState.SmartAppControlKnown)
$checkManualSmartApp.Add_CheckedChanged({
    $currentState = Get-ProtectionState
    $script:CurrentPhase = Get-WorkflowPhase -State $currentState -ManualSmartAppOverride $checkManualSmartApp.Checked
    $label.Text = Get-StatusText -State $currentState -Phase $script:CurrentPhase
})
$form.Controls.Add($checkManualSmartApp)

$buttonReopen = New-Object Windows.Forms.Button
$buttonReopen.Location = New-Object Drawing.Point(20, 245)
$buttonReopen.Size = New-Object Drawing.Size(170, 35)
$buttonReopen.Text = "Reabrir tela atual"
$buttonReopen.Add_Click({
    if ($script:CurrentPhase -ne "Concluido") {
        Close-WindowsSecurityUi
        Open-PhaseUi -Phase $script:CurrentPhase -ShowReminder $true
    }
})
$form.Controls.Add($buttonReopen)

$buttonCancel = New-Object Windows.Forms.Button
$buttonCancel.Location = New-Object Drawing.Point(440, 245)
$buttonCancel.Size = New-Object Drawing.Size(100, 35)
$buttonCancel.Text = "Cancelar"
$buttonCancel.Add_Click({
    $form.Close()
})
$form.Controls.Add($buttonCancel)

$timer = New-Object Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
    $currentState = Get-ProtectionState
    $newPhase = Get-WorkflowPhase -State $currentState -ManualSmartAppOverride $checkManualSmartApp.Checked

    if ($newPhase -eq "Concluido") {
        $script:Completed = $true
        $script:CurrentPhase = $newPhase
        $label.Text = Get-StatusText -State $currentState -Phase $script:CurrentPhase
        Close-WindowsSecurityUi
        $form.Close()
        return
    }

    if ($script:CurrentPhase -eq "Antivirus" -and $newPhase -eq "SmartApp") {
        Close-WindowsSecurityUi
        Start-Sleep -Milliseconds 500
        Open-PhaseUi -Phase "SmartApp" -ShowReminder $false
    } elseif ($newPhase -ne "Concluido" -and -not (Test-WindowsSecurityUiOpen)) {
        $secondsSinceLaunch = ((Get-Date) - $script:LastUiLaunchAt).TotalSeconds
        if ($secondsSinceLaunch -ge 2) {
            Open-PhaseUi -Phase $newPhase -ShowReminder $true
        }
    }

    $script:CurrentPhase = $newPhase
    $label.Text = Get-StatusText -State $currentState -Phase $script:CurrentPhase
    $checkManualSmartApp.Visible = ($script:CurrentPhase -ne "Antivirus" -and -not $currentState.SmartAppControlKnown)
    $buttonReopen.Enabled = ($script:CurrentPhase -ne "Concluido")
})
$timer.Start()

$form.Add_FormClosed({
    $timer.Stop()
    $timer.Dispose()
})

$form.Add_Shown({
    $workingArea = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $form.Location = [System.Drawing.Point]::new(
        ([int]$workingArea.Left + 10),
        ([int]$workingArea.Bottom - $form.Height - 10)
    )

    if ($script:CurrentPhase -ne "Concluido") {
        Open-PhaseUi -Phase $script:CurrentPhase -ShowReminder $false
    }
})

[void]$form.ShowDialog()
