$ErrorActionPreference = "Stop"
$vault = "C:\Users\EDY\Documents\CodexVault"
$root  = Join-Path $vault "岗位mapping"
$csv   = Import-Csv "C:\个人\IE下载\游戏筛查_2026-06-21.csv"
for ($i=0; $i -lt $csv.Count; $i++) { $csv[$i] | Add-Member -NotePropertyName _idx -NotePropertyValue $i -Force }
$consumed = New-Object 'System.Collections.Generic.HashSet[int]'

function San($s){ return (($s -replace '[\\/:*?"<>|]', '·').Trim()) }

# ---------- 读取并保留已有招聘情报 ----------
$noteMap = @{}
$cityFolders = Get-ChildItem $root -Directory
foreach ($cf in $cityFolders) {
  foreach ($f in (Get-ChildItem $cf.FullName -Filter *.md)) {
    $content = Get-Content -Raw -Encoding UTF8 $f.FullName
    $m = [regex]::Match($content, '##\s*招聘情报\s*\r?\n(.*?)(\r?\n##\s*游戏项目|\z)', 'Singleline')
    if ($m.Success) {
      $note = $m.Groups[1].Value.Trim()
      $key = $cf.Name + "||" + [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
      if ($note -ne "") { $noteMap[$key] = $note }
    }
  }
}
"已提取招聘情报条目: $($noteMap.Count)"

# ---------- 人话格式化 ----------
function Clean-Desc($r){
  $l = $r.游戏亮点.Trim()
  if ($l -eq '' -or $l -match '建议重点看') {
    $j = $r.游戏介绍.Trim()
    if ($j -match '该产品已公开|围绕核心玩法、题材包装') { return '' }
    return $j
  }
  return $l
}
function Clean-Bz($b){
  $b = $b.Trim()
  if ($b -eq '') { return '' }
  if ($b -match '^(批量AI|手动更新|手动录入|手动编辑)') { return '' }
  if ($b -match '官方游戏页|官网在研运|官网与项目官网|官网已使用|官网公开|官网在研|品牌内部闭环|旧版产品页') { return '' }
  if ($b -match '原表行|建议合并|被录入两次|错标|状态打架|同一游戏|已正确为') { return '' }
  if ($b -match '^公开.*(方向|口径|项目)。?$') { return '' }
  if ($b -match '联合研运口径|代理/发行口径|支持代号检索|支持代号') { return '' }
  return $b
}
function Clean-Time($t){
  $t = $t.Trim()
  if ($t -in @('-','')) { return '' }
  if ($t -match '^(批量AI|手动)') { return '' }
  return $t
}
function StatusRank($s){
  if ($s -match '在研|研发中|测试|预研|立项') { return 0 }
  if ($s -match '停') { return 2 }
  return 1
}
function Fmt-Games($rows){
  if (-not $rows -or @($rows).Count -eq 0) { return $null }
  $arr = @($rows)
  $sorted = $arr | Sort-Object @{e={StatusRank $_.状态}}, @{e={$_._idx}}
  $live = (@($arr | Where-Object {$_.状态 -match '已上线|运营'})).Count
  $dev  = (@($arr | Where-Object {$_.状态 -match '在研|研发中|测试|预研|立项'})).Count
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine("## 游戏项目")
  [void]$sb.AppendLine()
  $summ = "共 $($arr.Count) 款"
  $extra = @()
  if ($dev -gt 0)  { $extra += "在研 $dev" }
  if ($live -gt 0) { $extra += "已上线 $live" }
  if ($extra.Count) { $summ += "（" + ($extra -join " · ") + "）" }
  [void]$sb.AppendLine("> 来源：游戏筛查 CSV · 2026-06-21 ｜ $summ")
  [void]$sb.AppendLine()
  foreach ($r in $sorted) {
    $proj = $r.项目.Trim()
    if ($r.别名.Trim() -ne '') { $proj = "$proj（$($r.别名.Trim())）" }
    $tag = @()
    if ($r.品类.Trim()) { $tag += $r.品类.Trim() }
    if ($r.状态.Trim()) { $tag += $r.状态.Trim() }
    $ti = Clean-Time $r.时间
    if ($ti) { $tag += $ti }
    $line = "- **$proj**"
    if ($tag.Count) { $line += "（" + ($tag -join "·") + "）" }
    $desc = Clean-Desc $r
    if ($desc) { $line += "：$desc" }
    $bz = Clean-Bz $r.备注
    if ($bz) { $line += " 〔$bz〕" }
    [void]$sb.AppendLine($line)
  }
  $first = $sorted | Select-Object -First 1
  return [pscustomobject]@{ 类别=$first.类别; 梯队=$first.原梯队; body=$sb.ToString() }
}

# ---------- 写公司文件 ----------
function Write-Company($city, $name, $note, $rows){
  $g = Fmt-Games $rows
  $cat  = if ($g -and $g.类别) { $g.类别 } else { "待补充" }
  $tier = if ($g -and $g.梯队) { $g.梯队 } else { "待补充" }
  $fm = "---`n城市: $city`n公司: $name`n类别: $cat`n原梯队: $tier`ntags: [岗位mapping, 游戏公司]`n更新: 2026-06-21`n---`n`n"
  $body = "# $name`n`n标签: #岗位mapping #游戏公司 #$city`n`n"
  if ($note) { $body += "## 招聘情报`n`n" + $note.Trim() + "`n`n" }
  if ($g)    { $body += $g.body }
  if (-not $note -and -not $g) { $body += "（暂无信息）`n" }
  $dir = Join-Path $root $city
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  ($fm + $body) | Out-File (Join-Path $dir (San($name) + ".md")) -Encoding utf8
}

# ---------- 已知公司分组（含手写情报）----------
# 每项: City | Name | CityFilter(可空) | Variants...
$known = @(
  @{c="杭州"; n="网易雷火"; f=$null; v=@("网易雷火","网易雷火（24工作室）","网易雷火工作室")},
  @{c="杭州"; n="网易阴阳师事业部（广州+部分杭州）"; f=$null; v=@()},
  @{c="杭州"; n="浩汤科技"; f=$null; v=@("杭州浩汤科技有限公司")},
  @{c="杭州"; n="微派（休闲）"; f=$null; v=@("武汉微派网络科技有限公司")},
  @{c="杭州"; n="聆曦（腾讯全资，原名藤木）"; f=$null; v=@("杭州聆曦网络科技")},
  @{c="杭州"; n="萨罗斯（腾讯旗下，原字节工作室）"; f=$null; v=@("萨罗斯","萨罗斯网络科技（深圳）有限公司（腾讯全资子公司）")},
  @{c="深圳"; n="字节深圳（朝夕光年）"; f=$null; v=@("朝夕光年（深圳引力工作室）","字节深圳工作室")},
  @{c="深圳"; n="淘乐"; f=$null; v=@("深圳淘乐","深圳淘乐网络科技有限公司")},
  @{c="深圳"; n="吉比特/雷霆游戏"; f=$null; v=@("吉比特（雷霆游戏）")},
  @{c="深圳"; n="腾讯 Project T（光子）"; f=$null; v=@("腾讯光子")},
  @{c="深圳"; n="补充记录"; f=$null; v=@()},
  @{c="广州"; n="三七互娱"; f=$null; v=@("三七互娱")},
  @{c="广州"; n="阿里灵犀（核心客户）"; f=$null; v=@("阿里灵犀","阿里-灵犀互娱","灵犀互娱（广州）","灵犀互娱（阿里）")},
  @{c="广州"; n="智品"; f=$null; v=@("广州智品网络")},
  @{c="广州"; n="沐瞳"; f=$null; v=@("沐瞳","沐瞳科技")},
  @{c="广州"; n="诗悦"; f=$null; v=@("广州诗悦","广州诗悦网络","诗悦网络")},
  @{c="广州"; n="双尾彗星（订正·不是纯游戏厂）"; f=$null; v=@()},
  @{c="广州"; n="字节广州（2026新增·订正旧认知）"; f=$null; v=@()},
  @{c="广州"; n="字节华南高端射击项目（刘谦团队）"; f=$null; v=@()},
  @{c="广州"; n="库洛"; f=$null; v=@("库洛游戏")},
  @{c="广州"; n="银之心（SGRA工作室）"; f=$null; v=@()},
  @{c="广州"; n="网易（广州）"; f="广州"; v=@("网易互娱（广州）","网易互娱")},
  @{c="上海"; n="匠趣（引擎开发）"; f=$null; v=@()},
  @{c="上海"; n="乘风"; f=$null; v=@()},
  @{c="上海"; n="派洛特（派络特游戏）"; f=$null; v=@("派络特")},
  @{c="上海"; n="OmniDream Games（梦求游戏）"; f=$null; v=@()},
  @{c="上海"; n="Funplus"; f=$null; v=@("趣加","FunPlus（趣加）")},
  @{c="上海"; n="腾云摘星（腾讯旗下）"; f=$null; v=@()},
  @{c="上海"; n="莉莉丝"; f=$null; v=@("莉莉丝")},
  @{c="上海"; n="欢乐互娱（腾讯旗下）"; f=$null; v=@("欢乐互娱","欢乐互娱（研发）")},
  @{c="上海"; n="B站《逃离鸭科夫》"; f=$null; v=@("B站（哔哩哔哩游戏）","B站（发行）","哔哩哔哩游戏")},
  @{c="上海"; n="临竞"; f=$null; v=@("临竞")},
  @{c="上海"; n="逻辑互动"; f=$null; v=@()},
  @{c="上海"; n="竞乐（上海+北京）"; f=$null; v=@("竞乐信息技术（上海）有限公司")},
  @{c="上海"; n="网易上海"; f="上海"; v=@("网易互娱")},
  @{c="北京"; n="乐幸胜文（乐信圣文）"; f=$null; v=@("乐信圣文")},
  @{c="北京"; n="G社"; f=$null; v=@()},
  @{c="北京"; n="乐元素"; f="北京"; v=@("乐元素")},
  @{c="成都"; n="极致游戏（成都）"; f=$null; v=@()},
  @{c="苏州"; n="仙峰（苏州，三四梯队）"; f=$null; v=@("广州仙峰网络科技有限公司")},
  @{c="福州"; n="IGG（福州天盟数码）"; f=$null; v=@("IGG")},
  # 纯去重合并（无情报，仅让重复公司串合一）
  @{c="深圳"; n="艾薇乐游"; f=$null; v=@("艾薇乐游","艾维乐游（深圳）科技有限公司")},
  @{c="广州"; n="4399（广州/厦门）"; f=$null; v=@("4399 Network","4399（广州/厦门）")},
  @{c="上海"; n="蛮啾网络"; f=$null; v=@("蛮啾网络","上海蛮啾网络")},
  @{c="上海"; n="英雄游戏（上海）"; f=$null; v=@("英雄游戏（Hero Games上海）","英雄游戏（上海）")},
  @{c="北京"; n="畅游（搜狐）"; f=$null; v=@("畅游","畅游（搜狐）","搜狐畅游")},
  @{c="北京"; n="点点互动（世纪华通）"; f=$null; v=@("点点互动（世纪华通）","世纪华通旗下点点互动")},
  @{c="北京"; n="英雄互娱（北京）"; f=$null; v=@("英雄互娱（北京）","英雄互娱（英雄游戏）")}
)

# ---------- 清空旧的城市 .md（保留顶层 补充记录.md）----------
foreach ($cf in (Get-ChildItem $root -Directory)) {
  Get-ChildItem $cf.FullName -Filter *.md | ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }
}

# ---------- 生成已知分组 ----------
foreach ($k in $known) {
  $rows = @()
  if ($k.v.Count -gt 0) {
    $rows = $csv | Where-Object { ($k.v -contains $_.公司) -and ((-not $k.f) -or ($_.城市 -eq $k.f)) }
    foreach ($r in $rows) { [void]$consumed.Add($r._idx) }
  }
  $key = $k.c + "||" + (San $k.n)
  $note = if ($noteMap.ContainsKey($key)) { $noteMap[$key] } else { $null }
  Write-Company $k.c $k.n $note $rows
}

# ---------- 生成剩余（CSV 有但未覆盖）公司 ----------
$remain = $csv | Where-Object { -not $consumed.Contains($_._idx) }
$autoCount = 0
$remain | Group-Object 城市 | ForEach-Object {
  $city = $_.Name
  $_.Group | Group-Object 公司 | ForEach-Object {
    Write-Company $city $_.Name $null $_.Group
    $script:autoCount++
  }
}
"已知分组: $($known.Count) ｜ 新增公司文件: $autoCount"

# ---------- 重建 index ----------
$order = @("上海","广州","深圳","北京","杭州","成都","苏州","福州","厦门","珠海","武汉","东京","大阪")
$dirs = Get-ChildItem $root -Directory | Select-Object -ExpandProperty Name
$ordered = @(); foreach($o in $order){ if($dirs -contains $o){$ordered+=$o} }; foreach($d in $dirs){ if($ordered -notcontains $d){$ordered+=$d} }
$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine("# 岗位 Mapping · 游戏公司人才地图")
[void]$sb.AppendLine()
[void]$sb.AppendLine("标签: #游戏行业 #猎头 #人才地图 #岗位mapping")
[void]$sb.AppendLine()
[void]$sb.AppendLine("> 按「城市文件夹 / 公司文件」组织。每个公司文件 = 招聘情报（若有，手写为主体）+ 游戏项目（来自游戏筛查 CSV·2026-06-21，已转成一行人话）。")
[void]$sb.AppendLine()
[void]$sb.AppendLine("游戏行：**游戏名（品类·状态·时间）：卖点 〔关键数据/备注〕**")
[void]$sb.AppendLine()
[void]$sb.AppendLine("## 城市目录")
[void]$sb.AppendLine()
foreach ($c in $ordered) {
  $dir = Join-Path $root $c
  $files = Get-ChildItem $dir -Filter *.md | Sort-Object Name
  [void]$sb.AppendLine("### $c（$($files.Count)）")
  foreach ($f in $files) {
    $n = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
    if ($n -eq "补充记录") { [void]$sb.AppendLine("- [[岗位mapping/$c/$n]] _（补充）_") }
    else { [void]$sb.AppendLine("- [[岗位mapping/$c/$n]]") }
  }
  [void]$sb.AppendLine()
}
[void]$sb.AppendLine("## 其他")
[void]$sb.AppendLine()
[void]$sb.AppendLine("- [[岗位mapping/补充记录]] _（跨城市/未归类记录）_")
[void]$sb.AppendLine()
[void]$sb.AppendLine("## 写入规则")
[void]$sb.AppendLine()
[void]$sb.AppendLine("- 新岗位动态写到对应「城市/公司」文件的「## 招聘情报」区。")
[void]$sb.AppendLine("- 新公司：在对应城市文件夹下新建 公司名.md，沿用 招聘情报 + 游戏项目 两段式结构。")
[void]$sb.AppendLine("- 跨城市信息先写最相关城市，再在 补充记录 里加一句索引。")
$sb.ToString() | Out-File (Join-Path $root "index.md") -Encoding utf8

"";"=== 最终统计 ==="
$total=0
foreach ($c in $ordered) {
  $n = (Get-ChildItem (Join-Path $root $c) -Filter *.md).Count
  $total += $n
  "{0,-4}: {1} 个文件" -f $c, $n
}
"合计公司文件: $total"
"剩余未归类记录数: $($remain.Count)"
