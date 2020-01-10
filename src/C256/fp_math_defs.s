;;;
;;; Floating point math coprocessor definitions
;;;

; $AFE200..$AFE20F <- Registers

; Control register 0: MUX sources, Adder input sources, and add/subtract flag
FP_MATH_CTRL0 = $AFE200         ; Read/write
FP_MATH_CTRL0_ADD = $08         ; 0: Substraction - 1: Addition
FP_CTRL0_CONV_0 = %00000001     ; Input 0 should be converted from 24.12 fixed point to floating point
FP_CTRL0_CONV_1 = %00000010     ; Input 1 should be converted from 24.12 fixed point to floating point

; Options for the source of the adder's input #0
FP_ADD_IN0_MUX0 = %00000000     ; Adder input #0 is the output of MUX0
FP_ADD_IN0_MUX1 = %00010000     ; Adder input #0 is the output of MUX1
FP_ADD_IN0_MULT = %00100000     ; Adder input #0 is the output of the multiplier
FP_ADD_IN0_DIV  = %00110000     ; Adder input #0 is the output of the divider

; Options for the source of the adder's input #1
FP_ADD_IN1_MUX0 = %00000000     ; Adder input #1 is the output of MUX0
FP_ADD_IN1_MUX1 = %01000000     ; Adder input #1 is the output of MUX1
FP_ADD_IN1_MULT = %10000000     ; Adder input #1 is the output of the multiplier
FP_ADD_IN1_DIV  = %11000000     ; Adder input #1 is the output of the divider

; Control register 1: Source of the output data
FP_MATH_CTRL1 = $AFE201

; Output MUX control
FP_OUT_MULT = %00000000         ; Output is from the multiplier
FP_OUT_DIV  = %00000001         ; Output is from the divider
FP_OUT_ADD  = %00000010         ; Output is from the adder/subtracter
FP_OUT_ONE  = %00000011         ; Output is the constant '1.0'

FP_MATH_CTRL2 = $AFE202         ; Not Used - Reserved
FP_MATH_CTRL3 = $AFE203         ; Not Used - Reserved

;
; Read only status registers
;

FP_MATH_MULT_STAT = $AFE204     ; Status of the multiplier
FP_MULT_STAT_NAN  = $01         ; (NAN) Not a Number Status
FP_MULT_STAT_OVF  = $02         ; Overflow
FP_MULT_STAT_UDF  = $04         ; Underflow
FP_MULT_STAT_ZERO = $08         ; Zero

FP_MATH_DIV_STAT  = $AFE205     ; Status of the divider
FP_DIV_STAT_NAN       = $01     ; Not a number Status
FP_DIV_STAT_OVF       = $02     ; Overflow
FP_DIV_STAT_UDF       = $04     ; Underflow
FP_DIV_STAT_ZERO      = $08     ; Zero
FP_DIV_STAT_DIVBYZERO = $10     ; Division by Zero

FP_MATH_ADD_STAT  = $AFE206     ; Status of the adder/subtracter
FP_ADD_STAT_NAN  = $01          ; Not a number Status
FP_ADD_STAT_OVF  = $02          ; Overflow
FP_ADD_STAT_UDF  = $04          ; Underflow
FP_ADD_STAT_ZERO = $08          ; Zero

FP_MATH_CONV_STAT = $AFE207     ; Status of the fixed <=> float converters
FP_CONV_STAT_NAN  = $01         ; Not a number Status
FP_CONV_STAT_OVF  = $02         ; Overflow
FP_CONV_STAT_UDF  = $04         ; Underflow

;
; Read/write data input and output registers
;

; Write Input0 (either FP or Fixed (20.12)) - See MUX Setting
FP_MATH_INPUT0_LL = $AFE208
FP_MATH_INPUT0_LH = $AFE209
FP_MATH_INPUT0_HL = $AFE20A
FP_MATH_INPUT0_HH = $AFE20B

; Write Input1 (either FP or Fixed (20.12)) - See MUX Setting
FP_MATH_INPUT1_LL = $AFE20C
FP_MATH_INPUT1_LH = $AFE20D
FP_MATH_INPUT1_HL = $AFE20E
FP_MATH_INPUT1_HH = $AFE20F

; Read Output
FP_MATH_OUTPUT_FP_LL = $AFE208
FP_MATH_OUTPUT_FP_LH = $AFE209
FP_MATH_OUTPUT_FP_HL = $AFE20A
FP_MATH_OUTPUT_FP_HH = $AFE20B

; Read FIXED Output (20.12) Format
FP_MATH_OUTPUT_FIXED_LL = $AFE20C
FP_MATH_OUTPUT_FIXED_LH = $AFE20D
FP_MATH_OUTPUT_FIXED_HL = $AFE20E
FP_MATH_OUTPUT_FIXED_HH = $AFE20F

;DATAA[]  DATAB[]   SIGN BIT  RESULT[]  Overflow Underflow Zero NaN
;Normal   Normal    0         Zero      0       0           1   0
;Normal   Normal    0/1       Normal    0       0           0   0
;Normal   Normal    0/1       Denormal  0       1           1   0
;Normal   Normal    0/1       Infinity  1       0           0   0
;Normal   Denormal  0/1       Normal    0       0           0   0
;Normal   Zero      0/1       Normal    0       0           0   0
;Normal   Infinity  0/1       Infinity  1       0           0   0
;Normal   NaN       X         NaN       0       0           0   1
;Denormal Normal    0/1       Normal    0       0           0   0
;Denormal Denormal  0/1       Normal    0       0           0   0
;Denormal Zero      0/1       Zero      0       0           1   0
;Denormal Infinity  0/1       Infinity  1       0           0   0
;Denormal NaN       X         NaN       0       0           0   1
;Zero     Normal    0/1       Normal    0       0           0   0
;Zero     Denormal  0/1       Zero      0       0           1   0
;Zero     Zero      0/1       Zero      0       0           1   0
;Zero     Infinity  0/1       Infinity  1       0           0   0
;Zero     NaN       X         NaN       0       0           0   1
;Infinity Normal    0/1       Infinity  1       0           0   0
;Infinity Denormal  0/1       Infinity  1       0           0   0
;Infinity Zero      0/1       Infinity  1       0           0   0
;Infinity Infinity  0/1       Infinity  1       0           0   0
;Infinity NaN       X         NaN       0       0           0   1
;NaN      Normal    X         NaN       0       0           0   1
;NaN      Denormal  X         NaN       0       0           0   1
;NaN      Zero      X         NaN       0       0           0   1
;NaN      Infinity  X         NaN       0       0           0   1
;NaN      NaN       X         NaN       0       0           0   1
