param(
    [string]$Source = "watch"
)

# 公众号实时后处理监听器：
# - 监听 行业报告/公众号原内容 下的 md 新增/修改/重命名
# - 触发 .claude/hooks/pubclip-postprocess.ps1
# - 用 Mutex 防止重复启动多个 watcher

$ErrorActionPreference = "SilentlyContinue"

$vault = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$sourceDir = Join-Path $vault "行业报告\公众号原内容"
$postprocess = Join-Path $PSScriptRoot "pubclip-postprocess.ps1"
$logDir = Join-Path $vault ".claude\logs"
$logFile = Join-Path $logDir "pubclip-watch.log"

New-Item -ItemType Directory -Force -Path $sourceDir,$logDir | Out-Null

function Write-Log([string]$Message) {
    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -Path $logFile -Value $line -Encoding utf8
}

$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, "Global\CodexVault-PubClipWatch", [ref]$createdNew)
if (-not $createdNew) {
    Write-Log "watcher already running; exit"
    exit 0
}

try {
    if (-not (Test-Path $postprocess)) {
        Write-Log "postprocess missing: $postprocess"
        exit 1
    }

    Write-Log "watcher started: $sourceDir"

    # 启动时先跑一次，补掉已经剪藏但还没处理的内容
    & powershell -NoProfile -ExecutionPolicy Bypass -File $postprocess -Source "watch-start" | Out-Null

    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $sourceDir
    $watcher.Filter = "*.md"
    $watcher.IncludeSubdirectories = $false
    $watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite, Size, CreationTime'
    $watcher.EnableRaisingEvents = $true

    Register-ObjectEvent $watcher Created -SourceIdentifier PubClipCreated | Out-Null
    Register-ObjectEvent $watcher Changed -SourceIdentifier PubClipChanged | Out-Null
    Register-ObjectEvent $watcher Renamed -SourceIdentifier PubClipRenamed | Out-Null

    $pending = $false
    $nextRun = Get-Date

    while ($true) {
        $evt = Wait-Event -Timeout 1
        if ($evt) {
            $path = ""
            try { $path = $evt.SourceEventArgs.FullPath } catch {}
            Remove-Event -EventIdentifier $evt.EventIdentifier | Out-Null

            if ($path -and $path -notmatch '\\(_公众号收件箱|index)\.md$') {
                $pending = $true
                $nextRun = (Get-Date).AddSeconds(3)
                Write-Log "change detected: $path"
            }
        }

        if ($pending -and (Get-Date) -ge $nextRun) {
            $pending = $false
            Write-Log "run postprocess"
            & powershell -NoProfile -ExecutionPolicy Bypass -File $postprocess -Source "watch" | Out-Null
            Write-Log "postprocess done"
            # 冷却:后处理器会改写源文件(清洗正文/补媒体),清掉这些自触发事件并静默一段,打破自我循环
            Start-Sleep -Seconds 2
            Get-Event -ErrorAction SilentlyContinue | Remove-Event -ErrorAction SilentlyContinue
            $pending = $false
            $nextRun = (Get-Date).AddSeconds(15)
        }
    }
}
finally {
    try { $watcher.Dispose() } catch {}
    try { $mutex.ReleaseMutex() | Out-Null; $mutex.Dispose() } catch {}
    Write-Log "watcher stopped"
}

