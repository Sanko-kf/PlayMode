# Relaunch script as administrator if not already running with admin rights
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Warning "Script is not running as administrator. Relaunching with elevated privileges..."
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell -Verb runAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    exit
}

function Open-WindowsDefenderExclusions {
    Write-Host "Opening Windows Defender to the threat management page..."
    Start-Process "windowsdefender://threat"
    Start-Sleep -Seconds 2
    Write-Host "`nIn Windows Defender:"
    Write-Host "1. Click on 'Virus & threat protection settings'"
    Write-Host "2. Then click on 'Manage settings'"
    Write-Host "3. Scroll down and click 'Add or remove exclusions'"
    Write-Host "4. Add drive C: as a folder exclusion"
    Write-Host "`nPress Enter once done..."
    Read-Host
}

function Download-And-Run-Talon {
    $talonUrl = "https://code.ravendevteam.org/talon/talon.zip"
    $tempZip = "$env:TEMP\talon.zip"
    $extractPath = "$env:TEMP\talon"

    Write-Host "Downloading Talon..."
    Invoke-WebRequest -Uri $talonUrl -OutFile $tempZip

    Write-Host "Extracting Talon..."
    Expand-Archive -Path $tempZip -DestinationPath $extractPath -Force

    $exePath = Get-ChildItem -Path $extractPath -Filter *.exe -Recurse | Select-Object -First 1

    if ($null -eq $exePath) {
        Write-Error "Could not find the .exe file in the Talon archive."
        return
    }

    Write-Host "`n !!! DO NOT TOUCH ANYTHING during the Talon installation !!!"
    Write-Host "Installation will proceed automatically."
    Write-Host "Press Enter once it finishes installing."
    Start-Process -FilePath $exePath.FullName -Wait
    Read-Host
}

function Ask-To-Remove-C {
    Write-Host "`nReopening Windows Defender to remove the C: drive from exclusions..."
    Start-Process "windowsdefender://threat"
    Start-Sleep -Seconds 2
    Write-Host "`nManually remove the C: drive from the exclusions list."
    Write-Host "Press Enter to continue..."
    Read-Host
}

# Main script starts here
Write-Host "Do you want to perform a deep debloat? (recommended) [Y/N]: " -NoNewline
$choice = Read-Host

if ($choice -match '^[oOyY]$') {
    Open-WindowsDefenderExclusions
    Download-And-Run-Talon
    Ask-To-Remove-C
}

# Enable hibernation
powercfg -hibernate on

# Power settings for battery and plugged-in modes
powercfg /change standby-timeout-dc 1         # Sleep after 1 min on battery
powercfg /change hibernate-timeout-dc 3       # Hibernate after 3 min on battery
powercfg /change standby-timeout-ac 1         # Sleep after 1 min when plugged in
powercfg /change hibernate-timeout-ac 3       # Hibernate after 3 min when plugged in

# Disable hybrid sleep
powercfg /setacvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0
powercfg /setdcvalueindex SCHEME_CURRENT SUB_SLEEP HYBRIDSLEEP 0

# Configure power button to trigger hibernation
$regPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\7516b95f-f776-4464-8c53-06167f40cc99\7648efa3-dd9c-4e3e-b566-50f929386280"
Set-ItemProperty -Path $regPath -Name "DCSettingIndex" -Value 3
Set-ItemProperty -Path $regPath -Name "ACSettingIndex" -Value 3

# Apply current power scheme
powercfg /S SCHEME_CURRENT

Write-Output "Power configuration applied: sleep, hibernate, power button now triggers hibernate."

# Download and launch HandheldCompanion
$url = "https://github.com/Valkirie/HandheldCompanion/releases/download/0.24.1.2/HandheldCompanion-0.24.1.2.exe"
$output = "$env:TEMP\HandheldCompanion-0.24.1.2.exe"

Write-Host "`nDownloading HandheldCompanion..."
Invoke-WebRequest -Uri $url -OutFile $output

Write-Host "Launching HandheldCompanion..."
Start-Process -FilePath $output

Write-Host "`nPress Enter to reboot your PC once the installation is complete..."
Read-Host

Write-Host "Rebooting now..."
Restart-Computer -Force
