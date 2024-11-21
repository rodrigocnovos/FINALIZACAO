# Importar biblioteca Windows Forms
Add-Type -AssemblyName System.Windows.Forms

# Caminho do repositório local (dinâmico)
$localRepoPath = Get-Location

# Função para verificar mudanças no repositório remoto
function Check-RemoteChanges {
    # Salvar diretório atual e mudar para o repositório local
    $currentDir = Push-Location -Path $localRepoPath

    try {
        # Atualizar informações do remoto sem baixar nada
        git fetch origin
        
        # Verificar diferenças entre a branch local e a branch remota
        $localSha = git rev-parse "@"
        $remoteSha = git rev-parse "@{u}"
        $baseSha = git merge-base "@@" "@{u}"

        # Determinar se o repositório local está atualizado
        if ($localSha -eq $remoteSha) {
            return "updated"  # Nenhuma diferença
        } elseif ($localSha -eq $baseSha) {
            return "behind"  # Repositório local está atrasado
        } elseif ($remoteSha -eq $baseSha) {
            return "ahead"  # Repositório local está à frente
        } else {
            return "diverged"  # Mudanças divergentes
        }
    } catch {
        Write-Output "Erro ao verificar o status do repositório: $($_.Exception.Message)"
        return "error"
    } finally {
        # Voltar para o diretório original
        Pop-Location
    }
}

# Função para exibir uma janela perguntando sobre a atualização
function Ask-ForUpdate {
    $message = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Seu repositório local está desatualizado. Gostaria de atualizar?"))
    $caption = [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Atualizar Repositório"))

    $result = [System.Windows.Forms.MessageBox]::Show($message, $caption, [System.Windows.Forms.MessageBoxButtons]::YesNo)
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        return $true  # Usuário quer atualizar
    } else {
        return $false  # Usuário não quer atualizar
    }
}

# Função para realizar o pull no repositório local
function Perform-Pull {
    $currentDir = Push-Location -Path $localRepoPath

    try {
        git pull origin
        [System.Windows.Forms.MessageBox]::Show([System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Repositório atualizado com sucesso!")), "Sucesso")
    } catch {
        Write-Output "Erro ao atualizar o repositório: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show("Erro ao atualizar o repositório.", "Erro")
    } finally {
        Pop-Location
    }
}

# Principal lógica do script
$status = Check-RemoteChanges

switch ($status) {
    "updated" {
        [System.Windows.Forms.MessageBox]::Show([System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Seu repositório local já está atualizado.")), "Sem Atualização")
    }
    "behind" {
        if (Ask-ForUpdate) {
            Perform-Pull
        } else {
            [System.Windows.Forms.MessageBox]::Show([System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Você optou por não atualizar.")), "Sem Atualização")
        }
    }
    "ahead" {
        [System.Windows.Forms.MessageBox]::Show([System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Seu repositório local está à frente do remoto. Faça um push manual.")), [System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Atenção")))
    }
    "diverged" {
        [System.Windows.Forms.MessageBox]::Show([System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Seu repositório local e remoto divergiram. Resolva os conflitos manualmente.")), "Conflitos")
    }
    "error" {
        [System.Windows.Forms.MessageBox]::Show([System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::GetEncoding("ISO-8859-1").GetBytes("Não foi possível verificar o status do repositório.")), "Erro")
    }
}
