# Launch Microsoft Store TradingView Desktop with Chrome DevTools Protocol enabled.
# Resolves the install path via Get-AppxPackage, so it survives app updates
# (the WindowsApps folder name contains the version number).
# Usage: powershell -ExecutionPolicy Bypass -File scripts\launch_tv_debug_store.ps1 [-Port 9222]
param([int]$Port = 9222)

$pkg = Get-AppxPackage -Name 'TradingView.Desktop' | Select-Object -First 1
if (-not $pkg) { Write-Error 'TradingView (Microsoft Store) not found.'; exit 1 }
$exe = Join-Path $pkg.InstallLocation 'TradingView.exe'

# Already running with CDP? Nothing to do.
try {
  Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 "http://127.0.0.1:$Port/json/version" | Out-Null
  Write-Output "CDP already ready at http://127.0.0.1:$Port"
  exit 0
} catch {}

Stop-Process -Name TradingView -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
Start-Process -FilePath $exe -ArgumentList "--remote-debugging-port=$Port"

# Poll 127.0.0.1 explicitly - 'localhost' can resolve to ::1 first and hang.
for ($i = 0; $i -lt 20; $i++) {
  Start-Sleep -Seconds 2
  try {
    Invoke-WebRequest -UseBasicParsing -TimeoutSec 2 "http://127.0.0.1:$Port/json/version" | Out-Null
    Write-Output "CDP ready at http://127.0.0.1:$Port"
    exit 0
  } catch {}
}
Write-Error "TradingView started but CDP did not come up on port $Port."
exit 1
