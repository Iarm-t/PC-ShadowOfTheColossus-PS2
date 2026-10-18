@echo off
setlocal
set "HERE=%~dp0"
call "%HERE%Tools\win\vsenv.cmd" cmake "-DRELEASE_VERSION=%~1" -P "%HERE%Tools\package_release.cmake"
exit /b %ERRORLEVEL%
