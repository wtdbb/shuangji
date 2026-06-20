param([string]$Source = "scheduled")

# 公众号后处理器：
# 1) 读取行业报告/公众号原内容中的新剪藏
# 2) 生成公众号日报草稿
# 3) 生成岗位/行业 mapping 归档
# 4) 如有 source_url，则尝试下载图片/视频附件到本地

$ErrorActionPreference = "SilentlyContinue"

$vault = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$sourceDir = Join-Path $vault "行业报告\公众号原内容"
$dailyDir  = Join-Path $vault "行业报告\日报输出"
$dailyFile = Join-Path $dailyDir "公众号日报.md"
$jobDir    = Join-Path $vault "岗位mapping\公众号剪藏"
$indDir    = Join-Path $vault "行业mapping\公众号剪藏"
$imgDir    = Join-Path $vault "图片归档"
$vidDir    = Join-Path $vault "行业报告\视频链接\公众号附件"
$stateDir  = Join-Path $vault ".claude\wechat"
$stateFile = Join-Path $stateDir "pubclip-postprocess-state.json"

New-Item -ItemType Directory -Force -Path $dailyDir,$jobDir,$indDir,$imgDir,$vidDir,$stateDir | Out-Null

function Get-SafeFileName([string]$Name) {
    if ([string]::IsNullOrWhiteSpace($Name)) { return "untitled" }
    $n = $Name
    foreach ($c in [System.IO.Path]::GetInvalidFileNameChars()) {
        $n = $n.Replace($c, "_")
    }
    $n = $n -replace '\s+', ' '
    $n = $n.Trim()
    if ($n.Length -gt 120) { $n = $n.Substring(0, 120).Trim() }
    return $n
}

function Get-FrontMatterMap([string]$Text) {
    $map = @{}
    if ($Text -match '(?s)\A---\r?\n(.*?)\r?\n---\r?\n') {
        $block = $Matches[1]
        foreach ($line in ($block -split "\r?\n")) {
            if ($line -match '^\s*([^:]+):\s*(.*?)\s*$') {
                $map[$Matches[1].Trim()] = $Matches[2].Trim()
            }
        }
    }
    return $map
}

function Get-Field([string]$Text, [string]$Name) {
    if ($Text -match "(?m)^\s*$([regex]::Escape($Name))\s*[:：]\s*(.+?)\s*$") {
        return $Matches[1].Trim()
    }
    return ""
}

function Append-UniqueBlock([string]$Path, [string]$Marker, [string]$Block) {
    $existing = ""
    if (Test-Path $Path) { $existing = Get-Content $Path -Raw -Encoding utf8 }
    if ($existing.Contains($Marker)) { return }
    Add-Content -Path $Path -Value $Block -Encoding utf8
}

function Append-UniqueLine([string]$Path, [string]$Line) {
    $existing = ""
    if (Test-Path $Path) { $existing = Get-Content $Path -Raw -Encoding utf8 }
    if ($existing.Contains($Line)) { return }
    Add-Content -Path $Path -Value $Line -Encoding utf8
}

function Ensure-DailyHeader([string]$Path, [string]$DateKey) {
    if (-not (Test-Path $Path)) {
        Set-Content -Path $Path -Encoding utf8 -Value "# 公众号日报`n`n> 自动汇总公众号剪藏，先出日报草稿，再分流到 mapping。`n"
    }
    $content = Get-Content $Path -Raw -Encoding utf8
    if (-not $content.Contains("## $DateKey")) {
        Add-Content -Path $Path -Encoding utf8 -Value "`n## $DateKey`n"
    }
}

function Save-State($map) {
    $obj = @{}
    foreach ($k in $map.Keys) { $obj[$k] = $map[$k] }
    ($obj | ConvertTo-Json -Compress) | Set-Content -Path $stateFile -Encoding utf8
}

function Download-File([string]$Url, [string]$Folder) {
    try {
        $uri = [Uri]$Url
    } catch {
        return $null
    }
    $name = [System.IO.Path]::GetFileName($uri.AbsolutePath)
    if ([string]::IsNullOrWhiteSpace($name)) {
        $hash = [BitConverter]::ToString((New-Object System.Security.Cryptography.SHA1Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($Url))).Replace("-", "").ToLower()
        $name = $hash
    }
    if ($name -notmatch '\.[A-Za-z0-9]{2,5}$') {
        $name = $name + ".bin"
    }
    $out = Join-Path $Folder $name
    $i = 1
    while (Test-Path $out) {
        $base = [System.IO.Path]::GetFileNameWithoutExtension($name)
        $ext = [System.IO.Path]::GetExtension($name)
        $out = Join-Path $Folder ("{0}_{1}{2}" -f $base, $i, $ext)
        $i++
    }
    try {
        Invoke-WebRequest -Uri $Url -OutFile $out -UseBasicParsing -TimeoutSec 60 | Out-Null
        return $out
    } catch {
        return $null
    }
}

function Download-MediaFromSource([string]$SourceUrl) {
    $downloaded = New-Object System.Collections.Generic.List[string]
    if ([string]::IsNullOrWhiteSpace($SourceUrl)) { return $downloaded }

    try {
        $html = (Invoke-WebRequest -Uri $SourceUrl -UseBasicParsing -TimeoutSec 60 -Headers @{ "User-Agent" = "Mozilla/5.0" }).Content
    } catch {
        return $downloaded
    }

    $pattern = '(https?://[^"''\s<>]+?\.(?:jpg|jpeg|png|gif|webp|mp4|mov|m4v|webm)(?:\?[^"''\s<>]+)?)'
    $urls = [regex]::Matches($html, $pattern) | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
    if (-not $urls) {
        $urls = [regex]::Matches($html, '(https?://mmbiz\.qpic\.cn/[^"''\s<>]+)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
    }

    foreach ($u in $urls) {
        if ($u -match '\.(mp4|mov|m4v|webm)(\?|$)' ) {
            $saved = Download-File $u $vidDir
        } else {
            $saved = Download-File $u $imgDir
        }
        if ($saved) { $downloaded.Add($saved) }
    }
    return $downloaded
}

function Rewrite-MediaLinks([string]$Text, $Downloaded) {
    $out = $Text
    foreach ($p in $Downloaded) {
        $rel = $p.Replace($vault + "\", "").Replace("/", "\")
        $base = [System.IO.Path]::GetFileName($p)
        $out += "`n- 下载附件：![[${rel}]]"
    }
    return $out
}

$state = @{}
if (Test-Path $stateFile) {
    try {
        $json = Get-Content $stateFile -Raw -Encoding utf8 | ConvertFrom-Json
        if ($json) {
            foreach ($p in $json.PSObject.Properties) { $state[$p.Name] = [string]$p.Value }
        }
    } catch {}
}

$files = Get-ChildItem $sourceDir -Recurse -File -Filter *.md | Where-Object {
    $_.Name -ne "_公众号收件箱.md" -and $_.Name -ne "index.md"
}

if (-not $files) { exit 0 }

$today = Get-Date -Format "yyyy-MM-dd"
Ensure-DailyHeader $dailyFile $today

foreach ($file in $files) {
    $stamp = [string]$file.LastWriteTimeUtc.Ticks
    if ($state.ContainsKey($file.FullName) -and $state[$file.FullName] -eq $stamp) { continue }

    $text = Get-Content $file.FullName -Raw -Encoding utf8
    $front = Get-FrontMatterMap $text

    $title = $front["clip_title"]
    if ([string]::IsNullOrWhiteSpace($title)) { $title = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) }
    $sourceUrl = $front["source_url"]

    $category = Get-Field $text "分类"
    if ([string]::IsNullOrWhiteSpace($category)) { continue }
    $company  = Get-Field $text "公司名字"
    $event    = Get-Field $text "关键事件"
    $reason   = Get-Field $text "推断依据"

    # 如果有 source_url，尝试下载文章里的媒体
    $downloads = @()
    if (-not [string]::IsNullOrWhiteSpace($sourceUrl)) {
        $downloads = Download-MediaFromSource $sourceUrl
    }

    # 生成日报条目
    $reportMarker = "[[$($file.Directory.Name)/$($file.BaseName)]]"
    $reportBlock = @"

### $title
- 分类: $category
- 公司名字: $company
- 关键事件: $event
- 推断依据: $reason
- 原文: $reportMarker
"@
    if ($downloads.Count -gt 0) {
        $relLinks = $downloads | ForEach-Object { "![[{0}]]" -f ($_.Replace($vault + "\", "").Replace("/", "\")) }
        $reportBlock += "`n- 已下载附件:`n  - " + ($relLinks -join "`n  - ")
    }
    Add-Content -Path $dailyFile -Encoding utf8 -Value $reportBlock

    # 生成 mapping 草稿
    $targetDir = if ($category -match '岗位') { $jobDir } else { $indDir }
    $indexFile = Join-Path $targetDir "index.md"
    if (-not (Test-Path $indexFile)) {
        $kind = if ($targetDir -eq $jobDir) { "岗位" } else { "行业" }
        Set-Content -Path $indexFile -Encoding utf8 -Value "# 公众号剪藏（$kind）`n`n> 自动由公众号后处理器生成。`n"
    }

    $safeName = Get-SafeFileName $title
    $noteFile = Join-Path $targetDir ($safeName + ".md")

    $localAttachments = ""
    if ($downloads.Count -gt 0) {
        $localAttachments = "`n## 已下载附件`n" + (($downloads | ForEach-Object { "- ![[{0}]]" -f ($_.Replace($vault + "\", "").Replace("/", "\")) }) -join "`n")
    }

    $targetLabel = if ($targetDir -eq $jobDir) { "岗位mapping" } else { "行业mapping" }
    $targetAdvice = if ($targetDir -eq $jobDir) { "建议写入：[[岗位mapping/index]]" } else { "建议写入：[[行业mapping/index]]" }
    $noteBody = @"
---
source_note: [[行业报告/公众号原内容/$($file.BaseName)]]
source_url: $sourceUrl
category: $category
company: $company
status: processed
target: $targetLabel
---

# $title

- 分类：$category
- 公司名字：$company
- 关键事件：$event
- 推断依据：$reason
- $targetAdvice

## 归档建议

- $event

## 原文

- [[行业报告/公众号原内容/$($file.BaseName)]]

$localAttachments
"@
    Set-Content -Path $noteFile -Encoding utf8 -Value $noteBody

    Append-UniqueLine $indexFile "- [[{0}/{1}|{2}]]" -f ($targetDir.Split('\')[-1]), $safeName, $title

    $state[$file.FullName] = $stamp
}

Save-State $state
exit 0
