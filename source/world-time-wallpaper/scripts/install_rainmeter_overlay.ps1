$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ensureScript = Join-Path $scriptDir "ensure_world_time_overlay.ps1"
if (-not (Test-Path -LiteralPath $ensureScript)) {
  throw "ensure_world_time_overlay.ps1 was not found under $scriptDir"
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File $ensureScript -InstallRainmeter -CreateStartup -CreateScheduledTask
if ($LASTEXITCODE -ne 0) {
  throw "ensure_world_time_overlay.ps1 failed. Exit code: $LASTEXITCODE"
}

Write-Host "WorldTimeOverlay installed, loaded, and configured for automatic recovery."
