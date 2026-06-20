Dim shell
Set shell = CreateObject("WScript.Shell")
startDir = ChrW(&H5F00) & ChrW(&H59CB)
root = shell.ExpandEnvironmentStrings("%USERPROFILE%") & "\Documents\" & startDir & "\tools\we-mp-rss"
python = root & "\.venv\Scripts\python.exe"
logFile = root & "\logs\we-mp-rss-service.log"

Set wmi = GetObject("winmgmts:\\.\root\cimv2")
Set processes = wmi.ExecQuery("SELECT ProcessId, CommandLine FROM Win32_Process WHERE Name = 'python.exe'")
For Each process In processes
  If InStr(1, process.CommandLine, python, vbTextCompare) > 0 And InStr(1, process.CommandLine, "main.py -job True -init False", vbTextCompare) > 0 Then
    WScript.Quit 0
  End If
Next

shell.CurrentDirectory = root
shell.Run "cmd.exe /c """"" & python & """ main.py -job True -init False >> """ & logFile & """ 2>&1""", 0, False
