import subprocess
import time
import os

# Dynamic paths
userprofile = os.environ['USERPROFILE']
localappdata = os.environ['LOCALAPPDATA']

playnite_path = os.path.join(localappdata, "Playnite", "Playnite.FullscreenApp.exe")
explorer = "explorer.exe"

# Launch Playnite in fullscreen mode
subprocess.Popen([playnite_path], shell=False)

# Wait a few seconds to let Playnite fully initialize
time.sleep(20)

# Launch Windows Explorer (e.g., for taskbar refresh or file access)
subprocess.Popen([explorer], shell=False)
