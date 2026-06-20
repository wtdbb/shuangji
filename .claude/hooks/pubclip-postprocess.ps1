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
$jobDir    = Join-Path $vault "岗位mapping"
$indDir    = Join-Path $vault "行业mapping"
$imgDir    = Join-Path $vault "图片归档"
$attDir    = Join-Path $vault "图片归档\公众号附件"
$stateDir  = Join-Path $vault ".claude\wechat"
$stateFile = Join-Path $stateDir "pubclip-postprocess-state.json"

New-Item -ItemType Directory -Force -Path $dailyDir,$jobDir,$indDir,$imgDir,$attDir,$stateDir | Out-Null

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

function Get-ArticleBody([string]$Text) {
    if ($Text -match '(?s)\A---\r?\n.*?\r?\n---\r?\n(.*)$') {
        return $Matches[1].Trim()
    }
    return $Text
}

function Test-UsableValue([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
    if ($Value -match '\{\{.*\}\}') { return $false }
    if ($Value -match '判断这篇文章|只提取|不要解释|不要编造') { return $false }
    return $true
}

function Guess-Category([string]$Title, [string]$Text) {
    $jobWords = '招聘|岗位|JD|简历|面试|薪资|薪酬|经验|直招|猎头|HC|offer|到岗'
    if ($Title -match $jobWords -or $Text -match $jobWords) { return '岗位动态' }
    return '行业动态'
}

function Guess-Company([string]$Title, [string]$Text) {
    $known = @(
        '腾讯','网易','米哈游','莉莉丝','字节','抖音','B站','哔哩哔哩','完美世界','三七互娱','巨人','盛趣','西山居',
        '鹰角','叠纸','沐瞳','祖龙','灵犀','青瓷','友谊时光','雷霆','心动','IGG','昆仑','4399','诗悦','朝夕光年'
    )
    $hits = New-Object System.Collections.Generic.List[string]
    foreach ($k in $known) {
        if ($Title -match [regex]::Escape($k) -or $Text -match [regex]::Escape($k)) { $hits.Add($k) }
    }
    $uniq = $hits | Select-Object -Unique
    if ($uniq) { return ($uniq -join '，') + '（推断）' }
    return '未提及'
}

function Guess-Reason([string]$Title, [string]$Text) {
    $sentences = [regex]::Split($Text, '(?<=[。！？\.\n])')
    $focus = @()
    foreach ($s in $sentences) {
        if ($s -match '测试|上线|发布|代理|融资|裁员|招聘|收购|调整|立项|曝光|预约|开服|更新') {
            $clean = ($s -replace '\s+', ' ').Trim()
            if ($clean.Length -gt 0) { $focus += $clean }
        }
        if ($focus.Count -ge 2) { break }
    }
    if ($focus.Count -gt 0) { return ($focus -join ' / ').Trim() }
    return '无'
}

function Guess-Event([string]$Title, [string]$Text) {
    $sentences = [regex]::Split($Text, '(?<=[。！？\.\n])')
    foreach ($s in $sentences) {
        if ($s -match '测试|上线|发布|代理|融资|裁员|招聘|收购|调整|立项|曝光|预约|开服|更新') {
            $clean = ($s -replace '\s+', ' ').Trim()
            if ($clean.Length -gt 0) { return $clean }
        }
    }
    if ($Title) { return $Title.Trim() }
    return '未提及'
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
            $saved = Download-File $u $attDir
        } else {
            $saved = Download-File $u $imgDir
        }
        if ($saved) { $downloaded.Add($saved) }
    }
    return $downloaded
}

function Get-RelPath([string]$FullPath) {
    $root = $vault.TrimEnd('\')
    if ($FullPath.StartsWith($root, [System.StringComparison]::OrdinalIgnoreCase)) {
        return $FullPath.Substring($root.Length + 1).Replace('\', '/')
    }
    return $FullPath.Replace('\', '/')
}

function Ensure-RootNote([string]$Path, [string]$Title, [string]$Kind) {
    if (-not (Test-Path $Path)) {
        $header = "# $Title`n`n> 自动由公众号后处理器生成的 $Kind 精简条目。`n"
        Set-Content -Path $Path -Encoding utf8 -Value $header
    }
}

function Choose-MappingTarget([string]$Category, [string]$Title, [string]$Text) {
    $cities = @("上海","北京","广州","深圳","杭州","成都","福州","苏州")
    if ($Category -match '岗位') {
        foreach ($city in $cities) {
            if ($Title -match [regex]::Escape($city) -or $Text -match [regex]::Escape($city)) {
                return @{ Path = (Join-Path $jobDir ($city + ".md")); Kind = "岗位"; Label = $city }
            }
        }
        return @{ Path = (Join-Path $jobDir "补充记录.md"); Kind = "岗位"; Label = "补充记录" }
    }

    if ($Title -match '薪资|薪酬' -or $Text -match '薪资|薪酬') {
        return @{ Path = (Join-Path $indDir "薪资段位.md"); Kind = "行业"; Label = "薪资段位" }
    }
    if ($Title -match '工作室|团队' -or $Text -match '工作室|团队') {
        return @{ Path = (Join-Path $indDir "工作室分布.md"); Kind = "行业"; Label = "工作室分布" }
    }
    if ($Title -match '话术|说话|沟通' -or $Text -match '话术|说话|沟通') {
        return @{ Path = (Join-Path $indDir "说话技巧.md"); Kind = "行业"; Label = "说话技巧" }
    }
    if ($Title -match '现状|趋势|行业|市场' -or $Text -match '现状|趋势|行业|市场') {
        return @{ Path = (Join-Path $indDir "行业现状.md"); Kind = "行业"; Label = "行业现状" }
    }
    return @{ Path = (Join-Path $indDir "行业内报.md"); Kind = "行业"; Label = "行业内报" }
}

function Add-SectionOnce([string]$Path, [string]$Marker, [string]$Block) {
    $existing = ""
    if (Test-Path $Path) { $existing = Get-Content $Path -Raw -Encoding utf8 }
    if ($existing.Contains($Marker)) { return }
    Add-Content -Path $Path -Encoding utf8 -Value $Block
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

function Get-SourceFiles {
    $all = Get-ChildItem $vault -Recurse -File -Filter *.md | Where-Object {
        $_.FullName -notmatch '\\(\.obsidian|\.claude|skill)(\\|$)' -and
        $_.FullName -notmatch '\\(行业报告\\日报输出|行业报告\\视频链接|岗位mapping|行业mapping|图片归档)(\\|$)'
    }

    $out = New-Object System.Collections.Generic.List[System.IO.FileInfo]
    foreach ($f in $all) {
        if ($f.FullName -ieq (Join-Path $vault "配置\自动化\公众号剪藏模板.md")) { continue }
        if ($f.FullName -match '\\配置\\自动化\\') { continue }
        if ($f.FullName -like "*\行业报告\公众号原内容\*" ) {
            if ($f.Name -ne "_公众号收件箱.md" -and $f.Name -ne "index.md") { $out.Add($f) }
            continue
        }

        $txt = Get-Content $f.FullName -Raw -Encoding utf8
        if ($txt -match '(?s)\A---\r?\n.*?(?m)^\s*clip_type\s*:\s*公众号原文\s*$') {
            $out.Add($f)
        }
    }
    return $out
}

$files = Get-SourceFiles

if (-not $files) { exit 0 }

$today = Get-Date -Format "yyyy-MM-dd"
Ensure-DailyHeader $dailyFile $today

foreach ($file in $files) {
    $stamp = [string]$file.LastWriteTimeUtc.Ticks
    if ($state.ContainsKey($file.FullName) -and $state[$file.FullName] -eq $stamp) {
        continue
    }
    $text = Get-Content $file.FullName -Raw -Encoding utf8
    $front = Get-FrontMatterMap $text

    $title = $front["clip_title"]
    if ([string]::IsNullOrWhiteSpace($title)) { $title = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) }
    $sourceUrl = $front["source_url"]

    $body     = Get-ArticleBody $text
    $category = Get-Field $text "分类"
    if (-not (Test-UsableValue $category)) { $category = Guess-Category $title $body }
    $company  = Get-Field $text "公司名字"
    if (-not (Test-UsableValue $company)) { $company = Guess-Company $title $body }
    $event    = Get-Field $text "关键事件"
    if (-not (Test-UsableValue $event)) { $event = Guess-Event $title $body }
    $reason   = Get-Field $text "推断依据"
    if (-not (Test-UsableValue $reason)) { $reason = Guess-Reason $title $body }

    # 如果有 source_url，尝试下载文章里的媒体
    $downloads = @()
    if (-not [string]::IsNullOrWhiteSpace($sourceUrl)) {
        $downloads = Download-MediaFromSource $sourceUrl
    }

    # 生成日报条目
    $sourceRel = (Get-RelPath $file.FullName) -replace '\.md$', ''
    $reportMarker = "[[$sourceRel]]"
    $reportBlock = @"

### $title
- 分类: $category
- 公司名字: $company
- 关键事件: $event
- 推断依据: $reason
- 原文: $reportMarker
"@
    if ($downloads.Count -gt 0) {
        $relLinks = $downloads | ForEach-Object { "![[{0}]]" -f (Get-RelPath $_) }
        $reportBlock += "`n- 已下载附件:`n  - " + ($relLinks -join "`n  - ")
    }
    Add-SectionOnce $dailyFile $title $reportBlock

    # 生成 mapping 精简条目：优先写现有主文件，找不到合适字段就同层新建文件
    $route = Choose-MappingTarget $category $title $text
    Ensure-RootNote $route.Path $route.Label $route.Kind

    $localAttachments = ""
    if ($downloads.Count -gt 0) {
        $localAttachments = "`n- 已下载附件:`n" + (($downloads | ForEach-Object { "  - ![[{0}]]" -f (Get-RelPath $_) }) -join "`n")
    }

    $mappingBlock = "`n### $title`n"
    if (-not [string]::IsNullOrWhiteSpace($sourceUrl)) {
        $mappingBlock += "- 链接：$sourceUrl`n"
    }
    $routeRel = Get-RelPath $route.Path
    $mappingBlock += "- 去向：[[$routeRel]]`n"
    $mappingBlock += @"
- 分类：$category
- 公司：$company
- 关键事件：$event
- 推断依据：$reason
- 原文：[[行业报告/公众号原内容/$($file.BaseName)]]
$localAttachments
"@
    Add-SectionOnce $route.Path $title $mappingBlock

    $state[$file.FullName] = $stamp
}

Save-State $state
exit 0


