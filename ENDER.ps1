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


#Inicia o Form para escolher as opções
Start-Process powershell.exe -ArgumentList "-File update_script.ps1" -NoNewWindow -PassThru

Add-Type -AssemblyName System.Windows.Forms

$form = New-Object Windows.Forms.Form
$form.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Microfácil Finalização - V2.11 Por Rodrigo Silveira"))
$form.Size = New-Object Drawing.Size(460, 655)
$form.StartPosition = "CenterScreen"

<<<<<<< HEAD

$checkboxes = @()


=======
$checkboxes = @()

>>>>>>> main
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
$textBoxOS.Add_TextChanged({
    $buttonOK.Enabled = ($textBox.Text -match '\p{L}' -and $textBoxOS.Text -match '^\d+$')
})
$form.Controls.Add($textBoxOS)

# Função para criar checkboxes dinamicamente
function CriarCheckBox {
    param (
        [string]$texto,
        [string]$nome,
        [string]$tag,
        [int]$posY
        )
        $checkbox = New-Object Windows.Forms.CheckBox
        $checkbox.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes($texto))
        $checkbox.AutoSize = $true
        $checkbox.Name = $nome
        $checkbox.Location = New-Object Drawing.Point(20, $posY)
        $checkbox.Tag = $tag
        $form.Controls.Add($checkbox)
        return $checkbox
    }
<<<<<<< HEAD
    
    # Adicionar checkboxes
    $checkboxData = @(
        @{Texto = "Checar se faltam drivers"; Nome = ".\rel_driver.ps1"; Tag = "-Wait"},
        @{Texto = "Instalar office 2024 x64 PT-BR ativado"; Nome = ".\office.ps1"; Tag = ""},
        @{Texto = "Instalar pacote do Ninite + Anydesk"; Nome = ".\programas.ps1"; Tag = ""},
        @{Texto = "Abir compartilhamento de arquivos"; Nome = ".\share.ps1"; Tag = ""},
        @{Texto = "Forçar atualizações do Windows Update e Loja"; Nome = ".\wupdate.ps1"; Tag = ""},
        @{Texto = "Selecionar programas para bloqueio no Firewall"; Nome = ".\list_program_firewall.ps1"; Tag = "-Wait"},
        @{Texto = "Bloquear as atualizações"; Nome = ".\block.ps1"; Tag = "-Wait"},
        @{Texto = "Criar ponto de restauração"; Nome = ".\restorepoint.ps1"; Tag = ""},
        @{Texto = "Ativador Windows 10/11"; Nome = ".\licenca.ps1"; Tag = "-Wait"},
        @{Texto = "Gerar relatório de saúde de bateria"; Nome = ".\bat.ps1"; Tag = ""},
        @{Texto = "Abrir sites de testes de Teclado, Câmera e Microfone"; Nome = ".\test.ps1"; Tag = ""},
        @{Texto = "Script para correções diversas"; Nome = ".\correction.ps1"; Tag = "-Wait"},
        @{Texto = "Padronização, papel de parede, ícones de contatos e menus"; Nome = ".\wallpaper.ps1"; Tag = ""},
        @{Texto = "Limpeza de temporários, arquivos da instalação e rastros de uso"; Nome = ".\limpeza.ps1"; Tag = "-Wait"}
        )
        
        $yPosition = 90
=======

# Adicionar checkboxes
$checkboxData = @(
    @{Texto = "Checar se faltam drivers"; Nome = ".\rel_driver.ps1"; Tag = "-Wait"},
    @{Texto = "Instalar office 2024 x64 PT-BR ativado"; Nome = ".\office.ps1"; Tag = ""},
    @{Texto = "Instalar pacote do Ninite + Anydesk"; Nome = ".\programas.ps1"; Tag = ""},
    @{Texto = "Baixe os programas no nosso servidor"; Nome = ".\Servidor_share.ps1"; Tag = ""},
    @{Texto = "Forçar atualizações do Windows Update e Loja"; Nome = ".\wupdate.ps1"; Tag = ""},
    @{Texto = "Selecionar programas para bloqueio no Firewall"; Nome = ".\list_program_firewall.ps1"; Tag = "-Wait"},
    @{Texto = "Bloquear as atualizações"; Nome = ".\block.ps1"; Tag = "-Wait"},
    @{Texto = "Ativador Windows 10/11"; Nome = ".\licenca.ps1"; Tag = "-Wait"},
    @{Texto = "Gerar relatório de saúde de bateria"; Nome = ".\bat.ps1"; Tag = ""},
    @{Texto = "Abrir sites de testes de Teclado, Câmera e Microfone"; Nome = ".\test.ps1"; Tag = ""},
    @{Texto = "Script para correções diversas"; Nome = ".\correction.ps1"; Tag = "-Wait"},
    @{Texto = "Padronização, papel de parede, ícones de contatos e menus"; Nome = ".\wallpaper.ps1"; Tag = ""},
    @{Texto = "Criar ponto de restauração"; Nome = ".\restorepoint.ps1"; Tag = "-Wait"},
    @{Texto = "Limpeza de temporários, arquivos da instalação e rastros de uso"; Nome = ".\limpeza.ps1"; Tag = "-Wait"}
)

$yPosition = 90
>>>>>>> main
foreach ($data in $checkboxData) {
    $checkboxes += CriarCheckBox $data.Texto $data.Nome $data.Tag $yPosition
    $yPosition += 30
}

# Atualizar dinamicamente a posição de elementos abaixo dos checkboxes
$progressBarY = $yPosition + 20

<<<<<<< HEAD

=======
>>>>>>> main
# Configurar barra de progresso
$progressBar = New-Object Windows.Forms.ProgressBar
$progressBar.Location = New-Object Drawing.Point(20, $progressBarY)
$progressBar.Size = New-Object Drawing.Size(400, 20)
$progressBar.Minimum = 0
<<<<<<< HEAD
$progressBar.Maximum = $checkboxes.Count
$progressBar.Value = 0
$form.Controls.Add($progressBar)


# Função para atualizar a barra de progresso e status
function AtualizarBarra {
    param ($atual, $total)
    $progressBar.Value = $atual
    $status.Text = "Executando item $atual de $total..."
=======
$progressBar.Maximum = 100
$progressBar.Value = 0
$form.Controls.Add($progressBar)

# Função para atualizar a barra de progresso e status
function AtualizarBarra {
    param ($atual, $total)
    $percentual = [math]::Round(($atual / $total) * 100)
    $progressBar.Value = $percentual
    $status.Text = "Executando item $atual de $total... ($percentual%)"
>>>>>>> main
}

$status = New-Object Windows.Forms.Label
$status.AutoSize = $true
$status.Location = New-Object Drawing.Point(20, $($progressBarY - 20))
$form.Controls.Add($status)

<<<<<<< HEAD

# Botões
$buttonY = $progressBarY + 40


=======
# Botões
$buttonY = $progressBarY + 40

>>>>>>> main
# Botão OK
$buttonOK = New-Object Windows.Forms.Button
$buttonOK.Location = New-Object Drawing.Point(80, $buttonY)
$buttonOK.Size = New-Object Drawing.Size(80, 30)
$buttonOK.Text = "OK"
$buttonOK.Enabled = $false
$buttonOK.Add_Click({
<<<<<<< HEAD
    #Exigir desativação do antivírus
=======
    # Exigir desativação do antivírus
>>>>>>> main
    Start-Process "powershell.exe" -ArgumentList ".\defender.ps1" -Wait -NoNewWindow
    
    $tecnicoOS = $textBox.Text
    $total = ($checkboxes | Where-Object { $_.Checked }).Count
    $atual = 0
    
<<<<<<< HEAD
    function ExecuteSelectedScripts {
        param ($scriptPath, $text, $tag)
        if (Test-Path $scriptPath) {
            $status.Text = "Executando: $text"
            $process = Start-Process powershell.exe -ArgumentList "-File $scriptPath" -NoNewWindow -PassThru
            if ($tag) { $process.WaitForExit() }
        } else {
            Write-Host "Script não encontrado: $scriptPath"
        }
    }
=======
    # Função para execução dos scripts e atualizar a interface
# Função para execução dos scripts e atualizar a interface
function ExecuteSelectedScripts {
    param ($scriptPath, $text, $tag)
    if (Test-Path $scriptPath) {
        $status.Text = "Executando: $text"
        $process = Start-Process powershell.exe -ArgumentList "-File $scriptPath" -NoNewWindow -PassThru
        # Monitorar o status da execução para atualizar a barra
        do {
            try {
                # Tenta atualizar a interface de progresso
                $form.Invoke({
                    param ($atual, $total)
                    AtualizarBarra $atual $total
                }, $atual, $total)
            } catch {
                # Ignora qualquer erro ao invocar o método de atualização da interface
                # Utiliza o -ErrorAction SilentlyContinue para suprimir qualquer erro
            }
            Start-Sleep -Seconds 1
        } while (!$process.HasExited)  # Aguarda o processo terminar
        if ($tag) { $process.WaitForExit() }
    } else {
        Write-Host "Script não encontrado: $scriptPath"
    }
}
>>>>>>> main
    
    foreach ($checkbox in $checkboxes) {
        if ($checkbox.Checked) {
            $atual++
            AtualizarBarra $atual $total
            ExecuteSelectedScripts $checkbox.Name $checkbox.Text $checkbox.Tag
        }
    }
    
    [System.Windows.Forms.MessageBox]::Show([System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Execução concluída, mas pode haver tarefas em segundo plano!")), "AVISO", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    $form.Close()
})
$form.Controls.Add($buttonOK)

# Botão Cancelar
$buttonCancel = New-Object Windows.Forms.Button
$buttonCancel.Location = New-Object Drawing.Point(170, $buttonY)
$buttonCancel.Size = New-Object Drawing.Size(80, 30)
$buttonCancel.Text = "Cancelar"
$buttonCancel.Add_Click({ $form.Close() })
$form.Controls.Add($buttonCancel)

# Botão update
$buttonUpdate = New-Object Windows.Forms.Button
$buttonUpdate.Location = New-Object Drawing.Point(300, $buttonY)
$buttonUpdate.Size = New-Object Drawing.Size(80, 30)
$buttonUpdate.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Checar atualizações?"))
$buttonUpdate.AutoSize = $true
$buttonUpdate.Add_Click({ 
    Start-Process powershell.exe -ArgumentList "-File update_script.ps1" -NoNewWindow -PassThru
<<<<<<< HEAD
    
    # $form.Close()
     })
$form.Controls.Add($buttonUpdate)



=======
})
$form.Controls.Add($buttonUpdate)

>>>>>>> main
$form.ShowDialog()
