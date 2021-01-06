;;;
;;; Code to support integers
;;;

;
; Add two 32-bit integers
;
; INPUTS:
;   ARGUMENT1 = 32-bit integer
;   ARGUMENT2 = 32-bit integer
;
; Outputs:
;   ARGUMENT1 = the sum of the two 32-bit integers
;
OP_INT_ADD  .proc
            PHP
            setal

            CLC
            LDA ARGUMENT1
            ADC ARGUMENT2
            STA ARGUMENT1
            LDA ARGUMENT1+2
            ADC ARGUMENT2+2
            STA ARGUMENT1+2

            PLP
            RTS
            .pend

;
; Subtract two 32-bit integers
;
; INPUTS:
;   ARGUMENT1 = 32-bit integer
;   ARGUMENT2 = 32-bit integer
;
; Outputs:
;   ARGUMENT1 := ARGUMENT1 - ARGUMENT2
;
OP_INT_SUB  .proc
            PHP
            TRACE "OP_INT_SUB"

            setal

            SEC
            LDA ARGUMENT1
            SBC ARGUMENT2
            STA ARGUMENT1
            LDA ARGUMENT1+2
            SBC ARGUMENT2+2
            STA ARGUMENT1+2

            PLP
            RTS
            .pend

;
; Multiply two 32-bit integers
;
; INPUTS:
;   ARGUMENT1 = 32-bit integer
;   ARGUMENT2 = 32-bit integer
;
; Outputs:
;   ARGUMENT1 := ARGUMENT1 * ARGUMENT2
;
OP_INT_MUL  .proc
            PHP

            setaxl

            ; We don't have a hardware multiplier, so do the multiplication the hard way
            STZ SCRATCH
            STZ SCRATCH+2

loop        LDX ARGUMENT1       ; Is ARGUMENT1 = 0
            BNE shift_a1
            LDX ARGUMENT1+2
            BEQ done

shift_a1    CLC                 ; Shift ARGUMENT1 by 1 bit
            ROR ARGUMENT1+2
            LSR ARGUMENT1
            BCC shift_a2        ; If that bit was clear, skip the addition

            CLC                 ; Add ARGUMENT2 to our result so far
            LDA SCRATCH
            ADC ARGUMENT2
            STA SCRATCH
            LDA SCRATCH+2
            ADC ARGUMENT2+2
            STA SCRATCH+2

shift_a2    ASL ARGUMENT2       ; And shift ARGUMENT2 left by one bit
            ROL ARGUMENT2+2
            BRA loop

done        LDA SCRATCH         ; Copy result back to ARGUMENT1
            STA ARGUMENT1
            LDA SCRATCH+2
            STA ARGUMENT1+2

            PLP
            RETURN
            .pend

;
; Divide two 32-bit integers
;
; INPUTS:
;   ARGUMENT1 = 32-bit integer
;   ARGUMENT2 = 32-bit integer
;
; Outputs:
;   ARGUMENT1 := ARGUMENT1 / ARGUMENT2
;
OP_INT_DIV  .proc
            PHP

            PLP
            RETURN
            .pend

;
; Less-than: is ARGUMENT1 < ARGUMENT2
;
; Outputs:
;   ARGUMENT1 = -1 if ARGUMENT1 was < ARGUMENT2, 0 otherwise
;
OP_INT_LT   .proc
            PHP
            TRACE "OP_INT_LT"

            setal
            LDA ARGUMENT1+2
            CMP ARGUMENT2+2
            BLT return_true
            LDA ARGUMENT1
            CMP ARGUMENT2
            BLT return_true

            STZ ARGUMENT1
            STZ ARGUMENT1+2
            BRA done

return_true LDA #$FFFF
            STA ARGUMENT1
            STA ARGUMENT1+2

done        PLP
            RETURN
            .pend

;
; greater-than: is ARGUMENT1 > ARGUMENT2
;
; Outputs:
;   ARGUMENT1 = -1 if ARGUMENT1 was > ARGUMENT2, 0 otherwise
;
OP_INT_GT   .proc
            PHP

            TRACE "OP_INT_GT"

            setal
            LDA ARGUMENT2+2
            CMP ARGUMENT1+2
            BLT return_true
            LDA ARGUMENT2
            CMP ARGUMENT1
            BLT return_true

            STZ ARGUMENT1
            STZ ARGUMENT1+2
            BRA done

return_true LDA #$FFFF
            STA ARGUMENT1
            STA ARGUMENT1+2

done        PLP
            RETURN
            .pend

;
; equal-to: is ARGUMENT1 = ARGUMENT2
;
; Outputs:
;   ARGUMENT1 = -1 if ARGUMENT1 was = ARGUMENT2, 0 otherwise
OP_INT_EQ   .proc
            PHP
            TRACE "OP_INT_EQ"

            setal
            LDA ARGUMENT2+2
            CMP ARGUMENT1+2
            BNE ret_false
            LDA ARGUMENT2
            CMP ARGUMENT1
            BNE ret_false

            LDA #$FFFF
            STA ARGUMENT1
            STA ARGUMENT1+2
            BRA done

ret_false   STZ ARGUMENT1
            STZ ARGUMENT1+2

done        PLP
            RETURN
            .pend

;
; not-equal-to: is ARGUMENT1 <> ARGUMENT2
;
; Outputs:
;   ARGUMENT1 = -1 if ARGUMENT1 was <> ARGUMENT2, 0 otherwise
OP_INT_NE   .proc
            PHP
            TRACE "OP_INT_NE"

            setal
            LDA ARGUMENT2+2
            CMP ARGUMENT1+2
            BNE ret_true
            LDA ARGUMENT2
            CMP ARGUMENT1
            BNE ret_true

ret_false   STZ ARGUMENT1
            STZ ARGUMENT1+2
            BRA done

ret_true    LDA #$FFFF
            STA ARGUMENT1
            STA ARGUMENT1+2
            
done        PLP
            RETURN
            .pend

;
; greater-than-equal: is ARGUMENT1 >= ARGUMENT2
;
; Outputs:
;   ARGUMENT1 = -1 if ARGUMENT1 was >= ARGUMENT2, 0 otherwise
OP_INT_GTE  .proc
            PHP
            TRACE "OP_INT_GTE"

            setal
            LDA ARGUMENT1+2
            CMP ARGUMENT2+2
            BLT ret_false
            BNE ret_true
            
            LDA ARGUMENT1
            CMP ARGUMENT2
            BLT ret_false

ret_true    LDA #$FFFF
            STA ARGUMENT1
            STA ARGUMENT1+2
            BRA done

ret_false   STZ ARGUMENT1
            STZ ARGUMENT1+2
            
done        PLP
            RETURN
            .pend

;
; less-than-equal: is ARGUMENT1 <= ARGUMENT2
;
; Outputs:
;   ARGUMENT1 = -1 if ARGUMENT1 was <= ARGUMENT2, 0 otherwise
OP_INT_LTE  .proc
            PHP
            TRACE "OP_INT_LTE"

            setal
            LDA ARGUMENT1+2
            CMP ARGUMENT2+2
            BLT ret_true
            BEQ check_low

ret_false   STZ ARGUMENT1
            STZ ARGUMENT1+2
            BRA done

check_low   LDA ARGUMENT1
            CMP ARGUMENT2
            BEQ ret_true
            BGE ret_false

ret_true    LDA #$FFFF
            STA ARGUMENT1
            STA ARGUMENT1+2
            
done        PLP
            RETURN
            .pend