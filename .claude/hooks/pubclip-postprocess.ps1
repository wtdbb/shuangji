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

function Clean-ClipText([string]$Text) {
    $Text = [regex]::Replace($Text, '(?s)\r?\n?<!--\s*clip_full_html_begin.*?clip_full_html_end\s*-->\r?\n?', "`n")
    $lines = $Text -split "\r?\n"
    $out = New-Object System.Collections.Generic.List[string]
    $dropRest = $false
    $junkLine = '^\s*(X|新增人才|有可能重复的简历|继续滑动看下一个|向上滑动看下一个|微信扫一扫赞赏作者|作者提示[:：].*|.+[·•]\s*目录|手游[，,].*目录)\s*$'
    $tailStart = '继续滑动看下一个|向上滑动看下一个|微信扫一扫赞赏作者|新增人才|有可能重复的简历|声明：文中观点|喜欢文章的朋友请关注|转载.*原创文章|对稿件有异议|新增人才|有可能重复的简历'

    foreach ($line in $lines) {
        if ($dropRest) { continue }
        if ($line -match $tailStart) {
            $dropRest = $true
            continue
        }
        if ($line -match $junkLine) { continue }
        if ($line -match 'data:image/svg\+xml.*1px') { continue }
        $out.Add($line)
    }

    $clean = ($out -join "`n").TrimEnd() + "`n"
    return $clean
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

function Normalize-CompanyName([string]$Company) {
    if ([string]::IsNullOrWhiteSpace($Company)) { return "" }
    $c = $Company -replace '（推断）|\(推断\)', ''
    $c = ($c -split '[,，、/；;]')[0].Trim()
    $aliases = @{
        "字节" = "字节"
        "字节跳动" = "字节"
        "朝夕光年" = "字节"
        "腾讯" = "腾讯"
        "网易" = "网易"
        "米哈游" = "米哈游"
        "库洛游戏" = "库洛"
        "库洛" = "库洛"
        "三七互娱" = "三七互娱"
        "莉莉丝" = "莉莉丝"
        "鹰角" = "鹰角"
        "叠纸" = "叠纸"
        "完美世界" = "完美世界"
        "西山居" = "西山居"
    }
    foreach ($k in $aliases.Keys) {
        if ($c -match [regex]::Escape($k)) { return $aliases[$k] }
    }
    if ($c -eq "未提及") { return "" }
    return (Get-SafeFileName $c)
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

function Get-HashText([string]$Text) {
    return [BitConverter]::ToString((New-Object System.Security.Cryptography.SHA1Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($Text))).Replace("-", "").ToLower()
}

function Get-ExtFromUrl([string]$Url, [string]$DefaultExt = ".bin") {
    $ext = ""
    try {
        $uri = [Uri]$Url
        $ext = [System.IO.Path]::GetExtension($uri.AbsolutePath)
    } catch {}
    if ($ext -match '^\.[A-Za-z0-9]{2,5}$') { return $ext.ToLower() }
    if ($Url -match '(?:\?|&)(?:wx_fmt|tp|format)=([A-Za-z0-9]+)') {
        $fmt = $Matches[1].ToLower()
        if ($fmt -eq 'jpeg') { return '.jpg' }
        if ($fmt -match '^(jpg|png|gif|webp|mp4|mov|m4v|webm)$') { return ".$fmt" }
    }
    return $DefaultExt
}

function Download-File([string]$Url, [string]$Folder) {
    try {
        $uri = [Uri]$Url
    } catch {
        return $null
    }
    $hash = Get-HashText $Url
    $ext = Get-ExtFromUrl $Url ".bin"
    $name = "$hash$ext"
    $out = Join-Path $Folder $name
    if (Test-Path $out) { return $out }
    try {
        Invoke-WebRequest -Uri $Url -OutFile $out -UseBasicParsing -TimeoutSec 60 -Headers @{
            "User-Agent" = "Mozilla/5.0"
            "Referer" = "https://mp.weixin.qq.com/"
        } | Out-Null
        return $out
    } catch {
        return $null
    }
}

function Decode-UrlText([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return "" }
    $v = [System.Net.WebUtility]::HtmlDecode($Value)
    $v = $v -replace '\\/', '/'
    $v = $v -replace '\\u0026', '&'
    $v = $v -replace '&amp;', '&'
    return $v.Trim()
}

function Get-WechatMediaUrls([string]$Html) {
    $bag = New-Object System.Collections.Generic.List[string]
    $patterns = @(
        '(?:data-src|src|cover|cdn_url|video_url|url)\s*[:=]\s*["'']([^"'']+)["'']',
        '(https?:\\?/\\?/mmbiz\.qpic\.cn\\?/[^"''\s<>]+)',
        '(https?:\\?/\\?/[^"''\s<>]+?\.(?:jpg|jpeg|png|gif|webp|mp4|mov|m4v|webm)(?:\?[^"''\s<>]+)?)'
    )
    foreach ($pat in $patterns) {
        foreach ($m in [regex]::Matches($Html, $pat)) {
            $u = Decode-UrlText $m.Groups[1].Value
            if ($u -match '^https?://' -and ($u -match 'mmbiz\.qpic\.cn|\.jpg|\.jpeg|\.png|\.gif|\.webp|\.mp4|\.mov|\.m4v|\.webm')) {
                $bag.Add($u)
            }
        }
    }
    return $bag | Where-Object { $_ -notmatch 'data:image/svg|/emoji|mmbiz_png/0\?' } | Select-Object -Unique
}

function Download-MediaFromSource([string]$SourceUrl) {
    $downloaded = New-Object System.Collections.Generic.List[string]
    if ([string]::IsNullOrWhiteSpace($SourceUrl)) { return $downloaded }

    try {
        $html = (Invoke-WebRequest -Uri $SourceUrl -UseBasicParsing -TimeoutSec 60 -Headers @{ "User-Agent" = "Mozilla/5.0" }).Content
    } catch {
        return $downloaded
    }

    $urls = Get-WechatMediaUrls $html

    foreach ($u in $urls) {
        if ($u -match '\.(mp4|mov|m4v|webm)(\?|$)|(?:\?|&)type=video|video') {
            $saved = Download-File $u $attDir
        } else {
            $saved = Download-File $u $imgDir
        }
        if ($saved) { $downloaded.Add($saved) }
    }
    return $downloaded
}

function Download-MediaFromHtml([string]$Html) {
    $downloaded = New-Object System.Collections.Generic.List[string]
    if ([string]::IsNullOrWhiteSpace($Html)) { return $downloaded }
    $urls = Get-WechatMediaUrls $Html
    foreach ($u in $urls) {
        if ($u -match '\.(mp4|mov|m4v|webm)(\?|$)|(?:\?|&)type=video|video') {
            $saved = Download-File $u $attDir
        } else {
            $saved = Download-File $u $imgDir
        }
        if ($saved) { $downloaded.Add($saved) }
    }
    return $downloaded
}

function Update-SourceMediaSection([string]$Path, $Downloads) {
    if (-not $Downloads -or $Downloads.Count -eq 0) { return }
    $content = Get-Content $Path -Raw -Encoding utf8
    $marker = "## 本地媒体归档"
    if ($content.Contains($marker)) { return }
    $links = $Downloads | ForEach-Object { "- ![[{0}]]" -f (Get-RelPath $_) }
    $block = "`n`n$marker`n" + ($links -join "`n") + "`n"
    Add-Content -Path $Path -Value $block -Encoding utf8
}

function Rewrite-InlineImages([string]$Path, [string]$SourceUrl) {
    $content = Get-Content $Path -Raw -Encoding utf8
    $orig = $content
    # 1) 把正文里的远程图片/视频 ![alt](url) 下载到本地并改成本地嵌入,避免破图
    foreach ($m in [regex]::Matches($orig, '!\[[^\]]*\]\((https?://[^)\s]+)\)')) {
        $url = $m.Groups[1].Value
        if ($url -match '\.(mp4|mov|m4v|webm)(\?|$)') { $local = Download-File $url $attDir }
        else { $local = Download-File $url $imgDir }
        if ($local) {
            $content = $content.Replace($m.Value, ("![[" + (Get-RelPath $local) + "]]"))
        }
    }
    # 2) 再从源页面抓正文没覆盖到的图片/视频,补到“本地媒体归档”
    $extra = New-Object System.Collections.Generic.List[string]
    if (-not [string]::IsNullOrWhiteSpace($SourceUrl)) {
        foreach ($d in (Download-MediaFromSource $SourceUrl)) {
            $rel = Get-RelPath $d
            if (-not $content.Contains($rel)) { $extra.Add($rel) }
        }
    }
    if ($extra.Count -gt 0 -and -not $content.Contains("## 本地媒体归档")) {
        $links = $extra | ForEach-Object { "- ![[$_]]" }
        $content += "`n`n## 本地媒体归档`n" + ($links -join "`n") + "`n"
    }
    if ($content -ne $orig) { Set-Content -Path $Path -Value $content -Encoding utf8 }
}

function Set-RoundRegion($ctrl, [int]$radius) {
    try {
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $d = $radius * 2
        $w = $ctrl.Width; $h = $ctrl.Height
        $path.AddArc(0, 0, $d, $d, 180, 90)
        $path.AddArc($w - $d, 0, $d, $d, 270, 90)
        $path.AddArc($w - $d, $h - $d, $d, $d, 0, 90)
        $path.AddArc(0, $h - $d, $d, $d, 90, 90)
        $path.CloseAllFigures()
        $ctrl.Region = New-Object System.Drawing.Region($path)
    } catch {}
}

function Show-MappingReview([string]$Title, [string]$Category, [string]$TargetRel, [string]$Block) {
    # 仅手动运行(-Source manual)才弹确认框;后台 watch/watch-start/scheduled 一律静默直接写入,避免弹窗轰炸
    if ($Source -ne 'manual') { return $Block }
    try {
        Add-Type -AssemblyName System.Windows.Forms | Out-Null
        Add-Type -AssemblyName System.Drawing | Out-Null

        $accent  = [System.Drawing.Color]::FromArgb(108, 92, 231)
        $bg      = [System.Drawing.Color]::FromArgb(248, 249, 252)
        $cardBd  = [System.Drawing.Color]::FromArgb(225, 227, 234)
        $textCol = [System.Drawing.Color]::FromArgb(33, 37, 41)
        $white   = [System.Drawing.Color]::White
        $fontUI  = New-Object System.Drawing.Font("Microsoft YaHei UI", 9.5)
        $fontMono= New-Object System.Drawing.Font("Consolas", 10.5)

        $form = New-Object System.Windows.Forms.Form
        $form.Text = "确认 / 修改 mapping 导入内容"
        $form.Width = 880
        $form.Height = 690
        $form.StartPosition = "CenterScreen"
        $form.TopMost = $true
        $form.BackColor = $bg
        $form.Font = $fontUI
        $form.FormBorderStyle = "FixedDialog"
        $form.MaximizeBox = $false
        $form.MinimizeBox = $false

        # 顶部标题栏
        $header = New-Object System.Windows.Forms.Panel
        $header.Left = 0; $header.Top = 0; $header.Width = 864; $header.Height = 66
        $header.BackColor = $accent
        $form.Controls.Add($header)

        $hTitle = New-Object System.Windows.Forms.Label
        $hTitle.Text = "确认 / 修改 mapping 导入内容"
        $hTitle.ForeColor = $white
        $hTitle.BackColor = $accent
        $hTitle.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 13, [System.Drawing.FontStyle]::Bold)
        $hTitle.Left = 22; $hTitle.Top = 11; $hTitle.Width = 760; $hTitle.Height = 28
        $header.Controls.Add($hTitle)

        $hSub = New-Object System.Windows.Forms.Label
        $hSub.Text = "下面内容可直接编辑;满意后点【导入】写入对应 mapping"
        $hSub.ForeColor = [System.Drawing.Color]::FromArgb(226, 223, 252)
        $hSub.BackColor = $accent
        $hSub.Left = 24; $hSub.Top = 40; $hSub.Width = 780; $hSub.Height = 20
        $header.Controls.Add($hSub)

        # 信息行
        $info = New-Object System.Windows.Forms.Label
        $info.Text = ("标题:  " + $Title + "`r`n分类:  " + $Category + "      去向:  " + $TargetRel)
        $info.ForeColor = $textCol
        $info.Left = 24; $info.Top = 80; $info.Width = 816; $info.Height = 44
        $form.Controls.Add($info)

        # 内容卡片
        $card = New-Object System.Windows.Forms.Panel
        $card.Left = 24; $card.Top = 130; $card.Width = 816; $card.Height = 440
        $card.BackColor = $white
        $card.BorderStyle = "FixedSingle"
        $card.Padding = New-Object System.Windows.Forms.Padding(10)
        $form.Controls.Add($card)

        $box = New-Object System.Windows.Forms.TextBox
        $box.Multiline = $true
        $box.ScrollBars = "Vertical"
        $box.AcceptsReturn = $true
        $box.AcceptsTab = $true
        $box.BorderStyle = "None"
        $box.BackColor = $white
        $box.ForeColor = $textCol
        $box.Font = $fontMono
        $box.Dock = "Fill"
        $box.Text = $Block.Trim()
        $card.Controls.Add($box)

        # 按钮:导入(主色)
        $import = New-Object System.Windows.Forms.Button
        $import.Text = "✓  导入修改后内容"
        $import.Left = 24; $import.Top = 584; $import.Width = 196; $import.Height = 42
        $import.FlatStyle = "Flat"
        $import.FlatAppearance.BorderSize = 0
        $import.BackColor = $accent
        $import.ForeColor = $white
        $import.Font = New-Object System.Drawing.Font("Microsoft YaHei UI", 10, [System.Drawing.FontStyle]::Bold)
        $import.Cursor = [System.Windows.Forms.Cursors]::Hand
        $import.Add_Click({ $form.Tag = "import"; $form.Close() })
        $form.Controls.Add($import)

        # 按钮:打开目标(描边)
        $open = New-Object System.Windows.Forms.Button
        $open.Text = "打开目标文件"
        $open.Left = 232; $open.Top = 584; $open.Width = 150; $open.Height = 42
        $open.FlatStyle = "Flat"
        $open.FlatAppearance.BorderColor = $cardBd
        $open.FlatAppearance.BorderSize = 1
        $open.BackColor = $white
        $open.ForeColor = $textCol
        $open.Cursor = [System.Windows.Forms.Cursors]::Hand
        $open.Add_Click({
            $vaultName = Split-Path $vault -Leaf
            $obsPath = $TargetRel -replace '\\','/'
            Start-Process ("obsidian://open?vault={0}&file={1}" -f [uri]::EscapeDataString($vaultName), [uri]::EscapeDataString($obsPath))
        })
        $form.Controls.Add($open)

        # 按钮:不导入(柔和红)
        $cancel = New-Object System.Windows.Forms.Button
        $cancel.Text = "不导入"
        $cancel.Left = 740; $cancel.Top = 584; $cancel.Width = 100; $cancel.Height = 42
        $cancel.FlatStyle = "Flat"
        $cancel.FlatAppearance.BorderSize = 0
        $cancel.BackColor = [System.Drawing.Color]::FromArgb(245, 238, 238)
        $cancel.ForeColor = [System.Drawing.Color]::FromArgb(200, 60, 60)
        $cancel.Cursor = [System.Windows.Forms.Cursors]::Hand
        $cancel.Add_Click({ $form.Tag = "cancel"; $form.Close() })
        $form.Controls.Add($cancel)

        $form.Add_Shown({
            Set-RoundRegion $import 8
            Set-RoundRegion $open 8
            Set-RoundRegion $cancel 8
        })

        $null = $form.ShowDialog()
        if ($form.Tag -eq "import") {
            return "`n" + $box.Text.Trim() + "`n"
        }
        return $null
    } catch {
        return $Block
    }
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

function Choose-MappingTarget([string]$Category, [string]$Title, [string]$Text, [string]$Company = "") {
    $cities = @("上海","北京","广州","深圳","杭州","成都","福州","苏州")
    if ($Category -match '岗位') {
        $companyName = Normalize-CompanyName $Company
        if (-not [string]::IsNullOrWhiteSpace($companyName)) {
            return @{ Path = (Join-Path $jobDir ($companyName + ".md")); Kind = "岗位"; Label = $companyName }
        }
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
    $rawText = $text
    $cleanText = Clean-ClipText $text
    if ($cleanText -ne $text) {
        Set-Content -Path $file.FullName -Value $cleanText -Encoding utf8
        $text = $cleanText
        $file.Refresh()
        $stamp = [string]$file.LastWriteTimeUtc.Ticks
    }
    $front = Get-FrontMatterMap $text

    $title = $front["clip_title"]
    if ([string]::IsNullOrWhiteSpace($title)) { $title = [System.IO.Path]::GetFileNameWithoutExtension($file.Name) }
    if ($title -match '模板|剪藏模板|Web Clipper|Note content' -or $file.BaseName -match '模板|剪藏模板|Web Clipper') {
        $state[$file.FullName] = $stamp
        continue
    }
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
    $downloads = @(Download-MediaFromHtml $rawText)
    if (-not [string]::IsNullOrWhiteSpace($sourceUrl)) {
        $downloads = @($downloads + (Download-MediaFromSource $sourceUrl)) | Select-Object -Unique
        Update-SourceMediaSection $file.FullName $downloads
        if ($downloads.Count -gt 0) {
            $file.Refresh()
            $stamp = [string]$file.LastWriteTimeUtc.Ticks
        }
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
    $route = Choose-MappingTarget $category $title $text $company
    Ensure-RootNote $route.Path $route.Label $route.Kind

    $localAttachments = ""
    if ($downloads.Count -gt 0) {
        $localAttachments = "`n- 已下载附件:`n" + (($downloads | ForEach-Object { "  - ![[{0}]]" -f (Get-RelPath $_) }) -join "`n")
    }

    $routeRel = Get-RelPath $route.Path
    $routeLink = $routeRel -replace '\.md$', ''
    $srcLink = "行业报告/公众号原内容/$($file.BaseName)"
    # 只保留核心字段:重点讲了什么 + 并入哪个目标文件(callout 排版)
    $mappingBlock = "`n> [!tip] $title`n"
    $mappingBlock += "> **重点**:$event`n"
    $mappingBlock += "> `n"
    $mappingBlock += "> **并入**:[[$routeLink]]`n"
    if (-not [string]::IsNullOrWhiteSpace($sourceUrl)) {
        $mappingBlock += "> **原文**:[阅读原文]($sourceUrl)`n"
    } else {
        $mappingBlock += "> **原文**:[[$srcLink]]`n"
    }
    $mappingBlock += "`n"
    $reviewedBlock = Show-MappingReview $title $category $routeLink $mappingBlock
    if (-not [string]::IsNullOrWhiteSpace($reviewedBlock)) {
        Add-SectionOnce $route.Path $title $reviewedBlock
    }

    $state[$file.FullName] = $stamp
}

Save-State $state
exit 0









