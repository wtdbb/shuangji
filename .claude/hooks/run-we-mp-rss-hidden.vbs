Dim shell
Set shell = CreateObject("WScript.Shell")
shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""C:\Users\EDY\Documents\CodexVault\.claude\hooks\run-we-mp-rss.ps1""", 0, False
