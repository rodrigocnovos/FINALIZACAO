# Carregar a biblioteca de formulários do Windows
Add-Type -AssemblyName System.Windows.Forms

# Criar um formulário invisível para garantir que a mensagem apareça no topo
$form = New-Object System.Windows.Forms.Form
$form.TopMost = $true # Garantir que esteja no topo

# Criar a janela de mensagem
$mensagem = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Começar a limpeza?"))
$titulo = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Confirmação"))
$botoes = [System.Windows.Forms.MessageBoxButtons]::YesNo
$icone = [System.Windows.Forms.MessageBoxIcon]::Question

# Exibir a caixa de diálogo em primeiro plano
$resposta = [System.Windows.Forms.MessageBox]::Show($form, $mensagem, $titulo, $botoes, $icone)

# Verificar a resposta do usuário
if ($resposta -eq [System.Windows.Forms.DialogResult]::Yes) {
    Write-Host "confirmou a limpeza."
   
        function Limpeza {
            param ()
                
                
                # Limpar histórico de pesquisa no Explorador de Arquivos
                Clear-RecycleBin -Force 2>$null
                Remove-Item "$env:USERPROFILE\AppData\Local\Microsoft\Windows\Explorer\thumbcache_*" -Force -ErrorAction SilentlyContinue 2>$null  
                
                # Limpar cache de aplicativos do Windows
                $packageCleanupArgs = @('/StartComponentCleanup', '/ResetBase')
                Start-Process -Wait -FilePath dism.exe -ArgumentList $packageCleanupArgs
                
                # Limpar cache do Windows Update
                Start-Process -Wait -FilePath cleanmgr.exe -ArgumentList "/sagerun:1"
                
                # Limpar cache de execução do PowerShell
                $env:TEMP = [System.IO.Path]::GetTempPath()
                Remove-Item "$env:TEMP\*" -Force -Recurse -ErrorAction SilentlyContinue 2>$null  
                
                
                ### CLEAN CHROME
                # Fecha todas as instâncias abertas do Google Chrome
                try {
                    
                    Get-Process -Name chrome -ErrorAction Stop | Stop-Process -Force 
                }
                catch {
                    <#Do this if a terminating exception happens#>
                }
                Remove-Item -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default" -Recurse -Force 2>$null
                
                #Write-Host "Limpeza de dados de navegação do Google Chrome concluída com sucesso."
                
                ######
                
                
                ### CLEAN EDGE
                # Fecha todas as instâncias abertas do Microsoft Edge
                try {
                    
                    Get-Process -Name msedge -ErrorAction Stop | Stop-Process -Force
                }
                catch {
                    <#Do this if a terminating exception happens#>
                }
                
                Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default" -Recurse -Force 2>$null
                
                
                #Write-Host "Limpeza de dados de navegação do Microsoft Edge concluída com sucesso."
                
                
                ####CLEAN FIREFOX
                
                # Fecha todas as instâncias abertas do Mozilla Firefox
                try {
                    Get-Process -Name firefox -ErrorAction Stop | Stop-Process -Force
                    
                }
                catch {
                    <#Do this if a terminating exception happens#>
                }
                
                
                
                # Limpa o cache de navegação do Firefox
                
                $cachePath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::ApplicationData) + "\Mozilla\Firefox\Profiles"
                $profiles = Get-ChildItem -Path $cachePath -Directory
                foreach ($profile in $profiles) {
                    
                    # if (Test-Path -Path $cacheFolder) {
                        $finalProfilePath = Join-Path -Path $cachePath -ChildPath $profile
                        Remove-Item -Path $finalProfilePath\*.sqlite -Force -Recurse -ErrorAction SilentlyContinue 2>$null        
                        # }
                    }
                    
                    
                    
                    # "Limpando acesso rapido"
                    Remove-Item -Path %APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\* -Force -ErrorAction SilentlyContinue 2>$null
                    Remove-Item -Path %APPDATA%\Microsoft\Windows\Recent\CustomDestinations\* -Force -ErrorAction SilentlyContinue 2>$null
                    Remove-Item -Path %APPDATA%\Microsoft\Windows\Recent\* -Force -ErrorAction SilentlyContinue 2>$null
                    
                    #Limpando update
                    Remove-Item -Path "C:\Windows\SoftwareDistribution" -Force -Recurse -ErrorAction SilentlyContinue 2>$null
                    
                    #Caminho para o desktop do usuário corrente
                    $desktopPath = [Environment]::GetFolderPath("Desktop")
                    # Remove-Item $desktopPath\* -Force -Recurse -ErrorAction SilentlyContinue 2>$null
                    
                    # Excluir arquivos do desktop público
                    $publicDesktopPath = [System.Environment]::GetFolderPath("CommonDesktopDirectory")
                    Remove-Item "$publicDesktopPath\*" -Force -Recurse -ErrorAction SilentlyContinue 2>$null
                    
                    
                    
                    # Obter o caminho da pasta do usuário que fez login no sistema
                    $userProfilePath = [System.Environment]::GetEnvironmentVariable('USERPROFILE')
                    
                    # Limpar a pasta de Downloads do usuário corrente
                    $downloadsPath = Join-Path -Path $userProfilePath -ChildPath 'Downloads' 
                    Remove-Item -Path $downloadsPath\* -Force -Recurse -ErrorAction SilentlyContinue  2>$null
                    
                    # Limpar a pasta de Documentos do usuário corrente
                    $documentsPath = Join-Path -Path $userProfilePath -ChildPath 'Documents'
                    Remove-Item -Path $documentsPath\* -Force -Recurse -ErrorAction SilentlyContinue 2>$null
                    
                    #Limpar imagens
                    $picturesPath = Join-Path -Path $userProfilePath -ChildPath 'pictures'
                    Remove-Item -Path $picturesPath\* -Force -Recurse -ErrorAction SilentlyContinue 2>$null
                    
                    #Limpeza de arquivos recentes do windows
                    $Namespace = "shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}"
                    $QuickAccess = New-Object -ComObject shell.application
                    $RecentFiles = $QuickAccess.Namespace($Namespace).Items()
                    $RecentFiles | % {$_.InvokeVerb("remove")}

                    #Agendamento para remover essa do script

                    # Obtém o diretório atual
                    $currentDirectory = Get-Location

                    # Parâmetros
                    $taskName = "RemoveCurrentDirectoryTask"
                    $directoryPath = $currentDirectory.Path

                    # Ação: Remover o diretório com PowerShell
                    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -Command `"if (Test-Path '$directoryPath') { Remove-Item -Path '$directoryPath' -Recurse -Force }`""

                    # Disparo: Executar a tarefa 5 segundos a partir de agora
                    $trigger = New-ScheduledTaskTrigger -Once -At ([DateTime]::Now.AddSeconds(15))

                    # Configurações da tarefa
                    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

                    # Registrar a tarefa no Agendador
                    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings
                    
                    
                    Stop-Process -Name explorer -Force
                    # Fecha todas as janelas do Prompt de Comando (cmd.exe)
                    Stop-Process -Name cmd -Force -ErrorAction SilentlyContinue
                    
                    # Fecha todas as janelas do PowerShell (powershell.exe e pwsh.exe)
                    Stop-Process -Name powershell -Force -ErrorAction SilentlyContinue
                    Stop-Process -Name pwsh -Force -ErrorAction SilentlyContinue
                    
                    
                    Clear-Host
                    Write-Host "Limpeza concluída."
                    
                                    
                    
                }
        
    Limpeza
} else {
    Write-Host "cancelou a limpeza"
    # Código para cancelar ou encerrar
}

# Fechar o formulário criado
$form.Dispose()
