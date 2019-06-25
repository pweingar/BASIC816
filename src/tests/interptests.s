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
EXPECTED        .null 'Hello, world!',13
                .pend

; Verify that we can print integers
TST_PRINTEGER   .proc
                UT_BEGIN "TST_PRINTEGER"

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

                UT_STR_EQ TMP_BUFF_ORG,EXPECTED,"EXPECTED  1234{CR}'"

                UT_END
TEST            .null $8E,' 1234'
EXPECTED        .null ' 1234',13
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
TEST            .null "abc%",TOK_EQ,"1234"
VARIABLE        .null "ABC%"
                .pend

; Can add a tokenized line of BASIC to the current program
TST_APPLINE     .proc
                UT_BEGIN "TST_APPLINE"

                CALL INITBASIC

                UT_M_EQ_LIT_L LASTLINE,BASIC_BOT,"EXPECTED LASTLINE == BASIC_BOT"

                setaxl
                LDA #<>TEST
                STA CURLINE
                LDA #`TEST
                STA CURLINE+2

                LDA #10
                CALL APPLINE

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
                CALL APPLINE

                UT_M_NE_LIT_L LASTLINE,BASIC_BOT,"EXPECTED LASTLINE <> BASIC_BOT"
                UT_M_EQ_LIT_W BASIC_BOT+LINE_NUMBER,10,"EXPECTED 10"
                UT_M_EQ_LIT_B BASIC_BOT+LINE_TOKENS,TOK_LET,"EXPECTED TOKEN FOR LET"

                TRACE "ADDED"

                LDARG_EA ARGUMENT1,10,TYPE_INTEGER
                CALL FINDLINE
                MOVE_L INDEX,CURLINE
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
                CALL APPLINE

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
                CALL APPLINE

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
                CALL APPLINE

                LD_L CURLINE,LINE20
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

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
                CALL APPLINE

                LD_L CURLINE,LINE20
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                LD_L CURLINE,LINE30
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                LD_L CURLINE,LINE40
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                LD_L CURLINE,LINE50
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                LD_L CURLINE,LINE60
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

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
LINE20          .null "20 GOTO 60"
LINE30          .null "30 A%=2"
LINE40          .null "40 B%=3"
LINE50          .null "50 END"
LINE60          .null "60 GOTO 40"
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
                CALL APPLINE

                UT_M_EQ_LIT_W BASIC_BOT+2,10,"EXPECTED 10"
                UT_M_EQ_LIT_B BASIC_BOT+4,TOK_LET,"EXPECTED LET TOKEN"

                UT_END
LINE10          .null "10 LET A%=1"
                .pend

; Check that we can tokenize END properly
; (Also tests singleton statements)
TST_TOK_END     .proc
                UT_BEGIN "TST_TOK_END"

                CALL INITBASIC

                LD_L CURLINE,LINE10
                CALL TOKENIZE

                TRACE "TOKENIZED"

                LDA LINENUM
                CALL APPLINE

                UT_M_EQ_LIT_W BASIC_BOT+2,10,"EXPECTED 10"
                UT_M_EQ_LIT_B BASIC_BOT+4,TOK_END,"EXPECTED END TOKEN"

                UT_END
LINE10          .null "10 END"
                .pend

; Check that we END a program
TST_EXEC_END    .proc
                UT_BEGIN "TST_EXEC_END"

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

; Check that we execute a simple IF (IF <test> THEN <line>)
TST_EXEC_IFSIM  .proc
                UT_BEGIN "TST_EXEC_IFSIM"

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

                LD_L CURLINE,LINE40
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

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
                UT_M_EQ_LIT_W ARGUMENT1,2,"EXPECTED 2"

                UT_END
LINE10          .null "10 IF 1 THEN 40"
LINE20          .null "20 A%=1"
LINE30          .null "30 END"
LINE40          .null "40 A%=2"
VAR_A           .null "A%"
                .pend

; Check that we call a subroutine
TST_EXEC_SUB    .proc
                UT_BEGIN "TST_EXEC_SUB"

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

                LD_L CURLINE,LINE40
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                LD_L CURLINE,LINE50
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                LD_L CURLINE,LINE60
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

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
                UT_M_EQ_LIT_W ARGUMENT1,1234,"EXPECTED 1234"

                UT_END
LINE10          .null "10 A%=1232"
LINE20          .null "20 GOSUB 50"
LINE30          .null "30 A%=A%+1"
LINE40          .null "40 END"
LINE50          .null "50 A%=A%+1"
LINE60          .null "60 RETURN"
VAR_A           .null "A%"
                .pend

; Check that we can increment an integer
TST_EXEC_INC    .proc
                UT_BEGIN "TST_EXEC_INC"

                CALL INITBASIC

                LD_L CURLINE,LINE10
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                LD_L CURLINE,LINE20
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                LD_L CURLINE,BASIC_BOT
                CALL EXECPROGRAM

                ; Validate that A%=2
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
                UT_M_EQ_LIT_W ARGUMENT1,2,"EXPECTED 2"

                UT_END
LINE10          .null "10 A%=1"
LINE20          .null "20 A%=A%+1"
VAR_A           .null "A%"
                .pend

; Check that we can use a FOR loop
TST_EXEC_FOR    .proc
                UT_BEGIN "TST_EXEC_FOR"

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

                LD_L CURLINE,LINE40
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                LD_L CURLINE,BASIC_BOT
                CALL EXECPROGRAM

                ; Validate that A%=11
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
                UT_M_EQ_LIT_W ARGUMENT1,11,"EXPECTED A%=11"

                ; Validate that I%=11
                setal
                LDA #<>VAR_I
                STA TOFIND
                setas
                LDA #`VAR_I
                STA TOFIND+2

                LDA #TYPE_INTEGER
                STA TOFINDTYPE

                ; TODO: should i%=10 or 11?
                CALL VAR_REF            ; Try to get the result
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                UT_M_EQ_LIT_W ARGUMENT1,10,"EXPECTED I%=10"

                UT_END
LINE10          .null "10 A%=1"
LINE20          .null "20 FOR I%=1 TO 10"
LINE30          .null "30 A%=A%+1"
LINE40          .null "40 NEXT"
VAR_A           .null "A%"
VAR_I           .null "I%"
                .pend

; Check that we can find lines for updating / deleting
TST_FINDLINE    .proc
                UT_BEGIN "TST_FINDLINE"

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

                LD_L CURLINE,LINE40
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                LDA #120
                STA LINENUM
                CALL FINDINSPT

                UT_A_EQ_LIT_W 0,"EXPECTED 0"
                UT_M_EQ_M_L INDEX,LASTLINE,"EXPECTED LASTLINE"

                LDA #20
                STA LINENUM
                CALL FINDINSPT

                UT_A_EQ_LIT_W 2,"EXPECTED 2"
                UT_M_EQ_LIT_L INDEX,BASIC_BOT+9,"EXPECTED BASIC_BOT+9"

                LDA #15
                STA LINENUM
                CALL FINDINSPT

                UT_A_EQ_LIT_W 1,"EXPECTED 1"
                UT_M_EQ_LIT_L INDEX,BASIC_BOT+9,"EXPECTED BASIC_BOT+9"

                UT_END
LINE10          .null "10 A%=1"
LINE20          .null "20 FOR I%=1 TO 10"
LINE30          .null "30 A%=A%+1"
LINE40          .null "40 NEXT"
VAR_A           .null "A%"
VAR_I           .null "I%"
                .pend

; Check that we can insert a line into a program
TST_INSLINE     .proc
                UT_BEGIN "TST_INSLINE"

                setdp GLOBAL_VARS

                CALL INITBASIC

                ; Set up the temporary buffer
                setal
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
                LD_L CURLINE,LINE10
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                LD_L CURLINE,LINE30
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                LD_L CURLINE,LINE40
                CALL TOKENIZE
                LDA LINENUM
                CALL APPLINE

                LD_L CURLINE,LINE20
                CALL TOKENIZE

                LDA #20
                STA LINENUM
                CALL FINDINSPT

                LDA LINENUM
                CALL INSLINE

                CALL CMD_LIST

                CALL OBUFF_CLOSE

                UT_STR_EQ TMP_BUFF_ORG,EXPECTED,"EXPECTED LINES IN CORRECT ORDER"

                UT_END
LINE10          .null "10 A%=1"
LINE20          .null "20 FOR I%=1 TO 10"
LINE30          .null "30 A%=A%+1"
LINE40          .null "40 NEXT"
EXPECTED        .text "10 A%=1",13
                .text "20 FOR I%=1 TO 10",13
                .text "30 A%=A%+1",13
                .null "40 NEXT",13
                .pend

; Check that we can insert a line at the beginning of the program
TST_INSLINE2    .proc
                UT_BEGIN "TST_INSLINE2"

                setdp GLOBAL_VARS

                CALL INITBASIC

                ; Set up the temporary buffer
                setal
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

                LD_L CURLINE,LINE10
                CALL TOKENIZE

                LDA #10
                STA LINENUM
                CALL FINDINSPT

                CALL INSLINE

                CALL CMD_LIST

                CALL OBUFF_CLOSE

                UT_STR_EQ TMP_BUFF_ORG,EXPECTED,"EXPECTED LINES IN CORRECT ORDER"

                UT_END
LINE10          .null "10 A%=1"
LINE20          .null "20 FOR I%=1 TO 10"
LINE30          .null "30 A%=A%+1"
LINE40          .null "40 NEXT"
EXPECTED        .text "10 A%=1",13
                .text "20 FOR I%=1 TO 10",13
                .text "30 A%=A%+1",13
                .null "40 NEXT",13
                .pend

; Check that we can replace a line in a program
TST_EDITLINE    .proc
                UT_BEGIN "TST_EDITLINE"

                setdp GLOBAL_VARS

                CALL INITBASIC

                ; Set up the temporary buffer
                setal
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
                LD_L CURLINE,LINE10
                CALL TOKENIZE
                LDA LINENUM
                CALL ADDLINE

                LD_L CURLINE,LINE20_1
                CALL TOKENIZE
                LDA LINENUM
                CALL ADDLINE

                LD_L CURLINE,LINE30_1
                CALL TOKENIZE
                LDA LINENUM
                CALL ADDLINE

                LD_L CURLINE,LINE40
                CALL TOKENIZE
                LDA LINENUM
                CALL ADDLINE

                ; Replace line 20

                LD_L CURLINE,LINE20_2
                CALL TOKENIZE
                LDA LINENUM
                CALL ADDLINE

                ; Delete line 30
                LD_L CURLINE,LINE30_2
                CALL TOKENIZE
                LDA LINENUM
                CALL ADDLINE

                CALL CMD_LIST

                CALL OBUFF_CLOSE

                UT_STR_EQ TMP_BUFF_ORG,EXPECTED,"EXPECTED LINES IN CORRECT ORDER"

                UT_END
LINE10          .null "10 A%=1"
LINE20_1        .null "20 FOR K%=1 TO 10"
LINE20_2        .null "20 FOR I%=1 TO 10"
LINE30_1        .null "30 A%=A%+1"
LINE30_2        .null "30    "
LINE40          .null "40 NEXT"
EXPECTED        .text "10 A%=1",13
                .text "20 FOR I%=1 TO 10",13
                .null "40 NEXT",13

                .pend

;
; Run all the evaluator tests
;
TST_INTERP      .proc
                CALL TST_PRINT
                CALL TST_PRINTEGER
                CALL TST_TOK_LET
                CALL TST_LET_IMPLIED
                CALL TST_APPLINE
                CALL TST_DELLINE
                CALL TST_EXECLINE
                CALL TST_TOKEN_LINE
                CALL TST_EXEC_LINE2
                CALL TST_EXEC_GOTO
                CALL TST_TOK_END
                CALL TST_EXEC_END
                CALL TST_EXEC_IFSIM
                CALL TST_EXEC_SUB
                CALL TST_EXEC_INC
                CALL TST_EXEC_FOR
                CALL TST_FINDLINE
                ;CALL TST_INSLINE
                ;CALL TST_INSLINE2
                ;CALL TST_EDITLINE

                UT_LOG "TST_INTERP: PASSED"
                RETURN
                .pend
