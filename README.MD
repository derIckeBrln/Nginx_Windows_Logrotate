# Generic Log Rotation Script for Windows (PowerShell)

This PowerShell script provides flexible and automated log rotation for any log files on Windows systems. It is especially suitable for rotating logs of services like NGINX, but can be used with any application that writes to log files and can reopen logs on demand.

## Features

- Rotates one or more `.log` files by renaming them with a timestamp (`YYYY-MM-DD-HHmmss`)
- Supports multiple log sources (e.g. access logs, error logs, proxy logs)
- Compresses older rotated logs into `.zip` files
- Keeps only a defined number of uncompressed and compressed logs per file
- Optionally runs a post-rotation command (e.g. signal the app to reopen log files)
- All actions are logged to a user-defined rotation log file

## Requirements

- Windows 10 / Server 2016 or newer
- PowerShell 5.1+ or PowerShell Core 7+
- Optional: `Compress-Archive` (built-in in modern PowerShell versions)

## Parameters

| Parameter             | Type      | Description                                                                 |
|------------------------|-----------|-----------------------------------------------------------------------------|
| `LogPath`             | string    | Path where log files are stored (default: `C:\logs`)                        |
| `LogFile`             | string    | Path to the script’s own rotation log (e.g. `rotation.log`)                |
| `LogFiles`            | string[]  | One or more filenames to rotate (e.g. `access.log`, `error.log`)           |
| `PostRotationTrigger` | string    | Optional command to run after rotation (e.g. `nginx.exe -s reopen`)        |
| `ZipDelay`            | int       | Number of most recent rotated logs (per file) to keep uncompressed         |
| `KeepZips`            | int       | Number of compressed logs (`*.zip`) to retain per log file                 |

## Example Usage (Generic)

Rotate two logs, zip older than 2, and keep 10 zipped logs:

```powershell
.\logrotate.ps1 `
  -LogPath "D:\service\logs" `
  -LogFile "D:\service\logs\rotate.log" `
  -LogFiles @("app.log", "debug.log") `
  -ZipDelay 2 `
  -KeepZips 10
```

## Example Usage for NGINX on Windows

Rotate `access.log` and `error.log`, zip older rotated logs, and trigger NGINX to reopen logs:

```powershell
.\rotate-logs.ps1 `
  -LogPath "C:\nginx\logs" `
  -LogFile "C:\nginx\logs\rotation.log" `
  -LogFiles @("access.log", "error.log") `
  -PostRotationTrigger "C:\nginx\nginx.exe -s reopen" `
  -ZipDelay 2 `
  -KeepZips 14
```

### This setup will:

- Rename `access.log` to `access-YYYY-MM-DD-HHmmss.log`
- Rename `error.log` accordingly
- Keep the 2 newest `.log` files uncompressed for each type
- Zip all older rotated `.log` files into `.zip`
- Retain only 14 zipped files per type (oldest zipped logs are deleted)
- Log everything to `rotation.log`

### Scheduled Automation (Recommended)

You can schedule this script using Windows Task Scheduler:

#### Via Task Scheduler GUI

1. Open **Task Scheduler**
2. Create a new task
3. Set the **trigger** (e.g. daily at 00:00)
4. Set the **action**:
   - **Program**: `powershell.exe`
   - **Arguments**:
     ```text
     -ExecutionPolicy Bypass -File "C:\scripts\rotate-logs.ps1" -LogPath "C:\nginx\logs" -LogFile "C:\nginx\logs\rotation.log" -LogFiles @("access.log","error.log") -PostRotationTrigger "C:\nginx\nginx.exe -s reopen" -ZipDelay 2 -KeepZips 14
     ```
5. Enable **"Run with highest privileges"**

#### Via Command Line (Batch)

```batch
schtasks /Create ^
 /TN "Log Rotation - NGINX" ^
 /TR "powershell.exe -ExecutionPolicy Bypass -File \"C:\scripts\rotate-logs.ps1\" -LogPath \"C:\nginx\logs\" -LogFile \"C:\nginx\logs\rotation.log\" -LogFiles access.log error.log -PostRotationTrigger \"C:\nginx\nginx.exe -s reopen\" -ZipDelay 2 -KeepZips 14" ^
 /SC DAILY /ST 00:00 ^
 /RL HIGHEST /F
```

### Notes

- Ensure that log rotation does not interfere with your application’s logging  
  (e.g. use `-s reopen` for NGINX to reopen log files after rotation)
- The script does not rotate logs still being written to —  
  it relies on the application to reopen new log files after rotation
- Timestamps in filenames use 24h time format (`HHmmss`)  
  and are safe for chronological sorting and filesystem compatibility
