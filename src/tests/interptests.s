;;;
;;; Tests of the interpreter
;;;

TMP_BUFF_ORG = $004000
TMP_BUFF_SIZ = $100

TST_PRINT       .proc
                UT_BEGIN "TST_PRINT"

                setdp GLOBAL_VARS
                setdbr 0

                setaxl

                ; Interpret PRINT "Hello, world!"
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

                setal
                LDA #<>TEST
                STA BIP
                LDA #`TEST
                STA BIP+2

                CALL EXECSTMT

                CALL OBUFF_CLOSE

                UT_STR_EQ TMP_BUFF_ORG,EXPECTED,"EXPECTED 'Hello, world!{CR}'"

                UT_END
TEST            .null $8E,' "Hello, world!"'
EXPECTED        .null 'Hello, world!',13,10
                .pend

; Can assign a value to a variable using an implied LET
TST_LET_IMPLIED .proc
                UT_BEGIN "TST_LET_IMPLIED"

                setdp GLOBAL_VARS
                setdbr 0

                setaxl

                ; Interpret A = 1234
                CALL INITBASIC

                LDA #<>TEST
                STA BIP
                LDA #`TEST
                STA BIP+2

                CALL EXECSTMT

                ; Check the value of the variable
                LDA #<>VARIABLE
                STA TOFIND
                setas
                LDA #`VARIABLE
                STA TOFIND+2
                LDA #TYPE_INTEGER
                STA TOFINDTYPE
                CALL VAR_REF            ; Get the value of A

                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                UT_M_EQ_LIT_W ARGUMENT1,1234,"EXPECTED 1234"

                UT_END
TEST            .null "A%",TOK_EQ,"1234"
VARIABLE        .null "A%"
                .pend

; Can add a tokenized line of BASIC to the current program
TST_ADDLINE     .proc
                UT_BEGIN "TST_ADDLINE"

                CALL INITBASIC

                UT_M_EQ_LIT_L LASTLINE,BASIC_BOT,"EXPECTED LASTLINE == BASIC_BOT"

                setaxl
                LDA #<>TEST
                STA CURLINE
                setas
                LDA #`TEST
                STA CURLINE+2

                setal
                LDA #10
                CALL ADDLINE

                UT_M_NE_LIT_L LASTLINE,BASIC_BOT,"EXPECTED LASTLINE <> BASIC_BOT"
                UT_M_EQ_LIT_W BASIC_BOT+LINE_NUMBER,10,"EXPECTED 10"
                UT_M_EQ_LIT_B BASIC_BOT+LINE_TOKENS,TOK_LET,"EXPECTED TOKEN FOR LET"

                UT_END
TEST            .null TOK_LET,"A%=1234"
                .pend

; Can delete a line
TST_DELLINE     .proc
                UT_BEGIN "TST_DELLINE"

                CALL INITBASIC

                UT_M_EQ_LIT_L LASTLINE,BASIC_BOT,"EXPECTED LASTLINE == BASIC_BOT"

                setaxl
                LDA #<>TEST
                STA CURLINE
                setas
                LDA #`TEST
                STA CURLINE+2

                setal
                LDA #10
                CALL ADDLINE

                UT_M_NE_LIT_L LASTLINE,BASIC_BOT,"EXPECTED LASTLINE <> BASIC_BOT"
                UT_M_EQ_LIT_W BASIC_BOT+LINE_NUMBER,10,"EXPECTED 10"
                UT_M_EQ_LIT_B BASIC_BOT+LINE_TOKENS,TOK_LET,"EXPECTED TOKEN FOR LET"

                TRACE "ADDED"

                LDARG_EA ARGUMENT1,10,TYPE_INTEGER
                CALL DELLINE

                UT_M_EQ_LIT_L LASTLINE,BASIC_BOT,"EXPECTED LASTLINE = BASIC_BOT"
                UT_M_EQ_LIT_W BASIC_BOT+LINE_LINK,0,"EXPECTED LINK = 0"
                UT_M_EQ_LIT_W BASIC_BOT+LINE_NUMBER,0,"EXPECTED NUMBER = 0"
                UT_M_EQ_LIT_B BASIC_BOT+LINE_TOKENS,0,"EXPECTED END-OF-LINE token"

                UT_END
TEST            .null TOK_LET,"A%=1234"
                .pend

; Can add a tokenized line of BASIC to the current program
TST_EXECLINE    .proc
                UT_BEGIN "TST_EXECLINE"

                CALL INITBASIC
                UT_M_EQ_LIT_L LASTLINE,BASIC_BOT,"EXPECTED LASTLINE == BASIC_BOT"

                setaxl
                LDA #<>ON_ERROR
                STA HANDLEERR
                setas
                LDA #`ON_ERROR
                STa HANDLEERR+2

                ; Add the line to the program

                setaxl
                LDA #<>TEST
                STA CURLINE
                setas
                LDA #`TEST
                STA CURLINE+2

                setal
                LDA #10
                CALL ADDLINE

                TRACE "ADDED"

                ; Try to execute it

                setal
                LDA #<>BASIC_BOT
                STA CURLINE
                setas
                LDA #`BASIC_BOT
                STA CURLINE+2

                CALL EXECLINE

                ; Check that A% = 12
                setal
                LDA #<>VARA
                STA TOFIND
                setas
                LDA #`VARA
                STA TOFIND+2

                LDA #TYPE_INTEGER
                STA TOFINDTYPE

                CALL VAR_REF
                UT_M_EQ_LIT_W ARGUMENT1,12,"EXPECTED A% = 12"

                ; Check that B% = 34
                setal
                LDA #<>VARB
                STA TOFIND
                setas
                LDA #`VARB
                STA TOFIND+2

                LDA #TYPE_INTEGER
                STA TOFINDTYPE

                TRACE "BAR"

                CALL VAR_REF
                UT_M_EQ_LIT_W ARGUMENT1,34,"EXPECTED B% = 34"

                UT_END

ON_ERROR        UT_ASSERT_FAIL "DID NOT EXPECT AN ERROR"

TEST            .null "A%",TOK_EQ,"12:B%",TOK_EQ,"34"
VARA            .null "A%"
VARB            .null "B%"
                .pend

; Check that we can tokenize a full line of BASIC, including the line number
TST_TOKEN_LINE  .proc
                UT_BEGIN "TST_TOKEN_LINE"

                CALL INITBASIC

                LDA #<>LINE
                STA CURLINE
                setas
                LDA #`LINE
                STA CURLINE+2

                CALL TOKENIZE
                setal

                UT_M_EQ_LIT_W LINENUM,20,"EXPECTED 20"

                LDA LINENUM
                CALL ADDLINE

                UT_M_EQ_LIT_W BASIC_BOT+LINE_NUMBER,20,"EXPECTED 20"
                UT_M_EQ_LIT_B BASIC_BOT+LINE_TOKENS,"Z","EXPECTED 'Z'"

                UT_END
LINE            .null "20 Z%=1234"
                .pend

; Check that we can tokenize and run a simple two-line program
TST_EXEC_LINE2  .proc
                UT_BEGIN "TST_EXEC_LINE2"

                CALL INITBASIC

                LD_L CURLINE,LINE10
                CALL TOKENIZE
                LDA LINENUM
                CALL ADDLINE

                LD_L CURLINE,LINE20
                CALL TOKENIZE
                LDA LINENUM
                CALL ADDLINE

                LD_L CURLINE,BASIC_BOT
                CALL EXECPROGRAM

                ; Validate that A%=4321
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
                UT_M_EQ_LIT_W ARGUMENT1,4321,"EXPECTED 4321"

                ; Validate that B%=9876
                setal
                LDA #<>VAR_B
                STA TOFIND
                setas
                LDA #`VAR_B
                STA TOFIND+2

                LDA #TYPE_INTEGER
                STA TOFINDTYPE

                CALL VAR_REF            ; Try to get the result
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                UT_M_EQ_LIT_W ARGUMENT1,9876,"EXPECTED 9876"

                UT_END
LINE10          .null "10 A%=4321"
LINE20          .null "20 B%=9876"
VAR_A           .null "A%"
VAR_B           .null "B%"
                .pend

; Check that we GOTO a specific line
TST_EXEC_GOTO   .proc
                UT_BEGIN "TST_EXEC_GOTO"

                CALL INITBASIC

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

                LD_L CURLINE,LINE40
                CALL TOKENIZE
                LDA LINENUM
                CALL ADDLINE

                LD_L CURLINE,BASIC_BOT
                CALL EXECPROGRAM

                ; Validate that A%=1
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
                UT_M_EQ_LIT_W ARGUMENT1,1,"EXPECTED 1"

                ; Validate that B%=3
                setal
                LDA #<>VAR_B
                STA TOFIND
                setas
                LDA #`VAR_B
                STA TOFIND+2

                LDA #TYPE_INTEGER
                STA TOFINDTYPE

                CALL VAR_REF            ; Try to get the result
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                UT_M_EQ_LIT_W ARGUMENT1,3,"EXPECTED 3"

                UT_END
LINE10          .null "10 LET A%=1"
LINE20          .null "20 GOTO 40"
LINE30          .null "30 A%=2"
LINE40          .null "40 B%=3"
VAR_A           .null "A%"
VAR_B           .null "B%"
                .pend

; Check that we can tokenize LET properly
TST_TOK_LET     .proc
                UT_BEGIN "TST_TOK_LET"

                CALL INITBASIC

                LD_L CURLINE,LINE10
                CALL TOKENIZE

                TRACE "TOKENIZED"

                LDA LINENUM
                CALL ADDLINE

                UT_M_EQ_LIT_W BASIC_BOT+2,10,"EXPECTED 10"
                UT_M_EQ_LIT_B BASIC_BOT+4,TOK_LET,"EXPECTED LET TOKEN"

                UT_END
LINE10          .null "10 LET A%=1"
                .pend

; Check that we END a program
TST_EXEC_END    .proc
                UT_BEGIN "TST_EXEC_END"

                CALL INITBASIC

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

                LD_L CURLINE,BASIC_BOT
                CALL EXECPROGRAM

                ; Validate that A%=1
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
                UT_M_EQ_LIT_W ARGUMENT1,1,"EXPECTED 1"

                UT_END
LINE10          .null "10 LET A%=1"
LINE20          .null "20 END"
LINE30          .null "30 A%=2"
VAR_A           .null "A%"
                .pend

;
; Run all the evaluator tests
;
TST_INTERP      .proc
                ;CALL TST_PRINT
                CALL TST_TOK_LET
                CALL TST_LET_IMPLIED
                CALL TST_ADDLINE
                CALL TST_DELLINE
                CALL TST_EXECLINE
                CALL TST_TOKEN_LINE
                CALL TST_EXEC_LINE2
                CALL TST_EXEC_GOTO
                CALL TST_EXEC_END

                UT_LOG "TST_INTERP: PASSED"
                RETURN
                .pend
