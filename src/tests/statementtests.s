;;;
;;; Unit tests for statements
;;;

; Test that we can add comments
TST_REM         .proc
                UT_BEGIN "TST_REM"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                LD_L CURLINE,LINE10
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                LD_L CURLINE,LINE20
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                CALL CMD_RUN

                ; Validate that A%=1234
                setal
                LDA #<>VAR_A
                STA TOFIND
                setas
                LDA #`VAR_A
                STA TOFIND+2

                LDA #TYPE_INTEGER
                STA TOFINDTYPE

                CALL VAR_REF            ; Try to get the result
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                UT_M_EQ_LIT_W ARGUMENT1,1234,"EXPECTED ABC%=1234"

                setal
                CLC
                LDA @lBASIC_BOT         ; Point SCRATCH2 to the line (20)
                ADC #4                  ; Skip over the offset and line numbers
                STA SCRATCH2
                LDA #`BASIC_BOT
                STA SCRATCH2+2

                UT_STRIND_EQ SCRATCH2,EXPECTED, "EXPECTED REM:ABC%=5678"

                UT_END
LINE10          .null "10 ABC%=1234"
LINE20          .null "20 REM:ABC%=5678"
VAR_A           .null "ABC%"
EXPECTED        .null TOK_REM,":ABC%=5678"
                .pend

; Test that we can clear variables and heap
TST_CLR         .proc
                UT_BEGIN "TST_CLR"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                LD_L CURLINE,LINE10
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                LD_L CURLINE,LINE20
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                CALL CMD_RUN

                ; Validate that variables are empty
                UT_M_EQ_LIT_L VARIABLES,0,"EXPECTED VARIABLES = 0"

                ; Validate that heap is empty
                UT_M_EQ_LIT_L HEAP,HEAP_TOP,"EXPECTED HEAP = HEAP_TOP"

                ; Validate pointer to allocated objects is 0
                UT_M_EQ_LIT_L ALLOCATED,0,"EXPECTED ALLOCATED = 0"

                UT_END
LINE10          .null "10 A%=1234"
LINE20          .null "20 CLR"
                .pend

; Test that we can STOP execution
TST_STOP        .proc
                UT_BEGIN "TST_STOP"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                LD_L CURLINE,LINE10
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                LD_L CURLINE,LINE20
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                LD_L CURLINE,LINE30
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                CATCH TRAP_POINT

                setal
                LDA #<>BASIC_BOT            ; Point to the first line of the program
                STA CURLINE
                LDA #`BASIC_BOT
                STA CURLINE + 2

                CALL S_CLR
                STZ GOSUBDEPTH              ; Clear the depth of the GOSUB stack

                CALL EXECPROGRAM

                ; Validate that A%=1234
TRAP_POINT      setal
                LDA #<>VAR_A
                STA TOFIND
                setas
                LDA #`VAR_A
                STA TOFIND+2

                LDA #TYPE_INTEGER
                STA TOFINDTYPE

                CALL VAR_REF            ; Try to get the result
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                UT_M_EQ_LIT_W ARGUMENT1,1234,"EXPECTED A%=1234"

                UT_END
LINE10          .null "10 A%=1234"
LINE20          .null "20 STOP"
LINE30          .null "30 A%=5678"
VAR_A           .null "A%"
                .pend


; Test that we can execut the LET statement in various forms
TST_LET         .proc
                UT_BEGIN "TST_LET"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                LD_L CURLINE,LINE10
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                CALL CMD_RUN

                ; Validate that ABC%=1234
                setal
                LDA #<>VAR_ABC
                STA TOFIND
                setas
                LDA #`VAR_ABC
                STA TOFIND+2

                LDA #TYPE_INTEGER
                STA TOFINDTYPE

                CALL VAR_REF            ; Try to get the result
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                UT_M_EQ_LIT_W ARGUMENT1,1234,"EXPECTED ABC%=1234"

                TRACE "CHECK N$"

                ; Validate that NAME$ is a string
                setal
                LDA #<>VAR_NAME
                STA TOFIND
                setas
                LDA #`VAR_NAME
                STA TOFIND+2

                LDA #TYPE_STRING
                STA TOFINDTYPE

                CALL VAR_REF            ; Try to get the result

                MOVE_L SCRATCH2,ARGUMENT1

                UT_M_EQ_LIT_B ARGTYPE1,TYPE_STRING,"EXPECTED STRING"
                UT_STRIND_EQ SCRATCH2,EXPECTED,"EXPECTED 'FOO'"

                UT_END
LINE10          .null '10 ABC%=1234:BAND$="FOO"'
VAR_ABC         .null "ABC%"
VAR_NAME        .null "BAND$"
EXPECTED        .null "FOO"
                .pend

PIXMAP = $AFA000

; Test that we can POKE an 8-bit value into a memory location
; and that we can PEEK it too
TST_POKE        .proc
                UT_BEGIN "TST_POKE"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

; PIXMAP = $B90000

;                 ; setas
;                 ; LDA #$AA
;                 ; STA @lPIXMAP
;                 ; .rept 12
;                 ; NOP
;                 ; .next
;                 ; LDA @lPIXMAP
;                 ; CMP #$AA
;                 ; BEQ continue

;                 ; UT_LOG format("Could not STA [%x]", PIXMAP)
;                 ; BRK
;                 ; NOP


continue        TSTLINE "10 POKE $020000,$55"
                TSTLINE "20 A%=PEEK($020000)"
                TSTLINE "30 POKE $030000,$AA"
                TSTLINE "40 B%=PEEK($030000)"

                CALL CMD_RUN

                UT_M_EQ_LIT_B $020000,$55, "EXPECTED $55"

                ; Validate that A%=$55
                UT_VAR_EQ_W "A%",TYPE_INTEGER,$55

                ; Validate that B%=$AA
                UT_VAR_EQ_W "B%",TYPE_INTEGER,$AA

                UT_END
                .pend

; Test that we can POKE an 16-bit value into a memory location
; and that we can PEEK it too
TST_POKEW       .proc
                UT_BEGIN "TST_POKEW"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE '10 POKEW $020000,$1234'
                TSTLINE '20 A%=PEEKW($020000)'

                CALL CMD_RUN

                UT_M_EQ_LIT_W $020000,$1234, "EXPECTED $1234"

                ; Validate that A%=$55
                setal
                LDA #<>VAR_A
                STA TOFIND
                setas
                LDA #`VAR_A
                STA TOFIND+2

                LDA #TYPE_INTEGER
                STA TOFINDTYPE

                CALL VAR_REF
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                UT_M_EQ_LIT_W ARGUMENT1,$1234,"EXPECTED A%=$1234"

                UT_END   
VAR_A           .null "A%"
                .pend

; Test that we can POKE an 24-bit value into a memory location
; and that we can PEEK it too
TST_POKEL       .proc
                UT_BEGIN "TST_POKEL"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE '10 POKEL $020000,$123456'
                TSTLINE '20 A%=PEEKL($020000)'

                CALL CMD_RUN

                UT_M_EQ_LIT_L $020000,$123456, "EXPECTED $123456"

                ; Validate that A%=$55
                setal
                LDA #<>VAR_A
                STA TOFIND
                setas
                LDA #`VAR_A
                STA TOFIND+2

                LDA #TYPE_INTEGER
                STA TOFINDTYPE

                CALL VAR_REF
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                UT_M_EQ_LIT_L ARGUMENT1,$123456,"EXPECTED A%=$123456"

                UT_END   
VAR_A           .null "A%"
                .pend


; Test that we can nest FOR/NEXT loops
TST_NESTEDFOR   .proc
                UT_BEGIN "TST_NESTEDFOR"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE "10 A%=0"
                TSTLINE "20 FOR I%=1 TO 10:FOR J%=1 TO 20"
                TSTLINE "40 A%=A%+1"
                TSTLINE "50 NEXT:NEXT"

                CALL CMD_RUN

                ; Validate that A%=200
                UT_VAR_EQ_W "A%",TYPE_INTEGER,200

                UT_END

VAR_A           .null "A%"
                .pend

; Verify that READ/DATA work
TST_READ        .proc
                UT_BEGIN "TST_READ"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE "10 A%=5678"
                TSTLINE "20 READ B%, C$"
                TSTLINE "30 RESTORE"
                TSTLINE "40 READ D%"
                TSTLINE '50 DATA 1234, "ABC"'

                CALL CMD_RUN

                setal
                STZ LINENUM

                UT_VAR_EQ_W "A%",TYPE_INTEGER,5678
                UT_VAR_EQ_W "B%",TYPE_INTEGER,1234
                UT_VAR_EQ_W "D%",TYPE_INTEGER,1234
                UT_VAR_EQ_STR "C$","ABC"

                UT_END
                .pend

TST_STMNTS      .proc
                CALL TST_REM
                CALL TST_CLR
                CALL TST_LET
                CALL TST_POKE
                CALL TST_POKEW
                CALL TST_POKEL
                ; CALL TST_STOP
                CALL TST_NESTEDFOR
                CALL TST_READ

                UT_LOG "TST_STMNTS: PASSED"
                RETURN
                .pend