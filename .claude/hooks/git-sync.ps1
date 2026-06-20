param([string]$Source = "sync")

# Commit local changes, pull remote changes, then push back.
# This is the piece that actually makes two computers exchange data.

$ErrorActionPreference = "SilentlyContinue"

$vault = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

function Have($n) { return [bool](Get-Command $n -ErrorAction SilentlyContinue) }

$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if ($gitCmd) { $git = $gitCmd.Source } else {
    $cands = @(
        "$env:ProgramFiles\Git\cmd\git.exe",
        "${env:ProgramFiles(x86)}\Git\cmd\git.exe",
        "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe",
        "C:\个人\ai文件\Git\cmd\git.exe"
    )
    $git = $cands | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $git) { exit 0 }
}

Set-Location $vault

if (-not (Test-Path ".git")) { exit 0 }
$remote = & $git remote 2>$null
if ([string]::IsNullOrWhiteSpace($remote)) { exit 0 }

# Reuse the existing auto-commit script if it exists.
$autoCommit = Join-Path $vault ".claude\hooks\auto-commit.ps1"
if (Test-Path $autoCommit) {
    & $git add -A
    $changes = & $git status --porcelain
    if (-not [string]::IsNullOrWhiteSpace($changes)) {
        $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        & $git commit -m "[$Source] auto: $ts" 2>$null
    }
}

$branch = & $git rev-parse --abbrev-ref HEAD 2>$null
if ([string]::IsNullOrWhiteSpace($branch)) { exit 0 }

& $git pull --rebase --autostash
if ($LASTEXITCODE -ne 0) { exit 0 }

& $git push
if ($LASTEXITCODE -ne 0) {
    & $git push --set-upstream origin $branch
}

exit 0
