@echo off
REM -----------------------------------------------------------------------------
REM
REM   Title : romgen.bat
REM   COPYRIGHT (C) 2009 WebPHY
REM    _       __     __    ____  __  ____  __  
REM   | |     / /__  / /_  / __ \/ / / /\_\/_/  
REM   | | /| / / _ \/ __ \/ /_/ / /_/ /  \__/   
REM   | |/ |/ /  __/ /_/ / ____/ __  /   / /    
REM   |__/|__/\___/_.___/_/   /_/ /_/   /_/  
REM  
REM   All rights reserved.
REM  
REM -----------------------------------------------------------------------------
REM This batch file calls the romgen perl script and halts on errors if they occur.

cd ../web/html || goto :error
perl ../../scripts/romgen.pl index.html ../../src/webram.vhd  ../../out/webupdate.txt || goto :error

cd ../../scripts || goto :error

goto :EOF
:error
echo Failed with error #%errorlevel%.
cd ../../scripts
exit /b %errorlevel%
