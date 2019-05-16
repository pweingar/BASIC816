@echo off
SET VICEHOME=D:\c64\WinVICE-3.1-x86
SET DEBUG_FILE=z:\projects\basic816\debug.txt
del basic816.d64
del %DEBUG_FILE%

%VICEHOME%\c1541 -format "test,1" d64 basic816.d64
%VICEHOME%\c1541 -attach basic816.d64 -write basic816.prg basic816
%VICEHOME%\xscpu64 -iecdevice4 -device4 1 -pr4drv ascii -pr4txtdev 0 -prtxtdev1 %DEBUG_FILE% -moncommands basic816.cmd basic816.d64
