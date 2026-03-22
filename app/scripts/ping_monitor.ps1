# Caminho do script PowerShell e arquivo de configuração
$destinationScript = "C:\Users\Public\Documents\ping_monitor.ps1"
$serversFilePath = "C:\Users\Public\Documents\servers.txt"
$taskName = "Ping Monitor Script"

# Função para exibir a janela de entrada
function Show-AddressInputForm {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    # Criar o formulário
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Adicionar IP ao Monitoramento"
    $form.TopMost = $true
    $form.Size = New-Object System.Drawing.Size(400, 200)
    $form.StartPosition = "CenterScreen"

    # Label
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Digite um endereco IP, ou varios separados por (;):"
    $label.Size = New-Object System.Drawing.Size(350, 20)
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $form.Controls.Add($label)

    # TextBox
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Size = New-Object System.Drawing.Size(350, 20)
    $textBox.Location = New-Object System.Drawing.Point(20, 50)
    $form.Controls.Add($textBox)

    # Botão OK
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Size = New-Object System.Drawing.Size(80, 30)
    $okButton.Location = New-Object System.Drawing.Point(100, 100)
    $okButton.Add_Click({
        $form.Tag = $textBox.Text
        $form.Close()
    })
    $form.Controls.Add($okButton)

    # # Botão Cancelar
    # $cancelButton = New-Object System.Windows.Forms.Button
    # $cancelButton.Text = "Cancelar"
    # $cancelButton.Size = New-Object System.Drawing.Size(80, 30)
    # $cancelButton.Location = New-Object System.Drawing.Point(200, 100)
    # $cancelButton.Add_Click({
    #     $form.Tag = $null
    #     $form.Close()
    # })
    # $form.Controls.Add($cancelButton)

    # Exibir o formulário
    $form.ShowDialog() | Out-Null
    return $form.Tag
}

# Função para carregar ou inicializar os servidores
function Load-Servers {
    if (Test-Path $serversFilePath) {
        return Get-Content -Path $serversFilePath | ForEach-Object { $_.Trim() }
    } else {
        $defaultServers = @(
            "54.239.28.85",
            "23.216.164.39",
            "8.8.8.8",
            "1.1.1.1"
        )
        $defaultServers | Set-Content -Path $serversFilePath
        return $defaultServers
    }
}

# Função para salvar servidores no arquivo
function Save-Servers($servers) {
    $servers | Set-Content -Path $serversFilePath
}

# Função para atualizar o script com os servidores
function Update-ScriptWithServers {
    param([array]$servers)
    
    # Verificar se a lista de servidores não está vazia
    if ($servers.Count -eq 0) {
        $servers = @("54.239.28.85", "23.216.164.39", "8.8.8.8", "1.1.1.1")
    }

    # Construir o conteúdo do script
    $serversString = ($servers | ForEach-Object { "`"$_`"" }) -join ', '

    $scriptContent = @"
# Configurações
`$logFile = "C:\ping_monitor_log.txt"
`$servers = @($serversString)
`$intervalMinutes = 0.5 # Intervalo entre execuções (em minutos)

# Garante que o arquivo de log existe
if (-not (Test-Path -Path `$logFile)) {
    New-Item -Path `$logFile -ItemType File -Force | Out-Null
}

# Variáveis para controle de latência
`$lastLatency = @{ }
foreach (`$server in `$servers) { `$lastLatency[`$server] = `$null }

# Função para testar ping e retornar latência média
function Test-PingLatency {
    param([string]`$Target)
    try {
        `$pingData = Test-Connection -ComputerName `$Target -Count 5 -ErrorAction Stop
        `$avgLatency = (`$pingData | Measure-Object -Property ResponseTime -Average).Average
        return [math]::Round(`$avgLatency, 2)
    } catch {
        return `$null
    }
}

# Função para escrever no log
function Write-Log {
    param([string]`$Message)
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "`$timestamp - `$Message" | Out-File -FilePath `$logFile -Append
}

# Loop Infinito
while (`$true) {
    foreach (`$server in `$servers) {
        Write-Host "Testando ping para `$server..."

        # Teste de latência
        `$currentLatency = Test-PingLatency -Target `$server
        if (`$null -eq `$currentLatency) {
            Write-Log "`$server - Falha no ping (Perda de pacotes)."
            continue
        }

        # Primeira execução ou checar variação
        `$previousLatency = `$lastLatency[`$server]
        if (`$null -eq `$previousLatency) {
            `$lastLatency[`$server] = `$currentLatency
            continue
        }

        # Calcular variação de latência
        `$latencyDiff = [math]::Abs(`$currentLatency - `$previousLatency)
        `$percentChange = [math]::Round((`$latencyDiff / `$previousLatency) * 100, 2)

        if (`$percentChange -ge 50) {
            Write-Log "`$server - Latencia mudou em `$latencyDiff ms (Media atual: `$currentLatency` ms)"
            `$lastLatency[`$server] = `$currentLatency
        }
    }

    # Intervalo entre execuções
    Write-Host "Aguardando `$intervalMinutes minutos antes do próximo teste..."
    Start-Sleep -Seconds (`$intervalMinutes * 60)
}
"@

    Set-Content -Path $destinationScript -Value $scriptContent
}

# Adiciona endereços via interface
$input = Show-AddressInputForm
$servers = Load-Servers

if ($input) {
    $newServers = $input -split ';'
    foreach ($newServer in $newServers) {
        $newServer = $newServer.Trim()
        
        # Verificar se o endereço já existe nos servidores
        if ($servers -notcontains $newServer) {
            # Adicionar novo servidor
            $servers += $newServer
        }
    }
    Save-Servers -servers $servers
}

# Atualiza o script com os servidores configurados
Update-ScriptWithServers -servers $servers

# Configurações do Agendador de Tarefas
if (-not (Get-ScheduledTask | Where-Object {$_.TaskName -eq $taskName})) {
    Write-Host "Criando a tarefa agendada '$taskName'..."
    $taskAction = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$destinationScript`""
    $taskTrigger = New-ScheduledTaskTrigger -AtStartup
    $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

    Register-ScheduledTask -TaskName $taskName -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -User "SYSTEM" -RunLevel Highest -Force
    Write-Host "Tarefa agendada '$taskName' criada com sucesso."
} else {
    Write-Host "A tarefa agendada '$taskName' já existe."
}
