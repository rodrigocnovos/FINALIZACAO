# Configura o encoding da saída para UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName System.Windows.Forms

$form = New-Object Windows.Forms.Form
$form.Text = "Lista de Programas Instalados"
$form.Size = New-Object Drawing.Size(500, 400)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true  # Mantém o formulário sempre em primeiro plano

# Define o encoding do formulário como UTF-8
$form.Encoding = [System.Text.Encoding]::UTF8

$label = New-Object Windows.Forms.Label
$label.Text = "Selecione os programas:"
$label.Location = New-Object Drawing.Point(20, 20)
$label.AutoSize = $true
$form.Controls.Add($label)

$checkedListBox = New-Object Windows.Forms.CheckedListBox
$checkedListBox.Location = New-Object Drawing.Point(20, 50)
$checkedListBox.Size = New-Object Drawing.Size(460, 250)

# Lista os programas instalados usando o registro do Windows
$uninstallKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
$programs = Get-ItemProperty $uninstallKey | Where-Object { $_.DisplayName -and $_.UninstallString }

foreach ($program in $programs) {
    $installLocation = $program.InstallLocation

    # Verifica se a pasta de instalação não está vazia antes de adicionar o programa à lista
    if ($installLocation) {
        $checkedListBox.Items.Add($program.DisplayName) | Out-Null
    }
}

$form.Controls.Add($checkedListBox)

$buttonOK = New-Object Windows.Forms.Button
$buttonOK.Location = New-Object Drawing.Point(20, 320)
$buttonOK.Size = New-Object Drawing.Size(100, 30)
$buttonOK.Text = "OK"
$buttonOK.Add_Click({
    $selectedPrograms = $checkedListBox.CheckedItems
    Write-Host "Pasta de instalação dos programas selecionados:"
    foreach ($program in $selectedPrograms) {
        $installLocation = GetProgramInstallLocation $program
        Write-Host "- $installLocation"
    }
    $form.Close()
})
$form.Controls.Add($buttonOK)

# Função para obter a pasta de instalação do programa
function GetProgramInstallLocation($programName) {
    $uninstallKey = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $program = Get-ItemProperty $uninstallKey | Where-Object { $_.DisplayName -eq $programName }
    return $program.InstallLocation
}

$form.ShowDialog()
