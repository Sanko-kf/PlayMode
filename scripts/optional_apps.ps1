# Relaunch the script with administrator privileges if not already elevated
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Warning "Script is not running as administrator. Relaunching with elevated privileges..."
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell -Verb runAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    exit
}

# PART 1
$response1 = Read-Host "Do you want to install custom sleep mode ? (yes/no)"
if ($response1.ToLower() -eq "yes") {
    Write-Host "`nRunning PART 1..."

    # 1. Install VLC using winget
    Write-Host "Installing VLC..."
    try {
        winget install --id VideoLAN.VLC -e --source winget -h
    } catch {
        Write-Host "Error during VLC installation: $_"
    }

    # 2 Get the path to the 'Scripts' folder inside the user's Documents
    $documentsPath = [Environment]::GetFolderPath('MyDocuments')
    $scriptsPath = Join-Path $documentsPath 'Scripts'

    # Create the 'Scripts' folder if it doesn't already exist
    if (-Not (Test-Path $scriptsPath)) {
        Write-Host "Creating folder: $scriptsPath"
        New-Item -Path $scriptsPath -ItemType Directory | Out-Null
    } else {
        Write-Host "Scripts folder already exists: $scriptsPath"
    }

    # URLs of the files to download
    $files = @{
        "sleep_mode_detector.exe" = "https://raw.githubusercontent.com/Sanko-kf/PlayMode/main/builds/sleep_mode_detector.exe"
        "stop_sleep.bat"          = "https://raw.githubusercontent.com/Sanko-kf/PlayMode/main/scripts/stop_sleep.bat"
        "sleep_mode.bat"          = "https://raw.githubusercontent.com/Sanko-kf/PlayMode/main/scripts/sleep_mode.bat"
    }

    # Download each file to the Scripts folder
    foreach ($filename in $files.Keys) {
        $url = $files[$filename]
        $destination = Join-Path $scriptsPath $filename

        Write-Host "Downloading $filename..."
        Invoke-WebRequest -Uri $url -OutFile $destination
    }
    
    # 3 Get the path to the 'SleepVideos' folder inside the user's Videos
    $videosPath = [Environment]::GetFolderPath('MyVideos')
    $sleepVideosPath = Join-Path $videosPath 'SleepVideos'

    # Create the 'SleepVideos' folder if it doesn't already exist
    if (-Not (Test-Path $sleepVideosPath)) {
        Write-Host "Creating sleep videos folder: $sleepVideosPath"
        New-Item -Path $sleepVideosPath -ItemType Directory | Out-Null
    } else {
        Write-Host "SleepVideos folder already exists: $sleepVideosPath"
    }

    # Define the video file to download
    $videoUrl = "https://raw.githubusercontent.com/Sanko-kf/PlayMode/main/assets/sample.webm"
    $destinationPath = Join-Path $sleepVideosPath "sample.webm"

    # Download the video
    Write-Host "Downloading sample.webm..."
    Invoke-WebRequest -Uri $videoUrl -OutFile $destinationPath


    # 4. Create scheduled task for sleep_mode_detector.exe
    $exePath = Join-Path $scriptsPath 'sleep_mode_detector.exe'
    if (Test-Path $exePath) {
        $taskName = "SleepModeDetectorAutoStart"
        $action = New-ScheduledTaskAction -Execute $exePath
        $trigger = New-ScheduledTaskTrigger -AtLogOn
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

        try {
            Write-Host "Creating scheduled task for: $exePath"
            Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Principal $principal -Force
        } catch {
            Write-Host "Error creating scheduled task: $_"
        }
    } else {
        Write-Host "sleep_mode_detector.exe not found in $scriptsPath. Task not created."
    }

    # 5. Power settings: disable sleep/hibernate and configure power button
    Write-Host "`nConfiguring power settings..."

    try {
        # Disable sleep and screen timeout
        powercfg /change standby-timeout-ac 0
        powercfg /change standby-timeout-dc 0
        powercfg /change monitor-timeout-ac 0
        powercfg /change monitor-timeout-dc 0

        # Turn off hibernation
        powercfg /hibernate off

        # Set power button to shut down (action ID 3)
        $scheme = (powercfg /getactivescheme) -match '{(.+)}' | Out-Null ; $guid = $matches[1]

        powercfg /setacvalueindex $guid SUB_BUTTONS PBUTTONACTION 3
        powercfg /setdcvalueindex $guid SUB_BUTTONS PBUTTONACTION 3

        # Apply changes
        powercfg /setactive $guid

        Write-Host "Power settings configured successfully."

    } catch {
        Write-Host "Error configuring power settings: $_"
    }

} else {
    Write-Host "PART 1 skipped."
}


# PART 2
$response2 = Read-Host "Do you want to install lively wallpaper for desktop mod ? (yes/no)"
if ($response2.ToLower() -eq "yes") {
    Write-Host "`nRunning PART 2..."

    # 1. Install Lively Wallpaper via winget
    Write-Host "Installing Lively Wallpaper..."
    try {
        winget install --id rocksdanister.LivelyWallpaper -e --source winget -h
    } catch {
        Write-Host "Error during Lively Wallpaper installation: $_"
    }

    # 2. Create 'Wallpapers' folder inside Videos
    $videosPath = [Environment]::GetFolderPath('MyVideos')
    $wallpapersPath = Join-Path $videosPath 'Wallpapers'

    if (-Not (Test-Path $wallpapersPath)) {
        Write-Host "Creating Wallpapers folder: $wallpapersPath"
        New-Item -Path $wallpapersPath -ItemType Directory | Out-Null
    } else {
        Write-Host "Wallpapers folder already exists: $wallpapersPath"
    }

} else {
    Write-Host "PART 2 skipped."
}
