# BASIC816 Implementation Check List and Status

## System Tasks

1. [X] Add a BREAK/Interrupt key
1. [X] Move BASIC code to higher memory
1. [X] Update ADDLINE to handle out of order entry
1. [ ] Flesh out division for other systems
1. [ ] Implement the garbage collector
1. [ ] Implement floating points
1. [ ] Update screen.s scrolling once DMA is available
1. [ ] Update screen.s scrolling to work with multiple text screen sizes
1. [ ] Update io_c256.s once kernel is finalized
1. [ ] Remove RESET vector once C256 is “done” or the interpreter is folded into the kernel ROM

## Statements

1. [ ] Flesh out other forms of IF THEN ELSE
1. [ ] Expand PRINT to support FLOATS and other types?
1. [ ] BEGIN / BEND
1. [ ] CLOSE
1. [X] CLR
1. [ ] DATA
1. [ ] DEF FN
1. [ ] DIM
1. [ ] DO loops
1. [X] FOR / NEXT
1. [ ] GET
1. [ ] GET#
1. [ ] INPUT
1. [ ] INPUT#
1. [ ] ON … GOTO
1. [ ] OPEN
1. [ ] POKE / WPOKE
1. [ ] PRINT#
1. [ ] READ
1. [X] REM
1. [ ] RESTORE
1. [X] STOP
1. [ ] SYS

## Operators

1. [x] AND
1. [x] OR
1. [x] NOT

## Functions

1. [ ] ABS
1. [ ] ASC
1. [ ] CHR$
1. [ ] COS
1. [ ] DEC
1. [ ] EXP
1. [ ] FN
1. [ ] FRE
1. [ ] HEX$
1. [ ] INT
1. [ ] LEFT$
1. [ ] LEN
1. [ ] LOG
1. [ ] MID$
1. [ ] PEEK() / WPEEK()
1. [ ] RIGHT$
1. [ ] RND
1. [ ] SGN
1. [ ] SIN
1. [ ] SPC
1. [ ] SQR
1. [ ] STATUS
1. [ ] STR$
1. [ ] TAB
1. [ ] TAN
1. [ ] TIME
1. [ ] TIME$
1. [ ] USR
1. [ ] VAL

## Commands

1. [ ] LIST
    1. [ ] Support line target ranges
1. [ ] CONT
1. [ ] LOAD
1. [ ] SAVE
