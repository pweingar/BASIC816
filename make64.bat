@echo off
set TASSHOME=d:\c64\64tass
rem cl65 -t c64 -C c64-asm.cfg -u __EXEHDR__ -o forth816.prg -Ln forth816.lbl -l forth816.lst src\forth816.s

%TASSHOME%\64tass -D SYSTEM=1 -D UNITTEST=1 -D TRACE_LEVEL=2 -o basic816.prg --vice-labels -l basic816.lbl --list=basic816.lst src\basic816.s
