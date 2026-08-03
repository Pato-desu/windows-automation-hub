<#
.SYNOPSIS
    Registers the Windows Automation Hub with Windows Task Scheduler.
.DESCRIPTION
    Creates a Scheduled Task in Windows Task Scheduler to run runner.py automatically 
    at user logon or at recurring intervals.
#>

param (
    [string]$TaskName = "WindowsAutomationHub",
    [int]$IntervalMinutes = 15,
    [switch]$RunAtLogon = $true
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RunnerPy  = Join-Path $ScriptDir "runner.py"

# Find python executable path
$PythonExe = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $PythonExe) {
    $PythonExe = "python.exe"
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " Windows Automation Hub - Task Scheduler Registration" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Task Name:    $TaskName"
Write-Host "Script Path:  $RunnerPy"
Write-Host "Python Exe:   $PythonExe"
Write-Host "Interval:     Every $IntervalMinutes minutes"
Write-Host "Run at Logon: $RunAtLogon"
Write-Host "----------------------------------------------------------"

$Action = New-ScheduledTaskAction -Execute $PythonExe -Argument "`"$RunnerPy`"" -WorkingDirectory $ScriptDir

$Triggers = @()
if ($RunAtLogon) {
    $Triggers += New-ScheduledTaskTrigger -AtLogOn
}

# Add recurring interval trigger
$IntervalTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes)
$Triggers += $IntervalTrigger

$Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

try {
    # Unregister existing task if it exists
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue

    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Triggers -Settings $Settings -Description "Automation Hub Runner for Windows background conditional tasks" | Out-Null
    Write-Host "`n[SUCCESS] Scheduled Task '$TaskName' registered successfully!" -ForegroundColor Green
    Write-Host "You can view or edit this task in Windows Task Scheduler (taskschd.msc)." -ForegroundColor Yellow
}
catch {
    Write-Host "`n[ERROR] Failed to register Scheduled Task: $_" -ForegroundColor Red
    Write-Host "Note: Registering scheduled tasks may require running PowerShell as Administrator." -ForegroundColor Yellow
}
