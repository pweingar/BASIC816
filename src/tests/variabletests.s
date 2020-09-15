;;;
;;; Tests of variables
;;;

; Can create a and find variable
TST_VAR_CREATE  .proc
                UT_BEGIN "TST_VAR_CREATE"

                setdp <>GLOBAL_VARS

                CALL INITBASIC

                setal
                LDA #<>VARNAME
                STA TOFIND
                setas
                LDA #`VARNAME
                STA TOFIND+2

                LDA #TYPE_INTEGER
                STA TOFINDTYPE
                STA ARGTYPE1

                setal
                LDA #$1234
                STA ARGUMENT1
                LDA #0
                STA ARGUMENT1+2

                ; Check that we can allocate the variable on the heap

                CALL VAR_CREATE
                UT_M_NE_LIT_L VARIABLES,0,"EXPECTED NON-ZERO"

                setas
                LDY #BINDING.TYPE
                LDA [VARIABLES],Y
                UT_A_EQ_LIT_B TYPE_INTEGER,"EXPECTED INTEGER"

                LDY #BINDING.NAME
                LDA [VARIABLES],Y
                UT_A_EQ_LIT_B 'A',"EXPECTED A"
                INY
                LDA [VARIABLES],Y
                UT_A_EQ_LIT_B 0,"EXPECTED NULL"

                ; Check that we can find it again
                setal
                LDA #<>VARNAME
                STA TOFIND
                setas
                LDA #`VARNAME
                STA TOFIND+2

                LDA #TYPE_INTEGER
                STA TOFINDTYPE

                CALL VAR_FIND
                UT_C_SET "COULD NOT FIND A"
                UT_M_EQ_M_L INDEX,VARIABLES,"EXPECTED INDEX == VARIABLES"

                UT_END
VARNAME         .null "A%"
                .pend

; Test that we can look up a value of a variable
TST_VAR_LOOKUP  .proc
                UT_BEGIN "TST_VAR_LOOKUP"

                ; Create the variable
                setdp <>GLOBAL_VARS

                CALL INITBASIC

                setal
                LDA #<>VARNAME
                STA TOFIND
                setas
                LDA #`VARNAME
                STA TOFIND+2

                LDA #TYPE_INTEGER
                STA TOFINDTYPE
                STA ARGTYPE1

                setal
                LDA #$1234
                STA ARGUMENT1
                LDA #0
                STA ARGUMENT1+2

                CALL VAR_CREATE

                ; Check that we can get the value back
                CALL INITEVALSP         ; Clear arguments

                setal
                LDA #<>VARNAME
                STA TOFIND
                setas
                LDA #`VARNAME
                STA TOFIND+2

                LDA #TYPE_INTEGER
                STA TOFINDTYPE

                CALL VAR_REF            ; Try to get the result
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                UT_M_EQ_LIT_W ARGUMENT1,$1234,"EXPECTED $1234"

                UT_END
VARNAME         .null "A%"
                .pend

; Test that we can look up a value of a variable
TST_VAR_SET     .proc
                UT_BEGIN "TST_VAR_SET"

                ; Create the variable
                setdp <>GLOBAL_VARS

                CALL INITBASIC

                setal
                LDA #<>VARNAME
                STA TOFIND
                setas
                LDA #`VARNAME
                STA TOFIND+2

                LDA #TYPE_INTEGER
                STA TOFINDTYPE
                STA ARGTYPE1

                setal
                LDA #$1234
                STA ARGUMENT1
                LDA #0
                STA ARGUMENT1+2

                CALL VAR_CREATE

                ; Try to set the new value
 
                setal
                LDA #<>VARNAME
                STA TOFIND
                setas
                LDA #`VARNAME
                STA TOFIND+2

                LDA #TYPE_INTEGER
                STA TOFINDTYPE    

                setal
                LDA #$5678
                STA ARGUMENT1
                LDA #0
                STA ARGUMENT1+2
                setas
                LDA #TYPE_INTEGER
                STA ARGTYPE1

                CALL VAR_SET           

                ; Check that we can get the new value back
                CALL INITEVALSP         ; Clear arguments

                setal
                LDA #<>VARNAME
                STA TOFIND
                setas
                LDA #`VARNAME
                STA TOFIND+2

                LDA #TYPE_INTEGER
                STA TOFINDTYPE

                CALL VAR_REF            ; Try to get the result
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                UT_M_EQ_LIT_W ARGUMENT1,$5678,"EXPECTED $5678"

                UT_END
VARNAME         .null "A%"
                .pend


; Test that we create and reference multiple variables
TST_VAR_MULTI   .proc
                UT_BEGIN "TST_VAR_MULTI"

                ; Create the variable
                setdp <>GLOBAL_VARS

                CALL INITBASIC

                setal
                LDA #<>VAR_A
                STA TOFIND
                setas
                LDA #`VAR_A
                STA TOFIND+2

                LDA #TYPE_INTEGER
                STA TOFINDTYPE
                STA ARGTYPE1

                LDARG_EA ARGUMENT1,$1234,TYPE_INTEGER

                CALL VAR_SET

                TRACE "SET ABC%"

                ; Try to set the new value
 
                setal
                LDA #<>VAR_B
                STA TOFIND
                setas
                LDA #`VAR_B
                STA TOFIND+2

                LDA #TYPE_INTEGER
                STA TOFINDTYPE    

                LDARG_EA ARGUMENT1,$5678,TYPE_INTEGER

                CALL VAR_SET

                TRACE "SET B%"       

                ; Verify that A%=$1234
                CALL INITEVALSP         ; Clear arguments

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
                UT_M_EQ_LIT_W ARGUMENT1,$1234,"EXPECTED $1234"

                TRACE "GOT ABC%"

                ; Verify that B%=$5678
                CALL INITEVALSP         ; Clear arguments

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
                UT_M_EQ_LIT_W ARGUMENT1,$5678,"EXPECTED $5678"

                UT_END
VAR_A           .null "abc%"
VAR_B           .null "B%"
                .pend

; Test that we can assign the same variable twice
TST_VAR_REPEAT  .proc
                UT_BEGIN "TST_VAR_REPEAT"

                ; Create the variable
                setdp <>GLOBAL_VARS

                CALL INITBASIC

                setal
                LDA #<>VAR_A
                STA TOFIND
                setas
                LDA #`VAR_A
                STA TOFIND+2

                LDA #TYPE_STRING
                STA TOFINDTYPE
                STA ARGTYPE1

                LDARG_EA ARGUMENT1,MESSAGE,TYPE_STRING
                CALL STRCPY

                CALL VAR_SET

                TRACE "SET A$"

                ; Try to set the new value
 
                setal
                LDA #<>VAR_A
                STA TOFIND
                setas
                LDA #`VAR_A
                STA TOFIND+2

                LDA #TYPE_STRING
                STA TOFINDTYPE
                STA ARGTYPE1

                LDARG_EA ARGUMENT1,MESSAGE2,TYPE_STRING
                CALL STRCPY

                CALL VAR_SET

                TRACE "SET A$ AGAIN" 

                setal
                LDA #<>VAR_A
                STA TOFIND
                setas
                LDA #`VAR_A
                STA TOFIND+2

                LDA #TYPE_STRING
                STA TOFINDTYPE
                STA ARGTYPE1    

                CALL VAR_REF            ; Try to get the result

                UT_M_EQ_LIT_B ARGTYPE1,TYPE_STRING,"EXPECTED STRING"
                MOVE_D TST_TEMP1,ARGUMENT1
                UT_STRIND_EQ TST_TEMP1,MESSAGE2,"EXPECTED 'Goodbye'"

                UT_END
VAR_A           .null "A$"
MESSAGE         .null "Hello"
MESSAGE2        .null "Goodbye"
                .pend

;
; Run all the evaluator tests
;
TST_VARIABLES   .proc
                CALL TST_VAR_CREATE
                CALL TST_VAR_LOOKUP
                CALL TST_VAR_SET
                CALL TST_VAR_MULTI
                CALL TST_VAR_REPEAT

                UT_LOG "TST_VARIABLES: PASSED"
                RETURN
                .pend