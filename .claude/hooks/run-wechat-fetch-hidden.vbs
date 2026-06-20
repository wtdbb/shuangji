Set shell = CreateObject("WScript.Shell")
shell.Run "wscript.exe ""C:\Users\EDY\Documents\CodexVault\.claude\hooks\run-we-mp-rss-hidden.vbs""", 0, False
WScript.Sleep 3000
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""C:\Users\EDY\Documents\CodexVault\.claude\hooks\wechat-fetch.ps1"""
shell.Run cmd, 0, False
