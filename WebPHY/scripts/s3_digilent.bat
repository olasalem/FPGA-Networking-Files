@echo off
REM -----------------------------------------------------------------------------
REM
REM   Title : s3_digilent.bat
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
REM This batch file builds an example FPGA project targeted for the Digilent 
REM "Spartan-3 Starter Kit".

echo Starting s3_digilent.bat...

echo Setting Xilinx vars...
call C:\Xilinx\14.7\ISE_DS\settings64.bat || goto :error

echo Generating web page BRAM...
call romgen.bat || goto :error
del ..\syn\*.* /q || goto :error

echo Building the FPGA project...
copy s3_digilent.tcl ..\syn || goto :error
cd ..\syn || goto :error
xtclsh s3_digilent.tcl rebuild_project || goto :error

echo Downloading .bit file to FPGA and .mcs to PROM...
promgen -w -p mcs -c FF -u 0 s3_digilent.bit -o s3_digilent.mcs -x xcf04s || goto :error
impact -batch ..\scripts\s3_digilent.cmd || goto :error

echo Displaying timing results...
type *.twr || goto :error
Echo  || goto :error
cd ..\scripts || goto :error

echo Done

goto :EOF
:error
echo Failed with error #%errorlevel%.
cd ..\scripts
exit /b %errorlevel%
