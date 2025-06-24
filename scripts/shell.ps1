# 1. Define the path to the Scripts folder inside Documents
$documentsPath = [Environment]::GetFolderPath('MyDocuments')
$scriptsPath = Join-Path $documentsPath 'Scripts'

# 2. Create the Scripts folder if it doesn't exist
if (-Not (Test-Path $scriptsPath)) {
    Write-Host "Creating folder: $scriptsPath"
    New-Item -Path $scriptsPath -ItemType Directory | Out-Null
} else {
    Write-Host "Scripts folder already exists: $scriptsPath"
}

# 3. Download shell_playnite.exe from GitHub
$exeName = "shell_playnite.exe"
$exeUrl = "https://raw.githubusercontent.com/Sanko-kf/PlayMode/main/builds/shell_playnite.exe"
$exePath = Join-Path $scriptsPath $exeName

Write-Host "Downloading $exeName..."
Invoke-WebRequest -Uri $exeUrl -OutFile $exePath

# 4. Define registry path and backup location
$regPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
$backupPath = Join-Path $scriptsPath "shell_backup.txt"

# 5. Check that the executable exists
if (-Not (Test-Path $exePath)) {
    Write-Error "The executable was not found: $exePath"
    exit 1
}

# 6. Backup the current shell value (if it exists)
$existingShell = Get-ItemProperty -Path $regPath -Name Shell -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Shell
if ($existingShell) {
    Set-Content -Path $backupPath -Value $existingShell
    Write-Output "Current shell value backed up to: $backupPath"
}

# 7. Set the new shell value to shell_playnite.exe
Set-ItemProperty -Path $regPath -Name Shell -Value $exePath
Write-Output "Shell updated to execute: $exePath"
