# 1. Remove all currently pinned taskbar shortcuts
Remove-Item "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*" -Force -Recurse -ErrorAction SilentlyContinue
Remove-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" -Recurse -Force -ErrorAction SilentlyContinue

# 2. Restart Explorer to refresh taskbar display
Stop-Process -Name explorer -Force
Start-Process explorer

# 3. Download pttb.exe if not already present
$pttbUrl = "https://github.com/0x546F6D/pttb_-_Pin_To_TaskBar/releases/download/230124/pttb.exe"
$pttbPath = "$env:TEMP\pttb.exe"

if (-Not (Test-Path $pttbPath)) {
    Write-Host "Downloading pttb.exe..."
    Invoke-WebRequest -Uri $pttbUrl -OutFile $pttbPath
    Write-Host "pttb.exe downloaded successfully."
}

# 4. Define the list of applications to pin (excluding Settings, etc.)
$appsToPin = @(
    @{ Name = "File Explorer"; Path = "C:\Windows\explorer.exe" },
    @{ Name = "Firefox"; Path = "C:\Program Files\Mozilla Firefox\firefox.exe" }
)

# 5. Pin applications in defined order
foreach ($app in $appsToPin) {
    if (Test-Path $app.Path) {
        Write-Host "Pinning $($app.Name)..."
        Start-Process -FilePath $pttbPath -ArgumentList "`"$($app.Path)`" --pin" -Wait
    } else {
        Write-Warning "$($app.Name) not found at path: $($app.Path)"
    }
}

Write-Host "All applications have been pinned to the taskbar in the specified order."
