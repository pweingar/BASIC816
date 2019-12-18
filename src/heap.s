;;;
;;; Code to manage the heap
;;;
;;; We'll be storing string and arrays here.
;;; Note that the heap grows down from a starting position.
;;; Program memory will grow up from the bottom. If they collide, we have a problem.
;;;

.section globals
ALLOCATED   .long ?     ; Pointer to the most recently allocated object
HEAP        .long ?     ; Pointer to the top of the heap (next empty byte)
FREED       .long ?     ; Pointer to a linked list of freed heap objects
CURRBLOCK   .long ?     ; Pointer to the current heap allocated block
CURRHEADER  .long ?     ; Pointer to the header of the current block
CURREND     .long ?     ; Pointer to the byte immediately after the current block
CURRFREED   .long ?     ; Pointer to the current freed block
FREEDEND    .long ?     ; Pointer to the byte immediately after the current freed block
LASTFREED   .long ?     ;
.send

; Define a block allocated on the heap
; TYPE[7] will be the mark for garbage collection
HEAPOBJ     .struct
TYPE        .byte ?     ; Code for the type of object allocated
COUNT       .byte ?     ; Number of references to the heap object
NEXT        .long ?     ; Pointer to the next object in the list (used when freed)
END         .long ?     ; Pointer to the next byte after the block
            .ends

;
; Initialize the HEAP
;
INITHEAP    .proc
            PHP
            PHD

            setdp GLOBAL_VARS
            setaxl

            LDA #<>HEAP_TOP         ; Set the HEAP to the top
            STA HEAP
            setas
            LDA #`HEAP_TOP
            STA HEAP+2

            setal
            STZ ALLOCATED           ; And clear the pointer to the allocated objects
            STZ FREED               ; as well as the list of freed objects
            setas
            STZ ALLOCATED+2
            STZ FREED+2

            PLD
            PLP
            RETURN
            .pend

;
; Allocate a block of memory on the heap... uses freed memory first,
; if it's available. If not, it will pull from the heap memory that
; has not yet been allocated.
;
; Inputs:
;   A = the type to allocate
;   X = the size of the block to allocate
;
; Outputs:
;   CURRBLOCK = pointer to the allocated block of memory
;   CURRHEADER = pointer to the header for the allocated block of memory
;
ALLOC       .proc
            PHY
            PHP

            TRACE "ALLOC"

            setas
            STA TOFINDTYPE      ; Save the type of the block to TOFINDTYPE
            setxl
            STX MCOUNT           ; And the length of the block needed to MCOUNT

            setal
            LDA SCRATCH+2
            PHA
            LDA SCRATCH
            PHA
            LDA SCRATCH2+2
            PHA
            LDA SCRATCH2
            PHA

            CALL ALLOCFREED     ; Try allocating from the freed memory first
            BCS done            ; Return, if we got something back

            CALL ALLOCHEAP      ; Otherwise, allocate it from the unused heap

done        CALL HEAP_GETHED

            TRACE "/ALLOC"

            setal
            PLA
            STA SCRATCH2
            PLA
            STA SCRATCH2+2
            PLA
            STA SCRATCH
            PLA
            STA SCRATCH+2

            PLP
            PLY
            RETURN
            .pend

;
; Allocate a block of memory on the heap... uses memory that has not
; been allocated yet.
;
; Inputs:
;   TOFINDTYPE = the type to allocate
;   MCOUNT = the size of the block to allocate
;
; Outputs:
;   CURRBLOCK = pointer to the allocated block of memory
;   CURRHEAD = pointer to the header for the allocated block of memory
;
ALLOCHEAP   .proc
            PHP
            PHD
            TRACE "ALLOCHEAP"

            setdp GLOBAL_VARS

            setas
            LDX MCOUNT
            DEX
            STX SCRATCH             ; SCRATCH := size - 1
            INX

            setaxl                  ; CURRBLOCK := HEAP - size + 1
            SEC
            LDA HEAP
            SBC SCRATCH
            STA CURRBLOCK
            setas
            LDA HEAP+2
            SBC #0
            STA CURRBLOCK+2

            CALL HEAP_GETHED        ; Set CURRHEADER to point to the header of this block

            setas
            LDA TOFINDTYPE
            LDY #HEAPOBJ.TYPE       ; Set the type of the object
            STA [CURRHEADER],Y
            
            LDA #0                  ; Set the count to zero
            LDY #HEAPOBJ.COUNT
            STA [CURRHEADER],Y

            LDY #HEAPOBJ.NEXT
            STA [CURRHEADER],Y
            setal
            LDA #0
            STA [CURRHEADER],Y

            setal
            CLC
            LDA HEAP
            ADC #1
            LDY #HEAPOBJ.END        ; To get the address of the next byte
            STA [CURRHEADER],Y      ; after the block
            setas
            INY
            INY
            LDA HEAP+2
            ADC #0
            STA [CURRHEADER],Y

            setal                   ; Point ALLOCATED to the new object
            LDA CURRBLOCK
            STA ALLOCATED
            setas
            LDA CURRBLOCK+2
            STA ALLOCATED+2

            setal
            SEC                     ; Move the HEAP pointer to the first free byte under the header
            LDA CURRHEADER               
            SBC #1
            STA HEAP
            setas
            LDA CURRHEADER+2
            SBC #0
            STA HEAP+2

            PLD
            PLP
            RETURN
            .pend

;
; Allocate an object, pulling its memory from the freed object areas
;
; Inputs:
;   A = the type to allocate
;   X = the size of the block to allocate
;
; Outputs:
;   CURRBLOCK = pointer to the allocated block of memory
;   CURRHEAD = pointer to the header for the allocated block of memory
;   C is set if the memory was found, clear otherwise
;
ALLOCFREED  .proc
            PHP
            PHD
            TRACE "ALLOCFREED"

            setdp GLOBAL_VARS
            setaxl

            MOVE_L CURRFREED,FREED

loop        LDA CURRFREED           ; Has anything been freed?
            BNE has_block           ; Yes: check to see if there's a big enough block
            setas
            LDA CURRFREED+2
            BNE has_block           ; Yes: check to see if there's a big enough block

            LD_L LASTFREED,0        ; NULL out the pointer to the previously examined freed block

ret_false   PLD                     ; Return that we didn't find anything
            PLP
            CLC
            RETURN

            ; There is at least one block of memory on the freed list
            ; Check to see if any of them are big enough to reallocate
has_block   TRACE "has_block"
            LD_ind_L FREEDEND,CURRFREED,HEAPOBJ.END     ; FREEDEND := CURRHEADER->END

            setal
            CLC                         ; SCRATCH := CURRFREED + size of block required
            LDA CURRFREED
            ADC MCOUNT
            STA SCRATCH
            setas
            LDA CURRFREED+2
            ADC #0
            STA SCRATCH+2

            setal
            CLC                         ; SCRATCH := CURRFREED + size of block required + size of header
            LDA SCRATCH                 ; (that is, it's a pointer to the byte immediately after the block desired)
            ADC #size(HEAPOBJ)
            STA SCRATCH
            setas
            LDA SCRATCH+2
            ADC #0
            STA SCRATCH+2

            setal
            LDA SCRATCH                 ; Is SCRATCH == FREEDEND?
            CMP FREEDEND
            BNE not_exact               ; No: check if this block is bigger than needed
            setas
            LDA SCRATCH+2
            CMP FREEDEND+2
            BNE not_exact

            ; The block is exactly the right size...
            ; Remove it from the FREED list and return it

            setal
            LDA LASTFREED               ; LASTFREED == 0?
            BNE adj_last1               ; No: point LASTFREED->NEXT to skip this block
            setas
            LDA LASTFREED+2
            BNE adj_last1

            ; Yes: point FREED to the next block
            setal
            LDY #HEAPOBJ.NEXT
            LDA [CURRFREED],Y
            STA FREED
            setas
            INY
            INY
            LDA [CURRFREED],Y
            STA FREED+2
            JMP init_block              ; And return CURRFREED as our reallocated memory

            ; Check to see if CURRFREED's space is bigger than needed
not_exact   TRACE "not exact"

            setal
            LDA SCRATCH                 ; Add a buffer to the room needed
            ADC #size(HEAPOBJ)          ; So we have room to track the memory still freed
            STA SCRATCH2
            setas
            LDA SCRATCH+2
            ADC #0
            STA SCRATCH2+2

            setas
            LDA CURREND                 ; Is CURREND > SCRATCH2
            CMP SCRATCH2
            BGE has_room                ; Yes: there is room in this block to allocate some memory
            BLT try_next
            setal
            LDA CURREND
            CMP SCRATCH2
            BGE has_room

            ; There's no room in the current block
            ; Try the next one
try_next    MOVE_L LASTFREED,CURRFREED
            LD_ind_L CURRFREED,LASTFREED,HEAPOBJ.NEXT   ; CURRHEADER := CURRHEADER->NEXT
            JMP loop                                    ; And try the next header

            ; The current block is exactly the right size, so remove it from the FREED list
            ; Point LASTFREED->NEXT to the next block
adj_last1   TRACE "adj_last1"
            setal
            LDY #HEAPOBJ.NEXT           ; LASTFREED->NEXT := CURRFREED->NEXT
            LDA [CURRFREED],Y
            STA [LASTFREED],Y
            setas
            INY
            INY
            LDA [CURRFREED],Y
            STA [LASTFREED],Y
            JMP init_block              ; And get CURRFREED ready to return

            ; We have enough room to allocate an object
has_room    TRACE "has_room"
            setal
            LDY #HEAPOBJ.END            ; SCRATCH->END := CURRFREED->END
            LDA [CURRFREED],Y
            STA [SCRATCH],Y
            setas
            INY
            INY
            LDA [CURRFREED],Y
            STA [SCRATCH],Y

            setal
            LDY #HEAPOBJ.NEXT           ; CURREND->NEXT := CURRFREED->NEXT
            LDA [CURRFREED],Y
            STA [SCRATCH],Y
            setas
            INY
            INY
            LDA [CURRFREED],Y
            STA [SCRATCH],Y

            setal
            LDA LASTFREED               ; Is this the first object we've examined?
            BNE adj_last2               ; No: we'll need to adjust the previously examined block
            setas
            LDA LASTFREED
            BNE adj_last2

            MOVE_L FREED,SCRATCH        ; Yes: point FREED to the leftover memory
            BRA init_block              ; ... and return the block we've sliced off

            ; Since there is room in the current block, we need to remove it from the FREED list
            ; Update LASTFREED->NEXT to point to the part of the current block we leave on the list
adj_last2   TRACE "adj_last2"
            setal
            LDY #HEAPOBJ.NEXT           ; LASTFREED->NEXT := SCRATCH
            LDA SCRATCH                 ; (point the previous freed block to the newly sliced
            STA [LASTFREED],Y           ;  off part of the current block)
            setas
            INY
            INY
            LDA SCRATCH+2
            STA [LASTFREED],Y

            ; Get the current block of memory (that we've just grabbed) ready to return
            ; as the newly allocated block
init_block  TRACE "init_block"
            MOVE_L CURRHEADER,CURRFREED     ; Point to the freed object

            MOVE_L ALLOCATED,CURRHEADER

            setal
            LDY #HEAPOBJ.END        ; Set CURRHEADER->END to the byte after the block
            LDA SCRATCH
            STA [CURRHEADER],Y
            setas
            INY
            INY
            LDA SCRATCH+2
            STA [CURRHEADER],Y

            setal
            LDY #HEAPOBJ.NEXT       ; Set CURRHEADER->NEXT to NULL
            LDA #0
            STA [CURRHEADER],Y
            setas
            INY
            INY
            STA [CURRHEADER],Y

            setas
            LDA TOFINDTYPE          ; Get the type code back
            setas
            LDY #HEAPOBJ.TYPE
            STA [CURRHEADER],Y

            LDY #HEAPOBJ.COUNT      ; Set its reference count to 0
            LDA #0
            STA [CURRHEADER],Y
            
done        PLD
            PLP
            SEC
            RETURN
            .pend

;
; Set the current block to the most recently allocated
;
HEAP_GET1ST .proc
            PHP

            setaxl
            LDA ALLOCATED
            STA CURRBLOCK
            setas
            LDA ALLOCATED+2
            STA CURRBLOCK+2

            CALL HEAP_GETHED

            PLP
            RETURN
            .pend

;
; Set CURRHEADER to point to the header of the current block
;
HEAP_GETHED .proc
            PHP
            TRACE_L "HEAP_GETHED",CURRBLOCK
            
            setal

            SEC
            LDA CURRBLOCK
            SBC #size(HEAPOBJ)
            STA CURRHEADER
            setas
            LDA CURRBLOCK+2
            SBC #0
            STA CURRHEADER+2

            PLP
            RETURN
            .pend

;
; Register a reference to a heap allocated object
; This will increase the reference count by one.
;
; Inputs:
;   CURRHEADER = pointer to the object being referenced
;
HEAP_ADDREF .proc
            PHP

            TRACE_L "HEAP_ADDREF",CURRHEADER

            setas
            LDA CURRHEADER+2
            BEQ chk_null
            CMP #$17
            BGE out_of_bnds

chk_null    setal
            LDA CURRHEADER
            BEQ out_of_bnds

is_ok       setas
            LDY #HEAPOBJ.COUNT
            LDA [CURRHEADER],Y
            INC A
            STA [CURRHEADER],Y

            PLP
            RETURN

out_of_bnds BRK
            NOP
            .pend

;
; Remove a reference to a heap allocated object
; This will decrease the reference count by one.
; It will also free the object, if there are no more references.
;
; Inputs:
;   CURRHEADER = pointer to the object being referenced
;
HEAP_REMREF .proc
            PHP

            TRACE_L "HEAP_REMREF",CURRHEADER

            setas
            LDA CURRHEADER+2
            BEQ chk_null
            CMP #$17
            BGE out_of_bnds

chk_null    setal
            LDA CURRHEADER
            BEQ out_of_bnds

            setas
            LDY #HEAPOBJ.COUNT  ; Decrement the reference count
            LDA [CURRHEADER],Y
            DEC A
            STA [CURRHEADER],Y
            BNE done            ; If it's still >0, we are done

            CALL HEAP_FREE      ; Otherwise: return the object to the free space

done        PLP
            RETURN

out_of_bnds BRK
            NOP
            .pend

;
; Return the heap object CURRBLOCK to the list of free space
;
; Inputs:
;   CURRHEADER = pointer to the heap header for the object to be returned
;
HEAP_FREE   .proc
            PHP

            TRACE_L "HEAP_FREE", CURRHEADER

            setal
            LDA FREED           ; Check to see if blocks are already on the freed list
            BNE has_objects
            setas
            LDA FREED+2
            BNE has_objects

            LDA CURRHEADER+2    ; No: this block is the first one
            STA FREED+2         ; Just make it the freed list
            setal
            LDA CURRHEADER
            STA FREED

            LDA #0
            LDY #HEAPOBJ.NEXT   ; And clear its next link
            STA [CURRHEADER],Y
            INY
            INY
            setas
            STA [CURRHEADER],Y

            JMP done

            ; Is FREED < CURRHEADER?
has_objects setas
            LDA FREED+2
            CMP CURRHEADER+2
            BLT start_scan
            setal
            LDA FREED
            CMP CURRHEADER
            BLT start_scan

            ; Yes: insert at the head of the free list         
ins_first   setal
            LDA FREED               ; CURRHEADER->NEXT := FREED
            LDY #HEAPOBJ.NEXT
            STA [CURRHEADER],Y
            setas
            INY
            INY
            LDA FREED+2
            STA [CURRHEADER],Y

            MOVE_L FREED, CURRHEADER ; FREED := CURRHEADER
            JMP done

            ; No: Walk INDEX through each block on the FREED linked-list (until INDEX->NEXT = 0)
start_scan  MOVE_L INDEX, FREED

            ; Is INDEX->NEXT > CURREND?
loop        setas
            LDY #HEAPOBJ.NEXT+2
            LDA [INDEX],Y
            CMP CURREND+2
            BLT go_next             ; No: check the next spot
            BNE ins_next

            setal
            LDY #HEAPOBJ.NEXT
            LDA [INDEX],Y
            CMP CURREND
            BLT go_next             ; No: check the next spot

            ; Yes: insert CURRBLOCK between INDEX and INDEX->NEXT
ins_next    setal
            LDY #HEAPOBJ.NEXT       ; CURRHEADER->NEXT := INDEX->NEXT
            LDA [INDEX],Y
            STA [CURRHEADER],Y
            setas
            INY
            INY
            LDA [INDEX],Y
            STA [CURRHEADER],Y

            setal
            LDA CURRHEADER           ; INDEX->NEXT := CURRHEADER
            LDY #HEAPOBJ.NEXT
            STA [INDEX],Y
            setas
            LDA CURRHEADER+2
            INY
            INY
            STA [INDEX],Y            

            JMP done

go_next     setal
            LDY #HEAPOBJ.NEXT       ; Is INDEX->NEXT = 0
            LDA [INDEX],Y
            BNE not_at_end          ; No: load up the next object
            setas
            INY
            INY
            LDA [INDEX],Y
            BEQ at_end

            ; There is at least one more freed block... point INDEX to it and loop
not_at_end  setal
            LDY #HEAPOBJ.NEXT       ; INDEX := INDEX->NEXT
            LDA [INDEX],Y
            STA SCRATCH
            setas
            INY
            INY
            LDA [INDEX],Y
            STA INDEX+2
            setal
            LDA SCRATCH
            STA INDEX
            BRA loop

            ; Got to the end without finding an insertion point
at_end      setal
            LDA CURRHEADER           ; INDEX->NEXT := CURRHEADER
            LDY #HEAPOBJ.NEXT
            STA [INDEX],Y
            setas
            INY
            INY
            LDA CURRHEADER+2
            STA [INDEX],Y

            LDA #0                  ; CURRHEADER->NEXT := 0
            STA [CURRHEADER],Y
            setal
            LDY #HEAPOBJ.NEXT
            STA [CURRHEADER],Y 

done        CALL COALLESCE          ; Try to collapse contiguous blocks in freed memory

            PLP
            RETURN
            .pend

;
; Walk through the list of freed memory blocks and attempt to combine
; contiguous blocks into a single block
;
; Inputs:
;   FREED = pointer to the first freed block of memory
;
COALLESCE   .proc
            PHP

            ; CURRHEADER := FREED
            MOVE_L CURRHEADER,FREED

next_head   setal
            LDA CURRHEADER          ; Is CURRHEADER == 0?
            BNE check_next          ; No: check if NEXT is contiguous
            setas
            LDA CURRHEADER+2
            BNE check_next
            JMP done                ; Yes: we're done

            ; Check to see if CURRHEADER->NEXT == CURRHEADER->END
            ; If so, the blocks are contiguous and can be combined
check_next  LD_ind_L SCRATCH,CURRHEADER,HEAPOBJ.NEXT
            LD_ind_L SCRATCH2,CURRHEADER,HEAPOBJ.END

            setal
            LDA SCRATCH
            CMP SCRATCH2            ; Is CURRHEADER->END = CURRHEADER->NEXT?
            BNE go_next             ; No: go to the next block
            setas
            LDA SCRATCH+2
            CMP SCRATCH2+2
            BEQ combine             ; Yes: combine the two blocks 

            ; If they aren't contigous, move on to the next block to check it
go_next     LD_ind_L SCRATCH,CURRHEADER,HEAPOBJ.NEXT    ; CURRHEADER := CURRHEADER->NEXT
            MOVE_L CURRHEADER,SCRATCH
            BRA next_head                               ; And loop back to next_head

            ; If they are contiguous, combine them into one
combine     ; SCRATCH := CURRHEADER->NEXT
            LD_ind_L SCRATCH,CURRHEADER,HEAPOBJ.NEXT

            setal
            LDY #HEAPOBJ.NEXT       ; CURRHEADER->NEXT := SCRATCH->NEXT
            LDA [SCRATCH],Y
            STA [CURRHEADER],Y
            setas
            INY
            INY
            LDA [SCRATCH],Y
            STA [CURRHEADER],Y
            
            setal
            LDY #HEAPOBJ.END       ; CURRHEADER->END := SCRATCH->END
            LDA [SCRATCH],Y
            STA [CURRHEADER],Y
            setas
            INY
            INY
            LDA [SCRATCH],Y
            STA [CURRHEADER],Y

            JMP check_next          ; And loop back to check_next
            
done        PLP
            RETURN
            .pend