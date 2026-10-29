<#
.SYNOPSIS
    Windows Automation Hub - Master Control Center
.DESCRIPTION
    A centralized launcher and dashboard for all automations in this repository.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- Main Form ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Automation Hub"
$form.Size = New-Object System.Drawing.Size(460, 520)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(245, 246, 248)

$fontTitle   = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$fontSection = New-Object System.Drawing.Font("Segoe UI", 10.5, [System.Drawing.FontStyle]::Bold)
$fontRegular = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Regular)
$fontSmall   = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Regular)
$fontBold    = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)

# --- Header ---
$lblHeader = New-Object System.Windows.Forms.Label
$lblHeader.Text = "Windows Automation Hub"
$lblHeader.Font = $fontTitle
$lblHeader.ForeColor = [System.Drawing.Color]::FromArgb(30, 41, 59)
$lblHeader.Location = New-Object System.Drawing.Point(20, 15)
$lblHeader.Size = New-Object System.Drawing.Size(400, 28)
$form.Controls.Add($lblHeader)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text = "Control center for all your Windows background tasks and timers."
$lblSub.Font = $fontRegular
$lblSub.ForeColor = [System.Drawing.Color]::FromArgb(100, 116, 139)
$lblSub.Location = New-Object System.Drawing.Point(20, 43)
$lblSub.Size = New-Object System.Drawing.Size(400, 20)
$form.Controls.Add($lblSub)

# --- Helper to launch child UI ---
function Launch-ChildUI([string]$scriptName) {
    $path = Join-Path $ScriptDir $scriptName
    if (Test-Path $path) {
        Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$path`"" -WorkingDirectory $ScriptDir
    }
}

# --- Card 1: Power Timer ---
$card1 = New-Object System.Windows.Forms.GroupBox
$card1.Text = "Sleep & Shutdown Timer"
$card1.Font = $fontSection
$card1.Location = New-Object System.Drawing.Point(20, 70)
$card1.Size = New-Object System.Drawing.Size(400, 95)
$form.Controls.Add($card1)

$lblC1 = New-Object System.Windows.Forms.Label
$lblC1.Text = "Schedule PC to sleep or shut down after X minutes with live countdown."
$lblC1.Font = $fontSmall
$lblC1.ForeColor = [System.Drawing.Color]::FromArgb(71, 85, 105)
$lblC1.Location = New-Object System.Drawing.Point(15, 22)
$lblC1.Size = New-Object System.Drawing.Size(260, 60)
$card1.Controls.Add($lblC1)

$btnOpen1 = New-Object System.Windows.Forms.Button
$btnOpen1.Text = "Open Timer"
$btnOpen1.Font = $fontBold
$btnOpen1.BackColor = [System.Drawing.Color]::FromArgb(37, 99, 235)
$btnOpen1.ForeColor = [System.Drawing.Color]::White
$btnOpen1.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnOpen1.Location = New-Object System.Drawing.Point(280, 30)
$btnOpen1.Size = New-Object System.Drawing.Size(105, 38)
$btnOpen1.Add_Click({ Launch-ChildUI "power_timer.ps1" })
$card1.Controls.Add($btnOpen1)

# --- Card 2: Dumbbell Reminder ---
$card2 = New-Object System.Windows.Forms.GroupBox
$card2.Text = "Dumbbell Workout Reminder"
$card2.Font = $fontSection
$card2.Location = New-Object System.Drawing.Point(20, 175)
$card2.Size = New-Object System.Drawing.Size(400, 95)
$form.Controls.Add($card2)

$lblC2 = New-Object System.Windows.Forms.Label
$lblC2.Text = "Monitors YouTube/Stremio watchtime and nudges to workout when threshold is met."
$lblC2.Font = $fontSmall
$lblC2.ForeColor = [System.Drawing.Color]::FromArgb(71, 85, 105)
$lblC2.Location = New-Object System.Drawing.Point(15, 22)
$lblC2.Size = New-Object System.Drawing.Size(260, 60)
$card2.Controls.Add($lblC2)

$btnOpen2 = New-Object System.Windows.Forms.Button
$btnOpen2.Text = "Manage"
$btnOpen2.Font = $fontBold
$btnOpen2.BackColor = [System.Drawing.Color]::FromArgb(37, 99, 235)
$btnOpen2.ForeColor = [System.Drawing.Color]::White
$btnOpen2.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnOpen2.Location = New-Object System.Drawing.Point(280, 30)
$btnOpen2.Size = New-Object System.Drawing.Size(105, 38)
$btnOpen2.Add_Click({ Launch-ChildUI "dumbell_ui.ps1" })
$card2.Controls.Add($btnOpen2)

# --- Card 3: OBS Wake Handler ---
$card3 = New-Object System.Windows.Forms.GroupBox
$card3.Text = "OBS Studio Wake Handler"
$card3.Font = $fontSection
$card3.Location = New-Object System.Drawing.Point(20, 280)
$card3.Size = New-Object System.Drawing.Size(400, 95)
$form.Controls.Add($card3)

$lblC3 = New-Object System.Windows.Forms.Label
$lblC3.Text = "Restores and maximizes OBS Studio whenever Windows wakes from sleep."
$lblC3.Font = $fontSmall
$lblC3.ForeColor = [System.Drawing.Color]::FromArgb(71, 85, 105)
$lblC3.Location = New-Object System.Drawing.Point(15, 22)
$lblC3.Size = New-Object System.Drawing.Size(260, 60)
$card3.Controls.Add($lblC3)

$btnOpen3 = New-Object System.Windows.Forms.Button
$btnOpen3.Text = "Manage"
$btnOpen3.Font = $fontBold
$btnOpen3.BackColor = [System.Drawing.Color]::FromArgb(37, 99, 235)
$btnOpen3.ForeColor = [System.Drawing.Color]::White
$btnOpen3.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnOpen3.Location = New-Object System.Drawing.Point(280, 30)
$btnOpen3.Size = New-Object System.Drawing.Size(105, 38)
$btnOpen3.Add_Click({ Launch-ChildUI "obs_wake_ui.ps1" })
$card3.Controls.Add($btnOpen3)

# --- Bottom Bar: Shortcut Creator ---
$btnShortcuts = New-Object System.Windows.Forms.Button
$btnShortcuts.Text = "Install / Update All Shortcuts (Desktop & Start Menu)"
$btnShortcuts.Font = $fontRegular
$btnShortcuts.BackColor = [System.Drawing.Color]::FromArgb(241, 245, 249)
$btnShortcuts.ForeColor = [System.Drawing.Color]::FromArgb(30, 41, 59)
$btnShortcuts.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$btnShortcuts.Location = New-Object System.Drawing.Point(20, 395)
$btnShortcuts.Size = New-Object System.Drawing.Size(400, 38)
$btnShortcuts.Add_Click({
    $p = Join-Path $ScriptDir "create_all_shortcuts.ps1"
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$p`"" -WorkingDirectory $ScriptDir
})
$form.Controls.Add($btnShortcuts)

# Show Form
[void]$form.ShowDialog()
