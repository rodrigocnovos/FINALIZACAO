Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Check-WindowsActivationStatus {
    # Verificação mais confiável de ativação (slmgr é o oficial)
    $slmgrOutput = & slmgr /xpr
    $isActivated = $slmgrOutput -match "permanently activated|Windows is activated" -or $slmgrOutput -match "Ativado permanentemente"

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Status de Ativação do Windows"
    $form.Size = New-Object System.Drawing.Size(380, 180)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    $label = New-Object System.Windows.Forms.Label
    $label.Text = if ($isActivated) { "Windows está ativado" } else { "Windows NÃO está ativado" }
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(100, 20)
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
    $form.Controls.Add($label)

    $buttonOK = New-Object System.Windows.Forms.Button
    $buttonOK.Location = New-Object System.Drawing.Point(130, 70)
    $buttonOK.Size = New-Object System.Drawing.Size(120, 40)
    $buttonOK.Text = if ($isActivated) { "OK" } else { "Ativar agora (HWID + Office)" }
    $buttonOK.Font = New-Object System.Drawing.Font("Segoe UI", 9)
    $buttonOK.Enabled = $true

    $buttonOK.Add_Click({
        if (-not $isActivated) {
            try {
                # Forma oficial recomendada (primária) - HWID para Windows + TSforge para Office (permanente, sem task)
                & ([ScriptBlock]::Create((irm https://get.activated.win -UseBasicParsing -TimeoutSec 15))) /HWID /Z-Office /S
            }
            catch {
                try {
                    # Fallback (se primária bloqueada por ISP/DNS/antivírus)
                    & ([ScriptBlock]::Create((irm https://massgrave.dev/get -UseBasicParsing -TimeoutSec 15))) /HWID /Z-Office /S
                }
                catch {
                    [System.Windows.Forms.MessageBox]::Show(
                        "Falha ao executar o script de ativação.`n`nPossíveis causas:`n- Sem internet`n- Bloqueio por antivírus/firewall/ISP`n- Rode como administrador`n`nTente manualmente: irm https://get.activated.win | iex",
                        "Erro na Ativação",
                        [System.Windows.Forms.MessageBoxButtons]::OK,
                        [System.Windows.Forms.MessageBoxIcon]::Error
                    )
                }
            }

            # Atualiza o label após tentativa (opcional, mas melhora UX)
            $slmgrOutputAfter = & slmgr /xpr
            if ($slmgrOutputAfter -match "permanently activated|Windows is activated|Ativado permanentemente") {
                $label.Text = "Ativação concluída com sucesso!"
                $buttonOK.Text = "OK"
            }
        }

        $form.Close()
    })

    $form.Controls.Add($buttonOK)

    # Centraliza o botão se necessário
    $buttonOK.Anchor = "None"
    $form.AcceptButton = $buttonOK

    $form.ShowDialog() | Out-Null
}

# Chamada da função principal
Check-WindowsActivationStatus