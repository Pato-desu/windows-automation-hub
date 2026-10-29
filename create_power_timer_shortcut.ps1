<#
.SYNOPSIS
    Creates a Windows shortcut for the Sleep / Shutdown Power Timer.
.DESCRIPTION
    Creates 'Sleep or Shutdown Timer.lnk' with a native power icon in:
    1. Your Start Menu Programs folder (so it shows up in Windows Start search and 'All apps')
    2. Your Desktop
    3. The current folder (D:\Projects\windows-automation-hub-main)
    You can then right-click any of these shortcuts to select 'Pin to Start'.
#>

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$PowerTimerScript = Join-Path $ScriptDir "power_timer.ps1"

if (-not (Test-Path $PowerTimerScript)) {
    Write-Host "[ERROR] Could not find power_timer.ps1 in $ScriptDir" -ForegroundColor Red
    exit 1
}

$WshShell = New-Object -ComObject WScript.Shell

# Resolve destinations
$DesktopPath = [Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
if (-not $DesktopPath -and $env:USERPROFILE) {
    $DesktopPath = Join-Path $env:USERPROFILE "Desktop"
}
$StartMenuProgramsPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"

$ShortcutLocations = @()
if ($StartMenuProgramsPath) {
    $ShortcutLocations += (Join-Path $StartMenuProgramsPath "Sleep or Shutdown Timer.lnk")
}
if ($DesktopPath) {
    $ShortcutLocations += (Join-Path $DesktopPath "Sleep or Shutdown Timer.lnk")
}
$ShortcutLocations += (Join-Path $ScriptDir "Sleep or Shutdown Timer.lnk")

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Creating Power Timer Shortcuts" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

foreach ($Path in $ShortcutLocations) {
    try {
        $Shortcut = $WshShell.CreateShortcut($Path)
        $Shortcut.TargetPath = "powershell.exe"
        $Shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PowerTimerScript`""
        $Shortcut.WorkingDirectory = $ScriptDir
        $Shortcut.IconLocation = "$env:SystemRoot\System32\shell32.dll,27" # Native red Power button icon
        $Shortcut.Description = "Schedule PC Sleep or Shut Down in minutes"
        $Shortcut.Save()
        Write-Host "[CREATED] $Path" -ForegroundColor Green
    }
    catch {
        Write-Host "[WARNING] Could not create shortcut at ${Path}: $_" -ForegroundColor Yellow
    }
}

Write-Host "`n----------------------------------------------------------"
Write-Host "Done!" -ForegroundColor Cyan
Write-Host "A shortcut has been created with a Power button icon."
Write-Host "`nTo pin it to your Windows Start menu:" -ForegroundColor Yellow
Write-Host " 1. Search for 'Sleep or Shutdown Timer' in your Windows Start menu, OR"
Write-Host " 2. Right-click the shortcut on your Desktop or in this folder"
Write-Host " 3. Click 'Pin to Start'" -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
