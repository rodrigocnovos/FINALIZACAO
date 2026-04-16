param()

$ErrorActionPreference = "Stop"

$repoRoot = (git rev-parse --show-toplevel).Trim()
if (-not $repoRoot) {
    exit 0
}

Set-Location -LiteralPath $repoRoot

$versionFile = "app/config/launcher.version"

# Edite esta lista para ignorar arquivos ou pastas que nao devem disparar bump de versao.
# Exemplos:
#   "app/data/*"
#   "*.md"
#   "logs/*"
$excludedPatterns = @(
)

function Normalize-RepoPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return ($Path -replace "\\", "/").Trim()
}

function Test-IsExcluded {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [AllowEmptyCollection()]
        [string[]]$Patterns = @()
    )

    foreach ($pattern in $Patterns) {
        if ($Path -like $pattern) {
            return $true
        }
    }

    return $false
}

function Get-ChangedRepoPaths {
    $statusLines = @(git status --porcelain=v1 --untracked-files=all)
    $paths = New-Object System.Collections.Generic.List[string]

    foreach ($line in $statusLines) {
        if ([string]::IsNullOrWhiteSpace($line) -or $line.Length -lt 4) {
            continue
        }

        $pathText = $line.Substring(3).Trim()
        if (-not $pathText) {
            continue
        }

        if ($pathText -like "* -> *") {
            $pathText = ($pathText -split " -> ", 2)[1]
        }

        $normalizedPath = Normalize-RepoPath -Path $pathText
        if (-not $paths.Contains($normalizedPath)) {
            $paths.Add($normalizedPath)
        }
    }

    return $paths
}

function Get-NextVersion {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CurrentVersion
    )

    $parsedVersion = [version]$CurrentVersion
    return "{0}.{1}.{2}" -f $parsedVersion.Major, $parsedVersion.Minor, ($parsedVersion.Build + 1)
}

if (-not (Test-Path -LiteralPath $versionFile)) {
    Write-Host "pre-commit: arquivo de versao nao encontrado em $versionFile. Ignorando bump."
    exit 0
}

$changedPaths = @(Get-ChangedRepoPaths)
$eligiblePaths = @()
foreach ($changedPath in $changedPaths) {
    if (-not $changedPath) {
        continue
    }

    if ($changedPath -eq $versionFile) {
        continue
    }

    if (Test-IsExcluded -Path $changedPath -Patterns $excludedPatterns) {
        continue
    }

    $eligiblePaths += $changedPath
}

if ($eligiblePaths.Count -eq 0) {
    exit 0
}

$currentVersion = (Get-Content -LiteralPath $versionFile -TotalCount 1 -ErrorAction Stop).Trim()
if (-not $currentVersion) {
    $currentVersion = "0.0.0"
}

$nextVersion = Get-NextVersion -CurrentVersion $currentVersion
Set-Content -LiteralPath $versionFile -Value $nextVersion -Encoding ASCII -NoNewline
git add -- $versionFile | Out-Null

Write-Host "pre-commit: launcher.version $currentVersion -> $nextVersion"
