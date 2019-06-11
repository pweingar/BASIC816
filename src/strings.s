;;;
;;; String subroutines
;;;

;
; Allocate a temporary string.
;
; A temporary string is allocated in memory between the BASIC program
; and the bottom of the heap. Temporary strings may be over-written by
; the heap at any time, so they must be used immediately or copied to
; a regular heap-allocated string. This routine really just makes sure
; there is a free page between the program and the bottom of the heap.
; If there isn't, it will throw an out of memory error.
;
; Outputs:
;   STRPTR = pointer to the temp string (type not set)
;
TEMPSTRING  .proc
            PHP

            setxl
            setas               ; Set INDEX next free byte after the string
            STZ STRPTR
            LDA LASTLINE+1
            INC A
            INC A
            STA STRPTR+1
            setas
            LDA LASTLINE+2
            STA STRPTR+2

            CMP HEAP+2          ; Check the bank see if the there is a heap collision
            BCC has_room        ; No... return pointer
            BEQ no_room         ; Yes... throw error

            setal
            LDA STRPTR          ; Check the lower 16 bits
            CMP HEAP
            BCC has_room        ; No... return pointer

no_room     THROW ERR_MEMORY    ; Yes... throw error

has_room    PLP
            RETURN
            .pend

;
; Convert the integer in ARGUMENT1 to a temporary, null-terminated string
;
; Note: the temporary string is not allocated on the heap and
; can be over-written at any time. It should be used immediately
; or copied to a heap string
;
; Inputs:
;   ARGUMENT1 = the integer to convert to a string
;
; Outputs:
;   STRPTR = pointer to the temporary string
;
ITOS        .proc
            PHP
            TRACE "ITOS"

            setal
            STZ SCRATCH         ; Use scratch to store if negative

            LDA ARGUMENT1       ; Check to see if the number is negative
            BPL tsalloc

            EOR #$FFFF          ; Yes: make ARGUMENT1 positive
            CLC
            ADC #1
            STA ARGUMENT1

            LDA #$FFFF          ; Record that the number was negative
            STA SCRATCH

tsalloc     CALL TEMPSTRING     ; Allocate a temporary string

            setas
            LDA #$FF
            STA STRPTR          ; Point to its last byte

            LDA #0
            STA [STRPTR]        ; And make sure it's NULL

            LDA #$FE
            STA STRPTR          ; And point to the first possible digit

            LDA #'0'
            STA [STRPTR]        ; Pre-load a "0"

shift_loop  CALL IS_ARG1_Z      ; If ARGUMENT1 is 0....
            BEQ check_neg       ; ... then we've finished shifting out digits

            CALL DIVINT10       ; Divide by 10 (expect remainder in ARGUMENT2)

            setas
            CLC                 ; Convert the remainder to an ASCII digit
            LDA ARGUMENT2
            BMI fault
            CMP #10
            BGE fault
            ADC #'0'

            STA [STRPTR]        ; Write it to the temporary string

            setas
            DEC STRPTR          ; Move to the "next" character slot

            LDA #' '            ; Write a space as a placeholder
            STA [STRPTR]

            BRA shift_loop

check_neg   LDA SCRATCH         ; Check to see if the number was negative
            BEQ done            ; No: go ahead and return

            LDA #'-'
            STA [STRPTR]

done        PLP
            RETURN

fault       BRK
            NOP
            .pend

;
; Calculate the length of a string
;
; Inputs:
;   B = data bank of the string
;   X = pointer to the string
;
; Outputs:
;   Y = length of the string
;
STRLEN      .proc
            PHP

            setas
            setxl

            LDY #0
loop        LDA #0,B,X
            BEQ done
            INX
            INY
            BRA loop

done        PLP
            RETURN
            .pend

;
; Compare two strings
;
; Inputs:
;   ARGUMENT1 = first string
;   ARGUMENT2 = second string
;
; Outputs:
;   ARGUMENT1 = 0 if they are equal, 1 if ARGUMENT1 > ARGUMENT2, -1 if ARGUMENT1 < ARGUMENT2
;
STRCMP      .proc
            PHP
            PHD

            setdp GLOBAL_VARS

            setas
            setxl
            LDY #0

loop        LDA [ARGUMENT1],Y       ; Check if the character 1 is 0
            BNE comp_mag            ; If not, check the magnitudes
            LDA [ARGUMENT2],Y       ; If so, check if the character 2 is 0
            BEQ are_equal           ; If so, the strings are equal
comp_mag    LDA [ARGUMENT1],Y       ; Otherwise, get character 1 again
            CMP [ARGUMENT2],Y       ; And compare it to character 2
            BLT is_less             ; Check if character 1 < character 2
            BNE is_greater          ; Check if character 1 > character 2

            INY                     ; Equal so far... so go to the next pair of characters
            BRA loop

is_greater  setal                   ; character 1 > character 2
            LDA #1                  ; So return 1
            STA ARGUMENT1
            setas
            STZ ARGUMENT1+2
            BRA done

is_less     setal                   ; character 1 < character 2
            LDA #$FFFF              ; So return -1
            STA ARGUMENT1
            setas
            STA ARGUMENT1+2
            BRA done

are_equal   setal                   ; The strings were equal
            STZ ARGUMENT1           ; So return 0
            setas
            STZ ARGUMENT1+2

done        setas                   ; Make sure our return type is INTEGER
            LDA #TYPE_INTEGER
            STA ARGTYPE1

            PLD
            PLP
            RETURN
            .pend


;
; Allocate a new string and fill it with ARGUMENT1 concatenated with ARGUMENT2
;
; Inputs:
;   ARGUMENT1 = pointer to the first string
;   ARGUMENT2 = pointer to the second string
;
; Outputs:
;   ARGUMENT1 = pointer to the new string (ARGUMENT1 + ARGUMENT2)
;
STRCONCAT   .proc
            PHP
            PHD
            PHB

            TRACE "STRCONCAT"

            setdp GLOBAL_VARS

            setas
            setxl

            LDDBR ARGUMENT1+2       ; SCRATCH := LEN(ARGUMENT1)
            LDX ARGUMENT1
            CALL STRLEN
            STY SCRATCH

            LDDBR ARGUMENT2+2       ; A := LEN(ARGUMENT2)
            LDX ARGUMENT2
            CALL STRLEN
            setal
            TYA

            SEC                     ; X := LEN(ARGUMENT1) + LEN(ARGUMENT2) + 1
            ADC SCRATCH
            TAX

            setas
            LDA #TYPE_STRING        ; Set type to STRING
            CALL ALLOC              ; And allocate the block for the string

            setal
            LDA ALLOCATED           ; INDEX := pointer to the string
            STA INDEX
            setas
            LDA ALLOCATED+2
            STA INDEX+2

            LDY #0                  ; Set the target index to the beginning
            LDDBR ARGUMENT1+2       ; Point to the first source string
            LDX ARGUMENT1

loop1       LDA #0,B,X              ; Get the Xth byte of ARGUMENT1
            BEQ copy_2              ; Is it null? Yes: move on to the next string
            STA [INDEX],Y           ; And save it to the Yth position on the new string
            INX                     ; Point to the next characters
            INY
            BRA loop1               ; And do again

copy_2      setas
            LDDBR ARGUMENT2+2       ; Point to the second source string
            LDX ARGUMENT2

loop2       LDA #0,B,X              ; Get the Xth byte of ARGUMENT2
            STA [INDEX],Y           ; And save it to the Yth position on the new string
            BEQ terminate           ; Is it null? Yes: move on to the next string
            
            INX                     ; Point to the next characters
            INY
            BRA loop2               ; And do again

terminate   setal
            LDA INDEX               ; Set ARGUMENT1 to the new string
            STA ARGUMENT1
            setas
            LDA INDEX+2
            STA ARGUMENT1+2
            LDA #TYPE_STRING        ; Set ARGUMENT1's type to STRING
            STA ARGTYPE1

            TRACE "exit"

            PLB
            PLD
            PLP

            RETURN
            .databank `GLOBAL_VARS
            .pend