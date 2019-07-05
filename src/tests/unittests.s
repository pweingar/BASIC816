;;;
;;; A framework for simple unit testing
;;;

.section data
UT_PASS_MSG .text "PASSED",CHAR_CR,0
UT_FAIL_MSG .text "FAILED",CHAR_CR,0
.send

;
; Send a NUL terminated string to the log.
;
; Inputs:
;   X = pointer to the message to write
;   
UT_LOGMSG   .proc
            PHP
            setaxl
            PHA
            CALL PRINTS
            PLA
            PLP
            RETURN
            .pend

;
; Write a failure message to the log and stop the tests.
;
; Inputs:
;   X = pointer to the message (a NUL terminated string)
;
UT_FAIL     .proc
            CALL UT_LOGMSG
.if SYSTEM = SYSTEM_C64
WAIT        JMP WAIT
.else
            BRK
            NOP
.endif
            RETURN
            .pend

;
; Write a failure message to the log and stop the tests.
; Also write out what is stored in A (16 bit)
;
; Inputs:
;   X = pointer to the message (a NUL terminated string)
;
UT_FAIL_AW  .proc
            CALL UT_LOGMSG

            setal
            PHA

            setas
            LDA #' '
            CALL PRINTC
            LDA #'['
            CALL PRINTC

            setal
            PLA
            CALL PRHEXW

            setas
            LDA #']'
            CALL PRINTC

.if SYSTEM = SYSTEM_C64
WAIT        JMP WAIT
.else
            BRK
            NOP
.endif
            RETURN
            .pend

;
; Write a failure message to the log and stop the tests.
; Also write out what is stored in A (8 bit)
;
; Inputs:
;   X = pointer to the message (a NUL terminated string)
;
UT_FAIL_AB  .proc
            CALL UT_LOGMSG

            setas
            PHA

            setas
            LDA #' '
            CALL PRINTC
            LDA #'['
            CALL PRINTC

            setas
            PLA
            CALL PRHEXB

            setas
            LDA #']'
            CALL PRINTC

.if SYSTEM = SYSTEM_C64
WAIT        JMP WAIT
.else
            BRK
            NOP
.endif
            RETURN
            .pend

;
; Write a failure message to the log and stop the tests.
; Also write out what is stored in A/Y (24 bit)
;
; Inputs:
;   A = contains bits [23..16]
;   Y = contains bits [15..0]
;   X = pointer to the message (a NUL terminated string)
;
UT_FAIL_AL  .proc
            CALL UT_LOGMSG

            setas
            PHA

            setas
            LDA #' '
            CALL PRINTC
            LDA #'['
            CALL PRINTC

            setas
            PLA
            CALL PRHEXB

            setal
            TYA
            CALL PRHEXW

            setas
            LDA #']'
            CALL PRINTC

.if SYSTEM = SYSTEM_C64
WAIT        JMP WAIT
.else
            BRK
            NOP
.endif
            RETURN
            .pend

;
; Write a message to the log.
;
; Inputs:
;   X = pointer to the message (a NUL terminated string)
;
UT_LOG          .macro  ; name
                PHP
                setxl
                PHX
                LDX #<>TESTNAME
                PHB
                setdbr `DATA_BLOCK
                CALL UT_LOGMSG
                PLB
                BRA continue
.section data
TESTNAME        .null \1,CHAR_CR
.send
continue        PLX
                PLP
                .endm

;
; Start a unit test case
;
UT_BEGIN        .macro  ; name
                PHP
                setxl
                LDX #<>TESTNAME
                PHB
                setdbr `DATA_BLOCK
                CALL UT_LOGMSG
                PLB
                BRA continue
.section data
TESTNAME        .null \1
.send
continue        setas
                LDA #':'
                CALL PRINTC
                LDA #' '
                CALL PRINTC

                setaxl
                .endm

;
; End a unit test case... print the success message.
;
UT_END          .macro
                setxl
                LDX #<>UT_PASS_MSG
                PHB
                setdbr `DATA_BLOCK
                CALL UT_LOGMSG
                PLB               

                PLP
                RETURN
                .endm

;
; Assert that a memory location contains a literal value (byte)
;
; Be sure to call this with the correct accumulator width!
;
UT_M_EQ_LIT_B   .macro  ; address,literal,message
                PHP
                setas
                LDA \1
                CMP #\2
                BEQ continue

                setxl
                LDX #<>MESSAGE
                PHB
                setdbr `DATA_BLOCK
                CALL UT_FAIL_AB
                PLB
                BRA continue
.section data
MESSAGE         .null \3
.send
continue        PLP
                .endm

;
; Assert that a memory location contains a literal value (word)
;
; Be sure to call this with the correct accumulator width!
;
UT_M_EQ_LIT_W   .macro  ; address,literal,message
                PHP
                setal
                LDA \1
                CMP #\2
                BEQ continue

                setxl
                LDX #<>MESSAGE
                PHB
                setdbr `DATA_BLOCK
                CALL UT_FAIL_AW
                PLB
                BRA continue
.section data
MESSAGE         .null \3
.send
continue        PLP
                .endm

;
; Assert that a memory location contains a literal value (long)
;
; Be sure to call this with the correct accumulator width!
;
UT_M_EQ_LIT_L   .macro  ; address,literal,message
                PHP
                setal
                LDA \1
                CMP #<>\2
                BNE fail
                setas
                LDA \1+2
                CMP #`\2
                BEQ continue

fail            setxl
                LDX #<>MESSAGE
                PHB
                setdbr `DATA_BLOCK
                LDA \1
                TAY
                setas
                LDA \1+2
                CALL UT_FAIL_AL
                PLB
                BRA continue
.section data
MESSAGE         .null \3
.send
continue        PLP
                .endm

;
; Assert that a memory location does not contain a literal value (long)
;
; Be sure to call this with the correct accumulator width!
;
UT_M_NE_LIT_L   .macro  ; address,literal,message
                PHP
                setal
                LDA \1
                CMP #<>\2
                BNE continue
                setas
                LDA \1+2
                CMP #`\2
                BNE continue

fail            setxl
                LDX #<>MESSAGE
                PHB
                setdbr `DATA_BLOCK
                LDY \1
                setas
                LDA \1+2
                CALL UT_FAIL_AL
                PLB
                BRA continue
.section data
MESSAGE         .null \3
.send
continue        PLP
                .endm

;
; Assert that two memory locations contain the same value (long)
;
; Be sure to call this with the correct accumulator width!
;
UT_M_EQ_M_L     .macro  ; actual_address,expected_address,message
                PHP
                setal
                LDA \1
                CMP \2
                BNE fail
                setas
                LDA \1+2
                CMP \2+2
                BEQ continue

fail            setxl
                LDX #<>MESSAGE
                PHB
                setdbr `DATA_BLOCK
                LDY \1
                setas
                LDA \1+2
                CALL UT_FAIL_AL
                PLB
                BRA continue
.section data
MESSAGE         .null \3
.send
continue        PLP
                .endm

;
; Assert that A contains the expected byte value
;
UT_A_EQ_LIT_B   .macro  ; literal,message
                PHP
                setas
                CMP #\1
                BEQ continue

                setxl
                LDX #<>MESSAGE
                PHB
                setdbr `DATA_BLOCK
                CALL UT_FAIL_AB
                PLB
                BRA continue
.section data
MESSAGE         .null \2
.send
continue        PLP
                .endm

;
; Assert that A contains the expected word value
;
UT_A_EQ_LIT_W   .macro  ; literal,message
                PHP
                setaxl
                CMP #\1
                BEQ continue

                LDX #<>MESSAGE
                PHB
                setdbr `DATA_BLOCK
                CALL UT_FAIL_AW
                PLB
                BRA continue
.section data
MESSAGE         .null \2
.send
continue        PLP
                .endm

;
; Assert C is set
;
UT_C_SET        .macro  ; message
                BCS continue

                LDX #<>MESSAGE
                PHB
                setdbr `DATA_BLOCK
                CALL UT_FAIL
                PLB
                BRA continue
.section data
MESSAGE         .null \1
.send
continue        
                .endm

;
; Assert C is clear
;
UT_C_CLR        .macro  ; message
                BCC continue

                LDX #<>MESSAGE
                PHB
                setdbr `DATA_BLOCK
                CALL UT_FAIL
                PLB
                BRA continue
.section data
MESSAGE         .null \1
.send
continue        
                .endm

;
; Force a failure... mark test code that should never run
;
UT_ASSERT_FAIL  .macro ; message
                LDX #<>MESSAGE
                PHB
                setdbr `DATA_BLOCK
                CALL UT_FAIL
                PLB
                BRA continue
.section data
MESSAGE         .null \1
.send
continue        
                .endm      

;
; Assert that two null-terminated strings are equal
;
UT_STR_EQ       .macro ; actual, expected, message
                setal
                LDA #<>\1           ; Point ARGUMENT1 to actual
                STA ARGUMENT1
                LDA #`\1
                STA ARGUMENT1+2

                LDA #<>\2           ; Point ARGUMENT2 to expected
                STA ARGUMENT2
                LDA #`\2
                STA ARGUMENT2+2   

                setas               ; Set their types to string
                LDA #TYPE_STRING
                STA ARGTYPE1
                STA ARGTYPE2

                CALL STRCMP

                LDA ARGUMENT1       ; Check to see if the result is 0 (they are equal)
                BEQ continue

                LDX #<>MESSAGE      ; No, print the error message
                PHB
                setdbr `DATA_BLOCK
                CALL UT_FAIL
                PLB
                BRA continue
.section data
MESSAGE         .null \3
.send
continue             
                .endm          

;
; Assert that two null-terminated strings are equal
; Where the actual string is indirect
;
UT_STRIND_EQ    .macro ; actual, expected, message
                setal
                LDA \1              ; Point ARGUMENT1 to actual
                STA ARGUMENT1
                setas
                LDA \1+2
                STA ARGUMENT1+2

                setal
                LDA #<>\2           ; Point ARGUMENT2 to expected
                STA ARGUMENT2
                LDA #`\2
                STA ARGUMENT2+2   

                setas               ; Set their types to string
                LDA #TYPE_STRING
                STA ARGTYPE1
                STA ARGTYPE2

                CALL STRCMP

                LDA ARGUMENT1       ; Check to see if the result is 0 (they are equal)
                BEQ continue

                LDX #<>MESSAGE      ; No, print the error message
                PHB
                setdbr `DATA_BLOCK
                CALL UT_FAIL
                PLB
                BRA continue
.section data
MESSAGE         .null \3
.send
continue             
                .endm   

; Macro to append a line to the test program
TSTLINE         .macro              ; line
                LD_L CURLINE,LINETEXT
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE
                BRA continue
LINETEXT        .null \1

continue
                .endm

UT_VAR_EQ_W     .macro      ; variable name, type_code, expected value
                setal
                LDA #<>VAR_NAME
                STA TOFIND
                LDA #`VAR_NAME
                STA TOFIND+2

                setas
                LDA #\2
                STA TOFINDTYPE

                CALL VAR_REF            ; Try to get the result
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,format("EXPECTED TYPE %d", \3)
                UT_M_EQ_LIT_W ARGUMENT1,\3,format("EXPECTED %s=%s", \1, \3)
                BRA continue
VAR_NAME        .null \1
continue
                .endm

UT_VAR_EQ_STR   .macro      ; variable name, expected value
                setal
                LDA #<>VAR_NAME
                STA TOFIND
                LDA #`VAR_NAME
                STA TOFIND+2

                setas
                LDA #TYPE_STRING
                STA TOFINDTYPE

                CALL VAR_REF            ; Try to get the result
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_STRING,"EXPECTED STRING"
                UT_STRIND_EQ ARGUMENT1,EXPECTED,format("EXPECTED %s=[%s]", \1, \2)
                BRA continue
VAR_NAME        .null \1
EXPECTED        .null \2
continue
                .endm