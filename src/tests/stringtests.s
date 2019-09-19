;;;
;;; Tests for string functions
;;;

; Test that we can allocate a block
TST_STRLEN      .proc
                UT_BEGIN "TST_STRLEN"

                setdp GLOBAL_VARS
                setdbr `TEST
                setaxl

                LDX #<>TEST
                CALL STRLEN
                TYA

                UT_A_EQ_LIT_W len(TEST)-1,format("EXPECTED %x", len(TEST)-1)

                UT_END
TEST            .null "This is a test"
                .databank BASIC_BANK
                .pend

; Test that we can compare two strings
TST_STRCMP      .proc
                UT_BEGIN "TST_STRCMP"

                setdp GLOBAL_VARS

                ; Test: "ABC" = "ABC"
                LDARG_EA ARGUMENT1,STRING1,TYPE_STRING
                LDARG_EA ARGUMENT2,STRING2,TYPE_STRING
                CALL STRCMP
                UT_M_EQ_LIT_W ARGUMENT1,0,"EXPECTED 0"
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"

                ; Test: "ABC" < "ABD"
                LDARG_EA ARGUMENT1,STRING1,TYPE_STRING
                LDARG_EA ARGUMENT2,STRING3,TYPE_STRING
                CALL STRCMP
                UT_M_EQ_LIT_W ARGUMENT1,$FFFF,"EXPECTED -1"
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"

                ; Test: "ABD" > "ABC"
                LDARG_EA ARGUMENT1,STRING3,TYPE_STRING
                LDARG_EA ARGUMENT2,STRING1,TYPE_STRING
                CALL STRCMP
                UT_M_EQ_LIT_W ARGUMENT1,1,"EXPECTED 1"
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"

                ; Test: "ABC" < "ABCD"
                LDARG_EA ARGUMENT1,STRING1,TYPE_STRING
                LDARG_EA ARGUMENT2,STRING4,TYPE_STRING
                CALL STRCMP
                UT_M_EQ_LIT_W ARGUMENT1,$FFFF,"EXPECTED -1"
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"

                ; Test: "ABCD" > "ABC"
                LDARG_EA ARGUMENT1,STRING4,TYPE_STRING
                LDARG_EA ARGUMENT2,STRING1,TYPE_STRING
                CALL STRCMP
                UT_M_EQ_LIT_W ARGUMENT1,1,"EXPECTED 1"
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"

                UT_END

STRING1         .null "ABC"
STRING2         .null "ABC"
STRING3         .null "ABD"
STRING4         .null "ABCD"
                .pend

; Test that we can concatenate two strings
TST_STRCONCAT   .proc
                UT_BEGIN "TST_STRCONCAT"

                setdp GLOBAL_VARS
                setdbr `GLOBAL_VARS
                setaxl

                LDA #<>TEST1
                STA ARGUMENT1
                LDA #`TEST1
                STA ARGUMENT1+2

                LDA #<>TEST2
                STA ARGUMENT2
                LDA #`TEST2
                STA ARGUMENT2+2

                CALL STRCONCAT

                TRACE "EXIT STRCONCAT"

                setas
                LDDBR ARGUMENT1+2
                LDX ARGUMENT1
                CALL STRLEN

                setal
                TYA        

                ; Validate the size and type of the resulting string
                UT_A_EQ_LIT_W 6,"EXPECTED 6"
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_STRING,"EXPECTED STRING"

                ; Validate that the header for the allocated string is shown as
                ; being of type string
                setal
                LDA ARGUMENT1
                STA CURRBLOCK
                setas
                LDA ARGUMENT1+2
                STA CURRBLOCK+2
                CALL HEAP_GETHED

                LDY #HEAPOBJ.TYPE
                LDA [CURRHEADER],Y
                UT_A_EQ_LIT_B TYPE_STRING,"EXPECTED STRING HEADER"

                LDARG_EA ARGUMENT2,EXPECTED,TYPE_STRING
                CALL STRCMP
                UT_M_EQ_LIT_W ARGUMENT1,0,"EXPECTED 0"
                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"

                UT_END
TEST1           .null "ABC"
TEST2           .null "XYZ"
EXPECTED        .null "ABCXYZ"
                .databank BASIC_BANK
                .pend

TST_ITOS        .proc
                UT_BEGIN "TST_ITOS"

                setal               ; Set ARGUMENT1 to 123
                LDA #123
                STA @lARGUMENT1
                LDA #0
                STA @lARGUMENT1+2
                setas
                LDA #TYPE_INTEGER
                STA ARGTYPE1

                CALL ITOS
                UT_STRIND_EQ STRPTR, EXPECTED1, "EXPECTED 123"

                setal               ; Set ARGUMENT1 to -5678
                LDA #-5678
                STA @lARGUMENT1
                LDA #$FFFF
                STA @lARGUMENT1+2
                setas
                LDA #TYPE_INTEGER
                STA ARGTYPE1

                CALL ITOS
                UT_STRIND_EQ STRPTR, EXPECTED2, "EXPECTED -5678"

                UT_END
EXPECTED1       .null " 123"
EXPECTED2       .null "-5678"
                .pend

; Test that we can get various substrings
TST_SUBSTR      .proc
                UT_BEGIN "TST_SUBSTR"

                setaxl

                ; "Hello" := STRSUBSTR("Hello",0,5)
                LD_Q ARGUMENT1,STRING1
                LD_B ARGTYPE1,TYPE_STRING

                LD_Q ARGUMENT2,0
                LD_B ARGTYPE2,TYPE_INTEGER

                LD_W MCOUNT,5
                CALL STRSUBSTR

                MOVE_L STRPTR,ARGUMENT1
                UT_STRIND_EQ STRPTR,EXPECT1,"Expected Hello"

                ; "Hel" := STRSUBSTR("Hello",0,3)
                LD_Q ARGUMENT1,STRING1
                LD_B ARGTYPE1,TYPE_STRING

                LD_Q ARGUMENT2,0
                LD_B ARGTYPE2,TYPE_INTEGER

                LD_W MCOUNT,3
                CALL STRSUBSTR

                MOVE_L STRPTR,ARGUMENT1
                UT_STRIND_EQ STRPTR,EXPECT2,"Expected Hel"

                ; "lo" := STRSUBSTR("Hello",3,10)

                LD_Q ARGUMENT1,STRING1
                LD_B ARGTYPE1,TYPE_STRING

                LD_Q ARGUMENT2,3
                LD_B ARGTYPE2,TYPE_INTEGER

                LD_W MCOUNT,10

                CALL STRSUBSTR

                MOVE_L STRPTR,ARGUMENT1
                UT_STRIND_EQ STRPTR,EXPECT3,"Expected lo"

                ; "el" := STRSUBSTR("Hello",1,2)
                LD_Q ARGUMENT1,STRING1
                LD_B ARGTYPE1,TYPE_STRING

                LD_Q ARGUMENT2,1
                LD_B ARGTYPE2,TYPE_INTEGER

                LD_W MCOUNT,2
                CALL STRSUBSTR

                MOVE_L STRPTR,ARGUMENT1
                UT_STRIND_EQ STRPTR,EXPECT4,"Expected el"

                ; "" := STRSUBSTR("Hello",10,2)
                LD_Q ARGUMENT1,STRING1
                LD_B ARGTYPE1,TYPE_STRING

                LD_Q ARGUMENT2,10
                LD_B ARGTYPE2,TYPE_INTEGER

                LD_W MCOUNT,2
                CALL STRSUBSTR

                MOVE_L STRPTR,ARGUMENT1
                UT_STRIND_EQ STRPTR,EXPECT5,"Expected empty string"

                UT_END
STRING1         .null "Hello"
EXPECT1         .null "Hello"
EXPECT2         .null "Hel"
EXPECT3         .null "lo"
EXPECT4         .null "el"
EXPECT5         .null ""
                .pend
;
; Run all the evaluator tests
;
TST_STRINGS     .proc
                CALL TST_STRLEN
                CALL TST_STRCMP
                CALL TST_STRCONCAT
                CALL TST_ITOS
                CALL TST_SUBSTR

                UT_LOG "TST_STRINGS: PASSED"
                RETURN
                .pend