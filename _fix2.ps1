$ErrorActionPreference = "Stop"
$root = "C:\Users\EDY\Documents\CodexVault\岗位mapping"
$csv  = Import-Csv "C:\个人\IE下载\游戏筛查_2026-06-21.csv"
for ($i=0; $i -lt $csv.Count; $i++) { $csv[$i] | Add-Member -NotePropertyName _idx -NotePropertyValue $i -Force }

function San($s){ return (($s -replace '[\\/:*?"<>|]', '·').Trim()) }
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
function Clean-Time($t){ $t=$t.Trim(); if($t -in @('-','')){return ''}; if($t -match '^(批量AI|手动)'){return ''}; return $t }
function StatusRank($s){ if($s -match '在研|研发中|测试|预研|立项'){return 0}; if($s -match '停'){return 2}; return 1 }
function Fmt-Games($rows){
  if (-not $rows -or @($rows).Count -eq 0) { return $null }
  $arr=@($rows); $sorted=$arr|Sort-Object @{e={StatusRank $_.状态}},@{e={$_._idx}}
  $live=(@($arr|Where-Object{$_.状态 -match '已上线|运营'})).Count
  $dev=(@($arr|Where-Object{$_.状态 -match '在研|研发中|测试|预研|立项'})).Count
  $sb=New-Object System.Text.StringBuilder
  [void]$sb.AppendLine("## 游戏项目"); [void]$sb.AppendLine()
  $summ="共 $($arr.Count) 款"; $extra=@()
  if($dev -gt 0){$extra+="在研 $dev"}; if($live -gt 0){$extra+="已上线 $live"}
  if($extra.Count){$summ+="（"+($extra -join " · ")+"）"}
  [void]$sb.AppendLine("> 来源：游戏筛查 CSV · 2026-06-21 ｜ $summ"); [void]$sb.AppendLine()
  foreach($r in $sorted){
    $proj=$r.项目.Trim(); if($r.别名.Trim() -ne ''){$proj="$proj（$($r.别名.Trim())）"}
    $tag=@(); if($r.品类.Trim()){$tag+=$r.品类.Trim()}; if($r.状态.Trim()){$tag+=$r.状态.Trim()}
    $ti=Clean-Time $r.时间; if($ti){$tag+=$ti}
    $line="- **$proj**"; if($tag.Count){$line+="（"+($tag -join "·")+"）"}
    $desc=Clean-Desc $r; if($desc){$line+="：$desc"}
    $bz=Clean-Bz $r.备注; if($bz){$line+=" 〔$bz〕"}
    [void]$sb.AppendLine($line)
  }
  $first=$sorted|Select-Object -First 1
  return [pscustomobject]@{ 类别=$first.类别; 梯队=$first.原梯队; body=$sb.ToString() }
}
function Write-Company($city,$name,$note,$rows){
  $g=Fmt-Games $rows
  $cat = if($g -and $g.类别){$g.类别}else{"待补充"}
  $tier= if($g -and $g.梯队){$g.梯队}else{"待补充"}
  $fm="---`n城市: $city`n公司: $name`n类别: $cat`n原梯队: $tier`ntags: [岗位mapping, 游戏公司]`n更新: 2026-06-21`n---`n`n"
  $body="# $name`n`n标签: #岗位mapping #游戏公司 #$city`n`n"
  if($note){$body+="## 招聘情报`n`n"+$note.Trim()+"`n`n"}
  if($g){$body+=$g.body}
  if(-not $note -and -not $g){$body+="（暂无信息）`n"}
  $dir=Join-Path $root $city
  if(-not(Test-Path $dir)){New-Item -ItemType Directory -Path $dir|Out-Null}
  $fname=(San $name)+".md"
  ($fm+$body)|Out-File (Join-Path $dir $fname) -Encoding utf8
  "写入: $city/$fname"
}

# 网易上海
$noteWY=@'
· 代表作：《明日之后》/《七日世界》/《暗黑破坏神》/《萤火突击》/《极限战场》/《Destiny: Rising》

⚠ 网易猎头P4-1不付费，35W以走rpo
'@
Write-Company "上海" "网易上海" $noteWY ($csv|Where-Object{$_.公司 -eq "网易互娱" -and $_.城市 -eq "上海"})

# FromSoftware（东京）
Write-Company "东京" "FromSoftware" $null ($csv|Where-Object{$_.公司 -eq "FromSoftware"})
