$root = "C:\Users\EDY\Documents\CodexVault\岗位mapping"
function San($s){ return (($s -replace '[\\/:*?"<>|]', '·').Trim()) }
$city="上海"; $name="网易上海"
$dir = Join-Path $root $city
$path = Join-Path $dir (San($name) + ".md")
Write-Output ("dir=[" + $dir + "]")
Write-Output ("san=[" + (San($name)) + "]")
Write-Output ("path=[" + $path + "]")
"content" | Out-File $path -Encoding utf8
Write-Output ("exists=" + (Test-Path $path))
