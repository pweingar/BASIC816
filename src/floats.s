;;;
;;; Implement floating point numbers for the 65816
;;;
;;; Floating point number format
;;; This is the layout in memory and is compatible with the C256's coprocessor
;;; 
;;;      Sign   Exponent   Mantissa 
;;;      0      00000000   00000000000000000000000
;;; Bit: 31     [30 - 23]  [22        -         0]

;;;
;;; Set up variables for floating point operations
;;;

FFLG_NEGATIVE = $80
FFLG_DP = $40
FFLG_EXPSGN = $20

;
; Layout of floating point accumulator
;
; EEEEEEEE OOOOOOOO OMMMMMMM MMMMMMMM UUUUUUUU
; E = exponent
; O = mantissa overflow bits (guard)
; M = mantissa bits
; U = mantissa underflow bits (guard)
;

.section globals
FMANTGUARDL .byte ?     ; Low end guard byte for the accumulator bytes
FMANT       .long ?     ; 23-bit Mantissa (bit 23 is part of overflow space)
FMANTGUARDH .byte ?     ; High end guard byte for the accumulator bytes
FEXP        .byte ?     ; Binary exponent
FDEXP       .byte ?     ; Decimal exponent
FFLAGS      .byte ?     ; Flags for floating point operations:
                        ;   $80 = negative
                        ;   $40 = decimal point seen
                        ;   $20 = exponent sign
.send

.include "C256/floats.s"

;
; Multiply the floating point accumulator mantissa by 10
;
; Inputs:
;   FMANT = the mantissa to multiple
;   FMANTGUARDH = the high guard byte for overflowing bits
;
; Affects:
;   SCRATCH2 = temporary storage
;
FACCMUL10   .proc
            PHP
            TRACE "FACCMUL10"

            setal
            ASL FMANT
            ROL FMANT+2
            LDA FMANT           ; SCRATCH := FMANT * 2
            STA SCRATCH2
            LDA FMANT+2
            STA SCRATCH2+2

            ASL FMANT           ; FMANT *= 8
            ROL FMANT+2
            ASL FMANT
            ROL FMANT+2

            CLC                 ; FMANT := FMANT*8 + FMANT*2
            LDA FMANT
            ADC SCRATCH2
            STA FMANT
            LDA FMANT+2
            ADC SCRATCH2+2
            STA FMANT+2

            PLP
            RETURN
            .pend

;
; Load the floating point accumulator with the floating point number in ARG1 and unpack it.
;
ARG1TOACC   .proc
            PHP
            TRACE "ARG1TOACC"

            setas
            STZ FMANTGUARDL         ; Clear the registers we're not setting yet
            STZ FMANTGUARDH
            STZ FDEXP

            LDA ARGUMENT1           ; Copy the mantissa to FMANT (mask off the LSB of the exponent)
            STA FMANT
            LDA ARGUMENT1+1
            STA FMANT+1
            LDA ARGUMENT1+2
            AND #$7F
            STA FMANT+2

            LDA ARGUMENT1+2         ; Shift and copy the exponent
            ASL A
            LDA ARGUMENT1+3
            ROL A
            STA FEXP

            LDA #0                  ; And move the carry (which has the sign) into FFLAGS
            ROR A
            STA FFLAGS

            PLP
            RETURN
            .pend

;
; Pack the floating point number in the floating point accumulator into ARGUMENT1
;
ACCTOARG1   .proc
            PHP
            TRACE "ACCTOARG1"

            setas

            LDA FMANT+2             ; Make sure bit 24 is clear
            AND #$7F
            STA FMANT+2

            LDA FFLAGS              ; Get the sign into the carry bit
            ASL A
            LDA FEXP                ; Get the sign and exponent into ARGUMENT1
            ROR A
            STA ARGUMENT1+3

            LDA #0                  ; Get the LSB of the exponent into the MSB of FMANT+2
            ROR A
            ORA FMANT+2             ; Get the MSB of the mantissa
            STA ARGUMENT1+2

            LDA FMANT+1             ; Get the next byte of the mantissa
            STA ARGUMENT1+1
            LDA FMANT               ; Get the last byte of the mantissa
            STA ARGUMENT1

            LDA #TYPE_FLOAT         ; Set the type of ARGUMENT1
            STA ARGTYPE1

            PLP
            RETURN
            .pend

;
; Normalize the floating point number in the accumulator
;
; Inputs:
;   FMANT, FEXP, FFLAGS: the floating point number to normalize
;
; Outputs:
;   FMANT, FEXP, FFLAGS: the normalized form of the number
;   Y = number of left shifts
;
FMANTNORM   .proc
            PHP
            TRACE "FMANTNORM"

            LDY #0

            setas
loop        LDA FMANT+3             ; Check the guard
            BEQ check_msb           ; If zero, we may need to shift left

            LSR FMANT+3             ; Shift the mantissa right one bit
            ROR FMANT+2
            ROR FMANT+1
            ROR FMANT
            ROR FMANTGUARDL

            INC FEXP                ; Adjust exponent to match
            BRA loop                ; And check again

check_msb   LDA FMANT+2             ; Is bit 23 = 0?
            BMI round               ; No: round up

            ASL FMANT               ; Multiply mantissa by two
            ROL FMANT+1
            ROL FMANT+2

            DEC FEXP                ; Adjust the exponent to match
            INY                     ; Count the shift
            BNE check_msb           ; If not underflow: repeat

            LDA #0                  ; Clear the accumulator            
            STA FMANT
            STA FMANT+1
            STA FMANT+2
            STA FEXP
            STA FFLAGS

done        PLP                     ; Return to caller
            RETURN

round       LDA FMANTGUARDL         ; Is the first bit outside the accumulator 1?
            BPL done                ; No: just return

            CLC                     ; Increment the mantissa
            LDA FMANT
            ADC #1
            STA FMANT
            LDA FMANT+1
            ADC #0
            STA FMANT+1
            LDA FMANT+2
            ADC #0
            STA FMANT+2

            BCC done                ; If no carry, just return

            ROR FMANT+2             ; Divide the mantissa by two
            ROR FMANT+1
            ROR FMANT+0

            INC FEXP                ; And adjust the exponent to match
            BNE done                ; If not overflow, we're done

            THROW ERR_OVERFLOW      ; If so, throw the overflow error
            .pend

;
; Parse a string into a number... either INTEGER or FLOAT
;
; Input string formats:
;   INTEGER: "[+/-]d+"
;   FLOAT: "[+/-]d+.d*[E[-]d+]"
;
; Inputs:
;   BIP = pointer to the first character to try to parse
;
; Outputs:
;   ARGUMENT1 = the number parsed (can be either TYPE_INTEGER or TYPE_FLOAT)
;
; Modifies:
;   SCRATCH, SCRATCH2
;
STON        .proc
            PHP
            TRACE "STON"

            ; Clear the accumulator
            setas
            LDA #0
            LDX #7
clr_loop    STA FMANTGUARDL,X
            DEX
            BPL clr_loop

            LDA [BIP]               ; Get the character
            CMP #'+'                ; Is it a "+"
            BEQ fetch               ; Yes: skip it and look for a numeral

            CMP #'-'                ; Is it a "-"?
            BNE chk_digit           ; No: look for a numeral

            LDA #$80                ; Yes:...
            STA FFLAGS              ; Set the sign flag for negative

fetch       CALL INCBIP             ; Move to the next character
            LDA [BIP]               ; And fetch it

            CMP #'.'                ; Is it a decimal point?
            BNE chk_digit           ; No: check to see if it is a digit

            LDA FFLAGS              ; Have we already seen the decimal point?
            CMP #FFLG_DP
            BEQ finish              ; Yes: we've finished reading the number

            ORA #FFLG_DP            ; No: Set the DP flag
            STA FFLAGS
            BRA fetch               ; And go back to fetch the next character

            ; Finish processing the number and return it
finish      LDA FDEXP               ; Check the decimal exponent
            BEQ norm                ; If it's zero... normalize

            ; TODO: adjust the exponent and value to account for the decimal exponent
            
norm        CALL FMANTNORM          ; Normalize the value in the floating point accumulator

            setas
            STY SCRATCH2
            SEC
            LDA #23
            SBC SCRATCH2
            
            CLC
            ADC #127
            STA FEXP


            CALL ACCTOARG1          ; And pack it into ARGUMENT1

done        PLP
            RETURN

chk_digit   CMP #'0'                ; Is it a digit (0 - 9)?
            BLT not_digit           ; No: check for exponent or end of number
            CMP #'9'+1
            BGE not_digit

            CALL FACCMUL10          ; ACC := ACC * 10

            LDA [BIP]               ; Convert digit to a number
            SEC
            SBC #'0'

            setal
            AND #$00FF

            CLC                     ; ACC := ACC + digit (including high guard byte)
            ADC FMANT
            STA FMANT
            LDA FMANT+2
            ADC #0
            STA FMANT+2

            setas
            LDA FFLAGS              ; Is DP set?
            BIT #FFLG_DP
            BEQ fetch               ; No: just fetch the next digit

            DEC FDEXP               ; DEXP -= DEXP
            BRA fetch               ; And fetch the next digit

not_digit   CMP #'e'                ; Is it e/E?
            BNE finish              ; No: finish processing the number
            CMP #'E'
            BNE finish

            CALL INCBIP             ; Fetch the next character
            LDA [BIP]
            
            CMP #'+'                ; Is it a plus sign?
            BEQ exp_fetch           ; Yes: just read the digits

            CMP #'-'                ; Is it a minus sign?
            BNE exp_digit           ; No: just read the exponent digits

            LDA FFLAGS              ; Set the EXPSGN flag to indicate the exponent is negative
            ORA #FFLG_EXPSGN
            STA FFLAGS

exp_fetch   CALL INCBIP             ; Get the next character for the exponent
            LDA [BIP]

exp_digit   CMP #'0'                ; Is it a digit? (0 - 9)
            BLT finish              ; No: finish processing the number
            CMP #'9'+1
            BGE finish

            SEC                     ; Convert it to a number
            SBC #'0'

            STA SCRATCH             ; SCRATCH := the digit

            CALL INCBIP             ; Get what could be the second digit
            LDA [BIP]

            CMP #'0'                ; Is it a digit? (0 - 9)
            BLT exp_sgn             ; No: set the sign of the exponent
            CMP #'9'+1
            BGE exp_sgn

            PHA
            ASL SCRATCH             ; SCRATCH := SCRATCH * 10
            LDA SCRATCH
            ASL SCRATCH
            ASL SCRATCH
            CLC
            ADC SCRATCH
            STA SCRATCH
            PLA

            CLC
            ADC SCRATCH             ; SCRATCH += digit
            STA SCRATCH

exp_sgn     LDA FFLAGS              ; Is the exponent negative?
            BIT #FFLG_EXPSGN
            BEQ exp_pos             ; No: treat the exponent as positive

            LDA SCRATCH             ; SCRATCH := 0 - SCRATCH
            EOR #$FF
            INC A
            STA SCRATCH

exp_pos     CLC                     ; FDEXP += SCRATCH
            LDA SCRATCH
            ADC FDEXP
            STA FDEXP

            JMP finish              ; And finish processing the number
            .pend

;
; Convert a floating point number into a string
;
; Inputs:
;   ARGUMENT1 = floating point number to convert
;
; Outputs:
;   ARGUMENT1 = pointer to the (perhaps temporary) string representation of the float
;
FTOS        .proc
            PHP
            PLP
            RETURN
            .pend