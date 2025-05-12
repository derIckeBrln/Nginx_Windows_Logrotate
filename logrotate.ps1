param (
    [string]$LogPath = "C:\logs",
    [string]$LogFile = "C:\logs\rotation.log",
    [string[]]$LogFiles = @("example.log"),
    [string]$PostRotationTrigger = "",
    [int]$KeepZips = 14,
    [int]$ZipDelay = 2
)

function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $Message" | Out-File -FilePath $LogFile -Append -Encoding utf8
}

Write-Log "=== Rotation started ==="

$Now = Get-Date
$Timestamp = $Now.ToString("yyyy-MM-dd-HHmmss")

foreach ($baseName in $LogFiles) {
    $fullPath = Join-Path $LogPath $baseName
    if (Test-Path $fullPath) {
        $rotatedName = "$($baseName -replace '\.log$','')-$Timestamp.log"
        $rotatedPath = Join-Path $LogPath $rotatedName
        Rename-Item $fullPath $rotatedPath -Force
        Write-Log "Rotated $baseName to $rotatedName"
    }
}

if ($PostRotationTrigger -ne "") {
    try {
        Write-Log "Running post-rotation trigger: $PostRotationTrigger"
        Invoke-Expression $PostRotationTrigger
        Write-Log "Post-rotation trigger executed"
    } catch {
        Write-Log "ERROR: Post-rotation trigger failed: $_"
    }
}

foreach ($baseName in $LogFiles) {
    $prefix = $baseName -replace '\.log$',''
    
    $rotatedLogs = Get-ChildItem -Path $LogPath -Filter "$prefix-*.log" |
        Where-Object { $_.Name -match "^$prefix-\d{4}-\d{2}-\d{2}-\d{6}\.log$" } |
        Sort-Object LastWriteTime -Descending

    if ($rotatedLogs.Count -gt $ZipDelay) {
        $logsToZip = $rotatedLogs | Select-Object -Skip $ZipDelay
        foreach ($log in $logsToZip) {
            $zipPath = "$($log.FullName).zip"
            if (-not (Test-Path $zipPath)) {
                try {
                    Compress-Archive -Path $log.FullName -DestinationPath $zipPath -Force
                    Remove-Item $log.FullName -Force
                    Write-Log "Zipped and removed $($log.Name)"
                } catch {
                    Write-Log "ERROR: Failed to zip $($log.Name): $_"
                }
            }
        }
    }

    $zips = Get-ChildItem -Path $LogPath -Filter "$prefix-*.log.zip" | Sort-Object LastWriteTime
    if ($zips.Count -gt $KeepZips) {
        $toDelete = $zips | Select-Object -First ($zips.Count - $KeepZips)
        foreach ($zip in $toDelete) {
            try {
                Remove-Item $zip.FullName -Force
                Write-Log "Deleted old archive $($zip.Name)"
            } catch {
                Write-Log "ERROR: Failed to delete archive $($zip.Name): $_"
            }
        }
    }
}

Write-Log "=== Rotation finished ==="
