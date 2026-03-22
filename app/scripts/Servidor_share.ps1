# Habilitar Windows Forms
Add-Type -AssemblyName System.Windows.Forms

# Criar o formulário
$form = New-Object System.Windows.Forms.Form
$form.Text = "Escolha o que vai abrir"
# $textBox.Multiline = $true     # Permite várias linhas
$form.Size = New-Object System.Drawing.Size(600, 400)
$form.StartPosition = "CenterScreen"

# Lista de opções com texto e ações
$options = @(
    @{ Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Abrir Servidor de arquivos pela WEB")); Action = {
        Write-Host "abrir no navegador"
        Start-Process http://177.107.97.38:9123
        # Enable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -All -NoRestart

    }},
    @{ Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Abrir pelo navegador de arquivos do Windows/Rede Assistência")); Action = {
        Write-Host "abrir no explorador de arquivos"
        explorer \\172.20.0.42
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
   
    $form.Close()
})

# Adicionar botão ao formulário
$form.Controls.Add($button)

# Mostrar o formulário
$form.ShowDialog()
