param(
    [string]$SelectionKey
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appRoot = Split-Path -Parent $scriptDir

class OfficeOption {
    [string]$Key
    [string]$Name
    [string]$Description
    [string]$ConfigPath

    OfficeOption([string]$key, [string]$name, [string]$description, [string]$configPath) {
        $this.Key = $key
        $this.Name = $name
        $this.Description = $description
        $this.ConfigPath = $configPath
    }

    [string] ToString() {
        return $this.Name
    }
}

$officeBasePath = Join-Path $appRoot "softwares\Office 2013-2024 C2R Install - Lite v7.7.7.7 r25 x64"
$officeOptions = @(
    [OfficeOption]::new(
        "office2024_basic",
        "Office 2024 Word + Excel + PowerPoint",
        "Usa o Configure.xml atual com Word, Excel e PowerPoint.",
        (Join-Path $officeBasePath "Configure.xml")
    ),
    [OfficeOption]::new(
        "office2024_full",
        "Office 2024 completo + Access + Visio + Project + Publisher",
        "Usa o XML completo com Access, Visio, Project e Publisher.",
        (Join-Path $officeBasePath "office_visio_publisher_project.xml")
    )
)

function Get-OfficeOptionByKey {
    param([string]$Key)
    return $officeOptions | Where-Object { $_.Key -eq $Key } | Select-Object -First 1
}

function Disable-OfficeUpdates {
    $regFile = Join-Path $appRoot "assets\disble_office_updates.reg"
    if (Test-Path $regFile) {
        $regeditPath = Join-Path $env:SystemRoot "regedit.exe"
        Start-Process $regeditPath -ArgumentList "/s `"$regFile`"" -Wait
    }
}

function Install-OfficeFromConfig {
    param([OfficeOption]$Option)

    if (-not $Option) {
        throw "Opcao de Office invalida."
    }

    $officeExe = Join-Path $officeBasePath "OInstall_x64.exe"
    $zipInstaller = Join-Path $officeBasePath "OInstall.zip"

    if (-not (Test-Path $officeExe)) {
        Expand-Archive -Path $zipInstaller -DestinationPath $officeBasePath -Force
    }

    if (-not (Test-Path $Option.ConfigPath)) {
        throw "Arquivo de configuracao nao encontrado: $($Option.ConfigPath)"
    }

    Start-Process -FilePath $officeExe -ArgumentList "/configure `"$($Option.ConfigPath)`"", "/activate" -Wait
    Disable-OfficeUpdates
}

if ($SelectionKey) {
    $selectedOption = Get-OfficeOptionByKey -Key $SelectionKey
    Install-OfficeFromConfig -Option $selectedOption
    exit
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Selecionar Office"
$form.Size = New-Object System.Drawing.Size(520, 240)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true

$label = New-Object System.Windows.Forms.Label
$label.Text = "Escolha como deseja instalar o Office:"
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.AutoSize = $true
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(20, 50)
$listBox.Size = New-Object System.Drawing.Size(460, 60)
$officeOptions | ForEach-Object { [void]$listBox.Items.Add($_) }
$listBox.SelectedIndex = 0
$form.Controls.Add($listBox)

$descriptionLabel = New-Object System.Windows.Forms.Label
$descriptionLabel.Location = New-Object System.Drawing.Point(20, 125)
$descriptionLabel.Size = New-Object System.Drawing.Size(460, 40)
$descriptionLabel.Text = $officeOptions[0].Description
$form.Controls.Add($descriptionLabel)

$listBox.Add_SelectedIndexChanged({
    if ($listBox.SelectedItem) {
        $descriptionLabel.Text = $listBox.SelectedItem.Description
    }
})

$buttonInstall = New-Object System.Windows.Forms.Button
$buttonInstall.Text = "Instalar"
$buttonInstall.Location = New-Object System.Drawing.Point(290, 170)
$buttonInstall.Size = New-Object System.Drawing.Size(90, 30)
$buttonInstall.Add_Click({
    $selected = $listBox.SelectedItem
    if (-not $selected) {
        return
    }

    $form.Close()

    try {
        Install-OfficeFromConfig -Option $selected
        [System.Windows.Forms.MessageBox]::Show(
            "Fluxo do Office concluido.",
            "Office",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Falha ao instalar o Office.`n$($_.Exception.Message)",
            "Office",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
})
$form.Controls.Add($buttonInstall)

$buttonCancel = New-Object System.Windows.Forms.Button
$buttonCancel.Text = "Cancelar"
$buttonCancel.Location = New-Object System.Drawing.Point(390, 170)
$buttonCancel.Size = New-Object System.Drawing.Size(90, 30)
$buttonCancel.Add_Click({ $form.Close() })
$form.Controls.Add($buttonCancel)

[void]$form.ShowDialog()
