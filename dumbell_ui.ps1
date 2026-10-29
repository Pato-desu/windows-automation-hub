<#
.SYNOPSIS
    Dumbbell Reminder - Control Panel GUI
.DESCRIPTION
    A clean UI to start, stop, test, configure, and manage Windows Startup
    for the Dumbbell Reminder (Stremio / YouTube monitor).
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$DumbellScript = Join-Path $ScriptDir "dumbell_reminder.pyw"
$PidFile = Join-Path $ScriptDir ".dumbell_pid"
$StartupFolder = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
$StartupShortcut = Join-Path $StartupFolder "Dumbbell Reminder.lnk"

# Locate pythonw.exe
$PythonwExe = (Get-Command pythonw -ErrorAction SilentlyContinue).Source
if (-not $PythonwExe) {
    # Try finding in common paths or fallback to python
    $PythonExe = (Get-Command python -ErrorAction SilentlyContinue).Source
    if ($PythonExe) {
        $candidate = Join-Path (Split-Path $PythonExe) "pythonw.exe"
        if (Test-Path $candidate) { $PythonwExe = $candidate } else { $PythonwExe = $PythonExe }
    } else {
        $PythonwExe = "pythonw.exe"
    }
}

# --- Main Form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Dumbbell Reminder - Control Panel"
$form.Size = New-Object System.Drawing.Size(430, 480)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 246, 248)

$fontTitle   = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$fontSection = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$fontRegular = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Regular)
$fontBold    = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)

# --- Title Header ---
$lblHeader = New-Object System.Windows.Forms.Label
$lblHeader.Text = "Dumbbell Reminder"
$lblHeader.Font = $fontTitle
$lblHeader.ForeColor = [System.Drawing.Color]::FromArgb(30, 41, 59)
$lblHeader.Location = New-Object System.Drawing.Point(20, 15)
$lblHeader.Size = New-Object System.Drawing.Size(370, 28)
$form.Controls.Add($lblHeader)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "Monitors YouTube/Stremio watchtime and nudges to workout."
$lblSub.Font = $fontRegular
$lblSub.ForeColor = [System.Drawing.Color]::FromArgb(100, 116, 139)
$lblSub.Location = New-Object System.Drawing.Point(20, 43)
$lblSub.Size = New-Object System.Drawing.Size(370, 20)
$form.Controls.Add($lblSub)

# --- Status Box ---
$groupStatus = New-Object System.Windows.Forms.GroupBox
$groupStatus.Text = "Status"
$groupStatus.Font = $fontSection
$groupStatus.Location = New-Object System.Drawing.Point(20, 70)
$groupStatus.Size = New-Object System.Drawing.Size(370, 95)
$form.Controls.Add($groupStatus)

$lblProcessStatus = New-Object System.Windows.Forms.Label
$lblProcessStatus.Text = "Process: Checking..."
$lblProcessStatus.Font = $fontBold
$lblProcessStatus.Location = New-Object System.Drawing.Point(15, 25)
$lblProcessStatus.Size = New-Object System.Drawing.Size(340, 25)
$groupStatus.Controls.Add($lblProcessStatus)

$lblStartupStatus = New-Object System.Windows.Forms.Label
$lblStartupStatus.Text = "Startup: Checking..."
$lblStartupStatus.Font = $fontRegular
$lblStartupStatus.Location = New-Object System.Drawing.Point(15, 55)
$lblStartupStatus.Size = New-Object System.Drawing.Size(340, 25)
$groupStatus.Controls.Add($lblStartupStatus)

# --- Helper Functions ---
function Get-RunningProcessId {
    if (Test-Path $PidFile) {
        $savedPid = Get-Content $PidFile -ErrorAction SilentlyContinue
        if ($savedPid) {
            $p = Get-Process -Id $savedPid -ErrorAction SilentlyContinue
            if ($p -and $p.ProcessName -match "python") {
                return $p.Id
            }
        }
    }
    # Fallback to WMI/CIM if available
    try {
        $proc = Get-CimInstance Win32_Process -Filter "Name like 'python%'" -ErrorAction Stop |
            Where-Object { $_.CommandLine -like "*dumbell_reminder*" } |
            Select-Object -First 1
        if ($proc) {
            $proc.ProcessId | Set-Content $PidFile
            return $proc.ProcessId
        }
    } catch {}
    return $null
}

function Refresh-StatusDisplay {
    $runningPid = Get-RunningProcessId
    if ($runningPid) {
        $lblProcessStatus.ForeColor = [System.Drawing.Color]::FromArgb(22, 101, 52)
        $lblProcessStatus.Text = "Monitor: Running (PID: $runningPid)"
        $btnToggleRun.Text = "Stop Monitor"
        $btnToggleRun.BackColor = [System.Drawing.Color]::FromArgb(239, 68, 68)
        $btnToggleRun.ForeColor = [System.Drawing.Color]::White
    } else {
        $lblProcessStatus.ForeColor = [System.Drawing.Color]::FromArgb(100, 116, 139)
        $lblProcessStatus.Text = "Monitor: Stopped"
        $btnToggleRun.Text = "Start Monitor in Background"
        $btnToggleRun.BackColor = [System.Drawing.Color]::FromArgb(37, 99, 235)
        $btnToggleRun.ForeColor = [System.Drawing.Color]::White
    }

    if (Test-Path $StartupShortcut) {
        $lblStartupStatus.ForeColor = [System.Drawing.Color]::FromArgb(22, 101, 52)
        $lblStartupStatus.Text = "Startup: Enabled (runs on Windows boot)"
        $btnToggleStartup.Text = "Disable from Windows Startup"
    } else {
        $lblStartupStatus.ForeColor = [System.Drawing.Color]::FromArgb(100, 116, 139)
        $lblStartupStatus.Text = "Startup: Disabled"
        $btnToggleStartup.Text = "Enable on Windows Startup"
    }
}

# --- Action Controls ---
$btnToggleRun = New-Object System.Windows.Forms.Button
$btnToggleRun.Text = "Start Monitor in Background"
$btnToggleRun.Font = $fontBold
$btnToggleRun.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnToggleRun.Location = New-Object System.Drawing.Point(20, 175)
$btnToggleRun.Size = New-Object System.Drawing.Size(370, 40)
$form.Controls.Add($btnToggleRun)

$btnToggleStartup = New-Object System.Windows.Forms.Button
$btnToggleStartup.Text = "Enable on Windows Startup"
$btnToggleStartup.Font = $fontRegular
$btnToggleStartup.BackColor = [System.Drawing.Color]::FromArgb(241, 245, 249)
$btnToggleStartup.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnToggleStartup.Location = New-Object System.Drawing.Point(20, 223)
$btnToggleStartup.Size = New-Object System.Drawing.Size(370, 34)
$form.Controls.Add($btnToggleStartup)

$btnTestPopup = New-Object System.Windows.Forms.Button
$btnTestPopup.Text = "Test Popup Now (Preview Alert)"
$btnTestPopup.Font = $fontRegular
$btnTestPopup.BackColor = [System.Drawing.Color]::FromArgb(241, 245, 249)
$btnTestPopup.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnTestPopup.Location = New-Object System.Drawing.Point(20, 265)
$btnTestPopup.Size = New-Object System.Drawing.Size(370, 34)
$form.Controls.Add($btnTestPopup)

# --- Info / Configuration Overview ---
$groupConfig = New-Object System.Windows.Forms.GroupBox
$groupConfig.Text = "Active Rules"
$groupConfig.Font = $fontSection
$groupConfig.Location = New-Object System.Drawing.Point(20, 310)
$groupConfig.Size = New-Object System.Drawing.Size(370, 115)
$form.Controls.Add($groupConfig)

$lblRule1 = New-Object System.Windows.Forms.Label
$lblRule1.Text = "- Triggers when: Active window has 'YouTube' or 'Stremio'"
$lblRule1.Font = $fontRegular
$lblRule1.Location = New-Object System.Drawing.Point(15, 25)
$lblRule1.Size = New-Object System.Drawing.Size(340, 20)
$groupConfig.Controls.Add($lblRule1)

$lblRule2 = New-Object System.Windows.Forms.Label
$lblRule2.Text = "- Watch Threshold: 10 minutes (600s)"
$lblRule2.Font = $fontRegular
$lblRule2.Location = New-Object System.Drawing.Point(15, 48)
$lblRule2.Size = New-Object System.Drawing.Size(340, 20)
$groupConfig.Controls.Add($lblRule2)

$lblRule3 = New-Object System.Windows.Forms.Label
$lblRule3.Text = "- Alert Message: 'Mancuernas o para de mirar weas'"
$lblRule3.Font = $fontRegular
$lblRule3.Location = New-Object System.Drawing.Point(15, 71)
$lblRule3.Size = New-Object System.Drawing.Size(340, 20)
$groupConfig.Controls.Add($lblRule3)

$lblRule4 = New-Object System.Windows.Forms.Label
$lblRule4.Text = "- Cooldown after alert: 20 minutes (1200s)"
$lblRule4.Font = $fontRegular
$lblRule4.Location = New-Object System.Drawing.Point(15, 92)
$lblRule4.Size = New-Object System.Drawing.Size(340, 20)
$groupConfig.Controls.Add($lblRule4)

# --- Button Handlers ---
$btnToggleRun.Add_Click({
    $runningPid = Get-RunningProcessId
    if ($runningPid) {
        # Stop it
        try {
            Stop-Process -Id $runningPid -Force -ErrorAction Stop
            Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
            [System.Windows.Forms.MessageBox]::Show("Dumbbell Reminder stopped.", "Monitor Stopped", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to stop process: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    } else {
        # Start it
        try {
            $p = Start-Process -FilePath $PythonwExe -ArgumentList "`"$DumbellScript`"" -WorkingDirectory $ScriptDir -PassThru
            if ($p) {
                $p.Id | Set-Content $PidFile
                [System.Windows.Forms.MessageBox]::Show("Dumbbell Reminder is now running silently in the background!", "Monitor Started", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to start monitor: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    Refresh-StatusDisplay
})

$btnToggleStartup.Add_Click({
    if (Test-Path $StartupShortcut) {
        Remove-Item $StartupShortcut -Force
        [System.Windows.Forms.MessageBox]::Show("Removed Dumbbell Reminder from Windows Startup.", "Startup Updated", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        try {
            $WshShell = New-Object -ComObject WScript.Shell
            $Shortcut = $WshShell.CreateShortcut($StartupShortcut)
            $Shortcut.TargetPath = $PythonwExe
            $Shortcut.Arguments = "`"$DumbellScript`""
            $Shortcut.WorkingDirectory = $ScriptDir
            $Shortcut.Description = "Dumbbell Reminder Background Monitor"
            $Shortcut.Save()
            [System.Windows.Forms.MessageBox]::Show("Dumbbell Reminder added to Windows Startup!`nIt will launch automatically whenever you log in.", "Startup Enabled", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Failed to add to startup: $_", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    Refresh-StatusDisplay
})

$btnTestPopup.Add_Click({
    # Test message directly
    [System.Windows.Forms.MessageBox]::Show("Mancuernas o para de mirar weas", "Watchtime heat is high", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
})

# Initial refresh
Refresh-StatusDisplay

# Form display
[void]$form.ShowDialog()
