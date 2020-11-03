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

; Test that we can compare two integers for greater-than-equals
TST_GTE_INT     .proc
                UT_BEGIN "TST_GTE_INT"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE "10 A%=1 >= 0"
                TSTLINE "20 B%=0 >= 1"
                TSTLINE "30 C%=2 >= 2"

                CALL CMD_RUN

                UT_VAR_EQ_W "A%",TYPE_INTEGER,$FFFF
                UT_VAR_EQ_W "B%",TYPE_INTEGER,0
                UT_VAR_EQ_W "C%",TYPE_INTEGER,$FFFF

                UT_END
                .pend

; Test that we can compare two integers for less-than-equals
TST_LTE_INT     .proc
                UT_BEGIN "TST_LTE_INT"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE "10 A%=0 <= 1"
                TSTLINE "20 B%=1 <= 0"
                TSTLINE "30 C%=2 <= 2"

                CALL CMD_RUN

                UT_VAR_EQ_W "A%",TYPE_INTEGER,$FFFF
                UT_VAR_EQ_W "B%",TYPE_INTEGER,0
                UT_VAR_EQ_W "C%",TYPE_INTEGER,$FFFF

                UT_END
                .pend

; Test that we can compare two integers for greater-than
TST_NE_INT      .proc
                UT_BEGIN "TST_NE_INT"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE "10 A%=1<>0"
                TSTLINE "20 B%=1<>1"

                CALL CMD_RUN

                UT_VAR_EQ_W "A%",TYPE_INTEGER,$FFFF
                UT_VAR_EQ_W "B%",TYPE_INTEGER,0

                UT_END
                .pend


; Test that we can compare two floats for equality
TST_EQ_FLOAT    .proc
                UT_BEGIN "TST_EQ_FLOAT"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE "10 A%=1.25=1.25"
                TSTLINE "20 B%=1.0=0.0"

                CALL CMD_RUN

                UT_VAR_EQ_W "A%",TYPE_INTEGER,$FFFF
                UT_VAR_EQ_W "B%",TYPE_INTEGER,0

                UT_END
                .pend

; Test that we can compare two floats for less-than
TST_LT_FLOAT    .proc
                UT_BEGIN "TST_LT_FLOAT"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE "10 A%=0.0<1.0"
                TSTLINE "20 B%=1.0<0.0"

                CALL CMD_RUN

                UT_VAR_EQ_W "A%",TYPE_INTEGER,$FFFF
                UT_VAR_EQ_W "B%",TYPE_INTEGER,0

                UT_END
                .pend

; Test that we can compare two floats for greater-than
TST_GT_FLOAT    .proc
                UT_BEGIN "TST_GT_FLOAT"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE "10 A%=1.0>0.0"
                TSTLINE "20 B%=0.0>1.0"

                CALL CMD_RUN

                UT_VAR_EQ_W "A%",TYPE_INTEGER,$FFFF
                UT_VAR_EQ_W "B%",TYPE_INTEGER,0

                UT_END
                .pend

; Test that we can compare two floats for greater-than-equals
TST_GTE_FLOAT   .proc
                UT_BEGIN "TST_GTE_FLOAT"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE "10 A%=1.0 >= 0.0"
                TSTLINE "20 B%=0.0 >= 1.0"
                TSTLINE "30 C%=2.0 >= 2.0"

                CALL CMD_RUN

                UT_VAR_EQ_W "A%",TYPE_INTEGER,$FFFF
                UT_VAR_EQ_W "B%",TYPE_INTEGER,0
                UT_VAR_EQ_W "C%",TYPE_INTEGER,$FFFF

                UT_END
                .pend

; Test that we can compare two floats for less-than-equals
TST_LTE_FLOAT   .proc
                UT_BEGIN "TST_LTE_FLOAT"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE "10 A%=0.0 <= 1.0"
                TSTLINE "20 B%=1.0 <= 0.0"
                TSTLINE "30 C%=2.0 <= 2.0"

                CALL CMD_RUN

                UT_VAR_EQ_W "A%",TYPE_INTEGER,$FFFF
                UT_VAR_EQ_W "B%",TYPE_INTEGER,0
                UT_VAR_EQ_W "C%",TYPE_INTEGER,$FFFF

                UT_END
                .pend

; Test that we can compare two integers for greater-than
TST_NE_FLOAT    .proc
                UT_BEGIN "TST_NE_FLOAT"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE "10 A%=1.0<>1.0"
                TSTLINE "20 B%=0.0<>1.0"

                CALL CMD_RUN

                UT_VAR_EQ_W "A%",TYPE_INTEGER,0
                UT_VAR_EQ_W "B%",TYPE_INTEGER,$FFFF

                UT_END
                .pend

; Test that we can compare two strings for equality
TST_EQ_STR      .proc
                UT_BEGIN "TST_EQ_STR"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE "10 A%=(""A""=""A"")"
                TSTLINE "20 B%=(""A""=""D"")"

                CALL CMD_RUN

                UT_VAR_EQ_W "A%",TYPE_INTEGER,$FFFF
                UT_VAR_EQ_W "B%",TYPE_INTEGER,0

                UT_END
                .pend

; Test that we can compare two integers for less-than
TST_LT_STR      .proc
                UT_BEGIN "TST_LT_STR"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE '10 A%=("A"<"Z")'
                TSTLINE '20 B%=("ABC"<"A")'

                CALL CMD_RUN

                UT_VAR_EQ_W "A%",TYPE_INTEGER,$FFFF
                UT_VAR_EQ_W "B%",TYPE_INTEGER,0

                UT_END
                .pend

; Test that we can compare two integers for greater-than
TST_GT_STR      .proc
                UT_BEGIN "TST_GT_STR"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE '10 A%=("Z">"A")'
                TSTLINE '20 B%=("A">"ABC")'

                CALL CMD_RUN

                UT_VAR_EQ_W "A%",TYPE_INTEGER,$FFFF
                UT_VAR_EQ_W "B%",TYPE_INTEGER,0

                UT_END
                .pend

; Test that we can compare two integers for greater-than-equals
TST_GTE_STR     .proc
                UT_BEGIN "TST_GTE_STR"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE '10 A%="B" >= "A"'
                TSTLINE '20 B%="A" >= "B"'
                TSTLINE '30 C%="C" >= "C"'

                CALL CMD_RUN

                UT_VAR_EQ_W "A%",TYPE_INTEGER,$FFFF
                UT_VAR_EQ_W "B%",TYPE_INTEGER,0
                UT_VAR_EQ_W "C%",TYPE_INTEGER,$FFFF

                UT_END
                .pend

; Test that we can compare two integers for less-than-equals
TST_LTE_STR     .proc
                UT_BEGIN "TST_LTE_STR"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE '10 A%="A" <= "B"'
                TSTLINE '20 B%="B" <= "A"'
                TSTLINE '30 C%="C" <= "C"'

                CALL CMD_RUN

                UT_VAR_EQ_W "A%",TYPE_INTEGER,$FFFF
                UT_VAR_EQ_W "B%",TYPE_INTEGER,0
                UT_VAR_EQ_W "C%",TYPE_INTEGER,$FFFF

                UT_END
                .pend

; Test that we can compare two integers for greater-than
TST_NE_STR      .proc
                UT_BEGIN "TST_NE_STR"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE '10 A%="B"<>"A"'
                TSTLINE '20 B%="A"<>"A"'

                CALL CMD_RUN

                UT_VAR_EQ_W "A%",TYPE_INTEGER,$FFFF
                UT_VAR_EQ_W "B%",TYPE_INTEGER,0

                UT_END
                .pend

; Test that we can concatenate two string
TST_EVALSTRCAT  .proc
                UT_BEGIN "TST_EVALSTRCAT"

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setaxl

                CALL INITBASIC

                TSTLINE '10 A$ = "Hello, " + "world!"'

                CALL CMD_RUN

                UT_VAR_EQ_STR "A$", "Hello, world!"

                UT_END
                .pend

TST_OPS         .proc
                CALL TST_EQ_INT
                CALL TST_LT_INT
                CALL TST_GT_INT
                CALL TST_GTE_INT
                CALL TST_LTE_INT
                CALL TST_NE_INT

                CALL TST_EQ_FLOAT
                CALL TST_LT_FLOAT
                CALL TST_GT_FLOAT
                CALL TST_GTE_FLOAT
                CALL TST_LTE_FLOAT
                CALL TST_NE_FLOAT

                CALL TST_EQ_STR
                CALL TST_LT_STR
                CALL TST_GT_STR
                CALL TST_GTE_STR
                CALL TST_LTE_STR
                CALL TST_NE_STR

                CALL TST_EVALSTRCAT

                UT_LOG "TST_OP: PASSED"
                RETURN
                .pend
