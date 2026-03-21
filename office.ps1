param(
    [string]$SelectionKey
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$tempDir = Join-Path $env:TEMP "FINALIZACAO_Office"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

class OfficeOption {
    [string]$Key
    [string]$Name
    [string]$Description
    [string]$Type
    [string]$Url
    [string]$FileName
    [string]$FallbackName
    [string]$FallbackUrl
    [string]$FallbackFileName

    OfficeOption([string]$key, [string]$name, [string]$description, [string]$type, [string]$url, [string]$fileName, [string]$fallbackName, [string]$fallbackUrl, [string]$fallbackFileName) {
        $this.Key = $key
        $this.Name = $name
        $this.Description = $description
        $this.Type = $type
        $this.Url = $url
        $this.FileName = $fileName
        $this.FallbackName = $fallbackName
        $this.FallbackUrl = $fallbackUrl
        $this.FallbackFileName = $fallbackFileName
    }

    [string] ToString() {
        return $this.Name
    }
}

$officeOptions = @(
    [OfficeOption]::new(
        "local2024",
        "Local 2024 x64 PT-BR",
        "Usa o Louncher da pasta para iniciar mais rápido a instalação",
        "local",
        "",
        "",
        "",
        "",
        ""
    ),
    [OfficeOption]::new(
        "m365full",
        "Microsoft 365 Apps Full x64 PT-BR",
        "Pacote maior com Access, Excel, OneNote, Outlook, PowerPoint, Publisher, Word e OneDrive.",
        "download",
        "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=O365ProPlusRetail&language=pt-br&platform=x64&version=O16GA",
        "O365ProPlusRetail_pt-br_x64.exe",
        "Microsoft 365 Apps Basic x64 PT-BR",
        "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=O365AppsBasicRetail&language=pt-br&platform=x64&version=O16GA",
        "O365AppsBasicRetail_pt-br_x64.exe"
    ),
    [OfficeOption]::new(
        "m365basic",
        "Microsoft 365 Apps Basic x64 PT-BR",
        "Fallback menor com Excel, OneNote, PowerPoint, Word e OneDrive.",
        "download",
        "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=O365AppsBasicRetail&language=pt-br&platform=x64&version=O16GA",
        "O365AppsBasicRetail_pt-br_x64.exe",
        "",
        "",
        ""
    ),
    [OfficeOption]::new(
        "homebusiness2024",
        "Office Home Business 2024 x64 PT-BR",
        "Fallback perpetuo com Excel, OneNote, Outlook, PowerPoint, Word e OneDrive.",
        "download",
        "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=HomeBusiness2024Retail&language=pt-br&platform=x64&version=O16GA",
        "HomeBusiness2024Retail_pt-br_x64.exe",
        "Office Home 2024 x64 PT-BR",
        "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=Home2024Retail&language=pt-br&platform=x64&version=O16GA",
        "Home2024Retail_pt-br_x64.exe"
    ),
    [OfficeOption]::new(
        "home2024",
        "Office Home 2024 x64 PT-BR",
        "Fallback menor com Excel, OneNote, PowerPoint, Word e OneDrive.",
        "download",
        "https://c2rsetup.officeapps.live.com/c2r/download.aspx?ProductreleaseID=Home2024Retail&language=pt-br&platform=x64&version=O16GA",
        "Home2024Retail_pt-br_x64.exe",
        "",
        "",
        ""
    )
)

function Get-OfficeOptionByKey {
    param([string]$Key)
    return $officeOptions | Where-Object { $_.Key -eq $Key } | Select-Object -First 1
}

function Disable-OfficeUpdates {
    $regFile = Join-Path $scriptDir "disble_office_updates.reg"
    if (Test-Path $regFile) {
        $regeditPath = Join-Path $env:SystemRoot "regedit.exe"
        Start-Process $regeditPath -ArgumentList "/s `"$regFile`"" -Wait
    }
}

function Install-LocalOffice {
    $officeExe = Join-Path $scriptDir "softwares\Office 2013-2024 C2R Install - Lite v7.7.7.7 r25 x64\OInstall_x64.exe"
    $zipInstaller = Join-Path $scriptDir "softwares\Office 2013-2024 C2R Install - Lite v7.7.7.7 r25 x64\OInstall.zip"
    $extractPath = Join-Path $scriptDir "softwares\Office 2013-2024 C2R Install - Lite v7.7.7.7 r25 x64"
    $configPath = Join-Path $extractPath "Configure.xml"

    if (-not (Test-Path $officeExe)) {
        Expand-Archive -Path $zipInstaller -DestinationPath $extractPath -Force
    }

    Start-Process -FilePath $officeExe -ArgumentList "/configure `"$configPath`"", "/activate" -Wait
    Disable-OfficeUpdates
}

function Download-And-RunInstaller {
    param (
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$FileName,
        [string]$FallbackUrl,
        [string]$FallbackFileName,
        [string]$FallbackName
    )

    $installerPath = Join-Path $tempDir $FileName

    try {
        Write-Host "Baixando instalador: $FileName"
        Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $installerPath
    } catch {
        if ($FallbackUrl -and $FallbackFileName) {
            $result = [System.Windows.Forms.MessageBox]::Show(
                "Falha ao baixar a opcao principal.`n`nDeseja tentar o fallback: $FallbackName ?",
                "Office",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )

            if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
                Download-And-RunInstaller -Url $FallbackUrl -FileName $FallbackFileName
                return
            }
        }

        throw
    }

    Start-Process -FilePath $installerPath -Wait
    Disable-OfficeUpdates
}

function Invoke-OfficeInstall {
    param([OfficeOption]$Option)

    if (-not $Option) {
        throw "Opcao de Office invalida."
    }

    if ($Option.Type -eq "local") {
        Install-LocalOffice
        return
    }

    Download-And-RunInstaller -Url $Option.Url -FileName $Option.FileName -FallbackUrl $Option.FallbackUrl -FallbackFileName $Option.FallbackFileName -FallbackName $Option.FallbackName
}

if ($SelectionKey) {
    $selectedOption = Get-OfficeOptionByKey -Key $SelectionKey
    Invoke-OfficeInstall -Option $selectedOption
    exit
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Selecionar Office"
$form.Size = New-Object System.Drawing.Size(520, 330)
$form.StartPosition = "CenterScreen"
$form.TopMost = $true

$label = New-Object System.Windows.Forms.Label
$label.Text = "Escolha como deseja instalar o Office:"
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.AutoSize = $true
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(20, 50)
$listBox.Size = New-Object System.Drawing.Size(460, 120)
$officeOptions | ForEach-Object { [void]$listBox.Items.Add($_) }
$listBox.SelectedIndex = 0
$form.Controls.Add($listBox)

$descriptionLabel = New-Object System.Windows.Forms.Label
$descriptionLabel.Location = New-Object System.Drawing.Point(20, 180)
$descriptionLabel.Size = New-Object System.Drawing.Size(460, 50)
$descriptionLabel.Text = $officeOptions[0].Description
$form.Controls.Add($descriptionLabel)

$listBox.Add_SelectedIndexChanged({
    if ($listBox.SelectedItem) {
        $descriptionLabel.Text = $listBox.SelectedItem.Description
    }
})

$buttonInstall = New-Object System.Windows.Forms.Button
$buttonInstall.Text = "Instalar"
$buttonInstall.Location = New-Object System.Drawing.Point(290, 240)
$buttonInstall.Size = New-Object System.Drawing.Size(90, 30)
$buttonInstall.Add_Click({
    $selected = $listBox.SelectedItem
    if (-not $selected) {
        return
    }

    $form.Close()

    try {
        Invoke-OfficeInstall -Option $selected

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
$buttonCancel.Location = New-Object System.Drawing.Point(390, 240)
$buttonCancel.Size = New-Object System.Drawing.Size(90, 30)
$buttonCancel.Add_Click({ $form.Close() })
$form.Controls.Add($buttonCancel)

[void]$form.ShowDialog()
