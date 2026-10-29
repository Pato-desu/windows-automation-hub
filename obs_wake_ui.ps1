<#
.SYNOPSIS
    OBS Wake Handler - Control Panel GUI
.DESCRIPTION
    A clean UI to check, register, update, test, and manage the OBS Studio
    system wake scheduled task.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ObsWakeScript = Join-Path $ScriptDir "tasks\obs_wake_handler.py"
$TaskName = "OBS_Restore_On_Wake"
$LogPath = Join-Path $ScriptDir "logs\automation.log"

# Locate python executable
$PythonExe = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $PythonExe) {
    $PythonExe = "python.exe"
}

# --- Main Form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "OBS Studio Wake Handler - Control Panel"
$form.Size = New-Object System.Drawing.Size(440, 510)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 246, 248)

$fontTitle   = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$fontSection = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$fontRegular = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Regular)
$fontBold    = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$fontSmall   = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Regular)

# --- Title Header ---
$lblHeader = New-Object System.Windows.Forms.Label
$lblHeader.Text = "OBS Wake Handler"
$lblHeader.Font = $fontTitle
$lblHeader.ForeColor = [System.Drawing.Color]::FromArgb(30, 41, 59)
$lblHeader.Location = New-Object System.Drawing.Point(20, 15)
$lblHeader.Size = New-Object System.Drawing.Size(380, 28)
$form.Controls.Add($lblHeader)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "Restores and maximizes OBS when PC wakes from sleep."
$lblSub.Font = $fontRegular
$lblSub.ForeColor = [System.Drawing.Color]::FromArgb(100, 116, 139)
$lblSub.Location = New-Object System.Drawing.Point(20, 43)
$lblSub.Size = New-Object System.Drawing.Size(380, 20)
$form.Controls.Add($lblSub)

# --- Status Box ---
$groupStatus = New-Object System.Windows.Forms.GroupBox
$groupStatus.Text = "Task Scheduler Status"
$groupStatus.Font = $fontSection
$groupStatus.Location = New-Object System.Drawing.Point(20, 68)
$groupStatus.Size = New-Object System.Drawing.Size(380, 125)
$form.Controls.Add($groupStatus)

$lblTaskStatus = New-Object System.Windows.Forms.Label
$lblTaskStatus.Text = "Task: Checking..."
$lblTaskStatus.Font = $fontBold
$lblTaskStatus.Location = New-Object System.Drawing.Point(15, 22)
$lblTaskStatus.Size = New-Object System.Drawing.Size(350, 22)
$groupStatus.Controls.Add($lblTaskStatus)

$lblPathStatus = New-Object System.Windows.Forms.Label
$lblPathStatus.Text = "Target Script: Checking..."
$lblPathStatus.Font = $fontSmall
$lblPathStatus.Location = New-Object System.Drawing.Point(15, 48)
$lblPathStatus.Size = New-Object System.Drawing.Size(350, 42)
$groupStatus.Controls.Add($lblPathStatus)

$lblLastRun = New-Object System.Windows.Forms.Label
$lblLastRun.Text = "Last Run: Never"
$lblLastRun.Font = $fontSmall
$lblLastRun.ForeColor = [System.Drawing.Color]::FromArgb(100, 116, 139)
$lblLastRun.Location = New-Object System.Drawing.Point(15, 94)
$lblLastRun.Size = New-Object System.Drawing.Size(350, 20)
$groupStatus.Controls.Add($lblLastRun)

# --- Status Check Function ---
function Refresh-TaskStatus {
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($task) {
            $info = Get-ScheduledTaskInfo $task -ErrorAction SilentlyContinue
            if ($info -and $info.LastRunTime -and $info.LastRunTime.Year -gt 1999) {
                $lblLastRun.Text = "Last Triggered: $($info.LastRunTime.ToString('yyyy-MM-dd HH:mm:ss'))"
            } else {
                $lblLastRun.Text = "Last Triggered: Never / Not yet recorded"
            }

            $currentArg = ($task.Actions | Select-Object -First 1).Arguments
            if ($currentArg -like "*$ObsWakeScript*") {
                $lblTaskStatus.ForeColor = [System.Drawing.Color]::FromArgb(22, 101, 52)
                $lblTaskStatus.Text = "Status: Registered & Active"
                $lblPathStatus.ForeColor = [System.Drawing.Color]::FromArgb(22, 101, 52)
                $lblPathStatus.Text = "Target: Up to date`n$ObsWakeScript"
                $btnRegister.Text = "Re-register Task"
                $btnRegister.BackColor = [System.Drawing.Color]::FromArgb(241, 245, 249)
                $btnRegister.ForeColor = [System.Drawing.Color]::FromArgb(30, 41, 59)
            } else {
                $lblTaskStatus.ForeColor = [System.Drawing.Color]::FromArgb(217, 119, 6)
                $lblTaskStatus.Text = "Status: Outdated Path Detected"
                $lblPathStatus.ForeColor = [System.Drawing.Color]::FromArgb(180, 83, 9)
                $lblPathStatus.Text = "Warning: Points to old path:`n$currentArg"
                $btnRegister.Text = "Fix / Update Task Path Now"
                $btnRegister.BackColor = [System.Drawing.Color]::FromArgb(217, 119, 6)
                $btnRegister.ForeColor = [System.Drawing.Color]::White
            }
            $btnUnregister.Enabled = $true
        } else {
            $lblTaskStatus.ForeColor = [System.Drawing.Color]::FromArgb(100, 116, 139)
            $lblTaskStatus.Text = "Status: Not Registered"
            $lblPathStatus.ForeColor = [System.Drawing.Color]::FromArgb(100, 116, 139)
            $lblPathStatus.Text = "Task is not registered in Windows Task Scheduler."
            $lblLastRun.Text = "Last Triggered: -"
            $btnRegister.Text = "Register Scheduled Task"
            $btnRegister.BackColor = [System.Drawing.Color]::FromArgb(37, 99, 235)
            $btnRegister.ForeColor = [System.Drawing.Color]::White
            $btnUnregister.Enabled = $false
        }
    } catch {
        $lblTaskStatus.Text = "Status: Error checking task: $_"
    }
}

# --- Action Controls ---
$btnRegister = New-Object System.Windows.Forms.Button
$btnRegister.Text = "Register / Update Scheduled Task"
$btnRegister.Font = $fontBold
$btnRegister.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnRegister.Location = New-Object System.Drawing.Point(20, 203)
$btnRegister.Size = New-Object System.Drawing.Size(380, 38)
$form.Controls.Add($btnRegister)

$btnTestRun = New-Object System.Windows.Forms.Button
$btnTestRun.Text = "Test OBS Wake Now (Restore & Maximize)"
$btnTestRun.Font = $fontRegular
$btnTestRun.BackColor = [System.Drawing.Color]::FromArgb(241, 245, 249)
$btnTestRun.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnTestRun.Location = New-Object System.Drawing.Point(20, 249)
$btnTestRun.Size = New-Object System.Drawing.Size(380, 34)
$form.Controls.Add($btnTestRun)

$btnUnregister = New-Object System.Windows.Forms.Button
$btnUnregister.Text = "Remove Task from Task Scheduler"
$btnUnregister.Font = $fontRegular
$btnUnregister.BackColor = [System.Drawing.Color]::FromArgb(241, 245, 249)
$btnUnregister.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnUnregister.Location = New-Object System.Drawing.Point(20, 291)
$btnUnregister.Size = New-Object System.Drawing.Size(380, 34)
$form.Controls.Add($btnUnregister)

# --- Information Group ---
$groupInfo = New-Object System.Windows.Forms.GroupBox
$groupInfo.Text = "How It Works"
$groupInfo.Font = $fontSection
$groupInfo.Location = New-Object System.Drawing.Point(20, 335)
$groupInfo.Size = New-Object System.Drawing.Size(380, 115)
$form.Controls.Add($groupInfo)

$lblInfo1 = New-Object System.Windows.Forms.Label
$lblInfo1.Text = "- Trigger: Event ID 1 (Power-Troubleshooter)"
$lblInfo1.Font = $fontRegular
$lblInfo1.Location = New-Object System.Drawing.Point(15, 22)
$lblInfo1.Size = New-Object System.Drawing.Size(350, 18)
$groupInfo.Controls.Add($lblInfo1)

$lblInfo2 = New-Object System.Windows.Forms.Label
$lblInfo2.Text = "- Restores & maximizes OBS to refresh GPU hooks"
$lblInfo2.Font = $fontRegular
$lblInfo2.Location = New-Object System.Drawing.Point(15, 43)
$lblInfo2.Size = New-Object System.Drawing.Size(350, 18)
$groupInfo.Controls.Add($lblInfo2)

$lblInfo3 = New-Object System.Windows.Forms.Label
$lblInfo3.Text = "- Starts OBS with replay buffer if not currently open"
$lblInfo3.Font = $fontRegular
$lblInfo3.Location = New-Object System.Drawing.Point(15, 64)
$lblInfo3.Size = New-Object System.Drawing.Size(350, 18)
$groupInfo.Controls.Add($lblInfo3)

$lblInfo4 = New-Object System.Windows.Forms.Label
$lblInfo4.Text = "- Runs only on wake; takes 0% CPU while PC is in use"
$lblInfo4.Font = $fontRegular
$lblInfo4.Location = New-Object System.Drawing.Point(15, 85)
$lblInfo4.Size = New-Object System.Drawing.Size(350, 18)
$groupInfo.Controls.Add($lblInfo4)

# --- Button Handlers ---
$btnRegister.Add_Click({
    $ActionCmd = "`"$PythonExe`" `"$ObsWakeScript`""
    $SchtasksCmd = "schtasks /Create /TN `"$TaskName`" /TR `"$ActionCmd`" /SC ONEVENT /EC System /MO `"*`[System`[Provider`[`@Name='Microsoft-Windows-Power-Troubleshooter'`] and (EventID=1)`]`]`" /F"
    
    $res = Invoke-Expression $SchtasksCmd
    if ($LASTEXITCODE -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Task '$TaskName' registered successfully with the current path!`n`nOBS will now be restored whenever your PC wakes from sleep.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        [System.Windows.Forms.MessageBox]::Show("Failed to register task. Try running as Administrator.`nError: $res", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
    Refresh-TaskStatus
})

$btnUnregister.Add_Click({
    $confirm = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to remove '$TaskName' from Windows Task Scheduler?", "Confirm", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($confirm -eq [System.Windows.Forms.DialogResult]::Yes) {
        & schtasks /Delete /TN $TaskName /F
        Refresh-TaskStatus
        [System.Windows.Forms.MessageBox]::Show("Task removed from Windows Task Scheduler.", "Removed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

$btnTestRun.Add_Click({
    if (Test-Path $ObsWakeScript) {
        $p = Start-Process -FilePath $PythonExe -ArgumentList "`"$ObsWakeScript`"" -WorkingDirectory $ScriptDir -WindowStyle Hidden -PassThru
        [System.Windows.Forms.MessageBox]::Show("Executed OBS Wake script!`nCheck if OBS Studio was restored/maximized.", "Test Execution Sent", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        [System.Windows.Forms.MessageBox]::Show("Could not find script at: $ObsWakeScript", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
    Refresh-TaskStatus
})

# Initial status
Refresh-TaskStatus

# Show Form
[void]$form.ShowDialog()
