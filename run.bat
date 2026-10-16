@echo off
setlocal
set "HERE=%~dp0"
if not exist "%HERE%build\port\bin\sotc.exe" (
    echo The game has not been built yet. Run setup.bat first: it verifies
    echo your disc image, builds everything and offers to start the game.
    pause
    exit /b 1
)
"%HERE%build\port\bin\sotc.exe" %*
