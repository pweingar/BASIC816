@echo off

REM Generate a version file
python genver.py

REM The name portion of the top source file and all generated files
set SOURCE=basic816

REM The location of 64TASS
set TASSHOME=d:\64tass\64tass-1.55.2200

REM 1 = C64 with SuperCPU, 2 = C256
set SYSTEM=2

REM 0 = Interactive, 1 = Generate Unit Tests
set UNITTEST=0

REM 0 = No tracing information, 1 = Include subroutine names, 2 = Generate trace messages
set TRACE_LEVEL=0

REM Make for the U

REM C256 Foenix SKU: 1 = FMX/U+, 2 = User
set C256_SKU=2

set OPTS=-D SYSTEM=%SYSTEM% -D C256_SKU=%C256_SKU% -D UARTSUPPORT=%UART% -D UNITTEST=%UNITTEST% -D TRACE_LEVEL=%TRACE_LEVEL% --long-address --flat -b
set AUXFILES1A=--list=%SOURCE%_1A0000.lst --labels=%SOURCE%_1A0000.lbl
set DESTHEX1A=--m65816 --intel-hex -o %SOURCE%_1A0000.hex
set DESTBIN1A=--m65816  -b -o %SOURCE%_1A0000.bin

set AUXFILES3A=--list=%SOURCE%_3A0000.lst --labels=%SOURCE%_3A0000.lbl
set DESTHEX3A=--m65816 --intel-hex -o %SOURCE%_3A0000.hex
set DESTBIN3A=--m65816  -b -o %SOURCE%_3A0000.bin

%TASSHOME%\64tass %OPTS% %DESTBIN1A% %AUXFILES1A% src\%SOURCE%.s
%TASSHOME%\64tass %OPTS% %DESTHEX1A% %AUXFILES1A% src\%SOURCE%.s

REM Make for the FMX and U+

REM C256 Foenix SKU: 1 = FMX/U+, 2 = User
set C256_SKU=1
set OPTS=-D SYSTEM=%SYSTEM% -D C256_SKU=%C256_SKU% -D UARTSUPPORT=%UART% -D UNITTEST=%UNITTEST% -D TRACE_LEVEL=%TRACE_LEVEL% --long-address --flat -b

%TASSHOME%\64tass %OPTS% %DESTBIN3A% %AUXFILES3A% src\%SOURCE%.s
%TASSHOME%\64tass %OPTS% %DESTHEX3A% %AUXFILES3A% src\%SOURCE%.s