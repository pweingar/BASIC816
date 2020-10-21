;;;
;;; Test floating point numbers
;;;

TST_MUL_INT32       .proc
                    UT_BEGIN "TST_MUL_INT32"

                    LD_Q SIGNED32_MULT_A,10
                    LD_Q SIGNED32_MULT_B,5
                    UT_M_EQ_LIT_D SIGNED32_MULT_OUT,50,"Expected 50"

                    UT_END
                    .pend

; Test that we can convert an integer to a float and back again
TST_CONVERT         .proc
                    UT_BEGIN "TST_CONVERT"

                    setal

                    ; Check that 0 converts to 0.0
                    STZ ARGUMENT1
                    STZ ARGUMENT1+2

                    CALL ITOF               ; Convert the integer to a float
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"
                    CALL FARG1EQ0
                    UT_C_SET "EXPECTED 0.0"
                    CALL FP_TO_FIXINT
                    UT_M_EQ_LIT_D ARGUMENT1,0,"Expected 0"

                    ; Check that 1 converts to 1.0
                    LDARG_EA ARGUMENT1,1,TYPE_INTEGER
                    CALL ITOF
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"
                    UT_M_EQ_LIT_D ARGUMENT1,$3f800000,"Expected 1.0 (3f800000)"
                    CALL FP_TO_FIXINT
                    UT_M_EQ_LIT_D ARGUMENT1,1,"Expected 1"

                    ; Check that -1 converts to -1.0
                    LDARG_EA ARGUMENT1,$FFFFFFFF,TYPE_INTEGER
                    CALL ITOF
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"
                    UT_M_EQ_LIT_D ARGUMENT1,$bf800000,"Expected -1.0 (bf800000)"
                    CALL FP_TO_FIXINT
                    UT_M_EQ_LIT_D ARGUMENT1,$FFFFFFFF,"Expected -1"

                    ; Check that 20 converts to 20.0
                    LDARG_EA ARGUMENT1,20,TYPE_INTEGER
                    CALL ITOF
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"
                    UT_M_EQ_LIT_D ARGUMENT1,$41a00000,"Expected 20.0 (41a00000)"
                    CALL FP_TO_FIXINT
                    UT_M_EQ_LIT_D ARGUMENT1,20,"Expected 20"

                    ; Check that -20 converts to -20.0
                    LDARG_EA ARGUMENT1,$FFFFFFEC,TYPE_INTEGER
                    CALL ITOF
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"
                    UT_M_EQ_LIT_D ARGUMENT1,$c1a00000,"Expected -20.0 (c1a00000)"
                    CALL FP_TO_FIXINT
                    UT_M_EQ_LIT_D ARGUMENT1,$FFFFFFEC,"Expected -20"

                    UT_END
                    .pend

; Test that we can add two floats together
TST_FP_ADD          .proc
                    UT_BEGIN "TST_FP_ADD"

                    LDARG_EA ARGUMENT1,20,TYPE_INTEGER      ; ARGUMENT2 <-- 20.0
                    CALL ITOF
                    MOVE_D ARGUMENT2,ARGUMENT1
                    LD_B ARGTYPE2,TYPE_FLOAT

                    LDARG_EA ARGUMENT1,5,TYPE_INTEGER       ; ARGUMENT2 <-- 5.0
                    CALL ITOF

                    CALL OP_FP_ADD                          ; +
                    CALL FP_TO_FIXINT
                    UT_M_EQ_LIT_D ARGUMENT1,25,"Expected 25"

                    LDARG_EA ARGUMENT1,5,TYPE_INTEGER       ; ARGUMENT2 <-- 5.0
                    CALL ITOF
                    MOVE_D ARGUMENT2,ARGUMENT1
                    LD_B ARGTYPE2,TYPE_FLOAT

                    LDARG_EA ARGUMENT1,$FFFFFFFB,TYPE_INTEGER      ; ARGUMENT2 <-- -5.0
                    CALL ITOF

                    CALL OP_FP_ADD                          ; +

                    CALL FARG1EQ0
                    UT_C_SET "EXPECTED 0.0"

                    UT_END
                    .pend

; Test that we can add two floats together
TST_FP_SUB          .proc
                    UT_BEGIN "TST_FP_SUB"

                    LDARG_EA ARGUMENT1,5,TYPE_INTEGER       ; ARGUMENT2 <-- 5.0
                    CALL ITOF
                    MOVE_D ARGUMENT2,ARGUMENT1
                    LD_B ARGTYPE2,TYPE_FLOAT

                    LDARG_EA ARGUMENT1,20,TYPE_INTEGER      ; ARGUMENT2 <-- 20.0
                    CALL ITOF

                    CALL OP_FP_SUB                          ; -
                    CALL FP_TO_FIXINT
                    UT_M_EQ_LIT_D ARGUMENT1,15,"Expected 15"

                    LDARG_EA ARGUMENT1,5,TYPE_INTEGER       ; ARGUMENT2 <-- 5.0
                    CALL ITOF
                    MOVE_D ARGUMENT2,ARGUMENT1
                    LD_B ARGTYPE2,TYPE_FLOAT

                    LDARG_EA ARGUMENT1,5,TYPE_INTEGER       ; ARGUMENT2 <-- 5.0
                    CALL ITOF

                    CALL OP_FP_SUB                          ; -

                    CALL FARG1EQ0
                    UT_C_SET "EXPECTED 0.0"

                    UT_END
                    .pend

; Test that we can multiply two floats together
TST_FP_MUL          .proc
                    UT_BEGIN "TST_FP_MUL"

                    LDARG_EA ARGUMENT1,20,TYPE_INTEGER      ; ARGUMENT2 <-- 20.0
                    CALL ITOF
                    MOVE_D ARGUMENT2,ARGUMENT1
                    LD_B ARGTYPE2,TYPE_FLOAT

                    LDARG_EA ARGUMENT1,5,TYPE_INTEGER       ; ARGUMENT2 <-- 5.0
                    CALL ITOF
                    CALL OP_FP_MUL                          ; *
                    CALL FP_TO_FIXINT
                    UT_M_EQ_LIT_D ARGUMENT1,100,"Expected 100"

                    LDARG_EA ARGUMENT1,5,TYPE_INTEGER       ; ARGUMENT2 <-- 5.0
                    CALL ITOF
                    MOVE_D ARGUMENT2,ARGUMENT1
                    LD_B ARGTYPE2,TYPE_FLOAT

                    LDARG_EA ARGUMENT1,$FFFFFFFB,TYPE_INTEGER      ; ARGUMENT1 <-- -5.0
                    CALL ITOF
                    CALL OP_FP_MUL                          ; *
                    CALL FP_TO_FIXINT
                    UT_M_EQ_LIT_D ARGUMENT1,$FFFFFFE7,"Expected -25"

                    LDARG_EA ARGUMENT1,1,TYPE_INTEGER      ; ARGUMENT1 <-- 1.0
                    CALL ITOF
                    CALL FP_MUL10                          ; * 10
                    CALL FP_TO_FIXINT
                    UT_M_EQ_LIT_D ARGUMENT1,10,"Expected 10"

                    LDARG_EA ARGUMENT1,10000,TYPE_INTEGER      ; ARGUMENT1 <-- 10000.0
                    CALL ITOF
                    CALL FP_MUL10                          ; * 10
                    CALL FP_TO_FIXINT
                    UT_M_EQ_LIT_D ARGUMENT1,100000,"Expected 100000"

                    UT_END
                    .pend

; Test that we can divide two floats together
TST_FP_DIV          .proc
                    UT_BEGIN "TST_FP_DIV"

                    LDARG_EA ARGUMENT1,5,TYPE_INTEGER       ; ARGUMENT2 <-- 5.0
                    CALL ITOF
                    MOVE_D ARGUMENT2,ARGUMENT1
                    LD_B ARGTYPE2,TYPE_FLOAT

                    LDARG_EA ARGUMENT1,20,TYPE_INTEGER      ; ARGUMENT2 <-- 20.0
                    CALL ITOF

                    CALL OP_FP_DIV                          ; /
                    CALL FP_TO_FIXINT
                    UT_M_EQ_LIT_D ARGUMENT1,4,"Expected 4.0"

                    LDARG_EA ARGUMENT1,5,TYPE_INTEGER       ; ARGUMENT2 <-- 5.0
                    CALL ITOF
                    MOVE_D ARGUMENT2,ARGUMENT1
                    LD_B ARGTYPE2,TYPE_FLOAT

                    LDARG_EA ARGUMENT1,$FFFFFFFB,TYPE_INTEGER      ; ARGUMENT2 <-- -5.0
                    CALL ITOF

                    CALL OP_FP_DIV                          ; /
                    CALL FP_TO_FIXINT
                    UT_M_EQ_LIT_D ARGUMENT1,$FFFFFFFF,"Expected -1.0"

                    LDARG_EA ARGUMENT1,10,TYPE_INTEGER      ; ARGUMENT1 <-- 10.0
                    CALL ITOF

                    CALL FP_DIV10                          ; / 10
                    CALL FP_TO_FIXINT
                    UT_M_EQ_LIT_D ARGUMENT1,1,"Expected 1"

                    UT_END
                    .pend

; Test parsing of integers through general number parsing
TST_FP_PARSEINT     .proc
                    UT_BEGIN "TST_FP_PARSEINT"

                    LD_Q BIP, test_num_one                                  ; Parse "1"
                    CALL PARSENUM
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER, "Expected INTEGER" ; Verify we got an integer
                    UT_M_EQ_LIT_D ARGUMENT1,1,"Expected 1"                  ; Verify we got a 1

                    LD_Q BIP, test_num_negone                               ; Parse "-1"
                    CALL PARSENUM
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER, "Expected INTEGER" ; Verify we got an integer
                    UT_M_EQ_LIT_D ARGUMENT1,$FFFFFFFF,"Expected $FFFFFFFF"  ; Verify we got a -1

                    LD_Q BIP, test_num_32                                   ; Parse "32"
                    CALL PARSENUM
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER, "Expected INTEGER" ; Verify we got an integer
                    UT_M_EQ_LIT_D ARGUMENT1,32,"Expected 32"                ; Verify we got a 32

                    LD_Q BIP, test_num_ha3                                  ; Parse "&Ha3"
                    CALL PARSENUM
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER, "Expected INTEGER" ; Verify we got an integer
                    UT_M_EQ_LIT_D ARGUMENT1,$A3,"Expected $A3"              ; Verify we got a $A3

                    LD_Q BIP, test_num_bin                                  ; Parse "&b01010101"
                    CALL PARSENUM
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER, "Expected INTEGER" ; Verify we got an integer
                    UT_M_EQ_LIT_D ARGUMENT1,$55,"Expected $55"              ; Verify we got a $55

                    UT_END
test_num_one        .null "1"
test_num_negone     .null "-1"
test_num_32         .null "32"
test_num_ha3        .null "&Ha3"
test_num_bin        .null "&b01010101"
                    .pend

; Test parsing of integers through general number parsing
TST_FP_PARSEFLOATS  .proc
                    UT_BEGIN "TST_FP_PARSEFLOATS"

                    LD_Q BIP, test_num_1_                                   ; Parse "1."
                    CALL PARSENUM
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT, "Expected FLOAT"     ; Verify we got an float
                    UT_M_EQ_LIT_D ARGUMENT1,$3f800000,"Expected $3f800000 (1.)"  ; Verify we got a 1.0

                    LD_Q BIP, test_num_1_0                                  ; Parse "1.0"
                    CALL PARSENUM
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT, "Expected FLOAT"     ; Verify we got an float
                    UT_M_EQ_LIT_D ARGUMENT1,$3f800000,"Expected $3f800000 (1.0)"  ; Verify we got a 1.0

                    LD_Q BIP, test_num_2_5                                  ; Parse "2.5"
                    CALL PARSENUM
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT, "Expected FLOAT"     ; Verify we got an float
                    UT_M_EQ_LIT_D ARGUMENT1,$40200000,"Expected $40200000"  ; Verify we got a 2.5

                    LD_Q BIP, test_num_31_25                                ; Parse "31.25"
                    CALL PARSENUM
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT, "Expected FLOAT"     ; Verify we got an float
                    UT_M_EQ_LIT_D ARGUMENT1,$41fa0000,"Expected $41fa0000"  ; Verify we got a 31.25

                    LD_Q BIP, test_num_n100_5                               ; Parse "-100.5"
                    CALL PARSENUM
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT, "Expected FLOAT"     ; Verify we got an float
                    UT_M_EQ_LIT_D ARGUMENT1,$c2c90000,"Expected $c2c90000"  ; Verify we got a -100.5

                    LD_Q BIP, test_num_125e3                                ; Parse "1.25E+3"
                    CALL PARSENUM
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT, "Expected FLOAT"     ; Verify we got an float
                    UT_M_EQ_LIT_D ARGUMENT1,$449c4000,"Expected $449c4000"  ; Verify we got a 1250

                    LD_Q BIP, test_num_125e_3                               ; Parse "1.25E-3"
                    CALL PARSENUM
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT, "Expected FLOAT"     ; Verify we got an float
                    UT_M_EQ_LIT_D ARGUMENT1,$3aa3d70a,"Expected $3aa3d70a"  ; Verify we got a 1250

                    UT_END
test_num_1_         .null "1."
test_num_1_0        .null "1.0"
test_num_2_5        .null "2.5"
test_num_31_25      .null "31.25"
test_num_n100_5     .null "-100.5"
test_num_125e3      .null "1.25E+3"
test_num_125e_3     .null "1.25E-3"
                    .pend

; Validate we can convert a floating point number to a string
TST_FP_FTOS         .proc
                    UT_BEGIN "TST_FP_FTOS"

                    LD_Q ARGUMENT1, $3f800000                               ; "1.0"
                    LD_B ARGTYPE1, TYPE_FLOAT
                    CALL FTOS
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_STRING, "Expected STRING"   ; Verify we got an float
                    UT_ARG1STR_EQ expect_1,"Expected ' 1.00000'"            ; Verify that we got ' 1.00000'


                    LD_Q ARGUMENT1, $41200000                               ; "10.0"
                    LD_B ARGTYPE1, TYPE_FLOAT
                    CALL FTOS
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_STRING, "Expected STRING"   ; Verify we got an float
                    UT_ARG1STR_EQ expect_10,"Expected ' 1.00000E01'"        ; Verify that we got ' 1.00000E01'

                    LD_Q ARGUMENT1, $3f000000                               ; "0.5"
                    LD_B ARGTYPE1, TYPE_FLOAT
                    CALL FTOS
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_STRING, "Expected STRING"   ; Verify we got an float
                    UT_ARG1STR_EQ expect_05,"Expected ' 0.50000E-01'"       ; Verify that we got ' 0.50000E-01'

                    LD_Q ARGUMENT1, $c2c80000                               ; -100.0
                    LD_B ARGTYPE1, TYPE_FLOAT
                    CALL FTOS
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_STRING, "Expected STRING"   ; Verify we got an float
                    UT_ARG1STR_EQ expect_n100,"Expected '-1.00000E02'"      ; Verify that we got '-1.00000E02'\

                    LD_Q ARGUMENT1, $3fa00000                               ; 1.25
                    LD_B ARGTYPE1, TYPE_FLOAT
                    CALL FTOS
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_STRING, "Expected STRING"   ; Verify we got an float
                    UT_ARG1STR_EQ expect_125,"Expected ' 1.25000'"          ; Verify that we got ' 1.25000'

                    UT_END
expect_1            .null " 1.00000"
expect_10           .null " 1.00000E01"
expect_05           .null " 5.00000E-01"
expect_n100         .null "-1.00000E02"
expect_125          .null " 1.25000"
                    .pend

; Test that the operators work with floating point numbers
; That is +, -, * on two floats, or a float and an int should return a float
TST_FLOAT_OPS       .proc
                    UT_BEGIN "TST_FLOAT_OPS"

                    ; FLOAT + FLOAT -> FLOAT
                    LD_Q ARGUMENT1, $3fa00000                               ; 1.25
                    LD_B ARGTYPE1, TYPE_FLOAT       
                    LD_Q ARGUMENT2, $3e800000                               ; 0.25
                    LD_B ARGTYPE2, TYPE_FLOAT
                    CALL OP_PLUS                                            ; +
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT, "Expected FLOAT"     ; Verify we got an float
                    UT_M_EQ_LIT_D ARGUMENT1,$3fc00000,"Expected $3fc00000"  ; Verify we got a 1.5

                    ; INT + FLOAT -> FLOAT
                    LD_Q ARGUMENT1, 1                                       ; 1
                    LD_B ARGTYPE1, TYPE_INTEGER       
                    LD_Q ARGUMENT2, $3e800000                               ; 0.25
                    LD_B ARGTYPE2, TYPE_FLOAT
                    CALL OP_PLUS                                            ; +
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT, "Expected FLOAT"     ; Verify we got an float
                    UT_M_EQ_LIT_D ARGUMENT1,$3fa00000,"Expected $3fa00000"  ; Verify we got a 1.25

                    ; FLOAT + INT -> FLOAT
                    LD_Q ARGUMENT1, $3fa00000                               ; 1.25
                    LD_B ARGTYPE1, TYPE_FLOAT       
                    LD_Q ARGUMENT2, 1                                       ; 1
                    LD_B ARGTYPE2, TYPE_INTEGER
                    CALL OP_PLUS                                            ; +
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT, "Expected FLOAT"     ; Verify we got an float
                    UT_M_EQ_LIT_D ARGUMENT1,$40100000,"Expected $40100000"  ; Verify we got a 2.25

                    ; FLOAT - FLOAT -> FLOAT
                    LD_Q ARGUMENT1, $3fa00000                               ; 1.25
                    LD_B ARGTYPE1, TYPE_FLOAT       
                    LD_Q ARGUMENT2, $3e800000                               ; 0.25
                    LD_B ARGTYPE2, TYPE_FLOAT
                    CALL OP_MINUS                                           ; -
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT, "Expected FLOAT"     ; Verify we got an float
                    UT_M_EQ_LIT_D ARGUMENT1,$3f800000,"Expected $3f800000"  ; Verify we got a 1.0

                    ; INT - FLOAT -> FLOAT
                    LD_Q ARGUMENT1, 1                                       ; 1
                    LD_B ARGTYPE1, TYPE_INTEGER       
                    LD_Q ARGUMENT2, $3e800000                               ; 0.25
                    LD_B ARGTYPE2, TYPE_FLOAT
                    CALL OP_MINUS                                           ; +
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT, "Expected FLOAT"     ; Verify we got an float
                    UT_M_EQ_LIT_D ARGUMENT1,$3f400000,"Expected $3f400000"  ; Verify we got a 0.75

                    ; FLOAT - INT -> FLOAT
                    LD_Q ARGUMENT1, $3fa00000                               ; 1.25
                    LD_B ARGTYPE1, TYPE_FLOAT       
                    LD_Q ARGUMENT2, 1                                       ; 1
                    LD_B ARGTYPE2, TYPE_INTEGER
                    CALL OP_MINUS                                           ; +
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT, "Expected FLOAT"     ; Verify we got an float
                    UT_M_EQ_LIT_D ARGUMENT1,$3e800000,"Expected $3e800000"  ; Verify we got a 0.25

                    ; FLOAT * FLOAT -> FLOAT
                    LD_Q ARGUMENT1, $3fa00000                               ; 1.25
                    LD_B ARGTYPE1, TYPE_FLOAT       
                    LD_Q ARGUMENT2, $3e800000                               ; 0.25
                    LD_B ARGTYPE2, TYPE_FLOAT
                    CALL OP_MULTIPLY                                        ; *
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT, "Expected FLOAT"     ; Verify we got an float
                    UT_M_EQ_LIT_D ARGUMENT1,$3ea00000,"Expected $3ea00000"  ; Verify we got a 0.325

                    ; INT * FLOAT -> FLOAT
                    LD_Q ARGUMENT1, 1                                       ; 1
                    LD_B ARGTYPE1, TYPE_INTEGER       
                    LD_Q ARGUMENT2, $3e800000                               ; 0.25
                    LD_B ARGTYPE2, TYPE_FLOAT
                    CALL OP_MULTIPLY                                        ; *
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT, "Expected FLOAT"     ; Verify we got an float
                    UT_M_EQ_LIT_D ARGUMENT1,$3e800000,"Expected $3e800000"  ; Verify we got a 0.25

                    ; FLOAT * INT -> FLOAT
                    LD_Q ARGUMENT1, $3fa00000                               ; 1.25
                    LD_B ARGTYPE1, TYPE_FLOAT       
                    LD_Q ARGUMENT2, 1                                       ; 1
                    LD_B ARGTYPE2, TYPE_INTEGER
                    CALL OP_MULTIPLY                                        ; *
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT, "Expected FLOAT"     ; Verify we got an float
                    UT_M_EQ_LIT_D ARGUMENT1,$3fa00000,"Expected $3fa00000"  ; Verify we got a 1.25

                    UT_END
                    .pend

; Validate we can print floating point numbers
TST_PRINTFLOAT      .proc
                    UT_BEGIN "TST_PRINTFLOAT"

                    setdp GLOBAL_VARS
                    setdbr BASIC_BANK

                    setaxl

                    CALL INITBASIC

                    TSTLINE "10 PRINT 1.25"

                    setal

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

                    CALL CMD_RUN

                    CALL OBUFF_CLOSE

                    UT_STR_EQ TMP_BUFF_ORG,EXPECTED,"EXPECTED ' 1.25000{CR}'"

                    UT_END
EXPECTED            .null " 1.25000",13
                    .pend

TST_FLOATS          .proc
                    ; CALL TST_MUL_INT32
                    CALL TST_CONVERT
                    CALL TST_FP_ADD
                    CALL TST_FP_SUB
                    CALL TST_FP_MUL
                    CALL TST_FP_DIV
                    CALL TST_FP_PARSEINT
                    CALL TST_FP_PARSEFLOATS
                    CALL TST_FP_FTOS
                    CALL TST_FLOAT_OPS
                    ; CALL TST_PRINTFLOAT

                    UT_PASSED "TST_FLOATS"
                    RETURN
                    .pend