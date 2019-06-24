;;;
;;; Test BASIC functions
;;;

; Test LEN(S$)
TST_LEN         .proc
                UT_BEGIN "TST_LEN"

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

                TRACE "OK"

                ; Validate that A%=12
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
                UT_M_EQ_LIT_W ARGUMENT1,12,"EXPECTED A%=12"

                ; Validate that B%=5
                setal
                LDA #<>VAR_B
                STA TOFIND
                setas
                LDA #`VAR_B
                STA TOFIND+2

                LDA #TYPE_INTEGER
                STA TOFINDTYPE

                CALL VAR_REF
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                UT_M_EQ_LIT_W ARGUMENT1,5,"EXPECTED B%=5"

                UT_END
LINE10          .null '10 A%=LEN("Hello, World")'
LINE20          .null '20 N$="Hello":B%=LEN(N$)'
VAR_A           .null "A%"
VAR_B           .null "B%"
                .pend

; Test CHR$(value)
TST_CHR         .proc
                UT_BEGIN "TST_CHR"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                LD_L CURLINE,LINE10
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                CALL CMD_RUN

                ; Validate that A%=12
                setal
                LDA #<>VAR_A
                STA TOFIND
                setas
                LDA #`VAR_A
                STA TOFIND+2

                LDA #TYPE_STRING
                STA TOFINDTYPE

                CALL VAR_REF
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_STRING,"EXPECTED STRING"

                UT_END
LINE10          .null '10 A$=CHR$(64)'
VAR_A           .null "A%"
EXPECTED        .null "@"
                .pend

TST_FUNCS       .proc
                CALL TST_LEN
                CALL TST_CHR

                UT_LOG "TST_FUNCS: PASSED"
                RETURN
                .pend