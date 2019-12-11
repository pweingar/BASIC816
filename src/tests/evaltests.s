;;;
;;; Tests of the evaluator
;;;

TST_PUSH        .macro ; value, type
                PHP
                setaxl
                LDA #(\1 & $0000FFFF)
                STA ARGUMENT1
                LDA #((\1 & $FFFF0000) >> 16)
                STA ARGUMENT1+2
                setas
                LDA #\2
                STA ARGTYPE1

                LDX #<>ARGUMENT1
                CALL PHARGUMENT
                PLP
                .endm

; We can push and pull an argument
TST_PUSH_ARG    .proc
                UT_BEGIN "TST_PUSH_ARG"

                setdp GLOBAL_VARS
                setdbr 0

                CALL INITEVALSP

                setaxl
                TST_PUSH $12345678,TYPE_INTEGER
                UT_M_EQ_LIT_W ARGUMENTSP,ARGUMENT_TOP-5,"EXPECTED STACK -5"

                LDX #<>ARGUMENT2
                CALL PLARGUMENT

                UT_M_EQ_LIT_W ARGUMENT2,$5678,"EXPECTED $5678"
                UT_M_EQ_LIT_W ARGUMENT2+2,$1234,"EXPECTED $1234"
                UT_M_EQ_LIT_B ARGTYPE2,TYPE_INTEGER,"EXPECTED TYPE_INTEGER"

                CALL INITEVALSP

                TST_PUSH 1,TYPE_INTEGER
                TST_PUSH 2,TYPE_INTEGER

                LDX #ARGUMENT1
                CALL PLARGUMENT
                UT_M_EQ_LIT_W ARGUMENT1,2,"EXPECTED 2"

                LDX #ARGUMENT1
                CALL PLARGUMENT
                UT_M_EQ_LIT_W ARGUMENT1,1,"EXPECTED 1"

                UT_END
                .pend

; We can push and pull and operator token
TST_PUSH_OP     .proc
                UT_BEGIN "TST_PUSH_OP"

                setdp GLOBAL_VARS
                setdbr 0

                CALL INITEVALSP

                setas
                setxl
                LDA #$80
                CALL PHOPERATOR

                LDA #0
                CALL PLOPERATOR

                UT_A_EQ_LIT_B $80,"EXPECTED $80"

                UT_END
                .pend

; We can check to see if the top of the operator stack is of higher precedence than the operator in A
TST_OP_PREC     .proc
                UT_BEGIN "TST_OP_PREC"

                setdp GLOBAL_VARS
                setdbr 0

                setas
                setxl

                CALL INITEVALSP

                CALL OPHIGHPREC
                UT_C_CLR "EXPECTED C CLEAR 1"                

                LDA #$80            ; Push "+"
                CALL PHOPERATOR

                LDA #$82            ; "*"
                CALL OPHIGHPREC
                UT_C_CLR "EXPECTED C CLEAR 2"

                CALL INITEVALSP

                LDA #$82            ; Push "*"
                CALL PHOPERATOR

                LDA #$80            ; "+"
                CALL OPHIGHPREC
                UT_C_SET "EXPECTED C SET"

                UT_END
                .pend

; We can process an operator on the operator stack
TST_OP_PROCESS  .proc
                UT_BEGIN "TST_OP_PROCESS"

                setdp GLOBAL_VARS
                setdbr 0

                setas
                setxl

                CALL INITEVALSP

                LDA #TOK_PLUS       ; Push "+"
                CALL PHOPERATOR

                TST_PUSH 1,TYPE_INTEGER
                TST_PUSH 2,TYPE_INTEGER
                CALL PROCESSOP      ; Attempt to process the operator

                LDX #<>ARGUMENT1    ; Get the result
                CALL PLARGUMENT
                UT_M_EQ_LIT_W ARGUMENT1,3,"EXPECTED 3"

                UT_END
                .pend

; We can subtract two numbers
TST_OP_MINUS    .proc
                UT_BEGIN "TST_OP_MINUS"

                setdp GLOBAL_VARS
                setdbr 0

                setas
                setxl

                CALL INITEVALSP

                LDA #TOK_MINUS       ; Push "-"
                CALL PHOPERATOR

                TST_PUSH 3,TYPE_INTEGER
                TST_PUSH 2,TYPE_INTEGER
                CALL PROCESSOP      ; Attempt to process the operator

                LDX #<>ARGUMENT1    ; Get the result
                CALL PLARGUMENT
                UT_M_EQ_LIT_W ARGUMENT1,1,"EXPECTED 1"

                UT_END
                .pend

; We can multiply two numbers
TST_OP_MULT     .proc
                UT_BEGIN "TST_OP_MULT"

                setdp GLOBAL_VARS
                setdbr 0

                setas
                setxl

                CALL INITEVALSP

                LDA #TOK_MULT       ; Push "*"
                CALL PHOPERATOR

                TST_PUSH 3,TYPE_INTEGER
                TST_PUSH 2,TYPE_INTEGER
                CALL PROCESSOP      ; Attempt to process the operator

                LDX #<>ARGUMENT1    ; Get the result
                CALL PLARGUMENT
                UT_M_EQ_LIT_W ARGUMENT1,6,"EXPECTED 6"

                UT_END
                .pend      

TST_DIV10       .proc
                UT_BEGIN "TST_DIV10"

                setal               ; Set ARGUMENT1 to 123
                LDA #123
                STA @lARGUMENT1
                LDA #0
                STA @lARGUMENT1+2
                setas
                LDA #TYPE_INTEGER
                STA ARGTYPE1

                CALL DIVINT10
                UT_M_EQ_LIT_W ARGUMENT1,12,"EXPECTED 12"
                UT_M_EQ_LIT_W ARGUMENT2,3,"EXPECTED 3"

                UT_END
EXPECTED        .null " 123"
                .pend

; We can evaluate integers
TST_EVAL_INT    .proc
                UT_BEGIN "TST_EVAL_INT"

                setdp GLOBAL_VARS
                setdbr 0

                setaxl

                LDA #<>TEST1
                STA BIP
                LDA #`TEST1
                STA BIP+2

                CALL EVALNUMBER

                UT_M_EQ_LIT_L ARGUMENT1,$10000000,"EXPECTED $10000000"


                UT_END
TEST1           .null "268435456"
                .pend

; We can evaluate integers
TST_EVAL_INT2   .proc
                UT_BEGIN "TST_EVAL_INT2"

                setdp GLOBAL_VARS
                setdbr 0

                setaxl

                LDA #<>TEST1
                STA BIP
                LDA #`TEST1
                STA BIP+2

                CALL EVALEXPR

                UT_M_EQ_LIT_W ARGUMENT1,1234,"EXPECTED 1234"

                UT_END
TEST1           .null "1234"
                .pend

; We can evaluate integers in hexadecimal
TST_EVAL_HEX    .proc
                UT_BEGIN "TST_EVAL_HEX"

                setdp GLOBAL_VARS
                setdbr 0

                setaxl

                LDA #<>TEST1
                STA BIP
                LDA #`TEST1
                STA BIP+2

                CALL EVALEXPR

                UT_M_EQ_LIT_W ARGUMENT1,$1234,"EXPECTED $1234"

                setaxl
                LDA #<>TEST2
                STA BIP
                LDA #`TEST2
                STA BIP+2

                CALL EVALEXPR
                UT_M_EQ_LIT_W ARGUMENT1,$ABCD,"EXPECTED $ABCD"

                UT_END
TEST1           .null "&H1234"
TEST2           .null "&hABcd"
                .pend

TST_EVAL_ADD    .proc
                UT_BEGIN "TST_EVAL_ADD"

                setdp GLOBAL_VARS
                setdbr 0

                setaxl

                CALL INITEVALSP

                LDA #<>TEST1
                STA BIP
                LDA #`TEST1
                STA BIP+2

                CALL EVALEXPR
                ; LDX #<>ARGUMENT1    ; Get the result into ARGUMENT1
                ; CALL PLARGUMENT

                UT_M_EQ_LIT_W ARGUMENT1,3,"EXPECTED 3"

                UT_END
TEST1           .text "1",TOK_PLUS,"2",0
                .pend

TST_EVAL_MULT   .proc
                UT_BEGIN "TST_EVAL_MULT"

                setdp GLOBAL_VARS
                setdbr 0

                setaxl

                CALL INITEVALSP

                LDA #<>TEST1
                STA BIP
                LDA #`TEST1
                STA BIP+2

                CALL EVALEXPR
                ; LDX #<>ARGUMENT1    ; Get the result into ARGUMENT1
                ; CALL PLARGUMENT

                UT_M_EQ_LIT_W ARGUMENT1,6,"EXPECTED 6"

                UT_END
TEST1           .text "2",TOK_MULT,"3",0
                .pend

TST_EVAL_DIVIDE .proc
                UT_BEGIN "TST_EVAL_DIVIDE"

                setdp GLOBAL_VARS
                setdbr 0

                setaxl

                CALL INITEVALSP

                ; Test: 6 / 3 = 2
                LDA #<>TEST1
                STA BIP
                LDA #`TEST1
                STA BIP+2

                CALL EVALEXPR
                ; LDX #<>ARGUMENT1    ; Get the result into ARGUMENT1
                ; CALL PLARGUMENT

                UT_M_EQ_LIT_W ARGUMENT1,2,"EXPECTED 2"

                UT_END
TEST1           .text "6",TOK_DIVIDE,"3",0
                .pend

TST_EVAL_MOD    .proc
                UT_BEGIN "TST_EVAL_MOD"

                setdp GLOBAL_VARS
                setdbr 0

                setaxl

                CALL INITEVALSP

                ; Test: 7 % 3 = 1
                LDA #<>TEST1
                STA BIP
                LDA #`TEST1
                STA BIP+2

                CALL EVALEXPR

                UT_M_EQ_LIT_W ARGUMENT1,1,"EXPECTED 1"

                UT_END
TEST1           .text "7",TOK_MOD,"3",0
                .pend

; Can add and multiply with correct precedence
TST_EVAL_PREC1  .proc
                UT_BEGIN "TST_EVAL_PREC1"

                setdp GLOBAL_VARS
                setdbr 0

                setaxl

                ; Eval 1+2*3 == 7
                CALL INITEVALSP

                LDA #<>TEST
                STA BIP
                LDA #`TEST
                STA BIP+2

                CALL EVALEXPR
                ; LDX #<>ARGUMENT1    ; Get the result into ARGUMENT1
                ; CALL PLARGUMENT

                UT_M_EQ_LIT_W ARGUMENT1,7,"EXPECTED 7"

                UT_END
TEST            .text "1",TOK_PLUS,"2",TOK_MULT,"3",0
                .pend

; Can add and multiply with correct precedence
TST_EVAL_PREC2  .proc
                UT_BEGIN "TST_EVAL_PREC2"

                setdp GLOBAL_VARS
                setdbr 0

                setaxl

                ; Eval (1+2)*3 == 9
                CALL INITEVALSP

                LDA #<>TEST
                STA BIP
                LDA #`TEST
                STA BIP+2

                CALL EVALEXPR
                ; LDX #<>ARGUMENT1    ; Get the result into ARGUMENT1
                ; CALL PLARGUMENT

                UT_M_EQ_LIT_W ARGUMENT1,9,"EXPECTED 9"

                UT_END
TEST            .text TOK_LPAREN,"1",TOK_PLUS,"2",TOK_RPAREN,TOK_MULT,"3",0
                .pend

; We can evaluate a string literal
TST_EVAL_STR    .proc
                UT_BEGIN "TST_EVAL_STR"

                setdp GLOBAL_VARS
                setdbr 0

                setaxl

                ; Eval (1+2)*3 == 9
                CALL INITEVALSP

                LDA #<>TEST
                STA BIP
                LDA #`TEST
                STA BIP+2

                CALL EVALEXPR

                TRACE "/EVALEXPR"

                UT_M_EQ_LIT_B ARGTYPE1,TYPE_STRING,"EXPECTED STRING"
                LDARG_EA ARGUMENT2,EXPECTED,TYPE_STRING
                CALL STRCMP
                UT_M_EQ_LIT_W ARGUMENT1,0,"EXPECTED 0"
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"

                UT_END
TEST            .null '"ABC"'
EXPECTED        .null "ABC"
                .pend

; We can evaluate negative integers
TST_EVAL_NEG    .proc
                UT_BEGIN "TST_EVAL_NEG"

                setdp GLOBAL_VARS
                setdbr 0

                CALL INITBASIC
                CALL INITEVALSP

                setaxl

                LDA #<>TEST1
                STA BIP
                LDA #`TEST1
                STA BIP+2

                CALL EVALEXPR

                UT_M_EQ_LIT_W ARGUMENT1,1,"EXPECTED 1"

                UT_END
TEST1           .null "2 ", TOK_PLUS, " ", TOK_NEGATIVE, " 1 "
                .pend

;
; Run all the evaluator tests
;
TST_EVAL        .proc
                CALL TST_PUSH_ARG
                CALL TST_PUSH_OP
                CALL TST_OP_MINUS
                CALL TST_OP_MULT
                CALL TST_DIV10
                CALL TST_EVAL_DIVIDE
                CALL TST_EVAL_MOD
                CALL TST_OP_PREC
                CALL TST_OP_PROCESS
                CALL TST_EVAL_INT
                CALL TST_EVAL_INT2
                CALL TST_EVAL_HEX
                CALL TST_EVAL_ADD
                CALL TST_EVAL_MULT
                CALL TST_EVAL_PREC1
                CALL TST_EVAL_PREC2
                CALL TST_EVAL_STR
                CALL TST_EVAL_NEG

                UT_LOG "TST_EVAL: PASSED"
                RETURN
                .pend
