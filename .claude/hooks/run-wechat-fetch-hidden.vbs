Set shell = CreateObject("WScript.Shell")
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File ""C:\Users\EDY\Documents\CodexVault\.claude\hooks\wechat-fetch.ps1"""
shell.Run cmd, 0, False
