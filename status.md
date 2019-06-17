# BASIC816 Implementation Check List and Status

## System Tasks

- [X] Move BASIC code to higher memory
- [ ] Update ADDLINE to handle out of order entry
- [ ] - [ ] Update io_c256.s once kernel is finalized
- [ ] Remove RESET vector once C256 is “done” or the interpreter is folded into the kernel ROM
- [ ] Update screen.s scrolling once DMA is available
- [ ] Update screen.s scrolling to work with multiple text screen sizes
- [ ] Flesh out division for other systems
- [ ] Implement the garbage collector
- [ ] Implement floating points
- [X] Add a BREAK/Interrupt key

## Statements

- [ ] Flesh out other forms of IF THEN ELSE
- [ ] Expand PRINT to support FLOATS and other types?
- [ ] DO loops
- [ ] POKE
- [ ] CLOSE
- [ ] CLR
- [ ] DATA
- [ ] DEF FN
- [ ] DIM
- [ ] GET
- [ ] GET#
- [ ] INPUT
- [ ] INPUT#
- [ ] ON … GOTO
- [ ] OPEN
- [ ] PRINT#
- [ ] READ
- [ ] REM
- [ ] RESTORE
- [ ] STOP
- [ ] SYS

## Operators

- [x] AND
- [x] NOT
- [x] OR

## Functions

- [ ] PEEK()
- [ ] ABS
- [ ] ASC
- [ ] CHR$
- [ ] COS
- [ ] EXP
- [ ] FN
- [ ] FRE
- [ ] INT
- [ ] LEFT$
- [ ] LEN
- [ ] LOG
- [ ] MID$
- [ ] WPEEK()
- [ ] WPOKE
- [ ] RIGHT$
- [ ] RND
- [ ] SGN
- [ ] SIN
- [ ] SPC
- [ ] SQR
- [ ] STATUS
- [ ] STR$
- [ ] TAB
- [ ] TAN
- [ ] TIME
- [ ] TIME$
- [ ] USR
- [ ] VAL

## Commands

- [ ] LIST
- [ ] CONT
- [ ] LOAD
- [ ] SAVE
