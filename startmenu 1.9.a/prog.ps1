Add-Type -AssemblyName System.Windows.Forms

# Cria uma instância do formulário
$form = New-Object Windows.Forms.Form
$form.Text = "Barra de Progresso"
$form.Size = New-Object Drawing.Size(300, 100)

# Cria uma instância da barra de progresso
$progressBar = New-Object Windows.Forms.ProgressBar
$progressBar.Location = New-Object Drawing.Point(20, 30)
$progressBar.Size = New-Object Drawing.Size(260, 20)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Step = 10  # Defina o valor do incremento

# Adiciona a barra de progresso ao formulário
$form.Controls.Add($progressBar)

# Função para simular uma rotina
function SimulateRoutine {
    $progressBar.PerformStep()
    Start-Sleep -Milliseconds 1500  # Simula o tempo de execução da rotina
}

# Evento de clique para iniciar a simulação
$button = New-Object Windows.Forms.Button
$button.Text = "Iniciar"
$button.Location = New-Object Drawing.Point(120, 60)
$button.Add_Click({
    $progressBar.Value = 0  # Zera o valor antes de iniciar a simulação
    for ($i = 1; $i -le 10; $i++) {
        SimulateRoutine
    }
    [Windows.Forms.MessageBox]::Show("Rotinas concluídas!", "Concluído")
})
$form.Controls.Add($button)

# Exibe o formulário
$form.ShowDialog()
