# BASIC816 Implementation Check List and Status

## System Tasks

1. [X] Add a BREAK/Interrupt key
1. [X] Move BASIC code to higher memory
1. [X] Update ADDLINE to handle out of order entry
1. [ ] Move key functions to a modifiable vector table
    1. [ ] READLINE
    1. [ ] PUTC
    1. [ ] LOCATE
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
1. [X] CLR
1. [X] CLS
1. [ ] DATA
1. [ ] DEF FN
1. [ ] DIM
1. [ ] DO loops
1. [X] FOR / NEXT
1. [ ] ON … GOTO
1. [X] POKE
    1. [X] POKEW
1. [ ] READ
1. [X] REM
1. [ ] RESTORE
1. [X] STOP
1. [ ] SYS
1. [ ] I/O
    1. [ ] CLOSE
    1. [ ] GET
    1. [ ] GET#
    1. [ ] INPUT
    1. [ ] INPUT#
    1. [ ] OPEN
    1. [ ] PRINT#

## Operators

1. [x] AND
1. [x] OR
1. [x] NOT
1. [ ] Comparisons
    1. [X] =
    1. [X] <
    1. [X] <=
    1. [X] >
    1. [X] >=
    1. [X] <>
1. [ ] String +

## Functions

1. [ ] Floating Point Functions
    1. [ ] COS
    1. [ ] EXP
    1. [ ] INT
    1. [ ] LOG
    1. [ ] RND
    1. [ ] SIN
    1. [ ] SQR
    1. [ ] TAN
1. [ ] String Functions
    1. [X] ASC
    1. [X] CHR$
    1. [ ] HEX$
    1. [ ] LEFT$
    1. [X] LEN
    1. [ ] MID$
    1. [ ] RIGHT$
    1. [X] SPC
    1. [ ] STR$
    1. [X] TAB
    1. [ ] TIME$
    1. [ ] VAL
1. [ ] Other Functions
    1. [X] ABS
    1. [ ] DEC
    1. [ ] FN
    1. [ ] FRE
    1. [X] PEEK()
        1. [X] PEEKW()
    1. [X] SGN
    1. [ ] STATUS
    1. [ ] TIME
    1. [ ] USR

## Commands

1. [ ] LIST
    1. [ ] Support line target ranges
1. [ ] CONT
1. [ ] I/O Commands
    1. [ ] LOAD
    1. [ ] SAVE
    1. [ ] DIR
    1. [ ] DEL