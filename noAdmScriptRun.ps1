# Listar usuários não administrativos
$nonAdminUsers = Get-WmiObject Win32_UserAccount | Where-Object { $_.LocalAccount -eq $true -and $_.Disabled -eq $false -and $_.Lockout -eq $false }

# Selecionar o primeiro usuário não administrativo da lista
$chosenUser = $nonAdminUsers | Select-Object -First 1

# Caminho para o script que você deseja executar
$scriptPath = ".\programas.ps1"

# Script block para executar o script como outro usuário
$scriptBlock = {
    param($scriptPath)
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -WindowStyle Hidden
}

# Executar o script como o usuário selecionado sem fornecer senha
Invoke-Command -ScriptBlock $scriptBlock -ArgumentList $scriptPath -Credential $chosenUser.Name
