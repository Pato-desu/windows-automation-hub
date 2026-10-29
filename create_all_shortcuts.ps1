<#
.SYNOPSIS
    Creates Windows shortcuts for all Automation Hub tools.
.DESCRIPTION
    Creates shortcuts with native Windows icons in:
    1. Your Start Menu Programs folder
    2. Your Desktop
    3. The project root folder
#>

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$WshShell = New-Object -ComObject WScript.Shell

$DesktopPath = [Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
if (-not $DesktopPath -and $env:USERPROFILE) {
    $DesktopPath = Join-Path $env:USERPROFILE "Desktop"
}
$StartMenuProgramsPath = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"

$Tools = @(
    @{
        Name = "Sleep or Shutdown Timer"
        Script = "power_timer.ps1"
        Icon = "$env:SystemRoot\System32\shell32.dll,27" # Power button
        Desc = "Schedule Sleep or Shut Down in minutes"
    },
    @{
        Name = "Dumbbell Reminder Manager"
        Script = "dumbell_ui.ps1"
        Icon = "$env:SystemRoot\System32\shell32.dll,44" # Star / Activity
        Desc = "Start, stop, test and configure Dumbbell Reminder"
    },
    @{
        Name = "OBS Wake Manager"
        Script = "obs_wake_ui.ps1"
        Icon = "$env:SystemRoot\System32\shell32.dll,115" # Display / Video screen
        Desc = "Configure and test OBS Studio wake restoration"
    },
    @{
        Name = "Automation Hub Dashboard"
        Script = "automation_hub_ui.ps1"
        Icon = "$env:SystemRoot\System32\shell32.dll,41" # Gear / Hub
        Desc = "Central control panel for all Windows automations"
    }
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Creating Automation Hub Shortcuts" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

foreach ($tool in $Tools) {
    $targetScript = Join-Path $ScriptDir $tool.Script
    if (-not (Test-Path $targetScript)) {
        Write-Host "[SKIP] Missing script: $($tool.Script)" -ForegroundColor Yellow
        continue
    }

    $destinations = @(
        (Join-Path $ScriptDir "$($tool.Name).lnk")
    )
    if ($DesktopPath) {
        $destinations += (Join-Path $DesktopPath "$($tool.Name).lnk")
    }
    if ($StartMenuProgramsPath) {
        $destinations += (Join-Path $StartMenuProgramsPath "$($tool.Name).lnk")
    }

    foreach ($dest in $destinations) {
        try {
            $shortcut = $WshShell.CreateShortcut($dest)
            $shortcut.TargetPath = "powershell.exe"
            $shortcut.Arguments = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$targetScript`""
            $shortcut.WorkingDirectory = $ScriptDir
            $shortcut.IconLocation = $tool.Icon
            $shortcut.Description = $tool.Desc
            $shortcut.Save()
            Write-Host "[CREATED] $dest" -ForegroundColor Green
        } catch {
            Write-Host "[WARNING] Could not save shortcut at ${dest}: $_" -ForegroundColor Yellow
        }
    }
}

Write-Host "`n----------------------------------------------------------"
Write-Host "All shortcuts created successfully!" -ForegroundColor Cyan
Write-Host "You can right-click any shortcut and select 'Pin to Start'." -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
