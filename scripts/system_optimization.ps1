# Relaunch script as administrator if not already running in admin mode
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Script is not running as administrator. Relaunching with elevated privileges..."
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell -Verb runAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    exit
}

# Optional: Disable non-essential services (can be skipped if minimal changes are needed)
Write-Host "Skipping service disabling to preserve system stability..."

# Clean user startup folders
Write-Host "Cleaning user startup folders..."
$startupFolders = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
)
foreach ($folder in $startupFolders) {
    if (Test-Path $folder) {
        Get-ChildItem $folder -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    }
}

# Skip removal of provisioned apps – keep system intact

# Skip user Appx removal – except for OneDrive (handled separately)

# Disable known scheduled tasks for performance and privacy
Write-Host "Disabling known scheduled tasks..."
$tasksToDisable = @(
    "Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
    "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
    "Microsoft\Windows\Application Experience\ProgramDataUpdater",
    "Microsoft\Windows\Autochk\Proxy"
)
foreach ($taskPath in $tasksToDisable) {
    try {
        $taskName = $taskPath.Split("\")[-1]
        $taskFolder = $taskPath.Substring(0, $taskPath.LastIndexOf('\') + 1)
        $task = Get-ScheduledTask -TaskPath $taskFolder -TaskName $taskName -ErrorAction Stop
        Disable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue
        Write-Host "$taskPath disabled"
    } catch {
        Write-Host "Could not process $taskPath"
    }
}

# Enable dark mode
Write-Host "Enabling dark mode..."
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Force

# Uninstall OneDrive only
Write-Host "Uninstalling OneDrive..."

$onedriveSetup = "$env:SystemRoot\System32\OneDriveSetup.exe"
$onedriveUserPath = "$env:USERPROFILE\OneDrive"

Stop-Process -Name OneDrive -Force -ErrorAction SilentlyContinue

if (Test-Path $onedriveSetup) {
    Start-Process -FilePath $onedriveSetup -ArgumentList "/uninstall" -Wait
    Write-Host "OneDrive has been uninstalled"
} else {
    Write-Host "OneDriveSetup.exe not found"
}

if (Test-Path $onedriveUserPath) {
    Remove-Item -Path $onedriveUserPath -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "OneDrive folder removed"
}

# Get the directory where this script is running from.
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path

# Define the name of the script to be downloaded and executed.
$installerScriptName = "Get.ps1"
# Define the full path where the installer script will be saved.
$installerScriptPath = Join-Path $scriptDirectory $installerScriptName

# Replace this URL with the direct download link to your 'get.ps1' file.
$installerUrl = "https://github.com/Raphire/Win11Debloat/releases/download/2025.06.12/Get.ps1"

Write-Host "Attempting to download '$installerScriptName'..."
try {
    # Download the file from the specified URL and save it to the script's directory.
    # The -ErrorAction Stop parameter ensures that if Invoke-WebRequest fails, it will trigger the catch block.
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerScriptPath -UseBasicParsing -ErrorAction Stop
    Write-Host "Successfully downloaded '$installerScriptName'." -ForegroundColor Green
}
catch {
    # If the download fails, show an error and exit.
    Write-Error "Failed to download the script from '$installerUrl'."
    Write-Error "Please verify the URL and your network connection."
    Read-Host "Press Enter to exit."
    exit 1
}

# Double-check that the file actually exists before trying to run it.
if (-not (Test-Path $installerScriptPath)) {
    Write-Error "'$installerScriptName' was not found after the download attempt. Aborting."
    Read-Host "Press Enter to exit."
    exit 1
}


Write-Host "Launching '$installerScriptName' with administrator privileges..."
Write-Host "A User Account Control (UAC) prompt may appear. Please accept it to proceed."

Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$installerScriptPath`"" -Verb runAs

# The installer script has been launched in a separate window. This main script will now pause.
Write-Host ""
Write-Host "The installer has been launched in a new window." -ForegroundColor Cyan
Read-Host "Press ENTER to continue..."

# Set system power plan to Ultimate Performance
Write-Host "Enabling Ultimate Performance power plan..."
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61

# Disable automatic Windows Updates via Group Policy
Write-Host "Disabling automatic Windows Updates..."
$regPathWU = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
New-Item -Path $regPathWU -Force | Out-Null
New-ItemProperty -Path $regPathWU -Name "NoAutoUpdate" -Value 1 -PropertyType DWord -Force | Out-Null

# Optionally align taskbar to the left (instead of center)
Write-Host "Aligning taskbar to the left..."
$regPathTaskbar = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
Set-ItemProperty -Path $regPathTaskbar -Name "TaskbarAl" -Value 0
Stop-Process -Name explorer -Force
Write-Host "Taskbar is now aligned to the left."

# Enable Game Mode
Write-Host "Enabling Game Mode..."
$regPathGameMode = "HKCU:\Software\Microsoft\GameBar"
If (-Not (Test-Path $regPathGameMode)) {
    New-Item -Path $regPathGameMode -Force | Out-Null
}
Set-ItemProperty -Path $regPathGameMode -Name "AutoGameModeEnabled" -Value 1
Write-Host "Game Mode is now enabled."
