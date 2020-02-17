;;;
;;; Test floating point numbers
;;;

; Test that we can convert an integer to a float and back again
TST_CONVERT         .proc
                    UT_BEGIN "TST_CONVERT"

                    ; Set up our integer
                    setas
                    LDA #TYPE_INTEGER
                    STA ARGTYPE1

                    setal
                    LDA #42
                    STA ARGUMENT1
                    STZ ARGUMENT1+2

                    CALL ITOF               ; Convert the integer to a float
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"

                    ; Verify the integer can make the round-trip
                    CALL FTOI
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                    UT_M_EQ_LIT_W ARGUMENT1,42,"EXPECTED 42"

                    UT_END
                    .pend

; Test that we can convert integers to a float and add them together
TST_FADD_INT        .proc
                    UT_BEGIN "TST_FADD_INT"

                    ; Set up our first integer
                    setas
                    LDA #TYPE_INTEGER
                    STA ARGTYPE1

                    setal
                    LDA #40
                    STA ARGUMENT1
                    STZ ARGUMENT1+2

                    CALL ITOF               ; Convert the integer to a float
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"

                    setal
                    LDA ARGUMENT1           ; Save the first float in ARGUMENT2
                    STA ARGUMENT2
                    LDA ARGUMENT1+2
                    STA ARGUMENT2+2
                    setas
                    LDA #TYPE_FLOAT
                    STA ARGTYPE2

                    ; Set up our second integer

                    LDA #TYPE_INTEGER
                    STA ARGTYPE1

                    setal
                    LDA #2
                    STA ARGUMENT1
                    STZ ARGUMENT1+2

                    CALL ITOF               ; Convert the integer to a float
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"

                    CALL OP_FP_ADD          ; Attempt to add them
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"

                    ; Verify the integer can make the round-trip
                    CALL FTOI
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                    UT_M_EQ_LIT_W ARGUMENT1,42,"EXPECTED 42"

                    UT_END
                    .pend

; Test that we can convert integers to a float and subtract the first from the second
TST_FSUB_INT        .proc
                    UT_BEGIN "TST_FSUB_INT"

                    ; Set up our first integer
                    setas
                    LDA #TYPE_INTEGER
                    STA ARGTYPE1

                    setal
                    LDA #2
                    STA ARGUMENT1
                    STZ ARGUMENT1+2

                    CALL ITOF               ; Convert the integer to a float
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"

                    setal
                    LDA ARGUMENT1           ; Save the first float in ARGUMENT2
                    STA ARGUMENT2
                    LDA ARGUMENT1+2
                    STA ARGUMENT2+2
                    setas
                    LDA #TYPE_FLOAT
                    STA ARGTYPE2

                    ; Set up our second integer

                    LDA #TYPE_INTEGER
                    STA ARGTYPE1

                    setal
                    LDA #44
                    STA ARGUMENT1
                    STZ ARGUMENT1+2

                    CALL ITOF               ; Convert the integer to a float
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"

                    CALL OP_FP_SUB          ; Attempt to subtract them
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"

                    ; Verify the integer can make the round-trip
                    CALL FTOI
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                    UT_M_EQ_LIT_W ARGUMENT1,42,"EXPECTED 42"

                    UT_END
                    .pend

; Test that we can convert integers to a float and multiply them together
TST_FMUL_INT        .proc
                    UT_BEGIN "TST_FMUL_INT"

                    ; Set up our first integer
                    setas
                    LDA #TYPE_INTEGER
                    STA ARGTYPE1

                    setal
                    LDA #6
                    STA ARGUMENT1
                    STZ ARGUMENT1+2

                    CALL ITOF               ; Convert the integer to a float
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"

                    setal
                    LDA ARGUMENT1           ; Save the first float in ARGUMENT2
                    STA ARGUMENT2
                    LDA ARGUMENT1+2
                    STA ARGUMENT2+2
                    setas
                    LDA #TYPE_FLOAT
                    STA ARGTYPE2

                    ; Set up our second integer

                    LDA #TYPE_INTEGER
                    STA ARGTYPE1

                    setal
                    LDA #7
                    STA ARGUMENT1
                    STZ ARGUMENT1+2

                    CALL ITOF               ; Convert the integer to a float
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"

                    CALL OP_FP_MUL          ; Attempt to add them
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"

                    ; Verify the integer can make the round-trip
                    CALL FTOI
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                    UT_M_EQ_LIT_W ARGUMENT1,42,"EXPECTED 42"

                    UT_END
                    .pend

; Test that we can convert integers to a float and divide them
TST_FDIV_INT        .proc
                    UT_BEGIN "TST_FDIV_INT"

                    ; Set up our first integer
                    setas
                    LDA #TYPE_INTEGER
                    STA ARGTYPE1

                    setal
                    LDA #6
                    STA ARGUMENT1
                    STZ ARGUMENT1+2

                    CALL ITOF               ; Convert the integer to a float
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"

                    setal
                    LDA ARGUMENT1           ; Save the first float in ARGUMENT2
                    STA ARGUMENT2
                    LDA ARGUMENT1+2
                    STA ARGUMENT2+2
                    setas
                    LDA #TYPE_FLOAT
                    STA ARGTYPE2

                    ; Set up our second integer

                    LDA #TYPE_INTEGER
                    STA ARGTYPE1

                    setal
                    LDA #42
                    STA ARGUMENT1
                    STZ ARGUMENT1+2

                    CALL ITOF               ; Convert the integer to a float
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"

                    CALL OP_FP_DIV          ; Attempt to add them
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"

                    ; Verify the integer can make the round-trip
                    CALL FTOI
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                    UT_M_EQ_LIT_W ARGUMENT1,7,"EXPECTED 7"

                    UT_END
                    .pend

; Test that we can move floating point numbers into and out of the floating point accumulator
TST_PACKING         .proc
                    UT_BEGIN "TST_PACKING"

                    ; Try 42
                    
                    setas
                    LDA #TYPE_INTEGER
                    STA ARGTYPE1

                    setal
                    LDA #42
                    STA ARGUMENT1
                    STZ ARGUMENT1+2

                    CALL ITOF               ; Convert the integer to a float
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"

                    CALL ARG1TOACC          ; Unpack the float into the floating point accumulator

                    UT_M_EQ_LIT_L FMANT,$280000,"EXPECTED FMANT=$280000"
                    UT_M_EQ_LIT_B FEXP,$84,"EXPECTED FEXP=$84"   
                    UT_M_EQ_LIT_B FFLAGS,0,"EXPECTED FFLAGS=0"  

                    setal
                    STZ ARGUMENT1
                    STZ ARGUMENT1+2

                    CALL ACCTOARG1          ; Pack the float

                    UT_M_EQ_LIT_D ARGUMENT1,$42280000,"EXPECTED ARGUMENT1=$42280000"

                    ; Try -1

                    setas
                    LDA #TYPE_INTEGER
                    STA ARGTYPE1

                    setal
                    LDA #$FFFF
                    STA ARGUMENT1
                    STA ARGUMENT1+2

                    CALL ITOF               ; Convert the integer to a float
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"

                    CALL ARG1TOACC          ; Unpack the float into the floating point accumulator

                    UT_M_EQ_LIT_L FMANT,0,"EXPECTED FMANT=0"
                    UT_M_EQ_LIT_B FEXP,$7F,"EXPECTED FEXP=$7F"   
                    UT_M_EQ_LIT_B FFLAGS,$80,"EXPECTED FFLAGS=$80"  

                    setal
                    STZ ARGUMENT1
                    STZ ARGUMENT1+2

                    CALL ACCTOARG1          ; Pack the float

                    UT_M_EQ_LIT_D ARGUMENT1,$BF800000,"EXPECTED ARGUMENT1+2=$BF800000"

                    UT_END
                    .pend

; Verify that we can parse a floating point number
TST_STON            .proc
                    UT_BEGIN "TST_STON"

                    LD_L BIP,tst_number1    ; 1
                    CALL STON
                    UT_M_EQ_LIT_D ARGUMENT1, $3f800000, "EXPECTED ston('1') = $3f800000"

                    LD_L BIP,tst_number2    ; -1
                    CALL STON
                    UT_M_EQ_LIT_D ARGUMENT1, $BF800000, "EXPECTED ston('-1') = $BF800000"

                    LD_L BIP,tst_number3    ; 2
                    CALL STON
                    UT_M_EQ_LIT_D ARGUMENT1, $40000000, "EXPECTED ston('2') = $40000000"

                    LD_L BIP,tst_number4    ; -2
                    CALL STON
                    UT_M_EQ_LIT_D ARGUMENT1, $C0000000, "EXPECTED ston('-2') = $C0000000"   

                    LD_L BIP,tst_number5    ; 1.0
                    CALL STON
                    UT_M_EQ_LIT_D ARGUMENT1, $3f800000, "EXPECTED ston('1.0') = $3f800000" 

                    ; TODO: not passing... some sort of rounding issue. Returns 3.1415899
                    ; LD_L BIP,tst_number6    ; 3.14159
                    ; CALL STON
                    ; UT_M_EQ_LIT_D ARGUMENT1, $40490FD0, "EXPECTED ston('3.14159') = $40490FD0"   

                    LD_L BIP,tst_number7    ;0.25
                    CALL STON
                    UT_M_EQ_LIT_D ARGUMENT1, $3E800000, "EXPECTED ston('0.25') = $3E800000"      

                    LD_L BIP,tst_number8    ;123.0
                    CALL STON
                    UT_M_EQ_LIT_D ARGUMENT1, $42f60000, "EXPECTED ston('123') = $42f60000"         

                    UT_END
tst_number1         .null "1"
tst_number2         .null "-1"
tst_number3         .null "2"
tst_number4         .null "-2"
tst_number5         .null "1.0"
tst_number6         .null "3.14159"
tst_number7         .null "0.25"
tst_number8         .null "123"
                    .pend

; Verify that we can convert a floating point number to a string
TST_FTOS            .proc
                    UT_BEGIN "TST_FTOS"

                    ; Try 0.0
                    setal
                    STZ ARGUMENT1
                    STZ ARGUMENT1+2
                    setas
                    LDA #TYPE_FLOAT
                    STA ARGTYPE1
                    setal

                    CALL FTOS

                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_STRING,"Expected a string"
                    UT_ARG1STR_EQ expected0,"Expected that 0.0 => '0'"

                    ; ; Try 1.0
                    ; setal
                    ; STZ ARGUMENT1
                    ; LDA #$3f80
                    ; STA ARGUMENT1+2
                    ; setas
                    ; LDA #TYPE_FLOAT
                    ; STA ARGTYPE1
                    ; setal

                    ; CALL FTOS

                    ; UT_M_EQ_LIT_B ARGTYPE1,TYPE_STRING,"Expected a string"
                    ; UT_ARG1STR_EQ expected1,"Expected that 1.0 => '1'"

                    ; Try 123
                    setal
                    STZ ARGUMENT1
                    LDA #$42f6
                    STA ARGUMENT1+2
                    setas
                    LDA #TYPE_FLOAT
                    STA ARGTYPE1
                    setal

                    CALL FTOS

                    BRK

                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_STRING,"Expected a string"
                    UT_ARG1STR_EQ expected123,"Expected that 123.0 => '123'"                    

                    UT_END
expected0           .null "0"
expected1           .null "1"
expected123         .null "123"
                    .pend

TST_FLOATS          .proc
                    CALL TST_CONVERT
                    CALL TST_FADD_INT
                    CALL TST_FSUB_INT
                    CALL TST_FMUL_INT
                    CALL TST_FDIV_INT
                    ; CALL TST_PACKING
                    CALL TST_STON
                    CALL TST_FTOS

                    UT_LOG "TST_FLOATS: PASSED"
                    RETURN
                    .pend