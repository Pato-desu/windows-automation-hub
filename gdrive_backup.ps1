<#
.SYNOPSIS
    Google Drive -> local backup using rclone (sync with dated archive of deleted/changed files).
.DESCRIPTION
    - Mirrors the Drive remote into Dest.
    - Files that would be deleted or overwritten are moved to ArchiveRoot\<timestamp> instead.
    - Waits for the destination drive, refuses to run twice at once, and treats Google's
      "flagged as malware" download refusals as warnings rather than failures.
    Settings live in gdrive_backup_common.ps1 (override via gdrive_backup_config.json).
#>
param([switch]$DryRun)

. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "gdrive_backup_common.ps1")

$cfg = Get-BackupConfig
$started = Get-Date
$mode = if ($DryRun) { "dry-run" } else { "backup" }

function Finish([string]$state, [string]$message, $exit = $null) {
    Set-BackupStatus @{
        state = $state; mode = $mode; message = $message; exitCode = $exit
        started = $started.ToString("s"); ended = (Get-Date).ToString("s")
    }
    Remove-Item $LockPath -Force -ErrorAction SilentlyContinue
}

# --- Single instance ---
if (Get-RunnerPid) { exit 0 }
Set-Content -Path $LockPath -Value $PID

if (-not $cfg.RcloneExe) { Finish "failed" "rclone.exe not found (expected rclone-*\rclone.exe in the hub folder)."; exit 2 }

# --- Wait for destination drive (e.g. Z: mounting late after logon) ---
$driveRoot = [System.IO.Path]::GetPathRoot($cfg.Dest)
$deadline = (Get-Date).AddSeconds([int]$cfg.WaitForDriveSeconds)
while (-not (Test-Path $driveRoot) -and (Get-Date) -lt $deadline) { Start-Sleep -Seconds 5 }
if (-not (Test-Path $driveRoot)) { Finish "skipped" "Drive $driveRoot not available - run skipped."; exit 3 }

Set-BackupStatus @{ state = "running"; mode = $mode; message = "Running..."; pid = $PID; started = $started.ToString("s") }

if (Test-Path $LogPath) { Remove-Item $LogPath -Force }
$archive = Join-Path $cfg.ArchiveRoot ($started.ToString("yyyy-MM-dd_HHmmss"))

$rcloneArgs = @(
    "sync", $cfg.Remote, $cfg.Dest,
    "--backup-dir", $archive,
    "--drive-export-formats", $cfg.ExportFormats,
    "--drive-acknowledge-abuse",
    "--tpslimit", $cfg.TpsLimit,
    "--log-file", $LogPath, "--log-level", "INFO", "--stats", "30s"
)
if ($DryRun) { $rcloneArgs += "--dry-run" }

& $cfg.RcloneExe @rcloneArgs | Out-Null
$exit = $LASTEXITCODE

# --- Classify result ---
$benign = 'cannotDownloadAbusiveFile|not deleting directories as there were IO errors'
$errs   = @(Select-String -Path $LogPath -Pattern ' ERROR : ' -ErrorAction SilentlyContinue)
$other  = @($errs | Where-Object { $_.Line -notmatch $benign }).Count
$flagged = @($errs | Where-Object { $_.Line -match 'cannotDownloadAbusiveFile' }).Count -gt 0

if ($exit -eq 0) {
    Finish "success" "Completed with no errors." $exit
} elseif ($other -eq 0 -and $flagged) {
    Finish "warning" "Completed. Some files were skipped because Google flags them as malware (see log)." $exit
} else {
    Finish "failed" "rclone exited with code $exit and $other unexpected error(s). See log." $exit
    exit $exit
}

# --- Prune old dated archive folders (never on dry runs) ---
if (-not $DryRun -and (Test-Path $cfg.ArchiveRoot)) {
    $cutoff = (Get-Date).AddDays(-[int]$cfg.KeepDays)
    Get-ChildItem -Path $cfg.ArchiveRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}_\d{6}$' } |
        ForEach-Object {
            $d = [datetime]::ParseExact($_.Name, 'yyyy-MM-dd_HHmmss', $null)
            if ($d -lt $cutoff) {
                try { Remove-Item -LiteralPath ("\\?\" + $_.FullName) -Recurse -Force -ErrorAction Stop } catch { }
            }
        }
}
