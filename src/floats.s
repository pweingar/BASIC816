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
finish      CALL FMANTNORM          ; Normalize the value in the floating point accumulator

            setas
            STY SCRATCH2
            SEC
            LDA #23
            SBC SCRATCH2
            
            CLC
            ADC #127
            STA FEXP

            CALL ACCTOARG1          ; And pack it into ARGUMENT1

            ; Adjust the floating point value by the decimal exponent

            setas
            LDA FDEXP               ; Check the decimal exponent
            BEQ done                ; If it's zero... we're done
            BMI div10               ; If it's negative, we want to divide the number
            CALL FP_MUL10N          ; Multiply the value by 10^FDEXP
            BRA done

div10       EOR #$FF
            INC A
            CALL FP_DIV10N          ; Divide the value by 10^FDEXP

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
; Check to see if the floating point number in ARGUMENT1 is 0.0
;
; Inputs:
;   ARGUMENT1 = the floating point number to check (assumed to be a float)
;
; Outputs:
;   C = set if ARGUMENT1 = 0.0, clear otherwise
;
FARG1EQ0    .proc
            PHP
            setal
            LDA ARGUMENT1
            BNE ret_false
            LDA ARGUMENT1+2
            AND #$7FFF              ; Ignore the sign bit +0.0 and -0.0 are both 0.0
            BNE ret_false

ret_true    PLP
            SEC
            RETURN

ret_false   PLP
            CLC
            RETURN            
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

            CALL FARG1EQ0           ; Check to see if it's 0.0
            BCC not_zero            ; No: go ahead and process it

            setal                   ; Yes: return "0"
            LDA #<>fp_zero
            STA ARGUMENT1
            LDA #`fp_zero
            STA ARGUMENT1+2

            setas
            LDA #TYPE_STRING
            STA ARGTYPE1
            BRA done

            ; Otherwise, we need to unpack and process the number the hard way.
not_zero    STZ FDEXP
            STZ FFLAGS

            setal
neg_loop    LDA ARGUMENT1+2
            AND #$7F80              ; Mask out all but the exponent
            CMP #$3F80              ; Is it >= 127?
            BGE brz                 ; 

            LDA #1                  ; ARGUMENT1 *= 10
            CALL FP_MUL10N
            DEC FDEXP               ; Decimal Exponent --
            BRA neg_loop

brz         LDA ARGUMENT1+2
            AND #$7F80              ; Mask out all but the exponent
            CMP #$3F80              ; And check the exponent
            BEQ bcd                 ; If =127, start processing digits
            BLT brx

            LDA #1                  ; ARGUMENT1 /= 10
            CALL FP_DIV10N
            INC FDEXP               ; Decimal Exponent ++
            BRA brz

brx         NOP                     ; Not sure what is needed here

bcd         CALL ARG1TOACC          ; Unpack the float

            STZ MLINEBUF            ; We'll use MLINEBUF as the BCD buffer
            STZ MLINEBUF+2          ; So clear it to zeros
            STZ MLINEBUF+4

            LDY #23                 ; We'll process 23 bits

shift_add   setas
            ASL FMANT               ; Shift mantissa into carry
            ROL FMANT+1
            ROL FMANT+2
            setal

            BCC skip_bcdadd

            SED                     ; BCD := BCD * 2 + 1
            LDA MLINEBUF
            ADC MLINEBUF
            STA MLINEBUF
            LDA MLINEBUF+2
            ADC MLINEBUF+2
            STA MLINEBUF+2
            LDA MLINEBUF+4
            ADC MLINEBUF+4
            STA MLINEBUF+4
            CLD

skip_bcdadd DEY
            BNE shift_add

done        PLP
            RETURN
fp_zero     .null "0"
            .pend