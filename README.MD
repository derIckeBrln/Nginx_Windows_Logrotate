# NGINX Log Rotation Script (Windows, PowerShell)

This PowerShell script rotates NGINX log files on Windows systems. It renames `access.log` and `error.log` with a timestamp, compresses older log files, and deletes old ZIP archives according to configurable retention policies.

## Features

- Renames `access.log` and `error.log` to `access-YYYY-MM-DD-HHmmss.log`
- Sends a `-s reopen` signal to NGINX to start fresh log files
- Compresses older rotated log files with `.zip`
- Retains only the newest N uncompressed logs (per type)
- Keeps only the latest M compressed archives (per type)
- Writes all operations to a persistent `nginx-rotation.log`

## Requirements

- PowerShell 5.1 or newer (Windows 10+)
- `nginx.exe` accessible locally
- NGINX installed and configured with standard logging

## Parameters

| Parameter     | Type   | Description                                                                 |
|---------------|--------|-----------------------------------------------------------------------------|
| `LogPath`     | string | Path to the directory containing `access.log` and `error.log`               |
| `NginxExe`    | string | Full path to the `nginx.exe` executable                                     |
| `ZipDelay`    | int    | Number of the most recent rotated logs to keep uncompressed (per log type) |
| `KeepCopies`  | int    | Number of compressed `.zip` archives to retain (per log type)              |

## Example

```powershell
.\rotate-nginx.ps1 `
  -LogPath "D:\nginx\logs" `
  -NginxExe "D:\nginx\nginx.exe" `
  -ZipDelay 2 `
  -KeepCopies 14

# Automating NGINX Log Rotation with Task Scheduler (Windows)

To run the `rotate-nginx.ps1` script automatically on a schedule, you can use the Windows built-in **Task Scheduler**.

## Option 1: Manual Setup via Task Scheduler GUI

1. Open **Task Scheduler** (`taskschd.msc`)
2. Click **"Create Task"**
3. Under the **General** tab:
   - Name: `NGINX Log Rotation`
   - Check: "Run with highest privileges"
   - Configure for: Windows 10 or higher
4. Under the **Triggers** tab:
   - Click "New…"
   - Choose schedule (e.g. **Daily at 00:00** or **Hourly**)
5. Under the **Actions** tab:
   - Click "New…"
   - Action: Start a program
   - Program/script: `powershell.exe`
   - Add arguments:
     ```text
     -ExecutionPolicy Bypass -File "C:\scripts\rotate-nginx.ps1" -LogPath "C:\nginx\logs" -NginxExe "C:\nginx\nginx.exe" -ZipDelay 2 -KeepCopies 14
     ```
6. Save the task

## Option 2: Register via Batch Script

Use this example `.bat` file to create the task from the command line:

```batch
schtasks /Create ^
 /TN "NGINX Log Rotation" ^
 /TR "powershell.exe -ExecutionPolicy Bypass -File \"C:\scripts\rotate-nginx.ps1\" -LogPath \"C:\nginx\logs\" -NginxExe \"C:\nginx\nginx.exe\" -ZipDelay 2 -KeepCopies 14" ^
 /SC DAILY /ST 00:00 ^
 /RL HIGHEST /F
