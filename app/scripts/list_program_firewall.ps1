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

# Chaves de registro para buscar programas instalados
$uninstallKeys = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

# Hash para evitar duplicação de programas
$uniquePrograms = @{}
$executablePathsSet = @{}  # Para armazenar caminhos únicos dos executáveis

foreach ($key in $uninstallKeys) {
    $programs = Get-ItemProperty $key | Where-Object { $_.DisplayName -and $_.UninstallString }
    foreach ($program in $programs) {
        # Verifica se o DisplayName é válido e único
        if ($program.DisplayName -and -not $uniquePrograms.ContainsKey($program.DisplayName)) {
            $uniquePrograms[$program.DisplayName] = $program
            $checkedListBox.Items.Add($program.DisplayName) | Out-Null
        }
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
    foreach ($programName in $selectedPrograms) {
        $installLocation = $uniquePrograms[$programName].InstallLocation
        if ($installLocation) {
            Write-Host "Pasta de instalação para $programName"
            Write-Host $installLocation
            $executablePaths = Get-ChildItem -Path $installLocation -Filter "*.exe" -Recurse | Select-Object -ExpandProperty FullName
            foreach ($executablePath in $executablePaths) {
                if (-not $executablePathsSet.Contains($executablePath)) {
                    $executablePathsSet[$executablePath] = $true
                    Write-Host "- $executablePath"
                    # Criar regras de firewall aqui (necessita privilégios de administrador)
                    New-NetFirewallRule -DisplayName "Bloqueio $programName" -Direction Outbound -Program $executablePath -Action Block
                    New-NetFirewallRule -DisplayName "Bloqueio $programName" -Direction Inbound -Program $executablePath -Action Block
                }
            }
        }
    }
    $form.Close()
})
$form.Controls.Add($buttonOK)

$form.ShowDialog()
