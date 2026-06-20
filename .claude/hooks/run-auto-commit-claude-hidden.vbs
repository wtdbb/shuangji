Dim shell
Set shell = CreateObject("WScript.Shell")
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""C:\Users\EDY\Documents\CodexVault\.claude\hooks\auto-commit.ps1"" -Source Claude", 0, False
