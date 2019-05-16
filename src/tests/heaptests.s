;;;
;;; Test ability to allocate objects on the heap and to do garbage collection
;;;

; Test that we can allocate a block
TEST_ALLOCATE   .proc
                UT_BEGIN "TEST_ALLOCATE"

                setdp GLOBAL_VARS
                setdbr 0
                setaxl

                CALL INITHEAP

                LDA #0
                LDX #10
                CALL ALLOC

                UT_M_EQ_LIT_L HEAP,HEAP_TOP - 10 - size(HEAPOBJ),format("HEAP EXPECTED %x", HEAP_TOP - 10 - size(HEAPOBJ))
                UT_M_EQ_LIT_L ALLOCATED,HEAP_TOP - 10 + 1,format("ALLOCATED EXPECTED %x", HEAP_TOP - 10 + 1)
                
                CALL HEAP_GET1ST        ; Point CURRBLOCK and CURRHEADER to the allocated block

                setas
                LDY #HEAPOBJ.TYPE
                LDA [CURRHEADER],Y
                UT_A_EQ_LIT_B 0,"EXPECTED TYPE: 0"

                setal
                LDY #HEAPOBJ.SIZE
                LDA [CURRHEADER],Y
                UT_A_EQ_LIT_W 10,"EXPECTED SIZE: 10"         

                setal
                LDY #HEAPOBJ.NEXT
                LDA [CURRHEADER],Y
                UT_A_EQ_LIT_W 0,"EXPECTED NEXT: 0"         

                UT_END
                .pend

;
; Run all the evaluator tests
;
TST_HEAP        .proc
                CALL TEST_ALLOCATE

                UT_LOG "TST_HEAP: PASSED"
                RETURN
                .pend