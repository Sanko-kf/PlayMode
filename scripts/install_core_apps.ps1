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

# 7. Download, extract, and install JoyXoff
$joyxoffUrl = "https://joyxoff.com/download.php?culture=en&version=3.64.8.4"
$rarPath = "$env:TEMP\JoyXoff.rar"
$extractPath = "$env:TEMP\JoyXoff_Extracted"
$sevenZipInstallerUrl = "https://www.7-zip.org/a/7z2301-x64.exe"
$sevenZipInstallerPath = "$env:TEMP\7zip_installer.exe"
$sevenZipPath = "${env:ProgramFiles}\7-Zip\7z.exe"

function Ensure-SevenZip {
    if (-Not (Test-Path $sevenZipPath)) {
        Write-Host "7-Zip not found. Downloading and installing 7-Zip..."
        Invoke-WebRequest -Uri $sevenZipInstallerUrl -OutFile $sevenZipInstallerPath
        Start-Process -FilePath $sevenZipInstallerPath -ArgumentList "/S" -Wait
    } else {
        Write-Host "7-Zip is already installed."
    }
}

Write-Host "`n Downloading JoyXoff RAR..."
Invoke-WebRequest -Uri $joyxoffUrl -OutFile $rarPath

Ensure-SevenZip

if (!(Test-Path -Path $extractPath)) {
    New-Item -ItemType Directory -Path $extractPath | Out-Null
}

Write-Host "Extracting JoyXoff using 7-Zip..."
& "$sevenZipPath" x $rarPath "-o$extractPath" -y | Out-Null

$msiPath = Get-ChildItem -Path $extractPath -Filter *.msi -Recurse | Select-Object -First 1

if ($msiPath) {
    Write-Host " Installing JoyXoff..."
    Start-Process "msiexec.exe" -ArgumentList "/i `"$($msiPath.FullName)`"" -Wait
} else {
    Write-Host " MSI not found in extracted JoyXoff archive."
}


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
