param([string]$Source = "auto")

# 自动提交脚本:被 Claude hook 和 Windows 定时任务共用
# 只有在工作区有改动时才提交,避免空提交

$ErrorActionPreference = "SilentlyContinue"

$vault = "C:\Users\EDY\Documents\CodexVault"
$git = "C:\个人\ai文件\Git\cmd\git.exe"

if (-not (Test-Path $git)) {
    # 兜底:尝试从 PATH 找 git
    $cmd = Get-Command git -ErrorAction SilentlyContinue
    if ($cmd) { $git = $cmd.Source } else { exit 0 }
}

Set-Location $vault

# 防并发:hook 和定时任务可能同时触发,简单重试避开 index.lock
for ($i = 0; $i -lt 3; $i++) {
    $changes = & $git status --porcelain
    if ([string]::IsNullOrWhiteSpace($changes)) { exit 0 }

    & $git add -A
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    & $git commit -m "[$Source] auto: $ts" 2>$null
    if ($LASTEXITCODE -eq 0) { exit 0 }

    Start-Sleep -Milliseconds 800
}
exit 0
