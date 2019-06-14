;;;
;;; Code for evaluating operators
;;;
;;; These will all be called by PROCESSOP and will assume:
;;;     DP = GLOBAL_VARS
;;;     DBR = 0
;;;     MX set to 16 bit memory and indexes
;;;
;;; Also, arguments are expected in ARGUMENT1 and ARGUMENT2.
;;; Result will be stored in ARGUMENT1.
;;;
;;; Finally all are called through JSR, so they must use RTS to return.
;;;

; Perform addition
OP_PLUS     .proc
            CLC
            LDA ARGUMENT1
            ADC ARGUMENT2
            STA ARGUMENT1
            LDA ARGUMENT1+2
            ADC ARGUMENT2+2
            STA ARGUMENT1+2
            RTS
            .pend

; Perform subtraction
OP_MINUS    .proc
            SEC
            LDA ARGUMENT1
            SBC ARGUMENT2
            STA ARGUMENT1
            LDA ARGUMENT1+2
            SBC ARGUMENT2+2
            STA ARGUMENT1+2
            RTS
            .pend

; 32-bit multiplication
OP_MULTIPLY .proc
.if SYSTEM = SYSTEM_C256
            ; The C256 has a 16-bit hardware multiplier, so use it.
            LDA ARGUMENT1
            STA @lM1_OPERAND_A

            LDA ARGUMENT2
            STA @lM1_OPERAND_B

            LDA @lM1_RESULT
            STA ARGUMENT1
            LDA @lM1_RESULT+2
            STA ARGUMENT1+2
.else
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
.endif
            RTS
            .pend

; Division
OP_DIVIDE   .proc
            TRACE "OP_DIVIDE"

.if SYSTEM = SYSTEM_C256
            LDA ARGUMENT1
            STA @lD1_OPERAND_B

            LDA ARGUMENT2
            STA @lD1_OPERAND_A 

            LDA @lD1_RESULT
            STA ARGUMENT1
.endif
            RTS
            .pend

; Mod
OP_MOD      .proc
            TRACE "OP_MOD"

.if SYSTEM = SYSTEM_C256
            LDA ARGUMENT1
            STA @lD1_OPERAND_B

            LDA ARGUMENT2
            STA @lD1_OPERAND_A 

            LDA @lD1_REMAINDER
            STA ARGUMENT1
.endif
            RTS
            .pend

; Bitwise AND
OP_AND      .proc
            TRACE "OP_AND"

            setal
            LDA ARGUMENT1
            AND ARGUMENT2
            STA ARGUMENT1
            LDA ARGUMENT1+2
            AND ARGUMENT2+2
            STA ARGUMENT1+2

            RTS
            .pend

; Bitwise OR
OP_OR       .proc
            TRACE "OP_OR"

            setal
            LDA ARGUMENT1
            ORA ARGUMENT2
            STA ARGUMENT1
            LDA ARGUMENT1+2
            ORA ARGUMENT2+2
            STA ARGUMENT1+2

            RTS
            .pend

; Bitwise NOT
OP_NOT      .proc
            TRACE "OP_NOT"

            setal
            LDA ARGUMENT1
            EOR #$FFFF
            STA ARGUMENT1
            LDA ARGUMENT1+2
            EOR #$FFFF
            STA ARGUMENT1+2

            RTS
            .pend
