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
$versionFilePath = Join-Path $scriptDir "launcher.version"
$appVersion = "0.0.0"

if (Test-Path $versionFilePath) {
    $versionValue = (Get-Content -LiteralPath $versionFilePath -TotalCount 1 -ErrorAction SilentlyContinue).Trim()
    if ($versionValue) {
        $appVersion = $versionValue
    }
}

$form = New-Object Windows.Forms.Form
$form.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Microfácil Finalização - V$appVersion Por Rodrigo Silveira"))
$form.Size = New-Object Drawing.Size(940, 760)
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
    return (Join-Path $env:ProgramData "FINALIZACAO")
}

function Get-StateFilePath {
    return (Join-Path (Get-StateRoot) "state.json")
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
        [string]$ArgumentLine = ""
    )

    return [PSCustomObject]@{
        name = $Name
        scriptPath = $ScriptPath
        argumentLine = $ArgumentLine
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
    @{Texto = "Checar se faltam drivers"; Nome = ".\rel_driver.ps1"},
    @{Texto = "Baixe os programas no nosso servidor"; Nome = ".\Servidor_share.ps1"},
    @{Texto = "Forçar atualizações do Windows Update e Loja"; Nome = ".\wupdate.ps1"},
    @{Texto = "Selecionar programas para bloqueio no Firewall"; Nome = ".\list_program_firewall.ps1"},
    @{Texto = "Bloquear as atualizações"; Nome = ".\block.ps1"},
    @{Texto = "Ativador Windows 10/11"; Nome = ".\licenca.ps1"},
    @{Texto = "Gerar relatório de saúde de bateria"; Nome = ".\bat.ps1"},
    @{Texto = "Abrir sites de testes de Teclado, Câmera e Microfone"; Nome = ".\test.ps1"},
    @{Texto = "Script para correções diversas"; Nome = ".\correction.ps1"},
    @{Texto = "Padronização, papel de parede, ícones de contatos e menus"; Nome = ".\wallpaper.ps1"},
    @{Texto = "Criar ponto de restauração"; Nome = ".\restorepoint.ps1"},
    @{Texto = "Limpeza de temporários, arquivos da instalação e rastros de uso"; Nome = ".\limpeza.ps1"}
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
$officeOptionRadios += CriarRadioButton "Local 2024 x64 PT-BR" "local2024" $rightY $rightIndentX $true $false
$rightY += 24
$officeOptionRadios += CriarRadioButton "Microsoft 365 Apps Full x64 PT-BR" "m365full" $rightY $rightIndentX $false $false
$rightY += 24
$officeOptionRadios += CriarRadioButton "Microsoft 365 Apps Basic x64 PT-BR" "m365basic" $rightY $rightIndentX $false $false
$rightY += 24
$officeOptionRadios += CriarRadioButton "Office Home Business 2024 x64 PT-BR" "homebusiness2024" $rightY $rightIndentX $false $false
$rightY += 24
$officeOptionRadios += CriarRadioButton "Office Home 2024 x64 PT-BR" "home2024" $rightY $rightIndentX $false $false
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

# Atualizar dinamicamente a posição de elementos abaixo dos checkboxes
$progressBarY = $taskAreaBottom + 20

# Configurar barra de progresso
$progressBar = New-Object Windows.Forms.ProgressBar
$progressBar.Location = New-Object Drawing.Point(20, $progressBarY)
$progressBar.Size = New-Object Drawing.Size(880, 20)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$form.Controls.Add($progressBar)

# Função para atualizar a barra de progresso e status
function AtualizarBarra {
    param ($atual, $total)
    $percentual = [math]::Round(($atual / $total) * 100)
    $progressBar.Value = $percentual
    $status.Text = "Executando item $atual de $total... ($percentual%)"
}

$status = New-Object Windows.Forms.Label
$status.AutoSize = $true
$status.Location = New-Object Drawing.Point(20, $($progressBarY - 20))
$form.Controls.Add($status)

# Botões
$buttonY = $progressBarY + 40

# Botão OK
$buttonOK = New-Object Windows.Forms.Button
$buttonOK.Location = New-Object Drawing.Point(560, $buttonY)
$buttonOK.Size = New-Object Drawing.Size(80, 30)
$buttonOK.Text = "OK"
$buttonOK.Enabled = $false
$buttonOK.Add_Click({
    $selectedProgramKeys = @()
    if ($programInstallCheckbox.Checked) {
        $selectedProgramKeys = $programOptionCheckboxes | Where-Object { $_.Checked } | ForEach-Object { $_.Name }
    }

    if ($programInstallCheckbox.Checked -and $selectedProgramKeys.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Selecione pelo menos um instalador adicional.", "AVISO", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    $tasks = @()
    $tasks += New-TaskDefinition -Name "Desativar antivirus" -ScriptPath (Join-Path $scriptDir "defender.ps1")

    foreach ($checkbox in $taskCheckboxes) {
        if ($checkbox.Checked) {
            $tasks += New-TaskDefinition -Name $checkbox.Text -ScriptPath (Join-Path $scriptDir ($checkbox.Name.TrimStart(".\")))
        }
    }

    if ($officeInstallCheckbox.Checked) {
        $selectedOffice = $officeOptionRadios | Where-Object { $_.Checked } | Select-Object -First 1
        if ($selectedOffice) {
            $tasks += New-TaskDefinition -Name "Instalação do Office" -ScriptPath (Join-Path $scriptDir "office.ps1") -ArgumentLine "-SelectionKey $($selectedOffice.Name)"
        }
    }

    if ($programInstallCheckbox.Checked -and $selectedProgramKeys.Count -gt 0) {
        $selectedProgramsCsv = ($selectedProgramKeys -join ",")
        $tasks += New-TaskDefinition -Name "Instaladores adicionais" -ScriptPath (Join-Path $scriptDir "programas.ps1") -ArgumentLine "-SelectionKeysCsv `"$selectedProgramsCsv`""
    }

    if ($tasks.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Nenhuma etapa foi selecionada.", "AVISO", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    $stateRoot = Get-StateRoot
    if (-not (Test-Path $stateRoot)) {
        New-Item -ItemType Directory -Path $stateRoot -Force | Out-Null
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

    Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$((Join-Path $scriptDir "runner.ps1"))`"" -NoNewWindow
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
    Start-Process powershell.exe -ArgumentList "-File update_script.ps1" -NoNewWindow -PassThru
})
$form.Controls.Add($buttonUpdate)

AtualizarEstadoBotaoOK
$form.ShowDialog()
