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
                LDY #HEAPOBJ.END
                LDA [CURRHEADER],Y
                STA ARGUMENT1
                setas
                INY
                INY
                LDA [CURRHEADER],Y
                STA ARGUMENT1+2

                setal
                SEC
                LDA ARGUMENT1
                SBC CURRBLOCK
                STA ARGUMENT1
                setas
                LDA ARGUMENT1+2
                SBC CURRBLOCK+2
                STA ARGUMENT1+2

                UT_M_EQ_LIT_L ARGUMENT1,10,"EXPECTED ARGUMENT1 = 10"         
 
                setal
                LDY #HEAPOBJ.NEXT
                LDA [CURRHEADER],Y
                UT_A_EQ_LIT_W 0,"EXPECTED NEXT: 0"         

                UT_END
                .pend

; Validate that we can allocate and free objects and that contiguous objects collapse into one when freed
TST_FREE        .proc
                UT_BEGIN "TST_FREE"

                setdp GLOBAL_VARS
                setdbr 0
                setaxl

                CALL INITHEAP

                LDA #TYPE_STRING
                LDX #20
                CALL ALLOC                                  ; Allocate the object
                CALL HEAP_ADDREF                            ; Make a reference to it
                MOVE_L TST_TEMP1,CURRHEADER                 ; Save it to TST_TEMP1
                LD_ind_L TST_TEMP3,CURRHEADER,HEAPOBJ.END   ; TST_TEMP3 := CURRHEADER->END

                LDA #TYPE_STRING
                LDX #20
                CALL ALLOC                                  ; Allocate another object
                CALL HEAP_ADDREF                            ; Make a reference to it
                MOVE_L TST_TEMP2,CURRHEADER                 ; Save it to TST_TEMP2

                MOVE_L CURRHEADER,TST_TEMP1
                CALL HEAP_REMREF                            ; Remove the reference to first object

                ; Verify that the first thing FREED is returned to the FREED list
                UT_M_EQ_M_L FREED,TST_TEMP1,"Expected FREED = TST_TEMP1"

                MOVE_L CURRHEADER,TST_TEMP2
                CALL HEAP_REMREF                            ; Remove the reference to second object

                ; Verify that the second thing FREED (lower in the heap) is the first thing on the FREED list
                UT_M_EQ_M_L FREED,TST_TEMP2,"Expected FREED = TST_TEMP2"

                ; Verify that the two blocks of memory (which are contiguous) are merged
                LD_ind_L SCRATCH,FREED,HEAPOBJ.END          ; SCRATCH := FREED->END
                UT_M_EQ_M_L SCRATCH,TST_TEMP3,"Expected FREED->END = TST_TEMP->END"

                LD_ind_L SCRATCH2,FREED,HEAPOBJ.NEXT
                UT_M_EQ_LIT_L SCRATCH2,0,"Expected FREED->NEXT = 0"

                UT_END
                .pend

; Validate that we can allocate an object, preferring to pull from FREED blocks first
TST_ALLOCFREE   .proc
                UT_BEGIN "TST_ALLOCFREE"

                setdp GLOBAL_VARS
                setdbr 0
                setaxl

                CALL INITHEAP

                LDA #TYPE_STRING
                LDX #20
                CALL ALLOC                                  ; Allocate the object
                CALL HEAP_ADDREF                            ; Make a reference to it
                MOVE_L TST_TEMP1,CURRHEADER                 ; Save it to TST_TEMP1

                CALL HEAP_REMREF                            ; Remove the reference to the object

                LDA #TYPE_STRING
                LDX #10
                CALL ALLOC                                  ; Allocate another object
                CALL HEAP_ADDREF                            ; Make a reference to it
                MOVE_L TST_TEMP2,CURRHEADER                 ; Save it to TST_TEMP2

                ; Verify that the new string we got reuses memory from the freed object
                UT_M_EQ_M_L CURRHEADER,TST_TEMP1,"Expected CURRHEADER = TST_TEMP1"

                UT_END
                .pend

;
; Run all the evaluator tests
;
TST_HEAP        .proc
                CALL TEST_ALLOCATE
                CALL TST_FREE
                CALL TST_ALLOCFREE

                UT_LOG "TST_HEAP: PASSED"
                RETURN
                .pend