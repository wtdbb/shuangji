Set shell = CreateObject("WScript.Shell")
vbsPath = Replace(WScript.ScriptFullName, "run-pubclip-postprocess-hidden.vbs", "pubclip-postprocess.ps1")
shell.Run "powershell -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & vbsPath & """", 0, False
