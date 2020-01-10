;;;
;;; Low level support code for floating point math
;;;
;;; This code uses the C256's floating point coprocessor
;;;

.include "fp_math_defs.s"

;
; Add two floating point numbers
;
; Inputs:
;   ARGUMENT1 = a floating point number
;   ARGUMENT2 = a floating point number
;
; Outputs:
;   ARGUMENT1 := ARGUMENT1 - ARGUMENT2
;
OP_FP_SUB       PHP

                setas
                ; We will subtract two numbers in floating point format
                LDA #FP_ADD_IN0_MUX0 | FP_ADD_IN1_MUX1
                STA @lFP_MATH_CTRL0
                BRA FP_ADD_SUB

;
; Add two floating point numbers
;
; Inputs:
;   ARGUMENT1 = a floating point number
;   ARGUMENT2 = a floating point number
;
; Outputs:
;   ARGUMENT1 the sum of the old value of ARGUMENT1 and ARGUMENT2
;
OP_FP_ADD       PHP

                setas
                ; We will add two numbers in floating point format
                LDA #FP_MATH_CTRL0_ADD | FP_ADD_IN0_MUX0 | FP_ADD_IN1_MUX1
                STA @lFP_MATH_CTRL0

                ; We will take the output from the adder
FP_ADD_SUB      LDA #FP_OUT_ADD
                STA @lFP_MATH_CTRL1

                setal
                LDA ARGUMENT1               ; Send ARGUMENT1 to the math coprocessor
                STA @lFP_MATH_INPUT0_LL
                LDA ARGUMENT1+2
                STA @lFP_MATH_INPUT0_HL

                LDA ARGUMENT2               ; Send ARGUMENT2 to the math coprocessor
                STA @lFP_MATH_INPUT1_LL
                LDA ARGUMENT2+2
                STA @lFP_MATH_INPUT1_HL

                NOP
                NOP
                NOP

                setas
                LDA @lFP_MATH_ADD_STAT      ; Check the status of the addition
                AND #%00000111              ; Filter out the ZERO status
                BNE fp_add_error            ; If an issue was raise, process the math error

                setal
                LDA @lFP_MATH_OUTPUT_FP_LL  ; Retrieve the results into ARGUMENT1
                STA ARGUMENT1
                LDA @lFP_MATH_OUTPUT_FP_HL
                STA ARGUMENT1+2

fp_add_done     PLP
                RETURN

fp_add_error    CALL FP_MATH_ERROR           ; Jump to the handler for math error flags
                BRA fp_add_done

;
; Handle any FP math statuses
;
FP_MATH_ERROR   .proc
                BIT #FP_ADD_STAT_NAN        ; Is there a NaN condition?
                BEQ check_over              ; No: check for overflow
                THROW ERR_NAN               ; Yes: Throw NAN error

check_over      BIT #FP_ADD_STAT_OVF        ; Is ther an overflow condition?
                BEQ check_under             ; No: check for underflow
                THROW ERR_OVERFLOW          ; Yes: throw an overflow error

check_under     BIT #FP_ADD_STAT_UDF        ; Is there an underflow condition?
                BEQ done                    ; No: we should just return... this probably shouldn't happen
                THROW ERR_UNDERFLOW         ; Yes: throw an underflow error

done            RETURN
                .pend