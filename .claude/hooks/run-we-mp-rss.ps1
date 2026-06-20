$ErrorActionPreference = "Stop"

$startDir = "$([char]0x5F00)$([char]0x59CB)"
$root = Join-Path $env:USERPROFILE ("Documents\" + $startDir + "\tools\we-mp-rss")
Set-Location -LiteralPath $root

New-Item -ItemType Directory -Force -Path (Join-Path $root "data") | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $root "logs") | Out-Null

$python = Join-Path $root ".venv\Scripts\python.exe"
if (-not (Test-Path $python)) {
    $python = "python"
}

$log = Join-Path $root "logs\we-mp-rss-service.log"
& $python "main.py" -job True -init True *>> $log
