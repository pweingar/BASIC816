;;;
;;; Low level support code for floating point math
;;;
;;; This code uses the C256's floating point coprocessor
;;;

.include "fp_math_defs.s"

;
; Convert the integer in ARGUMENT1 to its floating point equivalent
; This routine uses the Foenix's built in converter, which restricts
; the integer portion to 24 bits.
;
; Inputs:
;   ARGUMENT1 = integer to convert
;
; Outputs:
;   ARGUMENT1 = the floating point equivalent of the original integer
;
ITOF            .proc
                PHX
                PHP

                ; Validate that the source is an integer
                CALL ASS_ARG1_INT

                ; Verify that ARGUMENT1's magnitude is in range for conversion:
                ;   00000000 00000xxx xxxxxxxx xxxxxxxx or
                ;   11111111 11111xxx xxxxxxxx xxxxxxxx
                setal
                LDA ARGUMENT1+2
                AND #$FFF8
                CMP #$0000                                  ; Is the number a small enough positive?
                BEQ is_in_range                             ; Yes: go ahead and convert it
                CMP #$FFF8                                  ; No: Is it a small enough negative?
                BNE overflow                                ; No: it's an overflow problem

                ; Set the math coprocessor to convert
                ; Set operation to ADDER, inputs to 24.12 converters
is_in_range     setas
                LDA #FP_MATH_CTRL0_ADD | FP_ADD_IN0_MUX0 | FP_ADD_IN1_MUX1 | FP_CTRL0_CONV_0 | FP_CTRL0_CONV_1
                STA @lFP_MATH_CTRL0

                LDA #FP_OUT_ADD                             ; Set output to the ADDER
                STA @lFP_MATH_CTRL1

                ; Copy the integer to the coprocessor
                setal
                LDA #0                                      ; Set input0 := 0
                STA @lFP_MATH_INPUT0_LL
                STA @lFP_MATH_INPUT0_HL
                
                LDX #4                                   
shift           ASL ARGUMENT1                               ; Shift ARGUMENT1 by 4 bits to make room for fraction
                ROL ARGUMENT1+2
                DEX
                BNE shift

                setas
                LDA #0                                      ; Set INPUT1 (lower 12 bits are 0)
                STA @lFP_MATH_INPUT1_LL
                LDA ARGUMENT1                               ; Integer portion in upper 20 bits
                STA @lFP_MATH_INPUT1_LH
                LDA ARGUMENT1+1
                STA @lFP_MATH_INPUT1_HL
                LDA ARGUMENT1+2
                STA @lFP_MATH_INPUT1_HH
                
                ; Wait?
                NOP
                NOP
                NOP

                ; Check for FP errors
                LDA @lFP_MATH_CONV_STAT
                BEQ converted                   ; Skip checks if no bits set

                BIT #FP_CONV_STAT_NAN           ; Check for not-a-number
                BNE notanumber
                BIT #FP_CONV_STAT_OVF           ; Check for an overflow error
                BNE overflow
                BIT #FP_CONV_STAT_UDF           ; Check for an underflow error
                BNE underflow
                
                ; We shouldn't come this way, but if so the conversion is probably ok?

                ; Copy the result to ARGUMENT1
converted       setal
                LDA @lFP_MATH_OUTPUT_FP_LL
                STA ARGUMENT1
                LDA @lFP_MATH_OUTPUT_FP_HL
                STA ARGUMENT1+2
                setas
                LDA #TYPE_FLOAT
                STA ARGTYPE1

                PLP
                PLX
                RETURN
overflow        THROW ERR_OVERFLOW                          ; Nope: throw overflow error
underflow       THROW ERR_UNDERFLOW                         ; Throw and underflow error
notanumber      THROW ERR_NAN                               ; Throw a "not-a-number" error
                .pend

;
; Attempt to convert a floating point number to integer
;
; Inputs:
;   ARGUMENT1 = floating point number to convert
;
; Outputs:
;   ARGUMENT1 = integer (if possible)
;
FTOI            .proc
                PHX
                PHP

                ; Validate the input is a float
                CALL ASS_ARG1_FLOAT

                ; Set the operation to ADDER with input0 set to input, and input1 set to converter
                setas
                LDA #FP_MATH_CTRL0_ADD | FP_ADD_IN0_MUX0 | FP_ADD_IN1_MUX1 | FP_CTRL0_CONV_1
                STA @lFP_MATH_CTRL0

                LDA #FP_OUT_ADD                             ; Set output to the ADDER
                STA @lFP_MATH_CTRL1

                ; Set input0 to the float to convert
                setal
                LDA ARGUMENT1
                STA @lFP_MATH_INPUT0_LL
                LDA ARGUMENT1+2
                STA @lFP_MATH_INPUT0_HL

                ; Set input1 to 0
                LDA #0
                STA @lFP_MATH_INPUT1_LL
                STA @lFP_MATH_INPUT1_HL

                ; Wait
                NOP
                NOP
                NOP

                ; Check for errors
                setas
                LDA @lFP_MATH_CONV_STAT
                BEQ converted                   ; Skip checks if no bits set

                BIT #FP_CONV_STAT_NAN           ; Check for not-a-number
                BNE notanumber
                BIT #FP_CONV_STAT_OVF           ; Check for an overflow error
                BNE overflow
                BIT #FP_CONV_STAT_UDF           ; Check for an underflow error
                BNE underflow

                ; Put the result into ARGUMENT1
                setas
converted       LDA @lFP_MATH_OUTPUT_FIXED_LH   ; Only copy over the integer portion bits [31..12]
                STA ARGUMENT1
                LDA @lFP_MATH_OUTPUT_FIXED_HL
                STA ARGUMENT1+1
                LDA @lFP_MATH_OUTPUT_FIXED_HH
                STA ARGUMENT1+2

                LDX #4
shift           LDA ARGUMENT1+2
                ASL A
                ROR ARGUMENT1+2
                ROR ARGUMENT1+1
                ROR ARGUMENT1
                DEX
                BNE shift

                LDA ARGUMENT1+2
                BMI is_negative                 ; Set MSB to $00 or $FF based on the sign
                LDA #0                          ; Positive: set MSB := 0
                STA ARGUMENT1+3
                BRA set_type

is_negative     LDA #$FF                        ; Negative: set MSB := $FF
                STA ARGUMENT1+3

set_type        LDA #TYPE_INTEGER               ; Set the return type to INTEGER
                STA ARGTYPE1

                PLP
                PLX
                RETURN
overflow        THROW ERR_OVERFLOW                          ; Nope: throw overflow error
underflow       THROW ERR_UNDERFLOW                         ; Throw and underflow error
notanumber      THROW ERR_NAN                               ; Throw a "not-a-number" error
                .pend

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
                BNE _fp_add_error           ; If an issue was raise, process the math error

                setal
                LDA @lFP_MATH_OUTPUT_FP_LL  ; Retrieve the results into ARGUMENT1
                STA ARGUMENT1
                LDA @lFP_MATH_OUTPUT_FP_HL
                STA ARGUMENT1+2

_fp_add_done    PLP
                RETURN

_fp_add_error   CALL FP_ADD_ERROR           ; Jump to the handler for math error flags
                BRA _fp_add_done

;
; Handle any FP add/sub statuses
;
FP_ADD_ERROR    .proc
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

;
; Divide two floating point numbers
;
; Inputs:
;   ARGUMENT1 = a floating point number
;   ARGUMENT2 = a floating point number
;
; Outputs:
;   ARGUMENT1 := ARGUMENT1 / ARGUMENT2
;
OP_FP_DIV       PHP

                setas
                ; We will add two numbers in floating point format
                LDA #FP_MATH_CTRL0_ADD | FP_ADD_IN0_MULT | FP_ADD_IN1_MULT
                STA @lFP_MATH_CTRL0

                ; We will take the output from the multiplier
                LDA #FP_OUT_DIV
                BRA FP_MUL_DIV

;
; Multiply two floating point numbers
;
; Inputs:
;   ARGUMENT1 = a floating point number
;   ARGUMENT2 = a floating point number
;
; Outputs:
;   ARGUMENT1 := ARGUMENT1 * ARGUMENT2
;
OP_FP_MUL       PHP

                setas
                ; We will add two numbers in floating point format
                LDA #FP_MATH_CTRL0_ADD | FP_ADD_IN0_MULT | FP_ADD_IN1_MULT
                STA @lFP_MATH_CTRL0

                ; We will take the output from the multiplier
                LDA #FP_OUT_MULT
FP_MUL_DIV      STA @lFP_MATH_CTRL1

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
                LDA @lFP_MATH_MULT_STAT     ; Check the status of the multiplier
                AND #%00000111              ; Filter out the ZERO status
                BNE _fp_mul_error           ; If an issue was raise, process the math error

                setal
                LDA @lFP_MATH_OUTPUT_FP_LL  ; Retrieve the results into ARGUMENT1
                STA ARGUMENT1
                LDA @lFP_MATH_OUTPUT_FP_HL
                STA ARGUMENT1+2

_fp_mul_done    PLP
                RETURN

_fp_mul_error   CALL FP_MUL_ERROR           ; Jump to the handler for math error flags
                BRA _fp_mul_done

;
; Handle any FP multiply statuses
;
FP_MUL_ERROR    .proc
                BIT #FP_MULT_STAT_NAN       ; Is there a NaN condition?
                BEQ check_over              ; No: check for overflow
                THROW ERR_NAN               ; Yes: Throw NAN error

check_over      BIT #FP_MULT_STAT_OVF       ; Is ther an overflow condition?
                BEQ check_under             ; No: check for underflow
                THROW ERR_OVERFLOW          ; Yes: throw an overflow error

check_under     BIT #FP_MULT_STAT_UDF       ; Is there an underflow condition?
                BEQ done                    ; No: we should just return... this probably shouldn't happen
                THROW ERR_UNDERFLOW         ; Yes: throw an underflow error

done            RETURN
                .pend