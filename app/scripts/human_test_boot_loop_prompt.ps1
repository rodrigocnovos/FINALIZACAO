Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$remainingSeconds = 10
$removeLoop = $false
$baseWindowTitle = "FINALIZACAO - Inicio Automatico"
$totalSeconds = 10

$form = New-Object System.Windows.Forms.Form
$form.Text = "$baseWindowTitle (10)"
$form.Size = New-Object System.Drawing.Size(800, 380)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::WhiteSmoke

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Loop de teste humano detectado"
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$titleLabel.Location = New-Object System.Drawing.Point(20, 18)
$titleLabel.Size = New-Object System.Drawing.Size(640, 28)
$form.Controls.Add($titleLabel)

$bodyLabel = New-Object System.Windows.Forms.Label
$bodyLabel.Font = New-Object System.Drawing.Font("Segoe UI", 10)
$bodyLabel.Location = New-Object System.Drawing.Point(20, 58)
$bodyLabel.AutoSize = $true
$bodyLabel.MaximumSize = New-Object System.Drawing.Size(740, 0)
$bodyLabel.Text = "O teste humano esta configurado para iniciar automaticamente neste boot.`r`n`r`nClique em 'Remover' para apagar o inicio automatico e parar o loop nos proximos boots.`r`n`r`nSe quiser continuar apenas neste boot, aguarde a contagem ou clique em 'Continuar'."
$form.Controls.Add($bodyLabel)

$removeButton = New-Object System.Windows.Forms.Button
$removeButton.Text = "Remover"
$removeButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$removeButton.Size = New-Object System.Drawing.Size(140, 40)
$removeButton.Location = New-Object System.Drawing.Point(250, 260)
$removeButton.Add_Click({
    $script:removeLoop = $true
    $form.Close()
})
$form.Controls.Add($removeButton)

$continueButton = New-Object System.Windows.Forms.Button
$continueButton.Text = "Continuar (10)"
$continueButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$continueButton.Size = New-Object System.Drawing.Size(160, 40)
$continueButton.Location = New-Object System.Drawing.Point(400, 260)
$continueButton.Add_Click({
    $form.Close()
})
$form.Controls.Add($continueButton)

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({
    $script:remainingSeconds--
    if ($script:remainingSeconds -le 0) {
        $timer.Stop()
        $form.Close()
        return
    }

    $form.Text = "$baseWindowTitle ($($script:remainingSeconds))"
    $continueButton.Text = "Continuar ($($script:remainingSeconds))"
    $continueButton.Refresh()
    $form.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
})

$form.Add_Shown({
    $form.Activate()
    $form.BringToFront()
    $removeButton.Focus()
    $timer.Start()
})

$form.Add_FormClosed({
    $timer.Stop()
})

$form.ShowDialog() | Out-Null

if ($removeLoop) {
    exit 6
}

exit 7
