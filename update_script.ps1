# Importar biblioteca Windows Forms
Add-Type -AssemblyName System.Windows.Forms

# Caminho do repositório local e do Git portátil
$localRepoPath = Get-Location
$gitExecutable = Join-Path $localRepoPath "softwares\PortableGit\bin\git.exe"

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
            "sha" = $response[0].sha
        }
    } catch {
        Write-Output "Erro ao consultar o commit remoto: $($_.Exception.Message)"
        return $null
    }
}

# Função para atualizar o repositório local
function UpdateRepo {
    $currentDir = Push-Location -Path $localRepoPath

    try {
        # Verificar se o repositório está inicializado
        if (-Not (Test-Path "$localRepoPath\.git")) {
            # Se o repositório não existir, clonar
            Write-Output "Repositório local não encontrado ou está corrompido. Clonando novamente..."
            & $gitExecutable clone "https://github.com/$owner/$repo.git" $localRepoPath
        } else {
            # Caso o repositório já exista, fazer pull
            Write-Output "Repositório local encontrado. Atualizando..."
            
            # Fazer o fetch para garantir que as referências remotas sejam atualizadas
            & $gitExecutable fetch origin

            # Obter o commit remoto mais recente
            $remoteCommit = Get-RemoteCommit
            if (-not $remoteCommit) {
                Write-Output "Erro ao obter o commit remoto."
                return
            }

            # Obter o commit local mais recente a partir da referência remota (origin/main)
            $localCommit = & $gitExecutable rev-parse origin/$branch

            # Comparar o commit local com o remoto
            if ($localCommit -ne $remoteCommit["sha"]) {
                Write-Output "O repositório remoto tem uma versão mais recente. Realizando git pull..."
                # Realizar git pull para atualizar a versão local
                & $gitExecutable pull origin $branch
            } else {
                Write-Output "O repositório local já está atualizado com o remoto."
            }
        }

        [System.Windows.Forms.MessageBox]::Show(
            "Repositório local atualizado com sucesso.",
            "Atualização Concluída"
        )
    } catch {
        Write-Output "Erro ao atualizar o repositório: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show(
            "Erro ao atualizar o repositório.",
            "Erro"
        )
    } finally {
        Pop-Location
    }
}

# Obter o último commit remoto
$remoteCommit = Get-RemoteCommit
if (-not $remoteCommit) {
    [System.Windows.Forms.MessageBox]::Show(
        "Não foi possível obter o status remoto.",
        "Erro"
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
    UpdateRepo
} else {
    [System.Windows.Forms.MessageBox]::Show(
        [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Atualização cancelada pelo usuário.")),
        [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Cancelado"))
    )
}
