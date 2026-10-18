@echo off
setlocal
cd /d "%~dp0"
if not exist "sotc.exe" (
    echo sotc.exe is missing. Extract the entire release ZIP before playing.
    pause
    exit /b 1
)
echo Shadow of the Colossus - experimental PC port
echo Put your SCES-53326 v1.00 PAL ISO in the Game folder.
echo You can also drag an ISO onto Play.bat or pass its path as an argument.
echo.
"%~dp0sotc.exe" %*
set "GAME_EXIT=%ERRORLEVEL%"
if "%GAME_EXIT%"=="0" exit /b 0
echo.
echo The game exited with code %GAME_EXIT%. Check the message above.
echo This build needs the Europe/Australia SCES-53326 v1.00 disc.
echo See README.txt for requirements and troubleshooting.
pause
exit /b %GAME_EXIT%
