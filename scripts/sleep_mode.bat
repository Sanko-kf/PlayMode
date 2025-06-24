@echo off
:: Path to the folder containing videos
set "videosFolder=%USERPROFILE%\Videos\SleepVideos"

:: Path to VLC player
set "vlcPath=C:\Program Files\VideoLAN\VLC\vlc.exe"

:: Launch VLC with the video folder in shuffle mode and fullscreen
start "" "%vlcPath%" --fullscreen --random --volume=128 "%videosFolder%"

:: End of script
exit /b