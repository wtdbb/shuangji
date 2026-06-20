param([string]$Source = "auto")

# 自动提交脚本(路径自适应):被 Claude hook 和 Windows 计划任务共用
# vault 根目录 = 本脚本所在目录(.claude/hooks)的上两级,换电脑/用户名也能用
# 只有在工作区有改动时才提交,避免空提交

$ErrorActionPreference = "SilentlyContinue"

$vault = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# git:优先 PATH,失败再找常见安装位置
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

# 防并发:hook 和计划任务可能同时触发,简单重试避开 index.lock
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
