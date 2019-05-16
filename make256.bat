@echo off
set TASSHOME=d:\c64\64tass

%TASSHOME%\64tass -D SYSTEM=2 -D UNITTEST=1 -D TRACE_LEVEL=0 --long-address --flat  -b --intel-hex -o basic816.hex --list=basic816.lst --labels=basic816.lbl src\basic816.s
