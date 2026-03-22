Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Check-WindowsActivationStatus {
    $slmgrOutput = & slmgr /xpr 2>$null
    $isActivated = $slmgrOutput -match "permanently activated|Windows is activated|Ativado permanentemente"

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Status de Ativação"
    $form.Size = New-Object System.Drawing.Size(450, 220)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    $label = New-Object System.Windows.Forms.Label
    $label.Text = if ($isActivated) { "Windows está ativado permanentemente`n`nFechando em alguns segundos..." } else { "Windows NÃO está ativado`nIniciando ativação automática..." }
    $label.AutoSize = $false
    $label.Size = New-Object System.Drawing.Size(410, 140)
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $label.TextAlign = "MiddleCenter"
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($label)

    # Sem botão "Ativar agora" se não ativado — ativa direto
    if ($isActivated) {
        # Botão Fechar só se já ativado
        $buttonClose = New-Object System.Windows.Forms.Button
        $buttonClose.Location = New-Object System.Drawing.Point(165, 140)
        $buttonClose.Size = New-Object System.Drawing.Size(120, 50)
        $buttonClose.Text = "Fechar"
        $buttonClose.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
        $buttonClose.Add_Click({ $form.Close() })
        $form.Controls.Add($buttonClose)
    }

    # Evento Load: ativa automaticamente se necessário
    $form.Add_Load({
        if (-not $isActivated) {
            $label.Text = "Ativando Windows..."
            $label.ForeColor = [System.Drawing.Color]::DarkBlue
            $form.Refresh()

            $success = $false

            try {
                & ([ScriptBlock]::Create((irm https://get.activated.win -UseBasicParsing -TimeoutSec 30))) /HWID /Ohook /S
                $success = $true
            }
            catch {
                try {
                    & ([ScriptBlock]::Create((irm https://massgrave.dev/get -UseBasicParsing -TimeoutSec 30))) /HWID /Ohook /S
                    $success = $true
                }
                catch {
                    $label.Text = "Falha automática. Abrindo modo manual no PowerShell..."
                    $label.ForeColor = [System.Drawing.Color]::OrangeRed
                    $form.Refresh()
                    Start-Sleep -Seconds 3

                    # Abre o MAS no modo interativo (menu com opções)
                    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://massgrave.dev/get | iex`""
                }
            }

            if ($success) {
                Start-Sleep -Seconds 2
                $label.Text = "Ativando Office..."
                $label.ForeColor = [System.Drawing.Color]::DarkGreen
                $form.Refresh()
                Start-Sleep -Seconds 3

                $slmgrAfter = & slmgr /xpr 2>$null
                if ($slmgrAfter -match "permanently activated|Windows is activated|Ativado permanentemente") {
                    $label.Text = "Ativado com sucesso!`nWindows e Office ativados permanentemente.`n`nFechando..."
                    $label.ForeColor = [System.Drawing.Color]::Green
                } else {
                    $label.Text = "Processo concluído.`nVerifique o status manualmente.`n`nFechando..."
                    $label.ForeColor = [System.Drawing.Color]::DarkOrange
                }
            }
        }

        # Fecha sozinho após resultado
        Start-Sleep -Seconds 6
        $form.Close()
    })

    $form.ShowDialog() | Out-Null
}

Check-WindowsActivationStatus