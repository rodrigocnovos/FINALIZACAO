# Importar biblioteca Windows Forms
Add-Type -AssemblyName System.Windows.Forms

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appRoot = Split-Path -Parent $scriptDir
$projectRoot = Split-Path -Parent $appRoot
$gitExecutable = Join-Path $appRoot "softwares\PortableGit\bin\git.exe"
if (-not (Test-Path $gitExecutable)) {
    $gitExecutable = "git"
}

$owner = "rodrigocnovos"
$repo = "FINALIZACAO"
$branch = "main"
$branchOverrideFile = Join-Path $appRoot "config\branch_update.ini"
$versionFile = "app/config/launcher.version"
$localVersionPath = Join-Path $appRoot "config\launcher.version"

function Get-UpdateBranch {
    if (Test-Path $branchOverrideFile) {
        $candidateLine = Get-Content -LiteralPath $branchOverrideFile -ErrorAction SilentlyContinue |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ -and -not $_.StartsWith('#') -and -not $_.StartsWith(';') } |
            Select-Object -First 1

        if ($candidateLine) {
            if ($candidateLine -match '^\s*branch\s*=\s*(.+)\s*$') {
                return $matches[1].Trim()
            }
            return $candidateLine
        }
    }

    return $branch
}

$branch = Get-UpdateBranch
$rawVersionUrl = "https://raw.githubusercontent.com/$owner/$repo/$branch/$versionFile"
$zipUrl = "https://github.com/$owner/$repo/archive/refs/heads/$branch.zip"

function Show-Info {
    param([string]$message, [string]$title = "Atualizar Repositório")
    [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
}

function Show-Error {
    param([string]$message, [string]$title = "Erro")
    [System.Windows.Forms.MessageBox]::Show($message, $title, [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
}

function Get-LocalVersion {
    if (Test-Path $localVersionPath) {
        $value = (Get-Content -LiteralPath $localVersionPath -TotalCount 1 -ErrorAction SilentlyContinue).Trim()
        if ($value) {
            return $value
        }
    }
    return "0.0.0"
}

function Get-RemoteVersion {
    try {
        $ProgressPreference = 'SilentlyContinue'
        return (Invoke-RestMethod -Uri $rawVersionUrl -Method Get -UseBasicParsing).Trim()
    } catch {
        Write-Output "Erro ao consultar a versao remota: $($_.Exception.Message)"
        return $null
    }
}

function Convert-ToVersion {
    param([string]$value)
    try {
        return [version]$value
    } catch {
        return [version]"0.0.0"
    }
}

function Is-RemoteVersionNewer {
    param(
        [string]$LocalVersion,
        [string]$RemoteVersion
    )

    return (Convert-ToVersion $RemoteVersion) -gt (Convert-ToVersion $LocalVersion)
}

function Update-RepoWithGit {
    param([string]$RemoteName)

    Write-Output "Atualizando repositorio local via Git..."
    & $gitExecutable -C $projectRoot fetch $RemoteName --prune
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao consultar o repositorio remoto."
    }

    & $gitExecutable -C $projectRoot pull --rebase --autostash $RemoteName $branch
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao aplicar a atualizacao via Git."
    }
}

function Update-RepoWithZip {
    $tempRoot = Join-Path $env:TEMP ("FINALIZACAO_update_" + [guid]::NewGuid().ToString("N"))
    $zipFile = Join-Path $tempRoot "update.zip"
    $extractDir = Join-Path $tempRoot "extract"

    try {
        New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
        New-Item -ItemType Directory -Path $extractDir -Force | Out-Null

        Write-Output "Baixando atualizacao por ZIP..."
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -UseBasicParsing -Uri $zipUrl -OutFile $zipFile

        Write-Output "Extraindo atualizacao..."
        Expand-Archive -LiteralPath $zipFile -DestinationPath $extractDir -Force

        $zipRoot = Get-ChildItem -Path $extractDir -Directory | Select-Object -First 1
        if (-not $zipRoot) {
            throw "Conteudo ZIP invalido."
        }

        Write-Output "Aplicando atualizacao por ZIP..."
        $robocopyArgs = @(
            $zipRoot.FullName,
            $projectRoot,
            "/E",
            "/R:2",
            "/W:1",
            "/NFL",
            "/NDL",
            "/NJH",
            "/NJS",
            "/NP",
            "/XD",
            ".git"
        )

        $robocopyProcess = Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -NoNewWindow -PassThru
        if ($robocopyProcess.ExitCode -ge 8) {
            throw "Falha ao copiar os arquivos da atualizacao."
        }
    } finally {
        if (Test-Path $tempRoot) {
            Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Update-Repo {
    try {
        if ((Test-Path (Join-Path $projectRoot ".git")) -and (Test-Path $gitExecutable -or $gitExecutable -eq "git")) {
            $remoteName = "origin"
            $configuredRemote = & $gitExecutable -C $projectRoot config --get "branch.$branch.remote" 2>$null
            if ($configuredRemote) {
                $remoteName = $configuredRemote.Trim()
            }

            & $gitExecutable -C $projectRoot ls-remote --exit-code $remoteName *> $null
            if ($LASTEXITCODE -ne 0) {
                throw "Remoto Git indisponivel."
            }

            Update-RepoWithGit -RemoteName $remoteName
        } else {
            Update-RepoWithZip
        }

        Show-Info "Repositorio local atualizado com sucesso." "Atualização Concluída"
    } catch {
        Write-Output "Erro ao atualizar o repositorio: $($_.Exception.Message)"
        Show-Error "Erro ao atualizar o repositorio.`n$($_.Exception.Message)"
    }
}

$localVersion = Get-LocalVersion
$remoteVersion = Get-RemoteVersion

if (-not $remoteVersion) {
    Show-Error "Nao foi possivel obter a versao remota."
    return
}

Write-Output "VERSAO LOCAL  $localVersion"
Write-Output "VERSAO REMOTA $remoteVersion"

if (Is-RemoteVersionNewer -LocalVersion $localVersion -RemoteVersion $remoteVersion) {
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Foi detectada uma versao remota mais recente.`n`nVersao local: $localVersion`nVersao remota: $remoteVersion`n`nDeseja atualizar seu repositorio local?",
        "Atualizar Repositório",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        Update-Repo
    } else {
        Show-Info "Atualizacao cancelada pelo usuario." "Cancelado"
    }
} else {
    Write-Output "O repositorio local ja esta atualizado com a versao publicada."
    Show-Info "O repositorio ja esta na ultima versao publicada."
}
