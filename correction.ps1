# Habilitar Windows Forms
Add-Type -AssemblyName System.Windows.Forms

# Criar o formulário
$form = New-Object System.Windows.Forms.Form
$form.Text = "Escolha o script para executar"
# $textBox.Multiline = $true     # Permite várias linhas
$form.Size = New-Object System.Drawing.Size(600, 400)
$form.StartPosition = "CenterScreen"

# Lista de opções com texto e ações
$options = @(
    @{ Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Coreção para compartilhamentos antigos e menos seguros - SMBv1 ATIVAR")); Action = {
        Write-Host "Executando instalação smbv1 para compatibilidade..."
        Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -All -NoRestart

    }},
    @{ Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Corrigir erro 0x80070035 (Compartilhamento de rede")); Action = {
        Write-Host "Executando fix para erro 0x80070035..."
        Set-SmbClientConfiguration -EnableInsecureGuestLogons $true -Force
        Set-SmbClientConfiguration -RequireSecuritySignature $false -Force
        Set-SmbServerConfiguration -RequireSecuritySignature $false -Force
    }},
    @{ Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Corrigir erro de impressão 0x00000709 (RPC over TCP)")); Action = {
        Write-Host "Executando fix para erro 0x00000709..."
        reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC" /v RpcUseNamedPipeProtocol /t REG_DWORD /d 1 /f
        reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Printers\RPC" /v RpcProtocols /t REG_DWORD /d 0x7 /f
    }},
    @{ Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Corrigir erro de impressão 0x0000011b (Impressão de rede)")); Action = {
        Write-Host "Executando fix para erro 0x0000011b..."
        reg add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Print" /v "RpcAuthnLevelPrivacyEnabled" /t REG_DWORD /d 0 /f
    }},
    @{ Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Executar o Massgrave -> irm https://get.activated.win | iex")); Action = {
        Write-Host "Confira a janela do ativado aberta e responda"
        irm https://get.activated.win | iex
    }}


    
)

# Criar caixas de seleção dinamicamente
$checkBoxes = @()
$yPosition = 30
foreach ($option in $options) {
    $checkBox = New-Object System.Windows.Forms.CheckBox
    $checkBox.Text = $option.Text
    $checkBox.Location = New-Object System.Drawing.Point(20, $yPosition)
    $checkBox.AutoSize = $true
    
    $form.Controls.Add($checkBox)
    $checkBoxes += $checkBox
    $yPosition += 40
}

# Botão de executar
$button = New-Object System.Windows.Forms.Button
$button.Text = "Executar"
$button.Location = New-Object System.Drawing.Point(20, $yPosition)
$button.Size = New-Object System.Drawing.Size(100, 30)

# Adicionar ação ao botão
$button.Add_Click({
    for ($i = 0; $i -lt $checkBoxes.Count; $i++) {
        if ($checkBoxes[$i].Checked) {
            $options[$i].Action.Invoke()
        }
    }
    $mensaagem = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("REINICIE PARA APLICAR E REPITA OS OUTROS PC´S"))
    [System.Windows.Forms.MessageBox]::Show($mensaagem
        ,
        "Status",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    $form.Close()
})

# Adicionar botão ao formulário
$form.Controls.Add($button)

# Mostrar o formulário
$form.ShowDialog()
