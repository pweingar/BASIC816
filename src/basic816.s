;;;
;;; BASIC for the 65816 processor
;;;

.cpu "65816"

.include "constants.s"
.include "memorymap.s"
.include "macros.s"

.section code

;;
;; Jump table 

COLDBOOT        JML START               ; Entry point to boot up BASIC from scratch
MONITOR         JML IMONITOR            ; Entry point to the machine language monitor

;;
;; I/O hooks... these could be replaced by an external system
;;

READLINE        JML IREADLINE           ; Wait for the user to enter a line of text (for programming input)
SCRCOPYLINE     JML ISCRCPYLINE         ; Copy the line on the screen the user just input to INPUTBUF
INPUTLINE       JML IINPUTLINE          ; Read a single line of text from the user, and copy it to TEMPBUF (for INPUT statement)
GETKEY          JML IGETKEY             ; Wait for a keypress by the user and return the ASCII code in A
PRINTC          JML IPRINTC             ; Print the character in A to the console
SHOWCURSOR      JML ISHOWCURSOR         ; Set cursor visibility: A=0, hide... A<>0, show.
CURSORXY        JML ICURSORXY           ; Set the position of the cursor to (X, Y)
CLSCREEN        JML ICLSCREEN           ; Clear the screen

;;
;; A mess o' includes...
;;

;.include "bootstrap.s"

.include "bios.s"
.include "utilities.s"
.include "tokens.s"
.include "heap.s"
.include "strings.s"
.include "listing.s"
.include "eval.s"
.include "returnstack.s"
.include "interpreter.s"
.include "repl.s"
.include "operators.s"
.include "statements.s"
.include "functions.s"
.include "commands.s"
.include "variables.s"
.include "integers.s"
.include "floats.s"
.include "transcendentals.s"
.include "arrays.s"
.include "dos.s"

.include "monitor.s"

.if UNITTEST
.include "tests/basictests.s"
.endif

START       CLC                 ; Go to native mode
            XCE

            setdp GLOBAL_VARS
            setdbr BASIC_BANK

            setaxl

            CALL INITBASIC

            LDA #STACK_END      ; Set the system stack
            TCS

            ; Clear the screen and print the welcome message
            ; CALL CLSCREEN

            setdbr `GREET
            LDX #<>GREET
            CALL PRINTS
            setdbr BASIC_BANK

            ; setaxl
            ; LDA #<>WAIT         ; Send subsquent restarts to the WAIT loop
            ; STA RESTART

.if UNITTEST
            CALL TST_BASIC      ; Run the BASIC816 unit tests
.else
            ; BRK
            ; NOP
            JMP INTERACT        ; Start accepting input from the user
.endif

WAIT        JMP WAIT

INITBASIC   .proc
            PHP

            CALL INITIO         ; Initialize I/O system
            CALL CMD_NEW        ; Clear the program

            PLP
            RETURN
            .pend
.send

.section data
GREET       .text "C256 Foenix BASIC816 "
            .include "version.s"
            .byte 13,0
.send
