;;;
;;; Unit tests for commands
;;;

; Test that we can list a single line
TST_LISTLINE    .proc
                UT_BEGIN "TST_LISTLINE"

                setdp GLOBAL_VARS
                setdbr 0

                setaxl

                CALL INITBASIC

                ; Set up the temporary buffer
                LDA #<>TMP_BUFF_ORG             ; Set the address of the buffer
                STA OBUFFER
                setas
                LDA #`TMP_BUFF_ORG
                STA OBUFFER

                setal                           ; Set the size of rhe buffer
                LDA #TMP_BUFF_SIZ
                STA OBUFFSIZE

                STZ OBUFFIDX                    ; Clear the index

                setas
                LDA BCONSOLE
                ORA #DEV_BUFFER                 ; Turn on the output buffer
                STA BCONSOLE

                LD_L CURLINE,LINE10
                CALL TOKENIZE
                LDA LINENUM
                CALL ADDLINE

                CALL CMD_LIST

                CALL OBUFF_CLOSE

                UT_STR_EQ TMP_BUFF_ORG,EXPECTED,"EXPECTED '10 A%=1{CR}'"

                UT_END
LINE10          .null '10 LET A%=1'
EXPECTED        .null '10 LET A%=1',13
                .pend

; Test that we can list a multi-line progtram
TST_LISTLINES   .proc
                UT_BEGIN "TST_LISTLINES"

                setdp GLOBAL_VARS
                setdbr 0

                setaxl

                CALL INITBASIC

                ; Set up the temporary buffer
                LDA #<>TMP_BUFF_ORG             ; Set the address of the buffer
                STA OBUFFER
                setas
                LDA #`TMP_BUFF_ORG
                STA OBUFFER

                setal                           ; Set the size of rhe buffer
                LDA #TMP_BUFF_SIZ
                STA OBUFFSIZE

                STZ OBUFFIDX                    ; Clear the index

                setas
                LDA BCONSOLE
                ORA #DEV_BUFFER                 ; Turn on the output buffer
                STA BCONSOLE

                LD_L CURLINE,LINE10
                CALL TOKENIZE
                LDA LINENUM
                CALL ADDLINE

                LD_L CURLINE,LINE20
                CALL TOKENIZE
                LDA LINENUM
                CALL ADDLINE

                LD_L CURLINE,LINE30
                CALL TOKENIZE
                LDA LINENUM
                CALL ADDLINE

                CALL CMD_LIST

                CALL OBUFF_CLOSE

                UT_STR_EQ TMP_BUFF_ORG,EXPECTED,"EXPECTED '10 A%=1{CR}'"

                UT_END
LINE10          .null '10 LET A%=1'
LINE20          .null '20 B%=A%+1'
LINE30          .null '30 PRINT B%'
EXPECTED        .text '10 LET A%=1',13
                .text '20 B%=A%+1',13
                .text '30 PRINT B%',13,0
                .pend

TST_CMD         .proc
                CALL TST_LISTLINE
                CALL TST_LISTLINES

                UT_LOG "TST_CMD: PASSED"
                RETURN
                .pend