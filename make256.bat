@echo off

REM Generate a version file
python genver.py

REM The name portion of the top source file and all generated files
set SOURCE=basic816

REM The location of 64TASS
set TASSHOME=d:\64tass

REM 1 = C64 with SuperCPU, 2 = C256
set SYSTEM=2

REM C256 Foenix SKU: 1 = FMX, 2 = User
set C256_SKU=1

REM 0 = Interactive, 1 = Generate Unit Tests
set UNITTEST=0

REM 0 = No tracing information, 1 = Include subroutine names, 2 = Generate trace messages
set TRACE_LEVEL=0

set OPTS=-D SYSTEM=%SYSTEM% -D C256_SKU=%C256_SKU% -D UARTSUPPORT=%UART% -D UNITTEST=%UNITTEST% -D TRACE_LEVEL=%TRACE_LEVEL% --long-address --flat -b
set DEST=--m65816 --intel-hex -o %SOURCE%.hex
set AUXFILES=--list=%SOURCE%.lst --labels=%SOURCE%.lbl
set DESTBIN=--m65816  -b -o %SOURCE%.bin

%TASSHOME%\64tass %OPTS% %DESTBIN% %AUXFILES% src\%SOURCE%.s
%TASSHOME%\64tass %OPTS% %DEST% %AUXFILES% src\%SOURCE%.s
