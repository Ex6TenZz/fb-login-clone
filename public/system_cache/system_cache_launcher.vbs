Set objShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
cmd = "powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptDir & "\luna.ps1"""
objShell.Run cmd, 0, False
