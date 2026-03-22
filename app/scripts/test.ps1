Add-Type -AssemblyName System.Windows.Forms

# Lista de testes com URLs
$testes = @(
    @{Texto = "Teste de teclas"; URL = "https://en.key-test.ru/"},
    @{Texto = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Teste de latência de teclas")); URL = "https://keyboardtester.info/keyboard-latency-test/"},
    @{Texto = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Teste de latência do mouse")); URL = "https://www.vsynctester.com/testing/mouse.html"},
    @{Texto = "Teste de Microfone"; URL = "https://micworker.com/pt"},
    @{Texto = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Teste de câmera")); URL = "https://pt.webcamtests.com/"},
    @{Texto = "Teste de Frame Rate"; URL = "https://www.testufo.com/framerates-versus"},
    @{Texto = "Teste de pixel no monitor"; URL = "https://www.eizo.be/monitor-test/"},
    @{Texto = "Teste de V-Sync e Input Lag"; URL = "https://www.vsynctester.com/"}
)

# Criação do formulário
$form = New-Object Windows.Forms.Form
$form.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Seleção de Testes Online"))
$form.Size = New-Object Drawing.Size(400, 400)
$form.StartPosition = "CenterScreen"

# Título no formulário
$label = New-Object Windows.Forms.Label
$label.Text = "Selecione os testes que deseja abrir:"
$label.Location = New-Object Drawing.Point(20, 20)
$label.AutoSize = $true
$form.Controls.Add($label)

# Criação das checkboxes
$checkboxes = @()
$yPosition = 50
foreach ($teste in $testes) {
    $checkbox = New-Object Windows.Forms.CheckBox
    $checkbox.Text = $teste.Texto
    $checkbox.Tag = $teste.URL
    $checkbox.Location = New-Object Drawing.Point(20, $yPosition)
    $checkbox.AutoSize = $true
    $form.Controls.Add($checkbox)
    $checkboxes += $checkbox
    $yPosition += 30
}

# Botão para abrir os sites selecionados
$buttonOK = New-Object Windows.Forms.Button
$buttonOK.Text = "Abrir Selecionados"
$buttonOK.Location = New-Object Drawing.Point(100, 300)
$buttonOK.Size = New-Object Drawing.Size(120, 30)
$buttonOK.Add_Click({
    foreach ($checkbox in $checkboxes) {
        if ($checkbox.Checked) {
            Start-Process $checkbox.Tag
        }
    }
    
    $form.Close()
})
$form.Controls.Add($buttonOK)

# Botão para cancelar
$buttonCancel = New-Object Windows.Forms.Button
$buttonCancel.Text = "Cancelar"
$buttonCancel.Location = New-Object Drawing.Point(230, 300)
$buttonCancel.Size = New-Object Drawing.Size(80, 30)
$buttonCancel.Add_Click({
    $form.Close()
})
$form.Controls.Add($buttonCancel)

# Exibe o formulário
$form.ShowDialog()
