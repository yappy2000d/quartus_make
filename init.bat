@echo off

SET "QUARTUS_PATH=C:\altera\13.1\quartus"
SET "FAMILY=Cyclone IV E"
SET "DEVICE=EP4CE115F29C7"
SET "MODELSIM_PATH=C:\altera\13.1\modelsim_ase"
SET "SIM_LIBS=altera_ver cycloneive_ver"

@REM Prepend Quartus and ModelSim bin directories to PATH temporarily
SET "PATH=%QUARTUS_PATH%\bin64\cygwin\bin;%PATH%"   ; for make
SET "PATH=%QUARTUS_PATH%\bin;%PATH%"            ; for quartus_sh, quartus_map, etc.
SET "PATH=%MODELSIM_PATH%\win32aloem;%PATH%"    ; for vlog, vsim, etc.

powershell -Command "Invoke-WebRequest https://raw.githubusercontent.com/yappy2000d/quartus_make/refs/heads/main/Makefile -OutFile Makefile"

make initial