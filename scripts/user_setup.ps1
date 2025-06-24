# Relaunch script as administrator if not already running in admin mode
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Warning "Script is not running as administrator. Relaunching with elevated privileges..."

    $scriptPath = $MyInvocation.MyCommand.Path
    Start-Process powershell -Verb runAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    exit
}

# Prompt for new local admin user credentials
Write-Host "Creating a new local administrator account..."

$username = Read-Host "Enter the username for the new local account"
$password = Read-Host "Enter a password for $username" -AsSecureString

# Try to create the user and add to Administrators group
try {
    New-LocalUser -Name $username -Password $password -FullName $username -Description "Local admin account for PLayMode setup" -PasswordNeverExpires
    Add-LocalGroupMember -Group "Administrators" -Member $username
    Write-Host "User '$username' has been successfully created and added to the Administrators group."
} catch {
    Write-Error "An error occurred while creating the user: $_"
    exit 1
}

# Set download and extraction paths for Sysinternals AutoLogon tool
$autologonUrl = "https://download.sysinternals.com/files/AutoLogon.zip"
$downloadPath = "$env:TEMP\AutoLogon.zip"
$extractPath = "$env:TEMP\AutoLogon"

# Download and extract AutoLogon if not already present
if (-Not (Test-Path $extractPath)) {
    Write-Host "Downloading Sysinternals AutoLogon tool..."
    Invoke-WebRequest -Uri $autologonUrl -OutFile $downloadPath
    Expand-Archive -Path $downloadPath -DestinationPath $extractPath
}

# Locate and launch Autologon.exe for manual configuration
$autologonExe = Join-Path $extractPath "Autologon.exe"
if (Test-Path $autologonExe) {
    Write-Host "Launching AutoLogon for manual configuration. Please follow the prompts..."
    Start-Process -FilePath $autologonExe -Verb runAs -Wait
    Write-Host "AutoLogon configuration complete. Script has finished."
} else {
    Write-Warning "Could not locate Autologon.exe in the extracted directory."
}
