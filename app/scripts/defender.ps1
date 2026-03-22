function Exibir-Formulario {
    Add-Type -AssemblyName System.Windows.Forms

    # Criar formulário
    $form = New-Object Windows.Forms.Form
    $form.TopMost = $true
    $form.Size = New-Object Drawing.Size(300, 150)
    $form.StartPosition = "CenterScreen"
    $form.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Configuração de Antivírus"))

    # Adicionar um rótulo informativo
    $label = New-Object Windows.Forms.Label
    $label.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("DESATIVE O ANTIVÍRUS TEMPORARIAMENTE"))
    $label.Location = New-Object Drawing.Point(20, 20)
    $label.AutoSize = $true
    $form.Controls.Add($label)

    # Criar botão OK
    $buttonOK = New-Object Windows.Forms.Button
    $buttonOK.Location = New-Object Drawing.Point(100, 60)
    $buttonOK.Size = New-Object Drawing.Size(90, 40)
    $buttonOK.Text = "OK"
    $buttonOK.Enabled = $false  # Desabilitado inicialmente
    $form.Controls.Add($buttonOK)

    # Configurar evento de clique do botão
    $buttonOK.Add_Click({
        Write-Host "Botão OK pressionado. Real-Time Protection está desativado."
        $form.Close()
    })

    # Timer para atualizar o estado do botão
    $timer = New-Object Windows.Forms.Timer
    $timer.Interval = 1000  # Intervalo de 1 segundo para verificar o status
    $timer.Add_Tick({
        $realTimeProtectionEnabled = (Get-MpPreference).DisableRealtimeMonitoring -eq $false
        $buttonOK.Enabled = -not $realTimeProtectionEnabled  # Habilita apenas se o Real-Time Protection estiver desativado
    })
    $timer.Start()

    # Mostrar formulário
    # $form.FormClosed.Add({
    #     $timer.Stop()  # Parar o timer ao fechar o formulário
    # })
    $form.ShowDialog()
}

# Abrir configurações do Windows Defender
$opcoes = "windowsdefender://ThreatSettings"
$programa = "explorer.exe"
Start-Process $programa -ArgumentList $opcoes -NoNewWindow -PassThru -Wait

# Verificar o status do Real-Time Protection
$realTimeProtectionEnabled = (Get-MpPreference).DisableRealtimeMonitoring -eq $false

# Exibir o formulário apenas se o Real-Time Protection estiver ativado
if ($realTimeProtectionEnabled) {
    Exibir-Formulario
} else {
    Write-Host "O Real-Time Protection já está desativado."
}
