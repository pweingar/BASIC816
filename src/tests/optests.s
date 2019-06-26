;;;
;;; Test Operators
;;;

; Test that we can compare two integers for equality
TST_EQ_INT      .proc
                UT_BEGIN "TST_EQ_INT"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE "10 A%=1=1"
                TSTLINE "20 B%=1=0"

                CALL CMD_RUN

                UT_VAR_EQ_W "A%",TYPE_INTEGER,$FFFF
                UT_VAR_EQ_W "B%",TYPE_INTEGER,0

                UT_END
                .pend

; Test that we can compare two integers for less-than
TST_LT_INT      .proc
                UT_BEGIN "TST_LT_INT"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE "10 A%=0<1"
                TSTLINE "20 B%=1<0"

                CALL CMD_RUN

                UT_VAR_EQ_W "A%",TYPE_INTEGER,$FFFF
                UT_VAR_EQ_W "B%",TYPE_INTEGER,0

                UT_END
                .pend

; Test that we can compare two integers for greater-than
TST_GT_INT      .proc
                UT_BEGIN "TST_GT_INT"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE "10 A%=1>0"
                TSTLINE "20 B%=0>1"

                CALL CMD_RUN

                UT_VAR_EQ_W "A%",TYPE_INTEGER,$FFFF
                UT_VAR_EQ_W "B%",TYPE_INTEGER,0

                UT_END
                .pend

TST_OPS         .proc
                CALL TST_EQ_INT
                CALL TST_LT_INT
                CALL TST_GT_INT

                UT_LOG "TST_OP: PASSED"
                RETURN
                .pend