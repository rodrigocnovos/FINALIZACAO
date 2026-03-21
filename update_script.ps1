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
        return @(
            @{
                "date" = $response[0].commit.author.date
                "message" = $response[0].commit.message
                "sha" = $response[0].sha
            }
        )
    } catch {
        Write-Output "Erro ao consultar o commit remoto: $($_.Exception.Message)"
        return $null
    }
}

# Função para inicializar o repositório local
# Função para inicializar o repositório local
function InitializeRepo {
    # Exibir aviso para o usuário
    [System.Windows.Forms.MessageBox]::Show(
        [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("O diretório local não foi inicializado como um repositório Git.`nSerá inicializado agora, isso pode levar alguns minutos.")),
        [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Inicialização do Repositório"))
    )

    Write-Output "Inicializando o repositório Git local..."
    & $gitExecutable init
    if ($LASTEXITCODE -ne 0) { throw "Falha ao inicializar o repositório local." }

    & $gitExecutable config --global init.defaultBranch $branch
    if ($LASTEXITCODE -ne 0) { throw "Falha ao definir o branch como main" }

    & $gitExecutable config --global user.name "RODRIGO"
    if ($LASTEXITCODE -ne 0) { throw "Falha ao configurar o nome do usuário." }

    & $gitExecutable config --global user.email "rodrigo@microfacilrn.com.br"
    if ($LASTEXITCODE -ne 0) { throw "Falha ao configurar o e-mail do usuário." }

    & $gitExecutable remote add origin "https://github.com/$owner/$repo.git"
    if ($LASTEXITCODE -ne 0) { throw "Falha ao adicionar o repositório remoto." }

    Write-Output "Adicionando arquivo ao stage, aguarde até 5 minutos..."
    & $gitExecutable add *
    if ($LASTEXITCODE -ne 0) { throw "Falha ao adicionar arquivos ao índice." }

    & $gitExecutable commit -m "iniciar"
    if ($LASTEXITCODE -ne 0) { throw "Falha ao criar o commit inicial." }

    & $gitExecutable fetch origin
    if ($LASTEXITCODE -ne 0) { throw "Falha ao buscar alterações do repositório remoto." }

    & $gitExecutable rebase origin/$branch
    if ($LASTEXITCODE -ne 0) { throw "Falha ao rebasesar com o branch remoto $branch." }

    Write-Output "Repositório inicializado e sincronizado com o remoto."
    UpdateRepo
}


# Função para atualizar o repositório local
function UpdateRepo {
    $currentDir = Push-Location -Path $localRepoPath

    try {
        # Verificar se o repositório está inicializado
        if (-Not (Test-Path "$localRepoPath\.git")) {
            # Inicializar o repositório local, caso necessário
            InitializeRepo
        } else {
            Write-Output "Repositório local encontrado. Atualizando..."
            
            # Fazer o fetch para garantir que as referências remotas sejam atualizadas
            & $gitExecutable fetch origin

            # Obter o commit remoto mais recente
            $remoteCommit = Get-RemoteCommit
            if (-not $remoteCommit) {
                Write-Output "Erro ao obter o commit remoto."
                return
            }

            # Obter o commit local mais recente a partir do git log (diretamente do repositório local)
            $localCommit = & $gitExecutable rev-parse HEAD
            # Exibir os hashes para debug
            Write-Output "Hash do commit local: $localCommit"
            Write-Output "Hash do commit remoto: $($remoteCommit["sha"])"

            # Comparar o commit local com o remoto
            if ($localCommit -ne $remoteCommit["sha"]) {
                Write-Output "O repositório remoto tem uma versão mais recente. Realizando rebase..."
                & $gitExecutable config --global --add safe.directory *
                & $gitExecutable pull origin $branch
            } else {
                Write-Output "O repositório local já está atualizado com o remoto."
            }
        }

        [System.Windows.Forms.MessageBox]::Show(
            [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Repositório local atualizado com sucesso.")),
            [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Atualização Concluída"))
        )
    } catch {
        Write-Output "Erro ao atualizar o repositório: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show(
            [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Erro ao atualizar o repositório.")),
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
        [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Não foi possível obter o status remoto.")),
        "Erro"
    )
    return
}

# Exibir informações do commit remoto
$commitDate = $remoteCommit["date"]
$commitMessage = $remoteCommit["message"]

# Obter o commit local diretamente
$localCommit = & $gitExecutable rev-parse HEAD
Write-Output "LOCAL $localCommit"
Write-Output "REMOTO $($remoteCommit["sha"])"

# Comparar os commits antes de perguntar ao usuário
if ($remoteCommit["sha"] -ne $localCommit) {
    # Exibir a caixa de diálogo para o usuário confirmar
    $result = [System.Windows.Forms.MessageBox]::Show(
        [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Foi detectado um commit remoto mais recente.`n`n Último commit:`n$commitMessage`n`nDeseja atualizar seu repositório local?")),
        [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Atualizar Repositório")),
        [System.Windows.Forms.MessageBoxButtons]::YesNo
    )

    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        UpdateRepo
    } else {
        [System.Windows.Forms.MessageBox]::Show(
            [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Atualização cancelada pelo usuário.")),
            [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Cancelado"))
        )
    }
} else {
    Write-Output "O repositório local já está atualizado com o remoto."
    [System.Windows.Forms.MessageBox]::Show(
        [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("O repositório já está na última versão.")),
        [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::Default.GetBytes("Atualização"))
    )
}
