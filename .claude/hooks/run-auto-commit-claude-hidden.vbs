Dim shell, fso, scriptDir, ps1
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
ps1 = fso.BuildPath(scriptDir, "auto-commit.ps1")

shell.Run "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & ps1 & """ -Source Claude", 0, False
