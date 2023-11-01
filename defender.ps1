function Exibir-Formulario {
    Add-Type -AssemblyName System.Windows.Forms

    $form = New-Object Windows.Forms.Form
    $form.TopMost = $true  # Mantém o formulário sempre em primeiro plano
    $form.Size = New-Object Drawing.Size(300, 150)  # Aumentamos a altura para acomodar as checkboxes
    $form.StartPosition = "CenterScreen"

    $label = New-Object Windows.Forms.Label
    $label.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("DESATIVE O ANTIVIRUS TEMPORARIAMENTE"))
    $label.Location = New-Object Drawing.Point(20, 20)
    $label.AutoSize = $true
    $form.Controls.Add($label)

    $buttonOK = New-Object Windows.Forms.Button
    $buttonOK.Location = New-Object Drawing.Point(100, 60)
    $buttonOK.Size = New-Object Drawing.Size(90, 40)
    $buttonOK.Text = "OK"

    $buttonOK.Add_Click({

	$realTimeProtectionEnabled = (Get-MpPreference).DisableRealtimeMonitoring -eq $false

      if ($realTimeProtectionEnabled) {
   		 Exibir-Formulario
	} else {
    		Write-Host "O Real-Time Protection já está desativado."
		$form.Close()
	}
        
    })
    $form.Controls.Add($buttonOK)

    $form.ShowDialog()
}

# Abrir as configurações do Windows Defender
$opcoes = "windowsdefender://ThreatSettings"
$programa = "explorer.exe"
Start-Process $programa -ArgumentList $opcoes -NoNewWindow -PassThru -Wait

# Verificar o status do Real-Time Protection
$realTimeProtectionEnabled = (Get-MpPreference).DisableRealtimeMonitoring -eq $false

# Se o Real-Time Protection estiver ativado, exibir o formulário
if ($realTimeProtectionEnabled) {
    Exibir-Formulario
} else {
    Write-Host "O Real-Time Protection já está desativado."
}
