Set shell = CreateObject("WScript.Shell")
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""C:\Users\EDY\Documents\CodexVault\.claude\hooks\auto-commit.ps1"" -Source scheduled"
shell.Run cmd, 0, False
