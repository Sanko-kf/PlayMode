import subprocess
import os

# Get the path to the user's LOCALAPPDATA folder
local_appdata = os.environ.get("LOCALAPPDATA")

# Build the full path to Playnite's Fullscreen executable
playnite_path = os.path.join(local_appdata, "Playnite", "Playnite.FullscreenApp.exe")

# Launch Playnite in Fullscreen Mode (non-blocking)
subprocess.Popen([playnite_path])
