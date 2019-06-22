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
; Attempt to add a BCD digit in A to temporary string
;
; Ignore leading zeros
;
; Inputs:
;   A = the digit to add (0 - 9)
;   STRPTR = the base address of the string to build
;   Y = the index to the digits location in the string
; 
ITOS_DIGIT  .proc
            CMP #0          ; Is it 0?
            BNE add_digit   ; No: go ahead and add it

            CPY #1          ; Are we on the first digit?
            BEQ done        ; Yes: ignore this leading 0

add_digit   ORA #$30        ; Convert it to ASCII
            STA [STRPTR],Y  ; Save it to the string
            INY             ; And point to the next location

done        RETURN
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

            LDA ARGUMENT1+2     ; Check to see if the number is negative
            BPL start_cnvt
         
            CLC                 ; Yes: make ARGUMENT1 positive
            LDA ARGUMENT1
            EOR #$FFFF
            ADC #1
            STA ARGUMENT1
            LDA ARGUMENT1+2
            EOR #$FFFF
            ADC #0
            STA ARGUMENT1+2

            LDA #$FFFF          ; Record that the number was negative
            STA SCRATCH

start_cnvt  ; Convert the binary number in ARGUMENT1 into a BCD
            ; equivalent in SCRATCH2

            STZ SCRATCH2        ; SCRATCH2 will be our BCD version of the number
            STZ SCRATCH2+2

            LDX #31
            SED                 ; Yes, we're really using BCD mode

shift_loop  ASL ARGUMENT1       ; Shift ARGUMENT1 left one bit
            ROL ARGUMENT1+2

            LDA SCRATCH2        ; SCRATCH2 := SCRATCH2 + SCRATCH2 + Carry
            ADC SCRATCH2
            STA SCRATCH2
            LDA SCRATCH2+2
            ADC SCRATCH2+2
            STA SCRATCH2+2

            DEX
            BPL shift_loop      ; Loop through all 32 bits of ARGUMENT1

            CLD                 ; Switch back out of BCD mode
            setas

            ; Convert the BCD number in SCRATCH2 to a string

            CALL TEMPSTRING     ; Allocate a temporary string

            LDY #0              ; Y will be index into the temporary string

            LDA SCRATCH         ; Check to see if the number was negative
            BEQ is_pos          ; No: write a leading space

            LDA #'-'            ; If negative, write the minus sign
            BRA wr_lead

is_pos      LDA #CHAR_SP        ; Write a leading space
wr_lead     STA [STRPTR],Y
            INY

            ; Skip over leading 0s
            LDX #3

            ; Process first nybble
ascii_loop  LDA SCRATCH2,X
            AND #$F0
            .rept 4
            LSR A
            .next
            CALL ITOS_DIGIT

            ; Process lower nybble
            LDA SCRATCH2,X
            AND #$0F
            CALL ITOS_DIGIT

            DEX
            BPL ascii_loop

            CPY #1              ; Did we write anything?
            BNE null_term       ; Yes: add a NULL to terminate

            LDA #'0'            ; No: write a "0" to the string
            STA [STRPTR]

null_term   LDA #0
            STA [STRPTR],Y      ; And terminate the string

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