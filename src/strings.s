;;;
;;; String subroutines
;;;

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