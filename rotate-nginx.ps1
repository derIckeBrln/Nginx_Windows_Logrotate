param (
    [string]$LogPath = "D:\nginx\logs",
    [string]$NginxExe = "D:\nginx\nginx.exe",
    [int]$KeepCopies = 4,
    [int]$ZipDelay = 2
)

$LogFile = Join-Path $LogPath "nginx-rotation.log"

function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp $Message" | Out-File -FilePath $LogFile -Append -Encoding utf8
}

Write-Log "=== Rotation started ==="

$Now = Get-Date
$Timestamp = $Now.ToString("yyyy-MM-dd-HHmmss")

$AccessLog = Join-Path $LogPath "access.log"
$ErrorLog  = Join-Path $LogPath "error.log"

if (Test-Path $AccessLog) {
    $new = Join-Path $LogPath "access-$Timestamp.log"
    Rename-Item $AccessLog $new -Force
    Write-Log "Renamed access.log to $(Split-Path $new -Leaf)"
}
if (Test-Path $ErrorLog) {
    $new = Join-Path $LogPath "error-$Timestamp.log"
    Rename-Item $ErrorLog $new -Force
    Write-Log "Renamed error.log to $(Split-Path $new -Leaf)"
}

try {
    Start-Process -FilePath $NginxExe -ArgumentList "-s reopen" -NoNewWindow -Wait
    Write-Log "NGINX signaled to reopen logs"
} catch {
    Write-Log "ERROR: Failed to signal NGINX: $_"
}

@("access", "error") | ForEach-Object {
    $type = $_
    $rotatedLogs = Get-ChildItem -Path $LogPath -Filter "$type-*.log" |
        Where-Object { $_.Name -match '^\w+-\d{4}-\d{2}-\d{2}-\d{6}\.log$' } |
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

    $zipped = Get-ChildItem -Path $LogPath -Filter "$type-*.log.zip" | Sort-Object LastWriteTime
    if ($zipped.Count -gt $KeepCopies) {
        $toDelete = $zipped | Select-Object -First ($zipped.Count - $KeepCopies)
        foreach ($zip in $toDelete) {
            try {
                Remove-Item $zip.FullName -Force
                Write-Log "Deleted old $type archive $($zip.Name)"
            } catch {
                Write-Log "ERROR: Failed to delete $type archive $($zip.Name): $_"
            }
        }
    }
}

Write-Log "=== Rotation finished ==="
