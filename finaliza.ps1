

Add-Type -AssemblyName System.Windows.Forms

$form = New-Object Windows.Forms.Form
$form.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Opções de finalização"))
$form.Size = New-Object Drawing.Size(400, 600)  # Aumentamos a altura para acomodar as checkboxes
$form.StartPosition = "CenterScreen"
# $form.TopMost = $true  # Mantém o formulário sempre em primeiro plano


# Rótulo para exibir a contagem
$status = New-Object Windows.Forms.Label
$status.AutoSize = $true
$status.Location = New-Object Drawing.Point(20, 390)
$form.Controls.Add($status)


# Variável para armazenar a contagem
$contagem = 0



# Função para atualizar a contagem
function AtualizarContagem {
    $contagem = 0
    if ($checkbox1.Checked) { $contagem++ }
    if ($checkbox2.Checked) { $contagem++ }
    if ($checkbox3.Checked) { $contagem++ }
    if ($checkbox4.Checked) { $contagem++ }
    if ($checkbox5.Checked) { $contagem++ }
    if ($checkbox6.Checked) { $contagem++ }
    if ($checkbox7.Checked) { $contagem++ }
    if ($checkbox8.Checked) { $contagem++ }
    if ($checkbox9.Checked) { $contagem++ }
    if ($checkbox10.Checked) { $contagem++ }
    # AtualizarExibicao
    $progressBar.Maximum = $contagem
}

$label = New-Object Windows.Forms.Label
$label.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Nome do técnico responsável e OS"))
$label.Location = New-Object Drawing.Point(20, 20)
$label.AutoSize = $true
$form.Controls.Add($label)

$textBox = New-Object Windows.Forms.TextBox
$textBox.Location = New-Object Drawing.Point(20, 50)
$textBox.Size = New-Object Drawing.Size(300, 30)
# Vincula a função ao evento TextChanged da caixa de texto
$textBox.Add_TextChanged({
    if ($textBox.Text -ne "" -and $textBox.Text -match '\p{L}' -and $textBox.Text -match '\d') {
        $buttonOK.Enabled = $true  # Habilita o botão quando o campo estiver preenchido
    } else {
        $buttonOK.Enabled = $false
    }
})
$form.Controls.Add($textBox)

# Cria uma instância da barra de progresso
$progressBar = New-Object Windows.Forms.ProgressBar
$progressBar.Location = New-Object Drawing.Point(5, 410)
$progressBar.Size = New-Object Drawing.Size(370, 20)
$progressBar.Minimum = 1
$progressBar.Maximum = 10
$progressBar.Step = 1  # Defina o valor do incremento
# Adiciona a barra de progresso ao formulário
$form.Controls.Add($progressBar)

# CheckBoxes com opções
$checkBox1 = New-Object Windows.Forms.CheckBox
$checkBox1.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("1 - Checar se faltam drivers"))
$checkBox1.AutoSize = $true
$checkbox1.Add_CheckedChanged({ AtualizarContagem })
# $checkBox1.Checked = $true
$checkBox1.Name = ".\rel_driver.ps1"
$checkBox1.Location = New-Object Drawing.Point(20, 90)
$checkBox1.Tag = "-Wait"
$form.Controls.Add($checkBox1)

$checkBox2 = New-Object Windows.Forms.CheckBox
$checkBox2.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("2 - Instalar office 2021 x64 PT-BR ativado"))
$checkBox2.AutoSize = $true
$checkBox2.Name = ".\office.ps1"
$checkBox2.Location = New-Object Drawing.Point(20, 120)
$checkbox2.Add_CheckedChanged({ AtualizarContagem })
$checkBox2.Tag = ""
$form.Controls.Add($checkBox2)


$checkBox3 = New-Object Windows.Forms.CheckBox
$checkBox3.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("3 - Instalar pacote do Ninite + Anydesk"))
$checkBox3.Name = ".\programas.ps1"
$checkBox3.Location = New-Object Drawing.Point(20, 150)
$checkbox3.Add_CheckedChanged({ AtualizarContagem })
$checkBox3.AutoSize = $true
$checkBox3.Tag = ""
$form.Controls.Add($checkBox3)

$checkBox4 = New-Object Windows.Forms.CheckBox
$checkBox4.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("4 - Forçar atualizações do windows update e loja"))
$checkBox4.Name = ".\wupdate.ps1"
$checkBox4.Location = New-Object Drawing.Point(20, 180)
$checkbox4.Add_CheckedChanged({ AtualizarContagem })
$checkBox4.AutoSize = $true
$checkBox3.Tag = ""
$form.Controls.Add($checkBox4)


$checkBox5 = New-Object Windows.Forms.CheckBox
$checkBox5.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("5 - Selecionar programas para bloqueio no Firewall"))
$checkBox5.AutoSize = $true
$checkBox5.Name = ".\list_program_firewall.ps1"
$checkBox5.Location = New-Object Drawing.Point(20, 210)
$checkbox5.Add_CheckedChanged({ AtualizarContagem })
$checkBox5.Tag = "-Wait"
$form.Controls.Add($checkBox5)

$checkBox6 = New-Object Windows.Forms.CheckBox
$checkBox6.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("6 - Limpeza de temporários, arquivos da instalacao e rastros de uso"))
$checkBox6.AutoSize = $true
$checkBox6.Name = ".\limpeza.ps1"
$checkBox6.Location = New-Object Drawing.Point(20, 240)
$checkbox6.Add_CheckedChanged({ AtualizarContagem })
$checkBox6.Tag = "-Wait"
$form.Controls.Add($checkBox6)

$checkBox7 = New-Object Windows.Forms.CheckBox
$checkBox7.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("7 -Padronização, papel de parede, icones de contatos e menus"))
$checkBox7.AutoSize = $true
$checkBox7.Name = ".\wallpaper.ps1"
$checkBox7.Location = New-Object Drawing.Point(20, 270)
$checkbox7.Add_CheckedChanged({ AtualizarContagem })
$checkBox7.Tag = ""
$form.Controls.Add($checkBox7)

$checkBox8 = New-Object Windows.Forms.CheckBox
$checkBox8.AutoSize = $true
$checkBox8.Name = ".\block.ps1"
$checkbox8.Add_CheckedChanged({ AtualizarContagem })
$checkBox8.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("8 - Bloquear as atualizações"))
$checkBox8.Location = New-Object Drawing.Point(20, 300)
$checkBox8.Tag = "-Wait"
$form.Controls.Add($checkBox8)

$checkBox9 = New-Object Windows.Forms.CheckBox
$checkBox9.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("9 - Criar ponto de restauração"))
$checkBox9.AutoSize = $true
$checkBox9.Name = ".\restorepoint.ps1"
$checkBox9.Location = New-Object Drawing.Point(20, 330)
$checkbox9.Add_CheckedChanged({ AtualizarContagem })
$checkBox9.Tag = ""
$form.Controls.Add($checkBox9)

$checkBox10 = New-Object Windows.Forms.CheckBox
$checkBox10.Text = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("10 - Ativador Windows10/11"))
$checkBox10.AutoSize = $true
$checkBox10.Name = ".\licenca.ps1"
$checkBox10.Location = New-Object Drawing.Point(20, 360)
$checkbox10.Add_CheckedChanged({ AtualizarContagem })
$checkBox10.Tag = "-Wait"
$form.Controls.Add($checkBox10)


$buttonOK = New-Object Windows.Forms.Button
$buttonOK.Location = New-Object Drawing.Point(80, 450)
$buttonOK.Size = New-Object Drawing.Size(80, 30)
$buttonOK.Text = "OK"
$buttonOK.Enabled = $false
$buttonOK.Add_Click({
    
$tecnicoOS = $textBox.Text
       
    
        
    function ExecuteSelectedScripts{param($scriptPath, $text, $tag)  
        
        if (Test-Path $scriptPath) {
            #Caso não clique em nada não rode o progressbar
            
            if ($text -ne "") {
                $progressBar.PerformStep()  
            }
            
            $status.Text = "Executando: "+$text
            # Executa o script em um novo processo e espera a conclusão
            $process = Start-Process powershell.exe -ArgumentList "-File $scriptPath $tag" -NoNewWindow -PassThru  
            
            $exitCode = $process.ExitCode
            if ($exitCode -eq 0) {
                Write-Host "Script $text concluído com êxito."
                
            } else {
                Write-Host "Script $text falhou com código de saída $exitCode."
            }
        } else {
            Write-Host "Script $text não encontrado: $scriptPath"
        }
        
    }
    
    if ($tecnicoOS -ne $null) {      
        # Caminho para o arquivo onde a variável será armazenada
        $caminhoArquivo = ".\tmp.txt"
        # Gravar o valor da variável no arquivo
        $tecnicoOS | Out-File -FilePath $caminhoArquivo
        ExecuteSelectedScripts(".\OEMInformation.ps1")
    }

    Start-Process "powershell.exe" -ArgumentList ".\defender.ps1" -Wait -NoNewWindow

    if ($checkbox1.Checked) { ExecuteSelectedScripts $checkBox1.Name $checkBox1.Text $checkbox1.Tag }
    if ($checkbox2.Checked) { ExecuteSelectedScripts $checkBox2.Name $checkBox2.Text $checkbox2.Tag }
    if ($checkbox3.Checked) { ExecuteSelectedScripts $checkBox3.Name $checkBox3.Text $checkbox3.Tag }
    if ($checkbox4.Checked) { ExecuteSelectedScripts $checkBox4.Name $checkBox4.Text $checkbox4.Tag }
    if ($checkbox5.Checked) { ExecuteSelectedScripts $checkBox5.Name $checkBox5.Text $checkbox5.Tag }
    if ($checkbox6.Checked) { ExecuteSelectedScripts $checkBox6.Name $checkBox6.Text $checkbox6.Tag }
    if ($checkbox7.Checked) { ExecuteSelectedScripts $checkBox7.Name $checkBox7.Text $checkbox7.Tag }
    if ($checkbox8.Checked) { ExecuteSelectedScripts $checkBox8.Name $checkBox8.Text $checkbox8.Tag }
    if ($checkbox9.Checked) { ExecuteSelectedScripts $checkBox9.Name $checkBox9.Text $checkbox9.Tag }
    if ($checkbox10.Checked) { ExecuteSelectedScripts $checkBox10.Name $checkBox10.Text $checkbox10.Tag }
    

    $form.Close()
})
$form.Controls.Add($buttonOK)

$buttonCancel = New-Object Windows.Forms.Button
$buttonCancel.Location = New-Object Drawing.Point(170, 450)
$buttonCancel.Size = New-Object Drawing.Size(80, 30)
$buttonCancel.Text = "Cancelar"
$buttonCancel.Add_Click({ $form.Close() })
$form.Controls.Add($buttonCancel)

$form.ShowDialog()
