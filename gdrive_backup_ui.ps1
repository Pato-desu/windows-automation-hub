<#
.SYNOPSIS
    Google Drive Backup - Control Panel GUI
.DESCRIPTION
    Start/stop the rclone Google Drive backup, run a safe dry run, see last result
    and live progress, open the backup/archive/log, and manage an optional nightly task.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $ScriptDir "gdrive_backup_common.ps1")
$RunnerScript = Join-Path $ScriptDir "gdrive_backup.ps1"
$cfg = Get-BackupConfig

$fontTitle   = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$fontSection = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$fontRegular = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Regular)
$fontBold    = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$fontSmall   = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Regular)
$cGreen = [System.Drawing.Color]::FromArgb(22, 101, 52)
$cAmber = [System.Drawing.Color]::FromArgb(180, 83, 9)
$cRed   = [System.Drawing.Color]::FromArgb(185, 28, 28)
$cGrey  = [System.Drawing.Color]::FromArgb(100, 116, 139)
$cBlue  = [System.Drawing.Color]::FromArgb(37, 99, 235)
$cLight = [System.Drawing.Color]::FromArgb(241, 245, 249)
$cDark  = [System.Drawing.Color]::FromArgb(30, 41, 59)

$form = New-Object System.Windows.Forms.Form
$form.Text = "Google Drive Backup - Control Panel"
$form.Size = New-Object System.Drawing.Size(440, 560)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 246, 248)

function New-Label($text, $font, $color, $x, $y, $w, $h) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text; $l.Font = $font; $l.ForeColor = $color
    $l.Location = New-Object System.Drawing.Point($x, $y)
    $l.Size = New-Object System.Drawing.Size($w, $h)
    return $l
}
function New-Button($text, $x, $y, $w, $h, $primary) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $b.Location = New-Object System.Drawing.Point($x, $y)
    $b.Size = New-Object System.Drawing.Size($w, $h)
    if ($primary) { $b.Font = $fontBold; $b.BackColor = $cBlue; $b.ForeColor = [System.Drawing.Color]::White }
    else { $b.Font = $fontRegular; $b.BackColor = $cLight; $b.ForeColor = $cDark }
    return $b
}

$form.Controls.Add((New-Label "Google Drive Backup" $fontTitle $cDark 20 15 380 28))
$form.Controls.Add((New-Label "Mirrors Google Drive to your backup folder. Deleted or replaced files are kept in a dated archive." $fontSmall $cGrey 20 43 390 32))

# --- Status ---
$grp = New-Object System.Windows.Forms.GroupBox
$grp.Text = "Status"; $grp.Font = $fontSection
$grp.Location = New-Object System.Drawing.Point(20, 80)
$grp.Size = New-Object System.Drawing.Size(380, 165)
$form.Controls.Add($grp)

$lblState  = New-Label "State: ..." $fontBold $cDark 15 22 350 22
$lblResult = New-Label "" $fontSmall $cGrey 15 46 350 34
$lblDrive  = New-Label "" $fontSmall $cGrey 15 82 350 18
$lblSched  = New-Label "" $fontSmall $cGrey 15 102 350 18
$lblProg   = New-Label "" $fontSmall $cGrey 15 122 350 36
foreach ($c in @($lblState, $lblResult, $lblDrive, $lblSched, $lblProg)) { $grp.Controls.Add($c) }

# --- Actions ---
$btnStart = New-Button "Start Backup" 20 255 380 38 $true
$btnDry   = New-Button "Dry Run (preview only, changes nothing)" 20 299 380 34 $false
$btnStop  = New-Button "Stop Running Backup" 20 339 380 34 $false
$btnBackup  = New-Button "Backup Folder" 20 383 122 32 $false
$btnArchive = New-Button "Archive Folder" 149 383 122 32 $false
$btnLog     = New-Button "Last Log" 278 383 122 32 $false
$btnSched   = New-Button "Schedule Nightly (02:00)" 20 425 380 34 $false
foreach ($b in @($btnStart, $btnDry, $btnStop, $btnBackup, $btnArchive, $btnLog, $btnSched)) { $form.Controls.Add($b) }
$form.Controls.Add((New-Label "Archive folders older than $($cfg.KeepDays) days are removed after each successful run." $fontSmall $cGrey 20 470 390 20))

function Start-Runner([bool]$dry) {
    if (Get-RunnerPid) { return }
    $argList = "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$RunnerScript`""
    if ($dry) { $argList += " -DryRun" }
    Start-Process powershell.exe -ArgumentList $argList -WorkingDirectory $ScriptDir -WindowStyle Hidden
    Start-Sleep -Milliseconds 800
    Refresh-Status
}

function Refresh-Status {
    $runnerPid = Get-RunnerPid
    $st = Get-BackupStatus

    if ($runnerPid) {
        $lblState.Text = "State: Running (PID $runnerPid)"; $lblState.ForeColor = $cBlue
        $lblResult.Text = "Started: $(if ($st) { $st.started } else { '-' })"
    } elseif ($st -and $st.state -eq "running") {
        $lblState.Text = "State: Interrupted"; $lblState.ForeColor = $cAmber
        $lblResult.Text = "The last run did not finish (stopped or PC restarted)."
    } elseif ($st) {
        $map = @{ success = @("Idle - last run OK", $cGreen); warning = @("Idle - last run OK with warnings", $cAmber)
                  failed = @("Idle - last run FAILED", $cRed); skipped = @("Idle - last run skipped", $cAmber) }
        $m = $map[[string]$st.state]
        if (-not $m) { $m = @("Idle", $cGrey) }
        $lblState.Text = "State: $($m[0])"; $lblState.ForeColor = $m[1]
        $lblResult.Text = "$($st.mode) finished $($st.ended)`n$($st.message)"
    } else {
        $lblState.Text = "State: Idle - never run"; $lblState.ForeColor = $cGrey
        $lblResult.Text = "No previous run recorded."
    }

    $root = [System.IO.Path]::GetPathRoot($cfg.Dest)
    if (Test-Path $root) { $lblDrive.Text = "Drive $root available"; $lblDrive.ForeColor = $cGreen }
    else { $lblDrive.Text = "Drive $root NOT available"; $lblDrive.ForeColor = $cRed }

    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($task) { $lblSched.Text = "Nightly task: registered"; $btnSched.Text = "Remove Nightly Schedule" }
    else { $lblSched.Text = "Nightly task: not scheduled (manual only)"; $btnSched.Text = "Schedule Nightly (02:00)" }

    if ($runnerPid -and (Test-Path $LogPath)) {
        $line = Get-Content $LogPath -Tail 40 -ErrorAction SilentlyContinue | Where-Object { $_ -match 'Transferred:|Checks:' } | Select-Object -Last 2
        $lblProg.Text = ($line -join "`n")
    } else { $lblProg.Text = "" }

    $running = [bool]$runnerPid
    $btnStart.Enabled = -not $running
    $btnDry.Enabled   = -not $running
    $btnStop.Enabled  = $running
    $btnStart.BackColor = if ($running) { $cLight } else { $cBlue }
    $btnStart.ForeColor = if ($running) { $cGrey } else { [System.Drawing.Color]::White }
}

$btnStart.Add_Click({
    if (-not $cfg.RcloneExe) { [System.Windows.Forms.MessageBox]::Show("rclone.exe not found in the hub folder.", "Google Drive Backup") | Out-Null; return }
    Start-Runner $false
})
$btnDry.Add_Click({ Start-Runner $true })
$btnStop.Add_Click({
    $id = Get-RunnerPid
    if ($id) {
        $r = [System.Windows.Forms.MessageBox]::Show("Stop the running backup? It can resume next time.", "Google Drive Backup", "YesNo", "Question")
        if ($r -eq "Yes") {
            & taskkill.exe /PID $id /T /F | Out-Null
            Remove-Item $LockPath -Force -ErrorAction SilentlyContinue
            Refresh-Status
        }
    }
})
function Open-Path($p) {
    if (Test-Path $p) { Start-Process explorer.exe -ArgumentList "`"$p`"" }
    else { [System.Windows.Forms.MessageBox]::Show("Not found yet:`n$p", "Google Drive Backup") | Out-Null }
}
$btnBackup.Add_Click({ Open-Path $cfg.Dest })
$btnArchive.Add_Click({ Open-Path $cfg.ArchiveRoot })
$btnLog.Add_Click({ if (Test-Path $LogPath) { Start-Process notepad.exe -ArgumentList "`"$LogPath`"" } else { Open-Path $LogPath } })

$btnSched.Add_Click({
    try {
        if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        } else {
            $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$RunnerScript`"" -WorkingDirectory $ScriptDir
            $trigger = New-ScheduledTaskTrigger -Daily -At "02:00"
            $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 12)
            $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
            Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Description "Nightly Google Drive backup via rclone (Windows Automation Hub)" | Out-Null
        }
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Could not change the schedule:`n$_", "Google Drive Backup") | Out-Null
    }
    Refresh-Status
})

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 3000
$timer.Add_Tick({ Refresh-Status })
$timer.Start()

Refresh-Status
[void]$form.ShowDialog()
$timer.Stop()
