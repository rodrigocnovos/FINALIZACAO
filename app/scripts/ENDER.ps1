#Desbloquear os arquivos baixados da internet
Unblock-File *


#Colocar o Edge como padrão
# Diretório temporário para armazenar o arquivo de associações
$tempDir = "C:\Temp"
$assocFile = "$tempDir\AppAssociations.xml"

# Garantir que o diretório existe
if (!(Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force
}

# Exportar as associações de aplicativos padrão existentes
Write-Host "Exportando associações atuais para $assocFile..."
Dism /Online /Export-DefaultAppAssociations:$assocFile

# Verificar se o arquivo foi exportado corretamente
if (!(Test-Path $assocFile)) {
    Write-Error "Falha ao exportar as associações padrão."
    exit 1
}

# Ler o conteúdo do arquivo exportado
Write-Host "Modificando o arquivo de associações para definir o Microsoft Edge..."
$appAssocContent = Get-Content -Path $assocFile

# Substituir as associações de navegadores existentes para usar o Microsoft Edge
$updatedContent = $appAssocContent -replace '<Association Identifier="\.htm".*?>', '<Association Identifier=".htm" ProgId="MSEdgeHTM" ApplicationName="Microsoft Edge" />'
$updatedContent = $updatedContent -replace '<Association Identifier="\.html".*?>', '<Association Identifier=".html" ProgId="MSEdgeHTM" ApplicationName="Microsoft Edge" />'
$updatedContent = $updatedContent -replace '<Association Identifier="http".*?>', '<Association Identifier="http" ProgId="MSEdgeHTM" ApplicationName="Microsoft Edge" />'
$updatedContent = $updatedContent -replace '<Association Identifier="https".*?>', '<Association Identifier="https" ProgId="MSEdgeHTM" ApplicationName="Microsoft Edge" />'

# Salvar as alterações no arquivo
$updatedContent | Set-Content -Path $assocFile -Force

# Importar o arquivo atualizado para aplicar as associações
Write-Host "Importando as novas associações..."
Dism /Online /Import-DefaultAppAssociations:$assocFile

# Verificar sucesso
if ($?) {
    Write-Host "Microsoft Edge foi definido como navegador padrão com sucesso."
} else {
    Write-Error "Falha ao importar as associações atualizadas."
}

# Limpar arquivos temporários (opcional)
Remove-Item -Path $assocFile -Force


Add-Type -AssemblyName System.Windows.Forms

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appRoot = Split-Path -Parent $scriptDir
$versionFilePath = Join-Path $appRoot "config\launcher.version"
$appVersion = "0.0.0"

if (Test-Path $versionFilePath) {
    $versionValue = (Get-Content -LiteralPath $versionFilePath -TotalCount 1 -ErrorAction SilentlyContinue).Trim()
    if ($versionValue) {
        $appVersion = $versionValue
    }
}

$form = New-Object Windows.Forms.Form
$form.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Microfácil Finalização - V$appVersion Por Rodrigo Silveira"))
$form.Size = New-Object Drawing.Size(940, 600)
$form.StartPosition = "CenterScreen"
$form.AutoScroll = $false

$taskCheckboxes = @()
$officeOptionRadios = @()
$programOptionCheckboxes = @()

# Adicionar um rótulo e caixa de texto para nome do técnico
$label = New-Object Windows.Forms.Label
$label.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Nome do técnico responsável"))
$label.Location = New-Object Drawing.Point(20, 20)
$label.AutoSize = $true
$form.Controls.Add($label)

$textBox = New-Object Windows.Forms.TextBox
$textBox.Location = New-Object Drawing.Point(20, 50)
$textBox.Size = New-Object Drawing.Size(200, 30)
$form.Controls.Add($textBox)

# Adicionar um rótulo e caixa de texto para OS
$labelOS = New-Object Windows.Forms.Label
$labelOS.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("OS"))
$labelOS.Location = New-Object Drawing.Point(250, 20)
$labelOS.AutoSize = $true
$form.Controls.Add($labelOS)

$textBoxOS = New-Object Windows.Forms.TextBox
$textBoxOS.Location = New-Object Drawing.Point(250, 50)
$textBoxOS.Size = New-Object Drawing.Size(100, 30)
$form.Controls.Add($textBoxOS)

# Função para criar checkboxes dinamicamente
function CriarCheckBox {
    param (
        [string]$texto,
        [string]$nome,
        [int]$posY,
        [int]$posX = 20,
        [bool]$marcado = $false,
        [bool]$habilitado = $true
        )
        $checkbox = New-Object Windows.Forms.CheckBox
        $checkbox.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($texto))
        $checkbox.AutoSize = $true
        $checkbox.Name = $nome
        $checkbox.Checked = $marcado
        $checkbox.Enabled = $habilitado
        $checkbox.Location = New-Object Drawing.Point($posX, $posY)
        $form.Controls.Add($checkbox)
        return $checkbox
    }

function CriarRadioButton {
    param (
        [string]$texto,
        [string]$nome,
        [int]$posY,
        [int]$posX = 40,
        [bool]$marcado = $false,
        [bool]$habilitado = $false
    )

    $radio = New-Object Windows.Forms.RadioButton
    $radio.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($texto))
    $radio.AutoSize = $true
    $radio.Name = $nome
    $radio.Checked = $marcado
    $radio.Enabled = $habilitado
    $radio.Location = New-Object Drawing.Point($posX, $posY)
    $form.Controls.Add($radio)
    return $radio
}

function CriarLabelSecao {
    param (
        [string]$texto,
        [int]$posY,
        [int]$posX = 40
    )

    $labelSecao = New-Object Windows.Forms.Label
    $labelSecao.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($texto))
    $labelSecao.Location = New-Object Drawing.Point($posX, $posY)
    $labelSecao.AutoSize = $true
    $form.Controls.Add($labelSecao)
    return $labelSecao
}

function ExisteTrabalhoSelecionado {
    $standardChecked = ($taskCheckboxes | Where-Object { $_.Checked }).Count -gt 0
    $officeChecked = $officeInstallCheckbox.Checked
    $programChecked = $programInstallCheckbox.Checked -and (($programOptionCheckboxes | Where-Object { $_.Checked }).Count -gt 0)
    return ($standardChecked -or $officeChecked -or $programChecked)
}

function AtualizarEstadoBotaoOK {
    $dadosValidos = ($textBox.Text -match '\p{L}' -and $textBoxOS.Text -match '^\d+$')
    $buttonOK.Enabled = ($dadosValidos -and (ExisteTrabalhoSelecionado))
}

function Get-StateRoot {
    return (Join-Path (Split-Path -Parent $script:appRoot) ".state")
}

function Get-StateFilePath {
    return (Join-Path (Get-StateRoot) "state.json")
}

function Get-LogRoot {
    return (Join-Path (Split-Path -Parent $script:appRoot) "logs")
}

function Register-ResumeRunKey {
    $runKeyPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
    $runnerPath = Join-Path $scriptDir "runner.ps1"
    $runnerCommand = "powershell.exe -ExecutionPolicy Bypass -File `"$runnerPath`""
    New-Item -Path $runKeyPath -Force | Out-Null
    Set-ItemProperty -Path $runKeyPath -Name "FINALIZACAOResume" -Value $runnerCommand
}

function New-TaskDefinition {
    param(
        [string]$Name,
        [string]$ScriptPath,
        [string]$ArgumentLine = "",
        [int]$PreferredOrder = 500,
        [bool]$WaitForCompletion = $true
    )

    return [PSCustomObject]@{
        name = $Name
        scriptPath = $ScriptPath
        argumentLine = $ArgumentLine
        preferredOrder = $PreferredOrder
        waitForCompletion = $WaitForCompletion
        status = "pending"
        rebootCount = 0
    }
}

$leftColumnX = 20
$rightColumnX = 470
$columnHeaderY = 95
$leftY = 130
$rightY = 130

$checkboxData = @(
    @{Texto = "Checar se faltam drivers"; Nome = "rel_driver.ps1"; Ordem = 100; Espera = $true},
    @{Texto = "Baixe os programas no nosso servidor"; Nome = "Servidor_share.ps1"; Ordem = 110; Espera = $false},
    @{Texto = "Forçar atualizações do Windows Update e Loja"; Nome = "wupdate.ps1"; Ordem = 120; Espera = $true},
    @{Texto = "Selecionar programas para bloqueio no Firewall"; Nome = "list_program_firewall.ps1"; Ordem = 130; Espera = $true},
    @{Texto = "Bloquear as atualizações"; Nome = "block.ps1"; Ordem = 140; Espera = $true},
    @{Texto = "Ativador Windows 10/11"; Nome = "licenca.ps1"; Ordem = 900; Espera = $true},
    @{Texto = "Gerar relatório de saúde de bateria"; Nome = "bat.ps1"; Ordem = 150; Espera = $false},
    @{Texto = "Abrir sites de testes de Teclado, Câmera e Microfone"; Nome = "test.ps1"; Ordem = 160; Espera = $false},
    @{Texto = "Script para correções diversas"; Nome = "correction.ps1"; Ordem = 170; Espera = $true},
    @{Texto = "Padronização, papel de parede, ícones de contatos e menus"; Nome = "wallpaper.ps1"; Ordem = 180; Espera = $false},
    @{Texto = "Criar ponto de restauração"; Nome = "restorepoint.ps1"; Ordem = 190; Espera = $true},
    @{Texto = "Limpeza de temporários, arquivos da instalação e rastros de uso"; Nome = "limpeza.ps1"; Ordem = 999; Espera = $true}
)

[void](CriarLabelSecao "Ações do sistema" $columnHeaderY $leftColumnX)
[void](CriarLabelSecao "Instalações" $columnHeaderY $rightColumnX)

foreach ($data in $checkboxData) {
    $taskCheckboxes += CriarCheckBox $data.Texto $data.Nome $leftY $leftColumnX
    $leftY += 30
}

$rightIndentX = $rightColumnX + 20

$officeInstallCheckbox = CriarCheckBox "Instalar Microsoft Office PT-BR" "__office__" $rightY $rightColumnX
$rightY += 28
[void](CriarLabelSecao "Escolha uma opção de Office abaixo:" $rightY $rightIndentX)
$rightY += 24
$officeOptionRadios += CriarRadioButton "Office 2024 Word + Excel + PowerPoint" "office2024_basic" $rightY $rightIndentX $true $false
$rightY += 24
$officeOptionRadios += CriarRadioButton "Office 2024 completo + Access + Visio + Project + Publisher" "office2024_full" $rightY $rightIndentX $false $false
$rightY += 38

$programInstallCheckbox = CriarCheckBox "Instalar aplicativos adicionais" "__programs__" $rightY $rightColumnX
$rightY += 28
[void](CriarLabelSecao "Esses instaladores rodam em sequência, nunca ao mesmo tempo:" $rightY $rightIndentX)
$rightY += 24
$programOptionCheckboxes += CriarCheckBox "Ninite AnyDesk + Chrome + Firefox + Foxit Reader" "ninite_web" $rightY $rightIndentX $true $false
$rightY += 24
$programOptionCheckboxes += CriarCheckBox "Ninite Glary + Malwarebytes + Revo + TeraCopy" "ninite_tools" $rightY $rightIndentX $false $false
$rightY += 24
$programOptionCheckboxes += CriarCheckBox "RustDesk" "rustdesk" $rightY $rightIndentX $true $false
$rightY += 30

$rightY += 10
$taskAreaBottom = [Math]::Max($leftY, $rightY)

$officeInstallCheckbox.Add_CheckedChanged({
    foreach ($radio in $officeOptionRadios) {
        $radio.Enabled = $officeInstallCheckbox.Checked
    }
    AtualizarEstadoBotaoOK
})

$programInstallCheckbox.Add_CheckedChanged({
    foreach ($programCheckbox in $programOptionCheckboxes) {
        $programCheckbox.Enabled = $programInstallCheckbox.Checked
    }
    AtualizarEstadoBotaoOK
})

foreach ($checkbox in ($taskCheckboxes + $programOptionCheckboxes)) {
    $checkbox.Add_CheckedChanged({ AtualizarEstadoBotaoOK })
}

foreach ($radio in $officeOptionRadios) {
    $radio.Add_CheckedChanged({ AtualizarEstadoBotaoOK })
}

$textBox.Add_TextChanged({ AtualizarEstadoBotaoOK })
$textBoxOS.Add_TextChanged({ AtualizarEstadoBotaoOK })

# Botões
$buttonY = $taskAreaBottom + 30
$buttonHeight = 30
$bottomPadding = 35
$minimumHeight = 560
$calculatedHeight = [Math]::Max($minimumHeight, $buttonY + $buttonHeight + $bottomPadding)
$form.ClientSize = New-Object Drawing.Size(940, $calculatedHeight)

# Botão OK
$buttonOK = New-Object Windows.Forms.Button
$buttonOK.Location = New-Object Drawing.Point(560, $buttonY)
$buttonOK.Size = New-Object Drawing.Size(80, 30)
$buttonOK.Text = "OK"
$buttonOK.Enabled = $false
$buttonOK.Add_Click({
    $selectedProgramKeys = @()
    $taskOrderMap = @{}
    $taskWaitMap = @{}
    foreach ($taskConfig in $checkboxData) {
        $taskOrderMap[$taskConfig.Nome] = [int]$taskConfig.Ordem
        $taskWaitMap[$taskConfig.Nome] = [bool]$taskConfig.Espera
    }

    if ($programInstallCheckbox.Checked) {
        $selectedProgramKeys = $programOptionCheckboxes | Where-Object { $_.Checked } | ForEach-Object { $_.Name }
    }

    if ($programInstallCheckbox.Checked -and $selectedProgramKeys.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Selecione pelo menos um instalador adicional.", "AVISO", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    $tasks = @()
    $tasks += New-TaskDefinition -Name "Desativar antivirus" -ScriptPath (Join-Path $scriptDir "defender.ps1") -PreferredOrder 10 -WaitForCompletion $true

    foreach ($checkbox in $taskCheckboxes) {
        if ($checkbox.Checked) {
            $preferredOrder = if ($taskOrderMap.ContainsKey($checkbox.Name)) { $taskOrderMap[$checkbox.Name] } else { 500 }
            $waitForCompletion = if ($taskWaitMap.ContainsKey($checkbox.Name)) { $taskWaitMap[$checkbox.Name] } else { $true }
            $taskDefinition = New-TaskDefinition -Name $checkbox.Text -ScriptPath (Join-Path $scriptDir $checkbox.Name) -PreferredOrder $preferredOrder -WaitForCompletion $waitForCompletion
            $tasks += $taskDefinition
        }
    }

    if ($officeInstallCheckbox.Checked) {
        $selectedOffice = $officeOptionRadios | Where-Object { $_.Checked } | Select-Object -First 1
        if ($selectedOffice) {
            $tasks += New-TaskDefinition -Name "Instalação do Office" -ScriptPath (Join-Path $scriptDir "office.ps1") -ArgumentLine "-SelectionKey $($selectedOffice.Name)" -PreferredOrder 200 -WaitForCompletion $true
        }
    }

    if ($programInstallCheckbox.Checked -and $selectedProgramKeys.Count -gt 0) {
        $selectedProgramsCsv = ($selectedProgramKeys -join ",")
        $tasks += New-TaskDefinition -Name "Instaladores adicionais" -ScriptPath (Join-Path $scriptDir "programas.ps1") -ArgumentLine "-SelectionKeysCsv `"$selectedProgramsCsv`"" -PreferredOrder 210 -WaitForCompletion $true
    }

    $tasks = @($tasks | Sort-Object -Property preferredOrder, name)

    if ($tasks.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Nenhuma etapa foi selecionada.", "AVISO", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    $stateRoot = Get-StateRoot
    if (-not (Test-Path $stateRoot)) {
        New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
    }

    $logRoot = Get-LogRoot
    if (-not (Test-Path $logRoot)) {
        New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
    }

    $state = [PSCustomObject]@{
        version = 1
        createdAt = (Get-Date).ToString("o")
        appVersion = $appVersion
        tecnico = $textBox.Text
        os = $textBoxOS.Text
        tasks = $tasks
    }

    $state | ConvertTo-Json -Depth 8 | Set-Content -Path (Get-StateFilePath) -Encoding UTF8
    Register-ResumeRunKey

    $runnerPath = Join-Path $scriptDir "runner.ps1"
    $runnerStdOut = Join-Path $logRoot "runner_stdout.log"
    $runnerStdErr = Join-Path $logRoot "runner_stderr.log"
    "[{0}] ENDER iniciou o runner." -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Out-File -LiteralPath (Join-Path $logRoot "ender.log") -Append -Encoding UTF8
    Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$runnerPath`"" -WindowStyle Hidden -RedirectStandardOutput $runnerStdOut -RedirectStandardError $runnerStdErr
    $form.Close()
})
$form.Controls.Add($buttonOK)

# Botão Cancelar
$buttonCancel = New-Object Windows.Forms.Button
$buttonCancel.Location = New-Object Drawing.Point(650, $buttonY)
$buttonCancel.Size = New-Object Drawing.Size(80, 30)
$buttonCancel.Text = "Cancelar"
$buttonCancel.Add_Click({ $form.Close() })
$form.Controls.Add($buttonCancel)

# Botão update
$buttonUpdate = New-Object Windows.Forms.Button
$buttonUpdate.Location = New-Object Drawing.Point(760, $buttonY)
$buttonUpdate.Size = New-Object Drawing.Size(80, 30)
$buttonUpdate.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Checar atualizações?"))
$buttonUpdate.AutoSize = $true
$buttonUpdate.Add_Click({ 
    Start-Process powershell.exe -ArgumentList "-File `"$((Join-Path $scriptDir "update_script.ps1"))`"" -NoNewWindow -PassThru
})
$form.Controls.Add($buttonUpdate)

AtualizarEstadoBotaoOK
$form.ShowDialog()
