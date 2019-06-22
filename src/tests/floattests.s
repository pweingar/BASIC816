;;;
;;; Test floating point numbers
;;;

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

                    ; Check that we get an float back
                    setal
                    LDA #16
                    STA ARGUMENT1
                    STX ARGUMENT1+2

                    CALL ITOF               ; Convert the integer to a float
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_FLOAT,"EXPECTED FLOAT"
                    UT_M_EQ_LIT_B EXPONENT1,4,"EXPECTED EXPONENT = 4"
                    UT_M_EQ_LIT_L MANTISSA1,0,"EXPECTED MANTISSA = 0"

                    ; Verify the integer can make the round-trip
                    CALL FTOI
                    UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                    UT_M_EQ_LIT_W ARGUMENT1,16,"EXPECTED 16"

                    UT_END
                    .pend

TST_FLOATS          .proc
                    CALL TST_CONVERT

                    UT_LOG "TST_FLOATS: PASSED"
                    RETURN
                    .pend