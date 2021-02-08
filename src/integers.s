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

            TRACE "OP_INT_MUL"

            ; Set up local storage
locals      .virtual 1,S
L_SIGN      .word ?
L_RESULT    .dword ?
            .dword ?
            .endv
            SALLOC SIZE(locals)

            setaxl

            LDA #0                  ; Start by assuming positive numbers
            STA L_SIGN

            STA L_RESULT            ; Clear result
            STA L_RESULT+2
            STA L_RESULT+4
            STA L_RESULT+6

            LDA ARGUMENT1+2         ; Ensure ARGUMENT1 is positive
            BPL chk_sign2

            LDA #$8000              ; Record that ARGUMENT1 is negative
            STA L_SIGN

            LDA ARGUMENT1+2         ; Take the two's complement of ARGUMENT1
            EOR #$FFFF
            STA ARGUMENT1+2
            LDA ARGUMENT1
            EOR #$FFFF
            INC A
            STA ARGUMENT1
            BNE chk_sign2
            INC ARGUMENT1+2

chk_sign2   LDA ARGUMENT2+2         ; Ensure ARGUMENT2 is positive
            BPL chk_over

            LDA L_SIGN              ; Flip the sign
            EOR #$8000
            STA L_SIGN

            LDA ARGUMENT2+2         ; Take the two's complement of ARGUMENT2
            EOR #$FFFF
            STA ARGUMENT2+2
            LDA ARGUMENT2
            EOR #$FFFF
            INC A
            STA ARGUMENT2
            BNE chk_over
            INC ARGUMENT2+2

chk_over    ; ARGUMENT1 = A << 16 + B
            ; ARGUMENT2 = C << 16 + D
            
            ; Make sure either A or C is 0 first, otherwise it's an overflow
            LDA ARGUMENT1+2
            BEQ do_mult
            LDA ARGUMENT2+2
            BNE overflow

do_mult     ; RESULT = B*C << 16 + A*D << 16 + B*D

            LDA ARGUMENT1           ; Calculate B*D
            STA @l M0_OPERAND_A
            LDA ARGUMENT2
            STA @l M0_OPERAND_B
            LDA @l M0_RESULT
            STA L_RESULT
            LDA @l M0_RESULT+2
            STA L_RESULT+2

            LDA ARGUMENT1+2         ; Calculate A*D << 16 + B*D
            STA @l M0_OPERAND_A
            LDA ARGUMENT2
            STA @l M0_OPERAND_B
            CLC
            LDA @l M0_RESULT
            ADC L_RESULT+2
            STA L_RESULT+2
            LDA @l M0_RESULT+2
            ADC L_RESULT+4
            STA L_RESULT+4

            LDA ARGUMENT1           ; Calculate B*C << 16 + A*D << 16 + B*D
            STA @l M0_OPERAND_A
            LDA ARGUMENT2+2
            STA @l M0_OPERAND_B
            CLC
            LDA @l M0_RESULT
            ADC L_RESULT+2
            STA L_RESULT+2
            LDA @l M0_RESULT+2
            ADC L_RESULT+4
            STA L_RESULT+4

            ; Check for over-flow

            LDA L_RESULT+4
            BEQ no_overflow
            LDA L_RESULT+6
            BEQ no_overflow

overflow    THROW ERR_OVERFLOW

no_overflow setaxl
            LDA L_SIGN              ; Check the sign
            BPL ret_result          ; If positive: just return the result

            LDA L_RESULT+2          ; Compute the two's complement of the result
            EOR #$FFFF
            STA L_RESULT+2
            LDA L_RESULT
            EOR #$FFFF
            INC A
            STA L_RESULT
            BNE ret_result
            LDA L_RESULT+2
            INC A
            STA L_RESULT+2

ret_result  ; Return the integer in L_RESULT

            LDA L_RESULT
            STA ARGUMENT1
            LDA L_RESULT+2
            STA ARGUMENT1+2

;             ; We don't have a hardware multiplier, so do the multiplication the hard way
;             STZ SCRATCH
;             STZ SCRATCH+2

; loop        LDX ARGUMENT1       ; Is ARGUMENT1 = 0
;             BNE shift_a1
;             LDX ARGUMENT1+2
;             BEQ done

; shift_a1    CLC                 ; Shift ARGUMENT1 by 1 bit
;             ROR ARGUMENT1+2
;             LSR ARGUMENT1
;             BCC shift_a2        ; If that bit was clear, skip the addition

;             CLC                 ; Add ARGUMENT2 to our result so far
;             LDA SCRATCH
;             ADC ARGUMENT2
;             STA SCRATCH
;             LDA SCRATCH+2
;             ADC ARGUMENT2+2
;             STA SCRATCH+2

; shift_a2    ASL ARGUMENT2       ; And shift ARGUMENT2 left by one bit
;             ROL ARGUMENT2+2
;             BRA loop

; done        LDA SCRATCH         ; Copy result back to ARGUMENT1
;             STA ARGUMENT1
;             LDA SCRATCH+2
;             STA ARGUMENT1+2

            SFREE SIZE(locals)          ; Clean the locals from the stack

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
            LDA ARGUMENT1
            CMP ARGUMENT2
            LDA ARGUMENT1+2
            SBC ARGUMENT2+2
            BVC skip_eor
            EOR #$8000
skip_eor    BMI ret_true

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
; greater-than: is ARGUMENT1 > ARGUMENT2
;
; Outputs:
;   ARGUMENT1 = -1 if ARGUMENT1 was > ARGUMENT2, 0 otherwise
;
OP_INT_GT   .proc
            PHP

            TRACE "OP_INT_GT"

            setal
            LDA ARGUMENT1
            CMP ARGUMENT2
            BNE test_fully
            LDA ARGUMENT1+2
            CMP ARGUMENT2+2
            BNE test_fully

ret_false   STZ ARGUMENT1
            STZ ARGUMENT1+2
            BRA done

test_fully  LDA ARGUMENT2
            CMP ARGUMENT1
            LDA ARGUMENT2+2
            SBC ARGUMENT1+2
            BVC skip_eor
            EOR #$8000
skip_eor    BPL ret_false

ret_true    LDA #$FFFF
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
            LDA ARGUMENT1
            CMP ARGUMENT2
            BNE test_fully
            LDA ARGUMENT1+2
            CMP ARGUMENT2+2
            BNE test_fully

ret_true    LDA #$FFFF
            STA ARGUMENT1
            STA ARGUMENT1+2
            BRA done

test_fully  LDA ARGUMENT2
            CMP ARGUMENT1
            LDA ARGUMENT2+2
            SBC ARGUMENT1+2
            BVC skip_eor
            EOR #$8000
skip_eor    BMI ret_true

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
            LDA ARGUMENT1
            CMP ARGUMENT2
            BNE test_fully
            LDA ARGUMENT1+2
            CMP ARGUMENT2+2
            BNE test_fully

ret_true    LDA #$FFFF
            STA ARGUMENT1
            STA ARGUMENT1+2
            BRA done

test_fully  LDA ARGUMENT1
            CMP ARGUMENT2
            LDA ARGUMENT1+2
            SBC ARGUMENT2+2
            BVC skip_eor
            EOR #$8000
skip_eor    BMI ret_true

ret_false   STZ ARGUMENT1
            STZ ARGUMENT1+2
            
done        PLP
            RETURN
            .pend