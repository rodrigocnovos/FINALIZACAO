Add-Type -AssemblyName System.Windows.Forms

# Cria um formulário
$form = New-Object System.Windows.Forms.Form
$form.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Entrada e Exibição de Texto com ç"))
$form.Size = New-Object System.Drawing.Size(400, 200)
$form.StartPosition = "CenterScreen"

# Cria uma caixa de texto para entrada
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Multiline = $true
$textBox.Size = New-Object System.Drawing.Size(350, 100)
$textBox.Location = New-Object System.Drawing.Point(25, 25)
$form.Controls.Add($textBox)

# Cria um botão para exibir o texto
$button = New-Object System.Windows.Forms.Button
$button.Text = "Exibir Texto"
$button.Size = New-Object System.Drawing.Size(100, 30)
$button.Location = New-Object System.Drawing.Point(150, 140)
$button.Add_Click({
    $inputText = $textBox.Text
    [System.Windows.Forms.MessageBox]::Show($inputText, [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Texto Inserido com ç")), "OK", [System.Windows.Forms.MessageBoxIcon]::Information)
})
$form.Controls.Add($button)

# Exibe o formulário
$form.ShowDialog()
