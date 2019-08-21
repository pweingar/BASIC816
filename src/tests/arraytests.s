;;;
;;; Test arrays
;;;

; Test that we can allocate an array on the heap
TST_ARRALLOC    .proc
                UT_BEGIN "TST_ARRALLOC"

                setas
                LDA #TYPE_INTEGER
                STA TOFINDTYPE

                LDA #10
                PHA
                LDA #1
                PHA

                CALL ARR_ALLOC

                PLA
                UT_A_EQ_LIT_B 1,"Expected POP 1 = 1"
                PLA
                UT_A_EQ_LIT_B 10,"Expected POP 2 = 10"

                ; Validate the type
                setxl
                LDY #HEAPOBJ.TYPE
                LDA [CURRHEADER],Y
                UT_A_EQ_LIT_B TYPE_ARR_INTEGER,"Expected Array of Integer"

                ; Validate the number of dimensions
                LDA [CURRBLOCK]
                UT_A_EQ_LIT_B 1,"Expected N = 1"

                ; Validate the size of the first dimension
                LDY #1
                LDA [CURRBLOCK],Y
                UT_A_EQ_LIT_B 10,"Expected D_0 = 10"

                setal
                SEC                         ; SCRATCH := CURRHEADER->END - 42
                LDY #HEAPOBJ.END            ; This _should_ be the same as CURRBLOCK
                LDA [CURRHEADER],Y          ; Since each of the 10 values is 4 bytes, plus 2 bytes for the dimension preamble
                SBC #42
                STA TST_TEMP1
                setas
                INY
                INY
                LDA [CURRHEADER],Y
                SBC #0
                STA TST_TEMP1+2

                UT_M_EQ_M_L CURRBLOCK,TST_TEMP1,"Expected CURRBLOCK->END - 42 = CURRBLOCK"

                UT_END
                RETURN
                .pend

; Can set and reference a value in a one dimensional array
TST_ARRSETREF1  .proc
                UT_BEGIN "TST_ARRSETREF1"

                setas
                LDA #TYPE_INTEGER
                STA TOFINDTYPE

                LDA #2
                PHA
                LDA #1
                PHA

                CALL ARR_ALLOC      ; Allocate the array

                setas
                PLA                 ; Clean the stack
                PLA

                LDA #0              ; Index will be 0
                PHA
                LDA #1
                PHA

                LDARG_EA ARGUMENT1,$1234,TYPE_INTEGER   ; Value will be $1234

                CALL ARR_SET        ; x(0) := $1234

                setas
                PLA                 ; Validate we haven't screwed up the stack
                UT_A_EQ_LIT_B 1,"Expected POP 1 = 1"
                PLA
                UT_A_EQ_LIT_B 0,"Expected POP 2 = 0"

                LDA #1              ; Index will be 1
                PHA
                LDA #1
                PHA

                LDARG_EA ARGUMENT1,$5678,TYPE_INTEGER   ; Value will be $5678

                CALL ARR_SET        ; x(1) := $5678

                setas
                PLA
                PLA

                ; Verify reads

                LDA #0              ; Index will be 0
                PHA
                LDA #1
                PHA

                CALL ARR_REF        ; ARGUMENT1 := x(0)

                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                UT_M_EQ_LIT_W ARGUMENT1,$1234,"EXPECTED $1234"

                setas
                PLA                 ; Validate we haven't screwed up the stack
                UT_A_EQ_LIT_B 1,"Expected POP 3 = 1"
                PLA
                UT_A_EQ_LIT_B 0,"Expected POP 4 = 0"

                LDA #1              ; Index will be 1
                PHA
                LDA #1
                PHA

                CALL ARR_REF        ; ARGUMENT1 := x(1)

                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                UT_M_EQ_LIT_W ARGUMENT1,$5678,"EXPECTED $5678"

                setas
                PLA
                PLA

                UT_END
                RETURN
                .pend

TST_ARRAY       .proc
                CALL TST_ARRALLOC
                CALl TST_ARRSETREF1

                UT_LOG "TST_ARRAY PASSED"
                RETURN
                .pend