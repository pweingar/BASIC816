;;;
;;; Low level support code for floating point math
;;;
;;; This code uses the C256's floating point coprocessor
;;;

.include "fp_math_defs.s"
.include "math_cop.s"

;
; Take an integer in ARGUMENT1 and convert it to a floating point using the C256's coprocessor
;
FIXINT_TO_FP        .proc
                    PHP
                    TRACE "FIXINT_TO_FP"

                    setas
                    ; Convert both inputs from 20:12 fixed point
                    LDA #FP_CTRL0_CONV_0 | FP_CTRL0_CONV_1
                    STA @l FP_MATH_CTRL0

                    LDA #FP_OUT_MULT
                    STA @l FP_MATH_CTRL1

                    setal
                    LDA ARGUMENT1               ; Send ARGUMENT1 to the math coprocessor
                    STA @l FP_MATH_INPUT0_LL
                    LDA ARGUMENT1+2
                    STA @l FP_MATH_INPUT0_HL

                    LDA #0
                    STA @l FP_MATH_INPUT1_LL    ; ARGUMENT2 = 0100 0000 = 4096 in 20:12
                    LDA #$0100
                    STA @l FP_MATH_INPUT1_HL

                    NOP
                    NOP
                    NOP
                    NOP
                    NOP
                    NOP

                    LDA @l FP_MATH_OUTPUT_FP_LL ; Retrieve the results into ARGUMENT1
                    STA ARGUMENT1
                    LDA @l FP_MATH_OUTPUT_FP_HL
                    STA ARGUMENT1+2

                    LDA #TYPE_FLOAT
                    STA ARGTYPE1

                    PLP
                    RETURN
                    .pend

;
; Take the float in ARGUMENT1 and convert it to an integer using the fixed point converter
;
; NOTE: this is currently not working correctly:
; A=1234.0
; B%=A
; B% will not be equal to 1234
;
; This error appears to have something to do either with parsing the decimal point or with calls
; to the floating point coprocessor... adding the code below to clear the FP registers changed the results.
;
FP_TO_FIXINT        .proc
                    PHP
                    TRACE "FP_TO_FIXINT"

                    setas
                    LDA #0
                    STA @l FP_MATH_CTRL0
                    STA @l FP_MATH_CTRL1
                    STA @l FP_MATH_INPUT0_LL
                    STA @l FP_MATH_INPUT0_LL+1
                    STA @l FP_MATH_INPUT0_LL+2
                    STA @l FP_MATH_INPUT0_LL+3
                    STA @l FP_MATH_INPUT1_LL
                    STA @l FP_MATH_INPUT1_LL+1
                    STA @l FP_MATH_INPUT1_LL+2
                    STA @l FP_MATH_INPUT1_LL+3
                    STA @l FP_MATH_INPUT1_LL+4

                    NOP
                    NOP
                    NOP
                    NOP
                    NOP
                    NOP
                    NOP
                    NOP
                    NOP
                    NOP
                    NOP
                    NOP

                    LDA #FP_CTRL0_CONV_1
                    STA @l FP_MATH_CTRL0

                    LDA #FP_OUT_DIV
                    STA @l FP_MATH_CTRL1

                    LDA ARGUMENT1
                    STA @l FP_MATH_INPUT0_LL
                    LDA ARGUMENT1+1
                    STA @l FP_MATH_INPUT0_LL+1
                    LDA ARGUMENT1+2
                    STA @l FP_MATH_INPUT0_LL+2
                    LDA ARGUMENT1+3
                    STA @l FP_MATH_INPUT0_LL+3

                    LDA #0
                    STA @l FP_MATH_INPUT1_LL    ; ARGUMENT2 = 0100 0000 = 4096 in 20:12
                    STA @l FP_MATH_INPUT1_LL+1
                    STA @l FP_MATH_INPUT1_LL+2
                    LDA #$01
                    STA @l FP_MATH_INPUT1_LL+3

                    NOP
                    NOP
                    NOP
                    NOP
                    NOP
                    NOP

                    LDA @l FP_MATH_OUTPUT_FIXED_LL
                    STA ARGUMENT1
                    LDA @l FP_MATH_OUTPUT_FIXED_LL+1
                    STA ARGUMENT1+1
                    LDA @l FP_MATH_OUTPUT_FIXED_LL+2
                    STA ARGUMENT1+2
                    LDA @l FP_MATH_OUTPUT_FIXED_LL+3
                    STA ARGUMENT1+3

                    LDA #TYPE_INTEGER
                    STA ARGTYPE1

                    PLP
                    RETURN
                    .pend

;
; Add two floating point numbers
;
; Inputs:
;   ARGUMENT1 = a floating point number
;   ARGUMENT2 = a floating point number
;
; Outputs:
;   ARGUMENT1 <-- ARGUMENT1 - ARGUMENT2
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
;   ARGUMENT1 <-- ARGUMENT1 + ARGUMENT2
;
OP_FP_ADD       PHP
                TRACE "OP_FP_ADD"

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
; Divide two floating point numbers
;
; Inputs:
;   ARGUMENT1 = a floating point number
;   ARGUMENT2 = a floating point number
;
; Outputs:
;   ARGUMENT1 <-- ARGUMENT1 / ARGUMENT2
;
OP_FP_DIV       PHP

                setas
                ; We will take the output from the multiplier
                LDA #FP_OUT_DIV
                STA @l FP_MATH_CTRL1

                ; Don't use the converters, or do anything special with the adder
                LDA #0
                STA @lFP_MATH_CTRL0

                setal
                LDA ARGUMENT1               ; Send ARGUMENT1 to the math coprocessor
                STA @l FP_MATH_INPUT0_LL
                LDA ARGUMENT1+2
                STA @l FP_MATH_INPUT0_HL

                LDA ARGUMENT2               ; Send ARGUMENT2 to the math coprocessor
                STA @l FP_MATH_INPUT1_LL
                LDA ARGUMENT2+2
                STA @l FP_MATH_INPUT1_HL

                NOP
                NOP
                NOP

                setas
                LDA @l FP_MATH_DIV_STAT     ; Check the status of the addition
                AND #%00010111              ; Filter out the ZERO status
                BNE fp_div_error            ; If an issue was raise, process the math error

                setal
                LDA @l FP_MATH_OUTPUT_FP_LL ; Retrieve the results into ARGUMENT1
                STA ARGUMENT1
                LDA @l FP_MATH_OUTPUT_FP_HL
                STA ARGUMENT1+2

fp_div_done     PLP
                RETURN

fp_div_error    CALL FP_MATH_ERROR           ; Jump to the handler for math error flags
                BRA fp_div_done

;
; Multiply two floating point numbers
;
; Inputs:
;   ARGUMENT1 = a floating point number
;   ARGUMENT2 = a floating point number
;
; Outputs:
;   ARGUMENT1 <-- ARGUMENT1 * ARGUMENT2
;
OP_FP_MUL       PHP

                setas
                ; We will take the output from the multiplier
                LDA #FP_OUT_MULT
                STA @l FP_MATH_CTRL1

                ; Don't use the converters, or do anything special with the adder
                LDA #0
                STA @lFP_MATH_CTRL0

                setal
                LDA ARGUMENT1               ; Send ARGUMENT1 to the math coprocessor
                STA @l FP_MATH_INPUT0_LL
                LDA ARGUMENT1+2
                STA @l FP_MATH_INPUT0_HL

                LDA ARGUMENT2               ; Send ARGUMENT2 to the math coprocessor
                STA @l FP_MATH_INPUT1_LL
                LDA ARGUMENT2+2
                STA @l FP_MATH_INPUT1_HL

                NOP
                NOP
                NOP

                setas
                LDA @l FP_MATH_MULT_STAT    ; Check the status of the addition
                AND #%00000111              ; Filter out the ZERO status
                BNE fp_mul_error            ; If an issue was raise, process the math error

                setal
                LDA @l FP_MATH_OUTPUT_FP_LL ; Retrieve the results into ARGUMENT1
                STA ARGUMENT1
                LDA @l FP_MATH_OUTPUT_FP_HL
                STA ARGUMENT1+2

fp_mul_done     PLP
                RETURN

fp_mul_error    CALL FP_MATH_ERROR           ; Jump to the handler for math error flags
                BRA fp_mul_done

;
; Handle any FP math statuses
;
FP_MATH_ERROR   .proc
                setas
                BIT #FP_ADD_STAT_NAN        ; Is there a NaN condition?
                BEQ check_over              ; No: check for overflow
                BRK
                THROW ERR_NAN               ; Yes: Throw NAN error

check_over      BIT #FP_ADD_STAT_OVF        ; Is ther an overflow condition?
                BEQ check_under             ; No: check for underflow
                THROW ERR_OVERFLOW          ; Yes: throw an overflow error

check_under     BIT #FP_ADD_STAT_UDF        ; Is there an underflow condition?
                BEQ done                    ; No: we should just return... this probably shouldn't happen
                THROW ERR_UNDERFLOW         ; Yes: throw an underflow error

done            RETURN
                .pend

;
; Use the C256 coprocessor to multiply the float in ARGUMENT1 by 10.0
;
; Inputs:
;   ARGUMENT1 = the floating point number to multiply by 10.0
;
; Outputs:
;   ARGUMENT1 = the number multiplied by 10.0
;
FP_MUL10        .proc
                PHP

                setas
                LDA #FP_OUT_MULT                ; Set for multiplication
                STA @l FP_MATH_CTRL1

                LDA #FP_CTRL0_CONV_1            ; Input 1 is fixed point
                STA @l FP_MATH_CTRL0

                setal
                LDA #$A000                      ; 10 is one factor
                STA @l FP_MATH_INPUT1_LL
                LDA #0
                STA @l FP_MATH_INPUT1_HL

                LDA ARGUMENT1                   ; N is the other
                STA @l FP_MATH_INPUT0_LL
                LDA ARGUMENT1+2
                STA @l FP_MATH_INPUT0_HL

                NOP
                NOP
                NOP

                setas
                LDA @l FP_MATH_MULT_STAT        ; Check the status
                BIT #FP_MULT_STAT_NAN | FP_MULT_STAT_OVF | FP_MULT_STAT_UDF
                BEQ ret_result

                ; TODO: proper error handling
                BRK                             ; There was an error...

ret_result      setal
                LDA @l FP_MATH_OUTPUT_FP_LL     ; Save result back
                STA ARGUMENT1
                LDA @l FP_MATH_OUTPUT_FP_HL
                STA ARGUMENT1+2

                PLP
                RETURN
                .pend

;
; Use the C256 coprocessor to divide the float in ARGUMENT1 by 10.0
;
; Inputs:
;   ARGUMENT1 = the floating point number to divide by 10.0
;
; Outputs:
;   ARGUMENT1 = the number divided by 10.0
;
FP_DIV10        .proc
                PHP

                setas
                LDA #FP_OUT_DIV             ; Set for multiplication
                STA @l FP_MATH_CTRL1

                LDA #FP_CTRL0_CONV_1        ; Input 1 is fixed point
                STA @l FP_MATH_CTRL0

                setal
                LDA #$A000                  ; 10 is one factor
                STA @l FP_MATH_INPUT1_LL
                LDA #0
                STA @l FP_MATH_INPUT1_HL

                LDA ARGUMENT1               ; N is the other
                STA @l FP_MATH_INPUT0_LL
                LDA ARGUMENT1+2
                STA @l FP_MATH_INPUT0_HL

                NOP
                NOP
                NOP

                LDA @l FP_MATH_OUTPUT_FP_LL ; Save result back
                STA ARGUMENT1
                LDA @l FP_MATH_OUTPUT_FP_HL
                STA ARGUMENT1+2

                PLP
                RETURN
                .pend