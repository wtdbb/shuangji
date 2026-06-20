# ============================================================
# CodexVault 新电脑配置脚本
# Run in vault root:
#   powershell -ExecutionPolicy Bypass -File .\setup.ps1
# ============================================================

$ErrorActionPreference = "Continue"

$vault = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($vault)) {
    $vault = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$legacyVault = "C:\Users\EDY\Documents\CodexVault"

function Have($n) { [bool](Get-Command $n -ErrorAction SilentlyContinue) }
function Say([string]$msg, [string]$color = "White") { Write-Host $msg -ForegroundColor $color }

Say "==== CodexVault 新电脑配置 ====" Cyan
Say ("Vault: " + $vault) Cyan

# 1) Dependencies
Say "`n[1/7] Check dependencies..." Yellow
$missing = @()
if (-not (Have git))    { $missing += "Git -> https://git-scm.com/download/win" }
if (-not (Have python)) { $missing += "Python 3.13+ -> https://www.python.org/downloads/" }
if (-not (Have ffmpeg)) { $missing += "FFmpeg -> https://github.com/BtbN/FFmpeg-Builds/releases" }

if ($missing.Count -gt 0) {
    Say "Missing dependencies:" Red
    $missing | ForEach-Object { Say ("  - " + $_) Red }
} else {
    Say "Git / Python / FFmpeg are available" Green
}

if (Have python) {
    python -c "import faster_whisper, ctranslate2" 2>$null
    if ($LASTEXITCODE -ne 0) {
        Say "Installing faster-whisper..." Yellow
        python -m pip install faster-whisper
    } else {
        Say "faster-whisper already installed" Green
    }
}

# 2) skill repo
Say "`n[2/7] Check skill repo..." Yellow
$skill = Join-Path $vault "skill"
if (-not (Test-Path (Join-Path $skill "sp-skill\SKILL.md"))) {
    if (Have git) {
        Say "Cloning skill repo..." Yellow
        git clone https://github.com/wtdbb/skill.git "$skill"
    } else {
        Say "git not found, cannot clone skill" Red
    }
} else {
    Say "skill repo exists" Green
}

# 3) Replace old absolute paths
Say "`n[3/7] Replace old paths..." Yellow
if ($legacyVault -ne $vault) {
    $files = Get-ChildItem (Join-Path $vault ".claude") -Recurse -File -Include *.vbs,*.ps1,*.json -ErrorAction SilentlyContinue
    $fixed = 0
    foreach ($f in $files) {
        if ($f.FullName -eq $PSCommandPath) { continue }
        $c = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
        if ($c.Contains($legacyVault)) {
            [System.IO.File]::WriteAllText($f.FullName, $c.Replace($legacyVault, $vault), (New-Object System.Text.UTF8Encoding($false)))
            $fixed++
        }
    }
    Say ("Updated " + $fixed + " files") Green
} else {
    Say "Current path equals legacy path; no replacement needed" Green
}

# 4) Rebuild junction
Say "`n[4/7] Rebuild .claude\skills junction..." Yellow
$link = Join-Path $vault ".claude\skills"
if (Test-Path $link) {
    Say ".claude\skills exists, skipping" Green
} else {
    cmd /c mklink /J "$link" "$skill" | Out-Null
    Say "Junction created" Green
}

# 5) .env template
Say "`n[5/7] Check .env..." Yellow
$envFile = Join-Path $skill "sp-skill\.env"
$envEx   = Join-Path $skill "sp-skill\.env.example"
if (-not (Test-Path $envFile)) {
    if (Test-Path $envEx) { Copy-Item $envEx $envFile }
    Say "Created .env template, fill AI_DOUYIN_API_KEY:" Red
    Say ("  " + $envFile) Red
} else {
    Say ".env already exists" Green
}

# 6) Scheduled tasks
Say "`n[6/7] Register scheduled tasks..." Yellow
$acVbs = Join-Path $vault ".claude\hooks\run-auto-commit-hidden.vbs"
$ac    = Join-Path $vault ".claude\hooks\auto-commit.ps1"
$syncVbs = Join-Path $vault ".claude\hooks\run-git-sync-hidden.vbs"
$sync    = Join-Path $vault ".claude\hooks\git-sync.ps1"
$wf    = Join-Path $vault ".claude\hooks\wechat-fetch.ps1"

if (Test-Path $acVbs) {
    schtasks /Create /TN "CodexVault-AutoCommit" /TR ("wscript.exe `"" + $acVbs + "`"") /SC MINUTE /MO 2 /F | Out-Null
} else {
    schtasks /Create /TN "CodexVault-AutoCommit" /TR ("powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"" + $ac + "`" -Source scheduled") /SC MINUTE /MO 2 /F | Out-Null
}

if (Test-Path $wf) {
    schtasks /Create /TN "CodexVault-WeChatFetch" /TR ("powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"" + $wf + "`"") /SC MINUTE /MO 30 /F | Out-Null
}

if (Test-Path $syncVbs) {
    schtasks /Create /TN "CodexVault-GitSync" /TR ("wscript.exe `"" + $syncVbs + "`"") /SC MINUTE /MO 5 /F | Out-Null
} elseif (Test-Path $sync) {
    schtasks /Create /TN "CodexVault-GitSync" /TR ("powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"" + $sync + "`"") /SC MINUTE /MO 5 /F | Out-Null
}
Say "Scheduled tasks registered" Green

# 7) Git remote status
Say "`n[7/7] Git remote check..." Yellow
$remote = & git remote -v 2>$null
if ([string]::IsNullOrWhiteSpace($remote)) {
    Say "No git remote configured yet, so two computers cannot sync automatically." Yellow
    Say "Add the same remote to both machines (GitHub/GitLab/bare repo), then use git pull/push." Yellow
} else {
    Say "Remote(s):" Green
    Say $remote Green
}

Say "`n==== Done ====" Cyan
Say "Manual follow-up:" Yellow
Say "  1. Install any missing dependency listed above" 
Say "  2. Fill skill\sp-skill\.env with AI_DOUYIN_API_KEY"
Say "  3. Configure the same git remote on both computers"
Say "  4. Restart Obsidian or trigger the Claude hook once"
