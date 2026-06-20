$ErrorActionPreference = "SilentlyContinue"

$documents = [Environment]::GetFolderPath("MyDocuments")
$startFolder = ([char]0x5F00).ToString() + ([char]0x59CB).ToString()
$workspace = Join-Path $documents $startFolder
$agent = Join-Path $workspace "tools\codexvault-agent\codexvault-agent.ps1"

if (Test-Path -Path $agent) {
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $agent
}

exit 0
