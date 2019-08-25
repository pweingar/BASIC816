;;;
;;; Test arrays
;;;

; Test that we can allocate an array on the heap
TST_ARRALLOC    .proc
                UT_BEGIN "TST_ARRALLOC"

                CALL INITBASIC

                setas
                LDA #TYPE_INTEGER
                STA TOFINDTYPE

                LDA #1
                STA TEMPBUF
                setal
                LDA #10
                STA TEMPBUF+1

                CALL ARR_ALLOC

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
                SEC                         ; SCRATCH := CURRHEADER->END - 43 (4 bytes per value, 1 for N, 2 for D_0)
                LDY #HEAPOBJ.END            ; This _should_ be the same as CURRBLOCK
                LDA [CURRHEADER],Y          ; Since each of the 10 values is 4 bytes, plus 2 bytes for the dimension preamble
                SBC #43
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

                CALL INITBASIC

                setas
                LDA #TYPE_INTEGER
                STA TOFINDTYPE

                LDA #1
                STA @lTEMPBUF
                setal
                LDA #2
                STA @lTEMPBUF+1

                CALL ARR_ALLOC      ; Allocate the array DIM x(2)


                setal
                LDA #0              ; Index will be 0
                STA @lTEMPBUF+1

                LDARG_EA ARGUMENT1,$1234,TYPE_INTEGER   ; Value will be $1234

                CALL ARR_SET        ; x(0) := $1234

                setal
                LDA #1              ; Index will be 1
                STA @lTEMPBUF+1

                LDARG_EA ARGUMENT1,$5678,TYPE_INTEGER   ; Value will be $5678

                CALL ARR_SET        ; x(1) := $5678

                ; Verify reads

                setal
                LDA #0              ; Index will be 0
                STA @lTEMPBUF+1

                CALL ARR_REF        ; ARGUMENT1 := x(0)

                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                UT_M_EQ_LIT_W ARGUMENT1,$1234,"EXPECTED $1234"

                setal
                LDA #1              ; Index will be 1
                STA @lTEMPBUF+1

                CALL ARR_REF        ; ARGUMENT1 := x(1)

                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                UT_M_EQ_LIT_W ARGUMENT1,$5678,"EXPECTED $5678"

                UT_END
                RETURN
                .pend

; Can set and reference a value in a two-D dimensional array
TST_ARR2D       .proc
                UT_BEGIN "TST_ARR2D"

                CALL INITBASIC

                setas
                LDA #TYPE_INTEGER
                STA TOFINDTYPE

                setas
                LDA #2
                STA TEMPBUF
                setal
                LDA #3
                STA TEMPBUF+1
                STA TEMPBUF+3

                CALL ARR_ALLOC      ; Allocate the array

                setas
                LDA #2
                STA TEMPBUF
                setal
                LDA #0              ; Index will be 0, 0
                STA TEMPBUF+1
                STA TEMPBUF+3

                LDARG_EA ARGUMENT1,$1234,TYPE_INTEGER   ; Value will be $1234

                CALL ARR_SET        ; x(0,0) := $1234

                setas
                LDA #2
                STA TEMPBUF
                setal
                LDA #1              ; Index will be 0, 0
                STA TEMPBUF+1
                STA TEMPBUF+3

                LDARG_EA ARGUMENT1,$5678,TYPE_INTEGER   ; Value will be $5678

                CALL ARR_SET        ; x(1,1) := $5678

                ; Verify reads

                setas
                LDA #2
                STA TEMPBUF
                setal
                LDA #0              ; Index will be 0, 0
                STA TEMPBUF+1
                STA TEMPBUF+3

                CALL ARR_REF        ; ARGUMENT1 := x(0,0)

                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                UT_M_EQ_LIT_W ARGUMENT1,$1234,"EXPECTED $1234"


                setas
                LDA #2
                STA TEMPBUF
                setal
                LDA #1              ; Index will be 0, 0
                STA TEMPBUF+1
                STA TEMPBUF+3

                CALL ARR_REF        ; ARGUMENT1 := x(1,1)

                UT_M_EQ_LIT_B ARGTYPE1,TYPE_INTEGER,"EXPECTED INTEGER"
                UT_M_EQ_LIT_W ARGUMENT1,$5678,"EXPECTED $5678"

                UT_END
                RETURN
                .pend

; Validate the DIM statement works
TST_ARRDIM      .proc
                UT_BEGIN "TST_ARRDIM"

                CALL INITBASIC

                TSTLINE "10 DIM A%(2)"

                CALL CMD_RUN

                setal
                LDA #<>ARR_A
                STA TOFIND
                LDA #`ARR_A
                STA TOFIND+2

                setas
                LDA #TYPE_ARR_INTEGER
                STA TOFINDTYPE
                CALL VAR_REF            ; Try to get the result

                UT_M_EQ_LIT_B ARGTYPE1,TYPE_ARR_INTEGER,"EXPECTED TYPE INTEGER ARRAY"

                setas
                LDA [ARGUMENT1]
                UT_A_EQ_LIT_B 1,"EXPECTED DIMENSION = 1"

                setaxl
                LDY #1
                LDA [ARGUMENT1],Y
                UT_A_EQ_LIT_W 2,"EXPECTED SIZE_0 = 2"

                UT_END
                RETURN
ARR_A           .null "A%"
                .pend

TST_ARRAY       .proc
                CALL TST_ARRALLOC
                CALL TST_ARRSETREF1
                CALL TST_ARR2D
                CALL TST_ARRDIM

                UT_LOG "TST_ARRAY PASSED"
                RETURN
                .pend