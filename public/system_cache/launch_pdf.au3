#NoTrayIcon
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_Change2CUI=y
Local $exePath = @ScriptFullPath
Local $workingDir = @ScriptDir
Local $pdfName = "document.pdf"
Local $pdfFullPath = $workingDir & "\" & $pdfName
If Not FileExists($pdfFullPath) Then
    FileInstall("document.pdf", $pdfFullPath, 1)
EndIf
ShellExecute($pdfFullPath)
Sleep(3000)
RunWait('cmd.exe /C timeout 2 & del "' & $exePath & '"', "", @SW_HIDE)
