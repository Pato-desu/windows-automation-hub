<#
.SYNOPSIS
    Registers the OBS Studio Wake Handler task in Windows Task Scheduler.
.DESCRIPTION
    Triggers automatically whenever Windows wakes up from sleep or hibernation
    (System Event ID 1 from Power-Troubleshooter).
#>

param (
    [string]$TaskName = "OBS_Restore_On_Wake"
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ObsWakeScript = Join-Path $ScriptDir "tasks\obs_wake_handler.py"

# Locate python executable
$PythonExe = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $PythonExe) {
    $PythonExe = "python.exe"
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " OBS Studio Wake Handler - Task Scheduler Setup" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Task Name:   $TaskName"
Write-Host "Script:      $ObsWakeScript"
Write-Host "Python Exe:  $PythonExe"
Write-Host "Trigger:     System Wake (Event ID 1, Power-Troubleshooter)"
Write-Host "----------------------------------------------------------"

# Use schtasks to create event-triggered task cleanly
$ActionCmd = "`"$PythonExe`" `"$ObsWakeScript`""

$SchtasksCmd = "schtasks /Create /TN `"$TaskName`" /TR `"$ActionCmd`" /SC ONEVENT /EC System /MO `"*`[System`[Provider`[`@Name='Microsoft-Windows-Power-Troubleshooter'`] and (EventID=1)`]`]`" /F"

Invoke-Expression $SchtasksCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[SUCCESS] Scheduled Task '$TaskName' registered successfully!" -ForegroundColor Green
    Write-Host "OBS will now be restored and maximized automatically whenever your PC wakes from sleep." -ForegroundColor Yellow
} else {
    Write-Host "`n[ERROR] Failed to register task with exit code $LASTEXITCODE" -ForegroundColor Red
}
