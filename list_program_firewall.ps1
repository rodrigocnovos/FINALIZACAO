
Add-Type -AssemblyName System.Windows.Forms

$form = New-Object Windows.Forms.Form
$form.Text = "Lista de Programas Instalados"
$form.Size = New-Object Drawing.Size(500, 400)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true  # Mantém o formulário sempre em primeiro plano


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
    Write-Host "Caminho dos executáveis dos programas selecionados:"
    foreach ($program in $selectedPrograms) {
        $installLocation = GetProgramInstallLocation $program
        if ($installLocation) {
            $executablePaths = Get-ChildItem -Path $installLocation -Filter "*.exe" -Recurse | Select-Object -ExpandProperty FullName
            foreach ($executablePath in $executablePaths) {
                Write-Host "- $executablePath"
                # Criar regras de firewall aqui (necessita privilégios de administrador)
                # Exemplo: New-NetFirewallRule -DisplayName "Bloqueio $program" -Direction Outbound -Program $executablePath -Action Block
                New-NetFirewallRule -DisplayName "Bloqueio $program" -Direction Outbound -Program $executablePath -Action Block
            }
        }
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
