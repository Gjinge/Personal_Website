param(
  [switch]$InstallRainmeter,
  [switch]$CreateStartup,
  [switch]$CreateScheduledTask,
  [switch]$Quiet
)

$ErrorActionPreference = "Stop"

function Write-Status {
  param([string]$Message)
  if (-not $Quiet) {
    Write-Host $Message
  }
}

function Find-Rainmeter {
  $candidates = New-Object System.Collections.Generic.List[string]

  $cmd = Get-Command "Rainmeter.exe" -ErrorAction SilentlyContinue
  if ($cmd -and $cmd.Source) {
    $candidates.Add($cmd.Source)
  }

  foreach ($path in @(
    "C:\Program Files\Rainmeter\Rainmeter.exe",
    "C:\Program Files (x86)\Rainmeter\Rainmeter.exe",
    "$env:LOCALAPPDATA\Programs\Rainmeter\Rainmeter.exe"
  )) {
    $candidates.Add($path)
  }

  foreach ($root in @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
  )) {
    Get-ItemProperty -Path $root -ErrorAction SilentlyContinue |
      Where-Object { $_.DisplayName -like "Rainmeter*" -and $_.InstallLocation } |
      ForEach-Object { $candidates.Add((Join-Path $_.InstallLocation "Rainmeter.exe")) }
  }

  foreach ($candidate in $candidates | Select-Object -Unique) {
    if ($candidate -and (Test-Path -LiteralPath $candidate)) {
      return (Resolve-Path -LiteralPath $candidate).Path
    }
  }

  return $null
}

function Install-RainmeterWithWinget {
  $winget = Get-Command "winget.exe" -ErrorAction SilentlyContinue
  if (-not $winget) {
    throw "Rainmeter is not installed and winget.exe is unavailable. Install Rainmeter from https://www.rainmeter.net/ and run this script again."
  }

  Write-Status "Rainmeter is missing; installing with winget..."
  & $winget.Source install --id Rainmeter.Rainmeter --exact --silent --disable-interactivity --accept-package-agreements --accept-source-agreements
  if ($LASTEXITCODE -ne 0) {
    throw "winget failed to install Rainmeter. Exit code: $LASTEXITCODE"
  }
}

function Get-DocumentsPath {
  $documents = [Environment]::GetFolderPath("MyDocuments")
  if ([string]::IsNullOrWhiteSpace($documents)) {
    $documents = Join-Path $env:USERPROFILE "Documents"
  }
  return $documents
}

function Get-OverlayPosition {
  $fallback = [pscustomobject]@{ X = 0; Y = 822 }

  try {
    Add-Type -AssemblyName System.Windows.Forms
    $workArea = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $overlayHeight = 168
    return [pscustomobject]@{
      X = [Math]::Max(0, [int]$workArea.Left)
      Y = [Math]::Max(0, [int]($workArea.Bottom - $overlayHeight - 8))
    }
  } catch {
    return $fallback
  }
}

function Install-OverlaySkin {
  param(
    [string]$RepoRoot,
    [string]$SkinRoot
  )

  $skinSource = Join-Path $RepoRoot "rainmeter\WorldTimeOverlay"
  $sourceIni = Join-Path $skinSource "WorldTimeOverlay.ini"
  if (-not (Test-Path -LiteralPath $sourceIni)) {
    throw "WorldTimeOverlay.ini was not found under $skinSource"
  }

  New-Item -ItemType Directory -Force -Path $SkinRoot | Out-Null
  $skinTarget = Join-Path $SkinRoot "WorldTimeOverlay"
  $targetIni = Join-Path $skinTarget "WorldTimeOverlay.ini"
  $needsCopy = $true
  if ((Test-Path -LiteralPath $sourceIni) -and (Test-Path -LiteralPath $targetIni)) {
    $sourceHash = (Get-FileHash -LiteralPath $sourceIni -Algorithm SHA256).Hash
    $targetHash = (Get-FileHash -LiteralPath $targetIni -Algorithm SHA256).Hash
    $needsCopy = $sourceHash -ne $targetHash
  }

  if ($needsCopy -and (Test-Path -LiteralPath $skinTarget)) {
    Remove-Item -LiteralPath $skinTarget -Recurse -Force
  }
  if ($needsCopy) {
    Copy-Item -LiteralPath $skinSource -Destination $skinTarget -Recurse -Force
  }

  return $skinTarget
}

function Set-RainmeterConfig {
  param(
    [string]$SkinRoot,
    [int]$WindowX,
    [int]$WindowY
  )

  $configDir = Join-Path $env:APPDATA "Rainmeter"
  $configPath = Join-Path $configDir "Rainmeter.ini"
  New-Item -ItemType Directory -Force -Path $configDir | Out-Null

  if (Test-Path -LiteralPath $configPath) {
    $content = Get-Content -LiteralPath $configPath -Raw
  } else {
    $content = "[Rainmeter]`r`n"
  }

  if ($content -notmatch "(?m)^\[Rainmeter\]") {
    $content = "[Rainmeter]`r`n" + $content
  }

  if ($content -match "(?m)^SkinPath=") {
    $content = $content -replace "(?m)^SkinPath=.*$", "SkinPath=$SkinRoot\"
  } else {
    $content = $content -replace "(?m)^\[Rainmeter\]\s*", "[Rainmeter]`r`nSkinPath=$SkinRoot\`r`n"
  }

  foreach ($section in "Clock", "Disk", "System", "Welcome") {
    $pattern = "(?ms)\[illustro\\$section\](.*?)(?=\r?\n\[|\z)"
    if ($content -match $pattern) {
      $content = $content -replace $pattern, "[illustro\$section]`r`nActive=0`r`n"
    }
  }

  $overlay = @"
[WorldTimeOverlay]
Active=1
WindowX=$WindowX
WindowY=$WindowY
ClickThrough=1
Draggable=0
SnapEdges=1
KeepOnScreen=1
AlwaysOnTop=-2
"@

  if ($content -match "(?m)^\[WorldTimeOverlay\]") {
    $content = $content -replace "(?ms)\[WorldTimeOverlay\](.*?)(?=\r?\n\[|\z)", $overlay
  } else {
    $content = $content.TrimEnd() + "`r`n`r`n" + $overlay + "`r`n"
  }

  Set-Content -LiteralPath $configPath -Value $content -Encoding Unicode
  return $configPath
}

function Ensure-StartupShortcut {
  param(
    [string]$ScriptPath,
    [string]$WatcherPath
  )

  $startup = [Environment]::GetFolderPath("Startup")
  New-Item -ItemType Directory -Force -Path $startup | Out-Null
  $linkPath = Join-Path $startup "World Time Overlay.lnk"
  $powershell = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
  $startupScript = $ScriptPath
  $startupArgs = "-InstallRainmeter -Quiet"
  if ($WatcherPath -and (Test-Path -LiteralPath $WatcherPath)) {
    $startupScript = $WatcherPath
    $startupArgs = "-Quiet"
  }

  $shell = New-Object -ComObject WScript.Shell
  $shortcut = $shell.CreateShortcut($linkPath)
  $shortcut.TargetPath = $powershell
  $shortcut.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$startupScript`" $startupArgs"
  $shortcut.WorkingDirectory = Split-Path -Parent $startupScript
  $shortcut.IconLocation = "$powershell,0"
  $shortcut.Save()

  return $linkPath
}

function Ensure-ScheduledTask {
  param([string]$ScriptPath)

  $powershell = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
  $taskName = "WorldTimeOverlaySelfHeal"
  $taskArgs = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`" -InstallRainmeter -Quiet"

  try {
    Import-Module ScheduledTasks -ErrorAction Stop
    $action = New-ScheduledTaskAction -Execute $powershell -Argument $taskArgs
    $logonTrigger = New-ScheduledTaskTrigger -AtLogOn
    $repeatTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration (New-TimeSpan -Days 3650)
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable -MultipleInstances IgnoreNew

    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger @($logonTrigger, $repeatTrigger) -Settings $settings -Description "Keeps the WorldTimeOverlay Rainmeter skin installed, running, and positioned." -Force | Out-Null
    return $taskName
  } catch {
    Write-Status "Scheduled task was not created: $($_.Exception.Message)"
    return $null
  }
}

function Start-And-LoadOverlay {
  param(
    [string]$Rainmeter,
    [int]$WindowX,
    [int]$WindowY
  )

  if (-not (Get-Process Rainmeter -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath $Rainmeter -WindowStyle Hidden
    Start-Sleep -Seconds 2
  }

  & $Rainmeter !RefreshApp
  Start-Sleep -Milliseconds 500
  & $Rainmeter !ActivateConfig "WorldTimeOverlay" "WorldTimeOverlay.ini"
  Start-Sleep -Milliseconds 500
  & $Rainmeter !Move $WindowX $WindowY "WorldTimeOverlay" "WorldTimeOverlay.ini"
  & $Rainmeter !ZPos -2 "WorldTimeOverlay" "WorldTimeOverlay.ini"
  & $Rainmeter !Draggable 0 "WorldTimeOverlay" "WorldTimeOverlay.ini"
  & $Rainmeter !ClickThrough 1 "WorldTimeOverlay" "WorldTimeOverlay.ini"
  & $Rainmeter !KeepOnScreen 1 "WorldTimeOverlay" "WorldTimeOverlay.ini"
}

function Start-Watcher {
  param([string]$WatcherPath)

  if (-not ($WatcherPath -and (Test-Path -LiteralPath $WatcherPath))) {
    return $false
  }

  $powershell = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
  $args = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$WatcherPath`" -Quiet"
  Start-Process -FilePath $powershell -ArgumentList $args -WindowStyle Hidden
  return $true
}

$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptPath
$watcherPath = Join-Path $scriptDir "watch_world_time_overlay.ps1"
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptPath)
$documents = Get-DocumentsPath
$skinRoot = Join-Path $documents "Rainmeter\Skins"
$position = Get-OverlayPosition

$rainmeter = Find-Rainmeter
if (-not $rainmeter -and $InstallRainmeter) {
  Install-RainmeterWithWinget
  Start-Sleep -Seconds 2
  $rainmeter = Find-Rainmeter
}
if (-not $rainmeter) {
  throw "Rainmeter is not installed. Run scripts\install_rainmeter_overlay.ps1 or install Rainmeter manually."
}

$skinTarget = Install-OverlaySkin -RepoRoot $repoRoot -SkinRoot $skinRoot
$configPath = Set-RainmeterConfig -SkinRoot $skinRoot -WindowX $position.X -WindowY $position.Y

if ($CreateStartup) {
  $startupShortcut = Ensure-StartupShortcut -ScriptPath $scriptPath -WatcherPath $watcherPath
  Write-Status "Startup shortcut: $startupShortcut"
}

if ($CreateScheduledTask) {
  $taskName = Ensure-ScheduledTask -ScriptPath $scriptPath
  if ($taskName) {
    Write-Status "Scheduled self-heal task: $taskName"
  }
}

Start-And-LoadOverlay -Rainmeter $rainmeter -WindowX $position.X -WindowY $position.Y

if ($CreateStartup -and (Start-Watcher -WatcherPath $watcherPath)) {
  Write-Status "Self-heal watcher started."
}

Write-Status "Rainmeter: $rainmeter"
Write-Status "Skin installed: $skinTarget"
Write-Status "Config updated: $configPath"
Write-Status "Overlay position: X=$($position.X), Y=$($position.Y)"
