param(
  [switch]$Quiet
)

$ErrorActionPreference = "Stop"

$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, "Global\WorldTimeOverlayWatcher", [ref]$createdNew)
if (-not $createdNew) {
  return
}

try {
  $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
  $ensureScript = Join-Path $scriptDir "ensure_world_time_overlay.ps1"
  $logDir = Join-Path $env:APPDATA "WorldTimeOverlay"
  $logPath = Join-Path $logDir "watcher.log"
  New-Item -ItemType Directory -Force -Path $logDir | Out-Null

  while ($true) {
    try {
      & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ensureScript -InstallRainmeter -Quiet
    } catch {
      "$(Get-Date -Format s) $($_.Exception.Message)" | Add-Content -LiteralPath $logPath
    }

    Start-Sleep -Seconds 300
  }
} finally {
  $mutex.ReleaseMutex()
  $mutex.Dispose()
}
