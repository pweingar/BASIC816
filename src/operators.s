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

; Get the types of the arguments
; Throw an error if they aren't identical
BINTYPE     .proc
            setas
            LDA ARGTYPE1            ; Get the type of the first argument
            CMP ARGTYPE2            ; Is it the same as for the second argument?
            BNE mismatch            ; No: throw a mismatch error

            setal
            AND #$00FF
            RETURN

mismatch    setal
            THROW ERR_TYPE          ; Throw a type mismatch error
            .pend

; Perform addition
OP_PLUS     .proc
            PHP

            TRACE "OP_PLUS"

            setas
            LDA ARGTYPE1            ; Are both inputs strings?
            CMP #TYPE_STRING
            BNE numbers
            LDA ARGTYPE2
            CMP #TYPE_STRING
            BNE type_error

is_string   CALL STRCONCAT          ; Yes: evaluate string concatenation
            BRA done

type_error  THROW ERR_TYPE          ; If the types can't be cast...

numbers     CALL ASS_ARGS_NUM       ; Check that both inputs are numbers and castable

            LDA ARGTYPE1            ; Get the type...
            CMP #TYPE_INTEGER       ; Is it integer?
            BNE chk_float
            CALL OP_INT_ADD         ; Yes: evaluate integer addition
            BRA done

chk_float   CMP #TYPE_FLOAT         ; Is it a float?
            BNE type_error          ; No: it's a type error
            CALL OP_FP_ADD          ; Yes: do a floating point add

done        PLP
            RETURN
            .pend

; Perform subtraction
OP_MINUS    .proc
            PHP

            CALL ASS_ARGS_NUM       ; Check that both inputs are numbers and castable

            setas
            LDA ARGTYPE1            ; Get the type...
            CMP #TYPE_INTEGER       ; Is it integer?
            BNE chk_float
            CALL OP_INT_SUB         ; Yes: evaluate integer subtraction
            BRA done

chk_float   CMP #TYPE_FLOAT         ; Is it a float?
            BNE type_error          ; No: it's a type error
            CALL OP_FP_SUB          ; Yes: do a floating point subtraction

done        PLP
            RETURN

type_error  THROW ERR_TYPE
            .pend

;
; Multiply two numbers
;
; INPUTS:
;   ARGUMENT1 = 32-bit number
;   ARGUMENT2 = 32-bit number
;
; Outputs:
;   ARGUMENT1 := ARGUMENT1 * ARGUMENT2
;
OP_MULTIPLY .proc
            PHP

            CALL ASS_ARGS_NUM       ; Check that both inputs are numbers and castable

            setas
            LDA ARGTYPE1            ; Get the type...
            CMP #TYPE_INTEGER       ; Is it integer?
            BNE chk_float
            CALL OP_INT_MUL         ; Yes: evaluate integer multiplication
            BRA done

chk_float   CMP #TYPE_FLOAT         ; Is it a float?
            BNE type_error          ; No: it's a type error
            CALL OP_FP_MUL          ; Yes: do a floating point multiplication

done        PLP
            RETURN

type_error  THROW ERR_TYPE
            .pend

;
; Divide two numbers
;
; INPUTS:
;   ARGUMENT1 = 32-bit number
;   ARGUMENT2 = 32-bit number
;
; Outputs:
;   ARGUMENT1 := ARGUMENT1 / ARGUMENT2
;
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

;
; Less-than: is ARGUMENT1 < ARGUMENT2
;
; Outputs:
;   ARGUMENT1 = -1 if ARGUMENT1 was < ARGUMENT2, 0 otherwise
OP_LT       .proc
            TRACE "OP_LT"

            ; TODO: handle floating point and string comparisons

            setal
            LDA ARGUMENT1+2
            CMP ARGUMENT2+2
            BLT return_true
            LDA ARGUMENT1
            CMP ARGUMENT2
            BLT return_true

            STZ ARGUMENT1
            STZ ARGUMENT1+2
            RTS

return_true LDA #$FFFF
            STA ARGUMENT1
            STA ARGUMENT1+2
            RTS
            .pend

;
; greater-than: is ARGUMENT1 > ARGUMENT2
;
; Outputs:
;   ARGUMENT1 = -1 if ARGUMENT1 was > ARGUMENT2, 0 otherwise
OP_GT       .proc
            TRACE "OP_GT"

            ; TODO: handle floating point and string comparisons

            setal
            LDA ARGUMENT2+2
            CMP ARGUMENT1+2
            BLT return_true
            LDA ARGUMENT2
            CMP ARGUMENT1
            BLT return_true

            STZ ARGUMENT1
            STZ ARGUMENT1+2
            RTS

return_true LDA #$FFFF
            STA ARGUMENT1
            STA ARGUMENT1+2
            RTS
            .pend

;
; equal-to: is ARGUMENT1 = ARGUMENT2
;
; Outputs:
;   ARGUMENT1 = -1 if ARGUMENT1 was = ARGUMENT2, 0 otherwise
OP_EQ       .proc
            TRACE "OP_GT"

            ; TODO: handle floating point and string comparisons

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
            RTS

ret_false   STZ ARGUMENT1
            STZ ARGUMENT1+2
            RTS
            .pend

;
; not-equal-to: is ARGUMENT1 <> ARGUMENT2
;
; Outputs:
;   ARGUMENT1 = -1 if ARGUMENT1 was <> ARGUMENT2, 0 otherwise
OP_NE       .proc
            TRACE "OP_NE"

            ; TODO: handle floating point and string comparisons

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
            RTS

ret_false   STZ ARGUMENT1
            STZ ARGUMENT1+2
            RTS
            .pend

;
; greater-than-equal: is ARGUMENT1 >= ARGUMENT2
;
; Outputs:
;   ARGUMENT1 = -1 if ARGUMENT1 was >= ARGUMENT2, 0 otherwise
OP_GTE      .proc
            TRACE "OP_GTE"

            ; TODO: handle floating point and string comparisons

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
            RTS

ret_false   STZ ARGUMENT1
            STZ ARGUMENT1+2
            RTS
            .pend

;
; less-than-equal: is ARGUMENT1 <= ARGUMENT2
;
; Outputs:
;   ARGUMENT1 = -1 if ARGUMENT1 was <= ARGUMENT2, 0 otherwise
OP_LTE      .proc
            TRACE "OP_LTE"

            ; TODO: handle floating point and string comparisons

            setal
            LDA ARGUMENT1+2
            CMP ARGUMENT2+2
            BLT ret_true
            BEQ check_low

ret_false   STZ ARGUMENT1
            STZ ARGUMENT1+2
            RTS

check_low   LDA ARGUMENT1
            CMP ARGUMENT2
            BEQ ret_true
            BGE ret_false

ret_true    LDA #$FFFF
            STA ARGUMENT1
            STA ARGUMENT1+2
            RTS
            .pend