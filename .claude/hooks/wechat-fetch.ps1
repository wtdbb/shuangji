# 微信公众号 RSS 抓取脚本
# 读取 .claude/wechat/feeds.txt 里的 RSS 链接,把新文章追加到
# 游戏行业日报/_公众号收件箱.md(供 AI 后续整理),并用 seen.json 去重。
# 本脚本只做"抓取+落地",不做 AI 分类(那一步由 Claude 完成)。

$ErrorActionPreference = "SilentlyContinue"

$vault    = "C:\Users\EDY\Documents\CodexVault"
$feedFile = Join-Path $vault ".claude\wechat\feeds.txt"
$seenFile = Join-Path $vault ".claude\wechat\seen.json"
$inbox    = Join-Path $vault "游戏行业日报\_公众号收件箱.md"

if (-not (Test-Path $feedFile)) { exit 0 }

# 读取已见过的文章 ID
$seen = @{}
if (Test-Path $seenFile) {
    try {
        (Get-Content $seenFile -Raw | ConvertFrom-Json).PSObject.Properties | ForEach-Object { $seen[$_.Name] = $true }
    } catch {}
}

function Get-NodeText($item, $name) {
    $n = $item.SelectSingleNode($name)
    if ($n) { return ([string]$n.InnerText).Trim() }
    return ""
}

function Strip-Html($s) {
    if (-not $s) { return "" }
    $s = $s -replace '<[^>]+>', ''
    $s = $s -replace '&nbsp;', ' ' -replace '&amp;', '&' -replace '&lt;', '<' -replace '&gt;', '>' -replace '&quot;', '"'
    $s = $s -replace '\s+', ' '
    return $s.Trim()
}

$feeds = Get-Content $feedFile | Where-Object { $_.Trim() -ne '' -and -not $_.Trim().StartsWith('#') }
$newItems = New-Object System.Collections.Generic.List[string]
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

foreach ($url in $feeds) {
    $url = $url.Trim()
    try {
        $resp = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30
        [xml]$xml = $resp.Content
    } catch { continue }

    $items = @($xml.rss.channel.item)
    foreach ($it in $items) {
        if (-not $it) { continue }
        $title = Get-NodeText $it 'title'
        $link  = Get-NodeText $it 'link'
        $date  = Get-NodeText $it 'pubDate'
        $id    = Get-NodeText $it 'guid'
        if ([string]::IsNullOrWhiteSpace($id)) { $id = $link }
        if ([string]::IsNullOrWhiteSpace($id)) { $id = $title }
        if ($seen.ContainsKey($id)) { continue }

        $desc = Strip-Html (Get-NodeText $it 'description')
        if ($desc.Length -gt 1000) { $desc = $desc.Substring(0,1000) + "…" }

        $block = @"

### $title
- 链接: $link
- 时间: $date
- 状态: ⏳ 待AI整理
- 摘要: $desc
"@
        $newItems.Add($block)
        $seen[$id] = $true
    }
}

if ($newItems.Count -gt 0) {
    if (-not (Test-Path $inbox)) {
        Set-Content -Path $inbox -Value "# 公众号推送收件箱`n`n> 自动抓取的公众号新文章。Claude 会把它们整理进日报与 mapping,整理后状态改为 ✅。`n" -Encoding utf8
    }
    $stamp = "`n## 抓取于 $(Get-Date -Format 'yyyy-MM-dd HH:mm')`n" + ($newItems -join "`n")
    Add-Content -Path $inbox -Value $stamp -Encoding utf8

    # 保存去重状态
    $obj = @{}
    foreach ($k in $seen.Keys) { $obj[$k] = $true }
    ($obj | ConvertTo-Json -Compress) | Set-Content -Path $seenFile -Encoding utf8
}

exit 0
