# Iniciar teste de estresse no CPU com operações matemáticas intensivas
Write-Host "Iniciando teste de estresse no CPU. Pressione Ctrl+C para interromper."

# Número de núcleos lógicos do processador
$threads = [Environment]::ProcessorCount 

# Criar tarefas paralelas para usar o máximo de núcleos
$tasks = @()
for ($i = 1; $i -le $threads; $i++) {
    $tasks += [System.Threading.Tasks.Task]::Run({
        while ($true) {
            # Operações matemáticas intensivas
            [Math]::Pow((Get-Random), 2) | Out-Null
        }
    })
}

# Monitorar uso por 60 segundos
Write-Host "Teste em andamento por 60 segundos..."
Start-Sleep -Seconds 60

# Encerrar tarefas
$tasks | ForEach-Object { $_.Dispose() }

Write-Host "Teste de estresse no CPU finalizado."
