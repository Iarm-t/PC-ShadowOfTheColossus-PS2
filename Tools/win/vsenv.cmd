@echo off
if defined VSROOT (
    if exist "%VSROOT%\VC\Auxiliary\Build\vcvars64.bat" goto vs_found
    echo VSROOT points at "%VSROOT%" but the C++ build tools were not found there.
    set "VSROOT="
)
if not exist "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" goto novs
for /f "usebackq delims=" %%P in (`call "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -version "[17.0,)" -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSROOT=%%P"
if not defined VSROOT goto novs
if not exist "%VSROOT%\VC\Auxiliary\Build\vcvars64.bat" goto novs
:vs_found
call "%VSROOT%\VC\Auxiliary\Build\vcvars64.bat" >nul
if errorlevel 1 goto nomsvc
if exist "%VSROOT%\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" set "PATH=%VSROOT%\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;%PATH%"
if exist "%VSROOT%\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja\ninja.exe" set "PATH=%VSROOT%\Common7\IDE\CommonExtensions\Microsoft\CMake\Ninja;%PATH%"
where /q cl.exe
if errorlevel 1 goto nomsvc
where /q rc.exe
if errorlevel 1 goto nosdk
where /q cmake.exe
if errorlevel 1 goto nocmake
where /q ninja.exe
if errorlevel 1 goto noninja
if "%~1"=="" exit /b 0
%*
exit /b %ERRORLEVEL%
:novs
echo MSVC C++ build tools from Visual Studio 2022 or newer were not found.
echo Install Visual Studio or standalone Build Tools with Desktop development with C++.
echo For a custom installation, set VSROOT to its installation directory.
exit /b 1
:nomsvc
echo Could not initialize the MSVC x64 compiler in "%VSROOT%".
echo Add or repair the Desktop development with C++ workload in Visual Studio Installer.
exit /b 1
:nosdk
echo Windows SDK tools were not found. Add a Windows 10 or 11 SDK in Visual Studio Installer.
exit /b 1
:nocmake
echo CMake was not found. Add C++ CMake tools for Windows in Visual Studio Installer,
echo or install CMake separately and add it to PATH.
exit /b 1
:noninja
echo Ninja was not found. Add C++ CMake tools for Windows in Visual Studio Installer,
echo or install Ninja separately and add it to PATH.
exit /b 1
