# Example PowerShell Task: System Performance Snapshot
# Logs CPU, RAM, and Disk space status to console and file

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Output "========================================"
Write-Output "System Info Snapshot - $timestamp"
Write-Output "========================================"

# CPU Usage
$cpu = Get-CimInstance Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
Write-Output "CPU Load: $cpu %"

# Memory Usage
$os = Get-CimInstance Win32_OperatingSystem
$totalRamGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
$freeRamGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedRamGB  = [math]::Round($totalRamGB - $freeRamGB, 2)
$ramPercent = [math]::Round(($usedRamGB / $totalRamGB) * 100, 1)

Write-Output "RAM Usage: $usedRamGB GB / $totalRamGB GB ($ramPercent%)"

# Disk Usage
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeDiskGB  = [math]::Round($disk.FreeSpace / 1GB, 2)
$totalDiskGB = [math]::Round($disk.Size / 1GB, 2)
Write-Output "C: Drive: $freeDiskGB GB free / $totalDiskGB GB total"

Write-Output "Snapshot completed."
