;
; Test the tokenizer
;

;
; Validate we can tokenize <> correctly
;
TST_TOK_NE      .proc
                UT_BEGIN "TST_TOK_NE"

                CALL INITBASIC

                TSTLINE "10 1<>2"

                UT_M_EQ_LIT_B BASIC_BOT+4,"1","Expected '1'"
                UT_M_EQ_LIT_B BASIC_BOT+5,TOK_NE,"Expected TOK_NE"
                UT_M_EQ_LIT_B BASIC_BOT+6,"2","Expected '2'"
                UT_M_EQ_LIT_B BASIC_BOT+7,0,"Expected NUL"
                UT_END
                .pend

TST_TOKENS      .proc
                CALL TST_TOK_NE

                UT_LOG "TST_INTERP: PASSED"
                RETURN
                .pend
