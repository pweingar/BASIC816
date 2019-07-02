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
CURRBLOCK   .long ?     ; Pointer to the current heap allocated block
CURRHEADER  .long ?     ; Pointer to the header of the current block
.send

; Define a block allocated on the heap
; TYPE[7] will be the mark for garbage collection
HEAPOBJ     .struct
TYPE        .byte ?     ; Code for the type of object allocated
SIZE        .word ?     ; Size of the block
NEXT        .long ?     ; Pointer to the next block allocated on the heap
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

            setal                   ; And clear the pointer to the allocated objects
            STZ ALLOCATED
            setas
            STZ ALLOCATED+2

            PLD
            PLP
            RETURN
            .pend

;
; Allocate a block of memory on the heap
;
; Inputs:
;   A = the type to allocate
;   X = the size of the block to allocate
;
; Outputs:
;   CURRBLOCK = pointer to the allocated block of memory
;   CURRHEAD = pointer to the header for the allocated block of memory
;
ALLOC       .proc
            PHP
            PHD
            TRACE "ALLOC"

            setdp GLOBAL_VARS

            setas
            PHA                     ; Save the type for later
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

            setal                   ; CURRHEADER := CURRBLOCK - sizeof(HEAPOBJ)
            SEC
            LDA CURRBLOCK
            SBC #size(HEAPOBJ)
            STA CURRHEADER
            setas
            LDA CURRBLOCK+2
            SBC #0
            STA CURRHEADER+2

            setas
            PLA
            LDY #HEAPOBJ.TYPE       ; Set the type of the object
            STA [CURRHEADER],Y

            setal
            TXA
            LDY #HEAPOBJ.SIZE       ; Set the size of the object
            STA [CURRHEADER],Y

            LDY #HEAPOBJ.NEXT       ; Set the pointer to the next object on the HEAP
            LDA ALLOCATED
            STA [CURRHEADER],Y
            INY
            setas
            LDA ALLOCATED+2
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
; Point CURRHEADER and CURRBLOCK to the next block allocated on the heap
;
HEAP_NEXT   .proc
            PHP

            setaxl
            LDY #HEAPOBJ.NEXT
            LDA [CURRHEADER],Y
            STA CURRBLOCK
            setas
            INY
            LDA [CURRHEADER],Y
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
            setaxl

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