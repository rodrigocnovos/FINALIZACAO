# Importar biblioteca Windows Forms
Add-Type -AssemblyName System.Windows.Forms

# Caminho do repositório local e do Git portátil
$localRepoPath = Get-Location
$gitExecutable = Join-Path $localRepoPath "software\gitportatil\bin\git.exe"

# URL da API do GitHub para obter informações do último commit remoto
$owner = "rodrigocnovos"
$repo = "finalizacao"
$branch = "main"
$apiUrl = "https://api.github.com/repos/$owner/$repo/commits?sha=$branch"

# Função para obter o último commit remoto
function Get-RemoteCommit {
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get -UseBasicParsing
        return @{
            "date" = $response[0].commit.author.date
            "message" = $response[0].commit.message
        }
    } catch {
        Write-Output "Erro ao consultar o commit remoto: $($_.Exception.Message)"
        return $null
    }
}

# Função para forçar a atualização do repositório local
function Force-UpdateRepo {
    $currentDir = Push-Location -Path $localRepoPath

    try {
        # Atualizar informações do remoto usando Git portátil
        & $gitExecutable fetch origin
        
        # Forçar o pull, sobrescrevendo mudanças locais
        & $gitExecutable reset --hard origin/$branch
        
        [System.Windows.Forms.MessageBox]::Show(
            [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Repositório local atualizado com sucesso.")),
            [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Atualização Concluída"))
        )
    } catch {
        Write-Output "Erro ao atualizar o repositório: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show(
            [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Erro ao atualizar o repositório.")),
            [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Erro"))
        )
    } finally {
        Pop-Location
    }
}

# Obter o último commit remoto
$remoteCommit = Get-RemoteCommit
if (-not $remoteCommit) {
    [System.Windows.Forms.MessageBox]::Show(
        [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Não foi possível obter o status remoto.")),
        [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Erro"))
    )
    return
}

# Exibir informações do commit remoto
$commitDate = $remoteCommit["date"]
$commitMessage = [System.Text.Encoding]::GetEncoding("ISO-8859-1").GetString([System.Text.Encoding]::UTF8.GetBytes($remoteCommit["message"]))


# Formatar a mensagem de notificação com UTF-8
$formattedMessage = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Foi detectado um commit remoto mais recente.`n`n Último commit:`n$commitMessage`n`nDeseja atualizar seu repositório local?"))
$caption = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Atualizar Repositório"))

# Exibir a caixa de diálogo para o usuário confirmar
$result = [System.Windows.Forms.MessageBox]::Show($formattedMessage, $caption, [System.Windows.Forms.MessageBoxButtons]::YesNo)

# Perguntar ao usuário se deseja atualizar
if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
    Force-UpdateRepo
} else {
    [System.Windows.Forms.MessageBox]::Show(
        [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Atualização cancelada pelo usuário.")),
        [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Cancelado"))
    )
}
