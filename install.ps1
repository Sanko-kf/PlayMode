function Show-Menu {
    Clear-Host
    Write-Host "==== PlayMode Installer ===="
    Write-Host "1. Add user"
    Write-Host "2. Installation"
    Write-Host "3. Handheld Device"
    Write-Host "4. Quit"
    Write-Host ""
}

function Run-Script-As-Admin {
    param (
        [string]$ScriptName
    )

    $scriptPath = Join-Path -Path (Join-Path $PSScriptRoot "temp") -ChildPath $ScriptName

    if (Test-Path $scriptPath) {
        Write-Host "`nLaunching $ScriptName as administrator..."
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy", "Bypass", "-File", "`"$scriptPath`"" -Verb RunAs -Wait
    } else {
        Write-Host "`nScript not found: $scriptPath"
        Pause
    }
}

do {
    Show-Menu
    $choice = Read-Host "Select an option (1-4)"

    switch ($choice) {
        "1" {
            $tempDir = Join-Path $PSScriptRoot "temp"
            if (-not (Test-Path $tempDir)) {
                New-Item -ItemType Directory -Path $tempDir | Out-Null
            }

            Invoke-WebRequest "https://raw.githubusercontent.com/Sanko-kf/PlayMode/main/scripts/user_setup.ps1" ` -OutFile (Join-Path $tempDir "user_setup.ps1")
            
            Run-Script-As-Admin "user_setup.ps1"

            Write-Host "`nRebooting in 5 seconds..."
            Start-Sleep -Seconds 5
            Restart-Computer -Force
        }
        "2" {
            $tempDir = Join-Path $PSScriptRoot "temp"
            if (-not (Test-Path $tempDir)) {
                New-Item -ItemType Directory -Path $tempDir | Out-Null
            }

            Invoke-WebRequest "https://raw.githubusercontent.com/Sanko-kf/PlayMode/main/scripts/system_optimization.ps1" ` -OutFile (Join-Path $tempDir "system_optimization.ps1")
            Invoke-WebRequest "https://raw.githubusercontent.com/Sanko-kf/PlayMode/main/scripts/install_core_apps.ps1" ` -OutFile (Join-Path $tempDir "install_core_apps.ps1")
            Invoke-WebRequest "https://raw.githubusercontent.com/Sanko-kf/PlayMode/main/scripts/visual_optimization.ps1" ` -OutFile (Join-Path $tempDir "visual_optimization.ps1")
            Invoke-WebRequest "https://raw.githubusercontent.com/Sanko-kf/PlayMode/main/scripts/taskbar.ps1" ` -OutFile (Join-Path $tempDir "taskbar.ps1")
            Invoke-WebRequest "https://raw.githubusercontent.com/Sanko-kf/PlayMode/main/scripts/desktop.ps1" ` -OutFile (Join-Path $tempDir "desktop.ps1")
            Invoke-WebRequest "https://raw.githubusercontent.com/Sanko-kf/PlayMode/main/scripts/optional_apps.ps1" ` -OutFile (Join-Path $tempDir "optional_apps.ps1")
            Invoke-WebRequest "https://raw.githubusercontent.com/Sanko-kf/PlayMode/main/scripts/shell.ps1" ` -OutFile (Join-Path $tempDir "shell.ps1")

            Run-Script-As-Admin "system_optimization.ps1"
            Run-Script-As-Admin "install_core_apps.ps1"
            Run-Script-As-Admin "visual_optimization.ps1"
            Run-Script-As-Admin "taskbar.ps1"
            Run-Script-As-Admin "desktop.ps1"
            Run-Script-As-Admin "optional_apps.ps1"
            Run-Script-As-Admin "shell.ps1"
        }
        "3" {
            $tempDir = Join-Path $PSScriptRoot "temp"
            if (-not (Test-Path $tempDir)) {
                New-Item -ItemType Directory -Path $tempDir | Out-Null
            }

            Invoke-WebRequest `
                "https://raw.githubusercontent.com/Sanko-kf/PlayMode/main/scripts/handheld_device.ps1" `
                -OutFile (Join-Path $tempDir "handheld_device.ps1")

            Run-Script-As-Admin "handheld_device.ps1"
        }
        "4" {
            Write-Host "`nBefore rebooting:"
            Write-Host "- Make sure you've enabled auto-arrange icons on the desktop."
            Write-Host "- Add any desired launchers to the desktop (e.g. Battle.net, Epic, etc.)."
            Write-Host "- Pin any useful apps to the taskbar (e.g. Steam, File Explorer)."
            Write-Host ""
            Read-Host "Press ENTER when you're ready to reboot..."
            Restart-Computer -Force
        }
    }
} while ($choice -ne "4")
