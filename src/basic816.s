;;;
;;; BASIC for the 65816 processor
;;;

.cpu "65816"

.include "constants.s"
.include "memorymap.s"
.include "macros.s"

.section code

.if SYSTEM == SYSTEM_C64
            ; Insert BASIC stub for C64 testing
            .word ss, 10
            .null $9e, format("%d", START)
ss          .word 0
.elsif SYSTEM == SYSTEM_C256
; Override RESET vector to point to the start of BASIC
.section vectors
RESTART     .word <>START
.send
.endif

.include "bios.s"
.include "utilities.s"
.include "tokens.s"
.include "heap.s"
.include "strings.s"
.include "listing.s"
.include "eval.s"
.include "returnstack.s"
.include "interpreter.s"
.include "operators.s"
.include "statements.s"
.include "commands.s"
.include "variables.s"

.if UNITTEST
.include "tests/basictests.s"
.endif

START       CLC                 ; Go to native mode
            XCE

            setdp GLOBAL_VARS
            setdbr `GLOBAL_VARS

            setaxl

            CALL INITBASIC

            setdbr `DATA_BLOCK
            LDX #<>GREET
            JSL PRINTS
            CALL PRINTCR
            setdbr `GLOBAL_VARS

.if UNITTEST
            setaxl
            LDA #<>WAIT         ; Send subsquent restarts to the WAIT loop
            STA RESTART

            CALL TST_BASIC      ; Run the BASIC816 unit tests

WAIT        JMP WAIT
.endif

INITBASIC   .proc
            PHP
            CALL INITIO         ; Initialize I/O system
            CALL CMD_NEW        ; Clear the program

            PLP
            RETURN
            .pend
.send

.section data
GREET       .null CHAR_ESC,"[2J",CHAR_ESC,"[H","BASIC816 for the C256 Foenix"
.send