# Relaunch the script with administrator privileges if not already elevated
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Warning "Script is not running as administrator. Relaunching with elevated privileges..."
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell -Verb runAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    exit
}

# Define paths for user and public desktops, and a temporary backup folder
$userDesktopPath   = [Environment]::GetFolderPath("Desktop")
$publicDesktopPath = "$env:PUBLIC\Desktop"
$tempBackupPath    = "$env:TEMP\DesktopBackup"

# Whitelist: list of files to preserve and their intended order (absolute paths from user/public desktops)
$filesToKeepOrdered = @(
    "$userDesktopPath\Return to Playnite.exe",
    "$userDesktopPath\Steam.lnk"
)

# Function to remove all files from a desktop except the whitelisted ones
function Clean-Desktop($desktopPath) {
    if (Test-Path $desktopPath) {
        Get-ChildItem -Path $desktopPath -Force | ForEach-Object {
            $itemName = $_.FullName
            if (-not ($filesToKeepOrdered -contains $itemName)) {
                try {
                    Remove-Item -Path $itemName -Recurse -Force -ErrorAction Stop
                } catch {
                    Write-Warning "Failed to remove $itemName : $_"
                }
            }
        }
    }
}

# Step 1: Backup whitelisted files to a temporary folder
New-Item -Path $tempBackupPath -ItemType Directory -Force | Out-Null
foreach ($file in $filesToKeepOrdered) {
    if (Test-Path $file) {
        Copy-Item $file -Destination $tempBackupPath -Force -Recurse
    }
}

# Step 2: Clean both the user and public desktops
Clean-Desktop $userDesktopPath
Clean-Desktop $publicDesktopPath

# Step 3: Restore the whitelisted files back to the user desktop in the specified order
foreach ($file in Get-ChildItem $tempBackupPath) {
    Copy-Item -Path $file.FullName -Destination $userDesktopPath -Force -Recurse
    Start-Sleep -Milliseconds 300
}

# Step 4: Clean up the temporary backup folder
Remove-Item $tempBackupPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Desktop successfully cleaned and rebuilt in the defined order."
