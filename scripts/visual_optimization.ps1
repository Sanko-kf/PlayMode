# Relaunch as administrator if not already elevated
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Warning "Script is not running as administrator. Relaunching with elevated privileges..."
    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell -Verb runAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    exit
}

# Pin Recycle Bin to Quick Access
$recycleBin = "::{645FF040-5081-101B-9F08-00AA002F954E}"
$shell = New-Object -ComObject Shell.Application
$folder = $shell.Namespace($recycleBin)
$folder.Self.InvokeVerb("p&in to Quick access")
Write-Host "Recycle Bin pinned to Quick Access."

# Hide Recycle Bin icon from desktop
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" `
                 -Name "{645FF040-5081-101B-9F08-00AA002F954E}" `
                 -Value 1
Write-Host "Recycle Bin icon hidden from desktop."

# Apply dark mode (apps + system)
Write-Host "Enabling dark mode..."
try {
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Force
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Force
    Write-Host "Dark mode enabled successfully."
} catch {
    Write-Warning "Failed to apply dark mode: $_"
}

# Open Personalization settings and wait for user input
Start-Process "control.exe" -ArgumentList "/name Microsoft.Personalization /page pageWallpaper"
Write-Host ""
Write-Host ">>> Personalization settings are now open."
Write-Host ">>> Please manually apply your desired theme (e.g. 'dark.theme')."
Write-Host ">>> Once done, return here and press ENTER to continue..."
Read-Host

# Enable window animations
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class NativeMethods {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, ref bool lpvParam, int fuWinIni);
}
"@

$enableAnimations = $true
[NativeMethods]::SystemParametersInfo(0x1043, 0, [ref]$enableAnimations, 0x03) | Out-Null

Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value 1
Write-Host "Window animations enabled (open/close, minimize/maximize)."

# Restart File Explorer to apply settings
Stop-Process -Name explorer -Force
Start-Process explorer

# Cursor theme setup
$sourceFolder = "$env:USERPROFILE\Documents\Cursor\dark"
$themeName = "MyTheme"
$destFolder = "C:\Windows\Cursors\$themeName"
$baseUrl = "https://raw.githubusercontent.com/Sanko-kf/PlayMode/main/assets/Cursor/dark"

# Create the folder if it doesn't exist
if (-not (Test-Path $sourceFolder)) {
    New-Item -Path $sourceFolder -ItemType Directory -Force | Out-Null
    Write-Host "Created folder: $sourceFolder"
} else {
    Write-Host "Folder already exists: $sourceFolder"
}

# List of files to download
$files = @(
    "Install.inf", "appstarting.ani", "arrow.cur", "crosshair.cur", "hand.cur",
    "help.cur", "ibeam.cur", "no.cur", "nwpen.cur", "person.cur",
    "pin.cur", "sizeall.cur", "sizenesw.cur", "sizens.cur", "sizenwse.cur",
    "sizewe.cur", "uparrow.cur", "wait.ani"
)

# Download each file
$files | ForEach-Object {
    $url = "$baseUrl/$_"
    $destination = Join-Path $sourceFolder $_

    try {
        Invoke-WebRequest -Uri $url -OutFile $destination -UseBasicParsing -ErrorAction Stop
        Write-Host "Downloaded: $_"
    } catch {
        Write-Warning "Failed to download: $_"
    }
}

# Cursor file mapping
$cursorMap = @{
    "Arrow"       = "arrow.cur"
    "Help"        = "help.cur"
    "Wait"        = "wait.ani"
    "IBeam"       = "ibeam.cur"
    "No"          = "no.cur"
    "SizeNS"      = "sizenesw.cur"
    "SizeWE"      = "sizewe.cur"
    "SizeNWSE"    = "sizenwse.cur"
    "SizeNE-SW"   = "sizens.cur"
    "UpArrow"     = "uparrow.cur"
    "Hand"        = "hand.cur"
}

# Copy cursor files to system folder
if (-not (Test-Path $destFolder)) {
    New-Item -ItemType Directory -Path $destFolder | Out-Null
}
foreach ($file in $cursorMap.Values) {
    $src = Join-Path $sourceFolder $file
    $dst = Join-Path $destFolder $file
    if (Test-Path $src) {
        Copy-Item $src -Destination $dst -Force
    } else {
        Write-Warning "Missing cursor file: $src"
    }
}

# Set registry entries for custom cursor theme
$regPath = "HKCU:\Control Panel\Cursors"
foreach ($key in $cursorMap.Keys) {
    $filename = $cursorMap[$key]
    Set-ItemProperty -Path $regPath -Name $key -Value "$destFolder\$filename"
}
Set-ItemProperty -Path $regPath -Name "Scheme Source" -Value 1
Set-ItemProperty -Path $regPath -Name "(Default)" -Value $themeName

# Apply the cursor theme
Start-Sleep -Milliseconds 500
[NativeMethods]::SystemParametersInfo(0x57, 0, $themeName, 0x03) | Out-Null

Write-Host ""
Write-Host "Custom cursor theme applied successfully."
