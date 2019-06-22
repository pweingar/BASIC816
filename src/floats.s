;;;
;;; Implement floating point numbers for the 65816
;;;
;;; Representation:
;;;
;;;  7 MSB  0 7      0 7      0 7  LSB  0
;;; +--------+--------+--------+---------+
;;; |EEEEEEEE|SMMMMMMM|MMMMMMMM|MMMMMMMMM|
;;; +--------+--------+--------+---------+
;;;
;;; Where:
;;;     E = exponent bit
;;;     S = sign bit (1 = negative, 0 = positive)
;;;     M = mantissa bit
;;;
;;; Special cases:
;;;     00000000 x0000000 00000000 00000000 = 0.0
;;;     11111111 x0000000 00000000 00000000 = +/- infinity
;;;     11111111 x1111111 11111111 11111111 = Not-a-Number (NaN)
;;;

;
; Check to see if the float in ARGUMENT1 is zero
;
; Inputs:
;   ARGUMENT1 = a float
;
; Outputs:
;   C is set if ARGUMENT1 is 0, clear otherwise
;
FARG1EQ0        .proc
                PHP

                setal
                LDA ARGUMENT1
                BNE return_false
                LDA ARGUMENT1+2
                AND #$FF7F              ; Mask off the sign bit
                BNE return_false

return_true     PLP
                SEC
                RETURN

return_false    PLP
                CLC
                RETURN
                .pend

;
; Convert a 16-bit integer to a float
;
; Inputs:
;   ARGUMENT1 = the integer to convert
;
; Outputs:
;   ARGUMENT1 = the floating point number
;
ITOF            ;.proc

                setdp GLOBAL_VARS

                setal
                LDA ARGUMENT1           ; Copy the argument to SCRATCH
                STA SCRATCH
                LDA ARGUMENT1+2
                STZ SCRATCH+2
                 
                STZ ARGUMENT1           ; Clear the result
                STZ ARGUMENT1+2
                
                setas
                STZ SIGN1               ; Mark as positive by default

                LDA #TYPE_FLOAT         ; And list it as a float
                STA ARGTYPE1

                setal
                LDA SCRATCH             ; Is the integer 0?
                BEQ itof_done           ; Yes: we're already done.
                BPL shift               ; If positive: start shifting

                setas
                LDA #$80                ; Flag the result as negative
                STA SIGN1

                setal
                EOR #$FFFF              ; SCRATCH := -SCRATCH
                INC A         
                STA SCRATCH

shift           setas
                INC EXPONENT1           ; Bump up the exponent

                setal                   ; And shift a bit into the mantissa
                LSR SCRATCH+2
                ROR SCRATCH
                
                setas
                ROR MANTISSA1+2
                ROR MANTISSA1+1
                ROR MANTISSA1

                setal
                LDA SCRATCH             ; Is the MSB in SCRATCH's bit 0 position?
                CMP #1
                BNE shift               ; No: keep shifting until it is

                setas
                ASL SIGN1               ; Yes: shift in the sign bit
                ROR MANTISSA1+2
                ROR MANTISSA1+1
                ROR MANTISSA1

itof_done       RETURN
                ;.pend

;
; Convert a floating point number to an integer
;
; Inputs:
;   ARGUMENT1 = the floating point number to convert
;
; Outputs:
;   ARGUMENT1 = the integer portion of the float
;
FTOI            .proc
                setal
                CALL FARG1EQ0
                BCC not_zero

                setas
                LDA #TYPE_INTEGER       ; If so, return 0 as the result
                STA ARGTYPE1
                STZ SIGN1               ; Set sign to positive as a default
                BRA done

                ; TODO: recognize infinities and NaN and throw an error

                ; Has a number... so start shifting it into SCRATCH
not_zero        setal
                LDA #1
                STA SCRATCH
                STZ SCRATCH+2

                setas                  
                ASL MANTISSA1           ; Shift out the sign bit
                ROL MANTISSA1+1
                ROL MANTISSA1+2

                LDA #$80
                STA SIGN1               ; Remember that the number was negative

shift_loop      setas
                LDA EXPONENT1           ; Check to see if the exponent is 0
                BEQ shift_done          ; If so: we're done and can package the result

                DEC EXPONENT1           ; If not: decrement the exponent and

                seta2                   ; ... shift a bit into SCRATCH
                ASL MANTISSA1
                ROL MANTISSA1+1
                ROL MANTISSA1+2
                setal
                ROL SCRATCH
                ROL SCRATCH+2

                BRA shift_loop          ; and try again

shift_done      setas
                LDA #TYPE_INTEGER       ; If so, return 0 as the result
                STA ARGTYPE1
                
                setal
                LDA SCRATCH             ; SCRATCH contains the integer
                STA ARGUMENT1           ; Copy it to ARGUMENT1
                LDA SCRATCH+2
                STA ARGUMENT1+2

done            RETURN
                .pend
