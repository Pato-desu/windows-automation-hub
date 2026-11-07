# Shared helpers for the Google Drive Backup tool (dot-sourced by gdrive_backup.ps1 and gdrive_backup_ui.ps1)

$script:HubDir     = Split-Path -Parent $MyInvocation.MyCommand.Path
$script:ConfigPath = Join-Path $HubDir "gdrive_backup_config.json"
$script:StatusPath = Join-Path $HubDir "logs\gdrive_backup_status.json"
$script:LogPath    = Join-Path $HubDir "logs\gdrive_backup_last.log"
$script:LockPath   = Join-Path $HubDir ".gdrive_backup_pid"
$script:TaskName   = "GDrive_Backup_Nightly"

function Get-BackupConfig {
    # Defaults; override any of them by creating gdrive_backup_config.json next to this script.
    $cfg = [ordered]@{
        RcloneExe           = ""                          # empty = auto-detect rclone-*\rclone.exe in the hub folder
        Remote              = "gdrive:"
        Dest                = "Z:\Google Drive Backup"
        ArchiveRoot         = "Z:\Google Drive Archive"   # deleted/replaced files are moved to a dated subfolder here
        KeepDays            = 90                          # dated archive folders older than this are removed after a successful run
        ExportFormats       = "docx,xlsx,pptx"
        TpsLimit            = 8
        WaitForDriveSeconds = 120
    }
    if (Test-Path $ConfigPath) {
        try {
            $user = Get-Content $ConfigPath -Raw | ConvertFrom-Json
            foreach ($p in $user.PSObject.Properties) { $cfg[$p.Name] = $p.Value }
        } catch { }
    }
    if (-not $cfg.RcloneExe -or -not (Test-Path $cfg.RcloneExe)) {
        $found = Get-ChildItem -Path $HubDir -Directory -Filter "rclone-*" -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending |
            ForEach-Object { Join-Path $_.FullName "rclone.exe" } |
            Where-Object { Test-Path $_ } | Select-Object -First 1
        $cfg.RcloneExe = $found
    }
    return $cfg
}

function Set-BackupStatus([hashtable]$Status) {
    $dir = Split-Path $StatusPath
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $Status | ConvertTo-Json | Set-Content -Path $StatusPath -Encoding UTF8
}

function Get-BackupStatus {
    if (Test-Path $StatusPath) {
        try { return Get-Content $StatusPath -Raw | ConvertFrom-Json } catch { }
    }
    return $null
}

# Returns the PID of a live backup runner, or $null.
function Get-RunnerPid {
    if (-not (Test-Path $LockPath)) { return $null }
    $raw = (Get-Content $LockPath -ErrorAction SilentlyContinue | Select-Object -First 1)
    $id = 0
    if ([int]::TryParse("$raw", [ref]$id)) {
        $p = Get-Process -Id $id -ErrorAction SilentlyContinue
        if ($p -and $p.ProcessName -match '^(powershell|pwsh)$') { return $id }
    }
    return $null
}
