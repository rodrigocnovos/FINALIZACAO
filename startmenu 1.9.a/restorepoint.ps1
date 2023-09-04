Enable-ComputerRestore -Drive "c:\"
$timestamp = Get-Date -Format "yyyyMMddHHmmss"
$description = "Ponto de Restauração Criado em $timestamp"
Checkpoint-Computer -Description $description -RestorePointType MODIFY_SETTINGS