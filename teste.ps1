# Configura o encoding da saída para UTF-8
#$OutputEncoding = [System.Text.Encoding]::UTF8


Add-Type -AssemblyName System.Windows.Forms

$form = New-Object Windows.Forms.Form
$form.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Opções de finalização"))
$form.Size = New-Object Drawing.Size(400, 600)  # Aumentamos a altura para acomodar as checkboxes
$form.StartPosition = "CenterScreen"
$form.TopMost = $true  # Mantém o formulário sempre em primeiro plano


$label = New-Object Windows.Forms.Label
$label.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Nome do técnico responsável"))
$label.Location = New-Object Drawing.Point(20, 20)
$label.AutoSize = $true
$form.Controls.Add($label)

$textBox = New-Object Windows.Forms.TextBox
$textBox.Location = New-Object Drawing.Point(20, 50)
$textBox.Size = New-Object Drawing.Size(300, 30)
$form.Controls.Add($textBox)

# CheckBoxes com opções
$checkBox1 = New-Object Windows.Forms.CheckBox
$checkBox1.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Limpeza de temporários e arquivos da instalacao"))
# $checkBox1.AutoSize = $false
$checkBox1.Checked = $true
$checkBox1.Location = New-Object Drawing.Point(20, 90)
$form.Controls.Add($checkBox1)

$checkBox2 = New-Object Windows.Forms.CheckBox
$checkBox1.AutoSize = $true
$checkBox2.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Limpeza de rastros de uso"))
$checkBox2.Location = New-Object Drawing.Point(20, 120)
$form.Controls.Add($checkBox2)

$checkBox3 = New-Object Windows.Forms.CheckBox
$checkBox3.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Instalar pacote do ninite"))
$checkBox3.Location = New-Object Drawing.Point(20, 150)
$form.Controls.Add($checkBox3)

$checkBox4 = New-Object Windows.Forms.CheckBox
$checkBox4.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Anydesk"))
$checkBox4.Location = New-Object Drawing.Point(20, 180)
$form.Controls.Add($checkBox4)

$checkBox5 = New-Object Windows.Forms.CheckBox
$checkBox5.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Instalar office 2021 x64"))
$checkBox5.Location = New-Object Drawing.Point(20, 210)
$form.Controls.Add($checkBox5)

$checkBox6 = New-Object Windows.Forms.CheckBox
$checkBox6.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Selecionar programas para bloqueio no Firewall"))
$checkBox6.Location = New-Object Drawing.Point(20, 240)
$form.Controls.Add($checkBox6)




$buttonOK = New-Object Windows.Forms.Button
$buttonOK.Location = New-Object Drawing.Point(80, 400)
$buttonOK.Size = New-Object Drawing.Size(80, 30)
$buttonOK.Text = "OK"
$buttonOK.Add_Click({
    $input = $textBox.Text
    $opcao1 = $checkBox1.Checked
    $opcao2 = $checkBox2.Checked
    $opcao3 = $checkBox3.Checked
    $opcao4 = $checkBox4.Checked

    Write-Host "Você digitou: $input"
    Write-Host "Opção 1 selecionada: $opcao1"
    Write-Host "Opção 2 selecionada: $opcao2"
    Write-Host "Opção 3 selecionada: $opcao3"
    Write-Host "Opção 4 selecionada: $opcao4"

    $form.Close()
})
$form.Controls.Add($buttonOK)

$buttonCancel = New-Object Windows.Forms.Button
$buttonCancel.Location = New-Object Drawing.Point(170, 400)
$buttonCancel.Size = New-Object Drawing.Size(80, 30)
$buttonCancel.Text = "Cancelar"
$buttonCancel.Add_Click({ $form.Close() })
$form.Controls.Add($buttonCancel)

$form.ShowDialog()
