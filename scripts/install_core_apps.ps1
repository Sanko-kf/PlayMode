# Relaunch script as administrator if not already running in admin mode
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Warning "Script is not running as administrator. Relaunching with elevated privileges..."
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell -Verb runAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    exit
}

# Create a temporary working directory
$temp = "$env:TEMP\PlayMode"
New-Item -ItemType Directory -Path $temp -Force | Out-Null

# 1. Download and install Steam
$steamUrl = "https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe"
$steamInstaller = "$temp\SteamSetup.exe"

Write-Host "Downloading Steam..."
Invoke-WebRequest -Uri $steamUrl -OutFile $steamInstaller

Write-Host "Installing Steam..."
Start-Process -FilePath $steamInstaller -ArgumentList "/SILENT" -Wait

Read-Host "Please complete Steam setup and sign-in. Press ENTER to continue..."

# 2. Install Xbox app via Winget
Write-Host "Installing Xbox App..."
Start-Process "winget" -ArgumentList "install --id Microsoft.XboxApp --silent --accept-package-agreements --accept-source-agreements" -Wait

Write-Host "Launching Xbox App..."
Start-Process "ms-windows-store://pdp/?productid=9MV0B5HZVK9Z"

Read-Host "Please complete Xbox setup and sign-in. Press ENTER to continue..."

# 3. Download and install Playnite
$playniteUrl = "https://playnite.link/download/PlayniteInstaller.exe"
$playniteInstaller = "$temp\PlayniteInstaller.exe"

Write-Host "Downloading Playnite..."
Invoke-WebRequest -Uri $playniteUrl -OutFile $playniteInstaller

Write-Host "Installing Playnite..."
Start-Process -FilePath $playniteInstaller -ArgumentList "/SILENT" -Wait

Read-Host "Please configure Playnite before continuing. Press ENTER when ready..."

# 4. Download custom "Return to Playnite" shortcut to the desktop
$exeUrl = "https://raw.githubusercontent.com/Sanko-kf/PlayMode/main/builds/Return%20to%20Playnite.exe"
$desktopPath = [Environment]::GetFolderPath("Desktop")
$exePath = Join-Path $desktopPath "Return to Playnite.exe"

Write-Host "Downloading custom Playnite shortcut..."
Invoke-WebRequest -Uri $exeUrl -OutFile $exePath

Write-Host "Custom Playnite shortcut placed on desktop."

# 5. Download and install Firefox
$firefoxUrl = "https://download.mozilla.org/?product=firefox-latest&os=win64&lang=fr"
$firefoxInstaller = "$temp\FirefoxSetup.exe"

Write-Host "Downloading Firefox..."
Invoke-WebRequest -Uri $firefoxUrl -OutFile $firefoxInstaller

Write-Host "Installing Firefox..."
Start-Process -FilePath $firefoxInstaller -ArgumentList "/S" -Wait

# 6. Install Xbox Accessories app
Write-Host "Installing Xbox Accessories App..."
Start-Process "winget" -ArgumentList "install --id Microsoft.XboxAccessories --silent --accept-package-agreements --accept-source-agreements" -Wait

Write-Host "Launching Xbox Accessories App..."
Start-Process "ms-windows-store://pdp/?productid=9NBLGGH30XJ3"

Read-Host "Please configure Xbox Accessories or any third-party tools (e.g. Lossless Scaling, keyboard shortcuts). Press ENTER when ready..."

# 7. Open Controller Companion download page (manual install)
Write-Host "Opening itch.io page for Controller Companion..."
Start-Process "https://kogatech.itch.io/controller-companion"

Read-Host "After installing Controller Companion and configuring all apps, press ENTER to continue..."

# 8. Enable fullscreen startup for Playnite
$configPath = "$env:APPDATA\Playnite\config.json"
if (Test-Path $configPath) {
    $json = Get-Content $configPath | ConvertFrom-Json
    $json.StartInFullscreen = $true
    $json | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath -Encoding UTF8
    Write-Host "Playnite is now configured to launch in fullscreen mode."
} else {
    Write-Warning "Playnite config not found. Please launch Playnite at least once manually."
}
