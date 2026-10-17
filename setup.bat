@echo off
setlocal enableextensions enabledelayedexpansion
title Shadow of the Colossus - PC port setup
cd /d "%~dp0"

set "DISCSHA256=068925770645266189005f09c9a9a1fee25726bfc93c89b12f832f3673664ac4"
set "DISCSIZE=4635918336"

echo.
echo  ==================================================================
echo   Shadow of the Colossus - PC port setup
echo  ==================================================================
echo.
echo  This checks your system, verifies your game disc, builds the port
echo  and offers to start it. If something is missing it tells you what,
echo  waits for you to fix it and continues by itself.
echo  Keep this console open until it says Setup complete.
echo  Running it again is safe: finished steps are skipped or re-checked
echo  in seconds.
echo.

echo [1/6] Checking the recompiler sources...
if exist "External\PS2Recomp\ps2xRecomp\CMakeLists.txt" goto step1_ok
git --version >nul 2>&1
if errorlevel 1 (
    echo    Git is needed to fetch the PS2Recomp sources.
    echo    Install Git for Windows from https://git-scm.com/ or re-clone
    echo    the repository with "git clone --recursive", then run setup.bat
    echo    again.
    goto fail_user
)
echo    Fetching PS2Recomp - one-time download...
git submodule update --init --recursive
if errorlevel 1 (
    echo    Fetching the PS2Recomp sources failed. Check the error above and
    echo    your connection, then run setup.bat again.
    goto fail_user
)
echo    Done.
goto step2
:step1_ok
echo    Found.
:step2
echo [2/6] Checking Python...
python --version >nul 2>&1
if errorlevel 1 goto py_missing
set "PYVER="
for /f "tokens=2" %%v in ('python --version 2^>^&1') do set "PYVER=%%v"
if not defined PYVER goto py_missing
for /f "tokens=1,2 delims=." %%a in ("!PYVER!") do (
    if %%a GEQ 3 if %%b GEQ 10 goto py_ok
)
:py_missing
echo.
if defined PYVER echo    Python !PYVER! was found, but 3.10 or newer is required.
if not defined PYVER echo    Python was not found on PATH.
echo    The port needs Python 3.10 or newer to generate the game code from
echo    the disc image. Install it from https://www.python.org/downloads/
echo    and tick "Add python.exe to PATH" in the installer's first screen.
choice /c YN /n /m "    Install Python now, then press Y to continue, or N to quit? "
if errorlevel 2 goto fail_user
goto step2
:py_ok
echo    Found Python !PYVER!.
:step3
echo [3/6] Checking Visual Studio 2022...
call :find_vs
if defined VSROOT goto vs_ok
echo.
echo    Visual Studio 2022 with the "Desktop development with C++" workload
echo    is required to compile the port. It provides the MSVC compiler,
echo    CMake and Ninja. Install the free Community edition from
echo    https://visualstudio.microsoft.com/downloads/ and select that
echo    workload in the installer.
echo    If Visual Studio is installed in a custom folder, set the VSROOT
echo    environment variable to that folder and run setup.bat again.
choice /c YN /n /m "    Install it now, then press Y to continue, or N to quit? "
if errorlevel 2 goto fail_user
goto step3
:vs_ok
echo    Found "!VSROOT!".
:step4
echo [4/6] Checking the disc image...
if not exist "Game" mkdir "Game"
if not exist "build" mkdir "build"
:iso_scan
set "ISOPATH="
set "ISOFNAME="
set "ISOSIZE="
set /a ISOWRONG=0
for /f "delims=" %%f in ('dir /b "Game\*.iso" 2^>nul') do (
    if not defined ISOPATH call :try_iso "Game\%%f" "%%f"
)
if defined ISOPATH goto iso_ok
if not "!ISOWRONG!"=="0" goto iso_bad
echo.
echo    No disc image was found in the Game folder.
echo.
echo    Copy your Shadow of the Colossus disc image into Game\ as a file
echo    whose name ends in .iso. The port supports exactly one release:
echo.
echo        Shadow of the Colossus (Europe, Australia)
echo        SCES-53326, version 1.00 (PAL)
echo        4,635,918,336 bytes, about 4.3 GB
choice /c YN /n /m "    Try again? [Y/N] "
if errorlevel 2 goto fail_user
goto iso_scan
:iso_bad
echo.
echo    The Game folder does not contain the disc image this port needs.
echo    It runs exactly one build of the game:
echo.
echo        Shadow of the Colossus (Europe, Australia)
echo        SCES-53326, version 1.00 (PAL)
echo        4,635,918,336 bytes, about 4.3 GB
echo.
echo    Everything else is rejected - other regions such as the NTSC US or
echo    Japanese discs, later revisions (v1.10 and up), the PS3 and PS2
echo    re-releases, and any trimmed, re-packed or patched dump - because
echo    the recompiled code matches this one disc. Look for a single
echo    approximately 4.3 GB .iso file.
choice /c YN /n /m "    Try again? [Y/N] "
if errorlevel 2 goto fail_user
goto iso_scan
:iso_ok
echo    Verified "Game\!ISOFNAME!" - SHA-256 matches SCES-53326 v1.00.
:step5
call :build_busy
if not "!BUSY!"=="1" goto step5_go
echo    The build folder looks busy: another process is holding files in
echo    it - most likely a build running in another window, or an
echo    antivirus scan. Two processes cannot build in the same folder at
echo    once, and that is what usually causes a "Permission denied"
echo    error from ninja. Wait for the other build to finish, then try
echo    again.
choice /c YN /n /m "    Wait 5 seconds and try again? [Y/N] "
if errorlevel 2 goto fail
ping -n 6 127.0.0.1 >nul
goto step5
:step5_go
echo [5/6] Building the code recompiler - MSVC configure plus compile,
echo       a few minutes the first time...
call configure.bat
if errorlevel 1 goto fail
call build.bat ps2_recomp
if errorlevel 1 goto fail
:step6
echo [6/7] Building the port...
set "DOGEN=1"
call :need_generate
if not "!DOGEN!"=="1" goto gen_skip
echo     Generating game code from the disc image - thousands of C++
echo     files, this takes a few minutes...
call Tools\generate.bat
if errorlevel 1 goto fail
call :stamp_generated
echo     Game code generated. The recompiler's report above ("Recompilation
echo     completed successfully") only covers that generation; the port's
echo     own executable is compiled in the steps below.
echo     Re-configuring with the generated game code...
call configure.bat
if errorlevel 1 goto fail
goto gen_done
:gen_skip
echo     Generated game code is already current - skipping generation.
:gen_done
echo     Compiling the port now - up to an hour on the first build, only a
echo     few seconds afterwards. Do not close this console until Setup
echo     complete appears.
call build.bat
if errorlevel 1 goto fail
:step7
call :capture_step
if errorlevel 1 goto fail
echo.
echo  ==================================================================
echo   Setup complete.
echo  ==================================================================
echo.
echo   The game is ready at build\port\bin\sotc.exe.
echo   From now on, start it with run.bat or by running setup.bat again.
echo.
choice /c YN /n /m "   Start the game now? [Y/N] "
if errorlevel 2 exit /b 0
call run.bat
exit /b 0

:capture_step
if exist "Port\generated\vu1\vu1_programs.cpp" (
    echo     VU1 microcode programs already present - skipping capture.
    exit /b 0
)
if not exist "%ISOPATH%" (
    echo     No disc image available - skipping capture.
    exit /b 0
)
echo     Recording the disc's VU1 microcode once: the game runs by itself
echo     in the background with no window and no audio for up to a few
echo     rounds x 12 minutes, then the captured programs are compiled in.
echo     You can use this console meanwhile; do not close it though.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Tools\vu1_capture_setup.ps1" -Root "%~dp0." -IsoPath "%ISOPATH%"
if errorlevel 1 (
    echo     Capture did not complete: the game falls back to the software
    echo     VU1 interpreter in that case - playable but slower in some
    echo     scenes. Re-running setup.bat later continues where it stopped.
    exit /b 1
)
exit /b 0

:try_iso
set "TRYNAME=%~2"
if not "%~z1"=="%DISCSIZE%" (
    echo    Game\!TRYNAME!: wrong size, %~z1 bytes - skipping.
    set /a ISOWRONG+=1
    exit /b 0
)
call :hash_file "%~1" "%~z1" "%~2"
if not defined FILEHASH exit /b 0
if /i "!FILEHASH!"=="%DISCSHA256%" (
    set "ISOPATH=%~1"
    set "ISOFNAME=%~2"
    set "ISOSIZE=%~z1"
    exit /b 0
)
echo    Game\!TRYNAME!: right size, but the SHA-256 does not match
echo    SCES-53326 v1.00 - skipping.
set /a ISOWRONG+=1
exit /b 0

:hash_file
set "FILEHASH="
set "HNAME=%~3"
set "CNAME="
set "CSIZE="
set "CHASH="
if exist "build\iso_state.txt" for /f "usebackq delims=" %%L in ("build\iso_state.txt") do (
    if not defined CNAME (set "CNAME=%%L") else if not defined CSIZE (set "CSIZE=%%L") else if not defined CHASH set "CHASH=%%L"
)
if defined CHASH if /i "!CNAME!"=="%~3" if "!CSIZE!"=="%~2" (
    set "FILEHASH=!CHASH!"
    exit /b 0
)
echo    Verifying Game\!HNAME! against the supported release - reading
echo    about 4.3 GB, this takes around a minute and happens only once...
for /f "delims=" %%H in ('certutil -hashfile "%~1" SHA256 ^| find /v ":"') do set "FILEHASH=%%H"
if not defined FILEHASH (
    echo    Could not compute the SHA-256 of Game\!HNAME! - certutil failed.
    exit /b 0
)
(
echo !HNAME!
echo %~2
echo !FILEHASH!
)>"build\iso_state.txt"
exit /b 0

:need_generate
set "DOGEN=1"
if not exist "build\generated_state.txt" exit /b 0
if not exist "Port\generated\register_functions.cpp" exit /b 0
call :mtime "Port\recomp\sotc.toml" GMT1
call :mtime "Port\profile\SCES-53326_v1.00.json" GMT2
call :mtime "Tools\sotc_link.py" GMT3
set "GNAME="
set "GSIZE="
set "GMTS="
for /f "usebackq delims=" %%L in ("build\generated_state.txt") do (
    if not defined GNAME (set "GNAME=%%L") else if not defined GSIZE (set "GSIZE=%%L") else set "GMTS=!GMTS!;%%L"
)
if /i "!GNAME!"=="!ISOFNAME!" if "!GSIZE!"=="!ISOSIZE!" if "!GMTS!"==";!GMT1!;!GMT2!;!GMT3!" set "DOGEN=0"
exit /b 0

:stamp_generated
call :mtime "Port\recomp\sotc.toml" GMT1
call :mtime "Port\profile\SCES-53326_v1.00.json" GMT2
call :mtime "Tools\sotc_link.py" GMT3
(
echo !ISOFNAME!
echo !ISOSIZE!
echo !GMT1!
echo !GMT2!
echo !GMT3!
)>"build\generated_state.txt"
exit /b 0

:mtime
set "%~2=%~t1"
exit /b 0

:build_busy
set "BUSY=0"
if not exist "build\port\.ninja_log" exit /b 0
powershell -NoProfile -Command "try { [IO.File]::Open('build\port\.ninja_log','Open','ReadWrite','None').Close() } catch { exit 1 }"
if errorlevel 1 set "BUSY=1"
exit /b 0

:find_vs
if defined VSROOT (
    if exist "!VSROOT!\VC\Auxiliary\Build\vcvars64.bat" if exist "!VSROOT!\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" if exist "!VSROOT!\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe" exit /b 0
    echo    VSROOT points at "!VSROOT!" but the expected tools were not
    echo    found there - searching the usual install locations too.
    set "VSROOT="
)
for %%P in (
    "C:\Program Files\Microsoft Visual Studio\2022\Community"
    "C:\Program Files\Microsoft Visual Studio\2022\Professional"
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise"
    "C:\Program Files\Microsoft Visual Studio\2022\BuildTools"
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
) do if not defined VSROOT if exist "%%~P\VC\Auxiliary\Build\vcvars64.bat" if exist "%%~P\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" if exist "%%~P\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe" set "VSROOT=%%~P"
exit /b 0

:fail
echo.
echo  ------------------------------------------------------------------
echo   A step failed. Scroll up for the actual error and fix the cause.
echo   If the error mentions "Permission denied", the build folder was
echo   in use by another process while the step ran - wait for it to
echo   finish (or close it) before continuing. Completed steps are
echo   skipped or re-checked in seconds, so trying again is cheap.
echo  ------------------------------------------------------------------
choice /c YN /n /m "   Try again now? [Y/N] "
if errorlevel 2 goto fail_quit
ping -n 6 127.0.0.1 >nul
goto step5

:fail_quit
pause
exit /b 1

:fail_user
echo.
echo   Setup cannot continue without the item above. Run setup.bat again
echo   whenever you are ready.
pause
exit /b 1
