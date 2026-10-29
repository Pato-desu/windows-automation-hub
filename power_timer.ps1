<#
.SYNOPSIS
    PC Sleep and Shutdown Timer GUI
.DESCRIPTION
    A lightweight, clean GUI to schedule sleep or shutdown in X minutes.
    Can be pinned to Windows Start menu via a shortcut.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

# --- Main Form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "PC Power Timer"
$form.Size = New-Object System.Drawing.Size(430, 440)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 246, 248)

$fontTitle     = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
$fontSection   = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$fontRegular   = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Regular)
$fontCountdown = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)

# --- Title Header ---
$lblHeader = New-Object System.Windows.Forms.Label
$lblHeader.Text = "Sleep or Shut Down Timer"
$lblHeader.Font = $fontTitle
$lblHeader.ForeColor = [System.Drawing.Color]::FromArgb(30, 41, 59)
$lblHeader.Location = New-Object System.Drawing.Point(20, 15)
$lblHeader.Size = New-Object System.Drawing.Size(370, 30)
$form.Controls.Add($lblHeader)

# --- Mode Group (Sleep vs Shutdown) ---
$groupMode = New-Object System.Windows.Forms.GroupBox
$groupMode.Text = "Select Action"
$groupMode.Font = $fontSection
$groupMode.Location = New-Object System.Drawing.Point(20, 50)
$groupMode.Size = New-Object System.Drawing.Size(370, 65)
$form.Controls.Add($groupMode)

$rbSleep = New-Object System.Windows.Forms.RadioButton
$rbSleep.Text = "Sleep (Suspend)"
$rbSleep.Font = $fontRegular
$rbSleep.Location = New-Object System.Drawing.Point(25, 25)
$rbSleep.Size = New-Object System.Drawing.Size(150, 25)
$rbSleep.Checked = $true
$groupMode.Controls.Add($rbSleep)

$rbShutdown = New-Object System.Windows.Forms.RadioButton
$rbShutdown.Text = "Shut Down"
$rbShutdown.Font = $fontRegular
$rbShutdown.Location = New-Object System.Drawing.Point(200, 25)
$rbShutdown.Size = New-Object System.Drawing.Size(140, 25)
$groupMode.Controls.Add($rbShutdown)

# --- Minutes Input Panel ---
$lblMinutes = New-Object System.Windows.Forms.Label
$lblMinutes.Text = "Minutes to wait:"
$lblMinutes.Font = $fontSection
$lblMinutes.Location = New-Object System.Drawing.Point(20, 125)
$lblMinutes.Size = New-Object System.Drawing.Size(120, 25)
$form.Controls.Add($lblMinutes)

$numMinutes = New-Object System.Windows.Forms.NumericUpDown
$numMinutes.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$numMinutes.Location = New-Object System.Drawing.Point(145, 122)
$numMinutes.Size = New-Object System.Drawing.Size(90, 28)
$numMinutes.Minimum = 1
$numMinutes.Maximum = 1440
$numMinutes.Value = 30
$form.Controls.Add($numMinutes)

# Preset buttons panel
$panelPresets = New-Object System.Windows.Forms.FlowLayoutPanel
$panelPresets.Location = New-Object System.Drawing.Point(20, 160)
$panelPresets.Size = New-Object System.Drawing.Size(370, 36)
$form.Controls.Add($panelPresets)

$presets = @(15, 30, 45, 60, 90, 120)
foreach ($p in $presets) {
    $btnP = New-Object System.Windows.Forms.Button
    $btnP.Text = "$($p)m"
    $btnP.Font = $fontRegular
    $btnP.Size = New-Object System.Drawing.Size(52, 30)
    $btnP.Margin = New-Object System.Windows.Forms.Padding(0, 0, 8, 0)
    $btnP.Tag = $p
    $btnP.Add_Click({
        $numMinutes.Value = [decimal]$this.Tag
    })
    $panelPresets.Controls.Add($btnP)
}

# --- Status / Countdown Label ---
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Text = "Choose action and minutes, then click Start Timer."
$lblStatus.Font = $fontRegular
$lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(71, 85, 105)
$lblStatus.Location = New-Object System.Drawing.Point(20, 205)
$lblStatus.Size = New-Object System.Drawing.Size(370, 50)
$lblStatus.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$form.Controls.Add($lblStatus)

# --- Action Buttons ---
$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Start Timer"
$btnStart.Font = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
$btnStart.BackColor = [System.Drawing.Color]::FromArgb(37, 99, 235)
$btnStart.ForeColor = [System.Drawing.Color]::White
$btnStart.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnStart.Location = New-Object System.Drawing.Point(20, 265)
$btnStart.Size = New-Object System.Drawing.Size(370, 42)
$form.Controls.Add($btnStart)

$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Cancel Active Timer / Shutdown"
$btnCancel.Font = $fontRegular
$btnCancel.BackColor = [System.Drawing.Color]::FromArgb(226, 232, 240)
$btnCancel.ForeColor = [System.Drawing.Color]::FromArgb(51, 65, 85)
$btnCancel.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnCancel.Location = New-Object System.Drawing.Point(20, 318)
$btnCancel.Size = New-Object System.Drawing.Size(370, 35)
$form.Controls.Add($btnCancel)

$btnImmediate = New-Object System.Windows.Forms.Button
$btnImmediate.Text = "Execute Right Now"
$btnImmediate.Font = $fontRegular
$btnImmediate.Visible = $false
$btnImmediate.BackColor = [System.Drawing.Color]::FromArgb(239, 68, 68)
$btnImmediate.ForeColor = [System.Drawing.Color]::White
$btnImmediate.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnImmediate.Location = New-Object System.Drawing.Point(20, 360)
$btnImmediate.Size = New-Object System.Drawing.Size(370, 30)
$form.Controls.Add($btnImmediate)

# --- Timer for countdown ---
$script:RemainingSeconds = 0
$script:IsSleepTimer = $false

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000

function Trigger-SleepNow {
    $lblStatus.Font = $fontRegular
    $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(30, 41, 59)
    $lblStatus.Text = "Putting computer to sleep..."
    $form.Refresh()
    Start-Sleep -Milliseconds 600
    [System.Windows.Forms.Application]::SetSuspendState([System.Windows.Forms.PowerState]::Suspend, $false, $false)
}

function Trigger-ShutdownNow {
    $lblStatus.Font = $fontRegular
    $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(30, 41, 59)
    $lblStatus.Text = "Shutting down now..."
    $form.Refresh()
    & shutdown.exe /s /t 0
}

$timer.Add_Tick({
    if ($script:RemainingSeconds -le 0) {
        $timer.Stop()
        if ($script:IsSleepTimer) {
            Trigger-SleepNow
        }
    } else {
        $script:RemainingSeconds--
        $span = [TimeSpan]::FromSeconds($script:RemainingSeconds)
        $min = [int][Math]::Floor($span.TotalMinutes)
        $sec = $span.Seconds
        $lblStatus.Font = $fontCountdown
        $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(220, 38, 38)
        $lblStatus.Text = [string]::Format("Sleeping in {0:D2}:{1:D2}", $min, $sec)
    }
})

# --- Event Handlers ---
$btnStart.Add_Click({
    $mins = [int]$numMinutes.Value
    $totalSeconds = $mins * 60

    if ($rbShutdown.Checked) {
        $timer.Stop()
        $script:RemainingSeconds = 0
        $btnImmediate.Visible = $false
        
        # Schedule Windows shutdown
        & shutdown.exe /a 2>$null
        & shutdown.exe /s /t $totalSeconds
        
        $lblStatus.Font = $fontRegular
        $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(22, 101, 52)
        $lblStatus.Text = "Shutdown scheduled in $mins minute(s).`r`nYou can close this window or click Cancel."
    }
    else {
        # Sleep timer
        $script:RemainingSeconds = $totalSeconds
        $script:IsSleepTimer = $true
        
        $span = [TimeSpan]::FromSeconds($script:RemainingSeconds)
        $min = [int][Math]::Floor($span.TotalMinutes)
        $sec = $span.Seconds
        $lblStatus.Font = $fontCountdown
        $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(220, 38, 38)
        $lblStatus.Text = [string]::Format("Sleeping in {0:D2}:{1:D2}", $min, $sec)
        
        $btnStart.Text = "Restart Timer"
        $btnImmediate.Text = "Sleep Right Now"
        $btnImmediate.Visible = $true
        
        $timer.Start()
    }
})

$btnImmediate.Add_Click({
    $timer.Stop()
    if ($rbShutdown.Checked) {
        Trigger-ShutdownNow
    } else {
        Trigger-SleepNow
    }
})

$btnCancel.Add_Click({
    $timer.Stop()
    $script:RemainingSeconds = 0
    & shutdown.exe /a 2>$null
    
    $btnStart.Text = "Start Timer"
    $btnImmediate.Visible = $false
    $lblStatus.Font = $fontRegular
    $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(71, 85, 105)
    $lblStatus.Text = "Timer / pending shutdown cancelled."
})

$form.Add_FormClosing({
    if ($timer.Enabled) {
        $timer.Stop()
    }
})

# Show Form
[void]$form.ShowDialog()
