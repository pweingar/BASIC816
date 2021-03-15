;;;
;;; Implement floating point numbers for the 65816
;;;
;;; Representation:
;;;
;;;  7 MSB  0 7      0 7      0 7  LSB  0
;;; +--------+--------+--------+---------+
;;; |SEEEEEEE|EMMMMMMM|MMMMMMMM|MMMMMMMMM|
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

.include "C256/floats.s"

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
                AND #$7FFF              ; Mask off the sign bit
                BNE return_false

return_true     PLP
                SEC
                RETURN

return_false    PLP
                CLC
                RETURN
                .pend

;
; Shift the decimal digit in A onto ARGUMENT1
SHIFTDEC        .proc
                PHP

                setas
                SEC                     ; Convert '0'..'9' to it's number
                SBC #'0'

                CALL MULINT10           ; ARGUMENT1 *= 10

                setal
                AND #$00FF              ; Add the number to ARGUMENT1
                CLC
                ADC ARGUMENT1
                STA ARGUMENT1
                LDA ARGUMENT1+2
                ADC #0
                STA ARGUMENT1+2

                PLP
                RETURN
                .pend

;
; Shift the hexadecimal digit in the accumulator onto ARGUMENT1
;
SHIFTHEX        .proc
                PHP

                setas

                CMP #'0'                ; Process 0-9
                BLT not_09
                CMP #'9'+1
                BLT is_09

not_09          CMP #'a'                ; Process lowercase A-F
                BLT not_lc
                CMP #'f'+1
                BLT is_lc

not_lc          CMP #'A'                ; Process uppercase A-F
                BLT not_uc
                CMP #'F'+1
                BLT is_uc

not_uc          BRA done                ; Just return if we couldn't convert... this shouldn't happen

is_lc           SEC                     ; Convert 'a'-'f' to the actual number
                SBC #'a'-10
                BRA shift

is_uc           SEC                     ; Convert 'A'-'F' to the actual number
                SBC #'A'-10
                BRA shift

is_09           SEC                     ; Convert '0'-'9' to the actual number
                SBC #'0'

shift           .rept 4
                ASL ARGUMENT1           ; ARGUMENT1 *= 16
                ROL ARGUMENT1+1
                ROL ARGUMENT1+2
                ROL ARGUMENT1+3
                .next

                ORA ARGUMENT1           ; Add the number to it
                STA ARGUMENT1

done            PLP
                RETURN
                .pend

;
; Shift a binary digit in A onto ARGUMENT1
;
SHIFTBIN        .proc
                PHP

                setas
                CMP #'0'                ; If the character is '0'...
                BEQ shift_0             ; Shift a 0 onto ARGUMENT1
                CMP #'1'                ; If the character is '1'...
                BEQ shift_1             ; Shift a 1 onto ARGUMENT1

                BRA done

shift_0         setal                   ; Shift a 0 onto ARGUMENT1
                ASL ARGUMENT1
                ROL ARGUMENT1+2
                BRA done

shift_1         setal                   ; Shift a 1 onto ARGUMENT1
                SEC
                ROL ARGUMENT1
                ROL ARGUMENT1+2

done            PLP
                RETURN
                .pend

;
; Calculate the floating point 10^x
;
; Inputs:
;   MARG4 = the power to raise (or lower!) 10.0 [0..127]
;   MARG6 = whether or not the exponent should be negative
;
; Outputs:
;   ARGUMENT1 = 10.0 ^ MARG4
;
FP_POW10        .proc
                PHP

                setaxs
                LDA MARG4
                BEQ return_1
                TAX

                LDA MARG6
                BNE do_div

                ; Repeatedly multiply 10.0

                LDA #FP_OUT_MULT                    ; We'll multiply
                STA @l FP_MATH_CTRL1
                BRA start_loop

return_1        setas
                LDA #FP_OUT_ONE                     ; We want to return a 1.0
                STA @l FP_MATH_CTRL1

                NOP
                NOP
                NOP

                BRA ret_result                      ; And return the result

do_div          ; Repeatedly divide by 10.0

                setas
                LDA #FP_OUT_DIV                     ; We'll divide
                STA @l FP_MATH_CTRL1

start_loop      setas
                LDA #FP_ADD_IN0_MUX0 | FP_ADD_IN1_MUX1 | FP_CTRL0_CONV_0 | FP_CTRL0_CONV_1
                STA @l FP_MATH_CTRL0                ; Used fixed point inputs

                setal
                LDA #$1000                          ; Input 0 = 1.0
                STA @l FP_MATH_INPUT0_LL
                LDA #0
                STA @l FP_MATH_INPUT0_HL

loop            setal
                LDA #$A000                          ; Input 1 = 10.0
                STA @l FP_MATH_INPUT1_LL
                LDA #0
                STA @l FP_MATH_INPUT1_HL

                NOP                                 ; Wait for the operation to complete
                NOP
                NOP

                DEX                                 ; Count down
                BEQ ret_result                      ; If 0, then we're done

                LDA @l FP_MATH_OUTPUT_FP_LL         ; SCRATCH <-- Result
                STA @l SCRATCH
                LDA @l FP_MATH_OUTPUT_FP_HL
                STA @l SCRATCH+2

                setas
                LDA #FP_ADD_IN0_MUX0 | FP_ADD_IN1_MUX1 | FP_CTRL0_CONV_1
                STA @l FP_MATH_CTRL0                ; Used fixed point inputs

                setal
                LDA @l SCRATCH                      ; Input 0 <-- SCRATCH
                STA @l FP_MATH_INPUT0_LL
                LDA @l SCRATCH+2
                STA @l FP_MATH_INPUT0_HL

                BRA loop
 
ret_result      setal
                LDA @l FP_MATH_OUTPUT_FP_LL         ; Return the result
                STA ARGUMENT1
                LDA FP_MATH_OUTPUT_FP_HL
                STA ARGUMENT1+2

                setas
                LDA #TYPE_FLOAT
                STA ARGTYPE1

done            PLP
                RETURN
                .pend

;
; Take the mantissa and exponent, and pack it into a float
;
; Inputs:
;   MARG1 = the integer portion of the mantissa (as a floating point number)
;   MARG2 = the fractional portion of the mantissa (as a floating point number)
;   MARG3 = the fractional divisor (10, 100, 1000, etc.... as an integer)
;   MARG4 = the exponent of the floating point number (as a single byte)
;
; Outputs:
;   ARGUMENT1 = the resulting floating point number
;
PACKFLOAT       .proc
                PHP

                MOVE_D ARGUMENT1,MARG3          ; Convert the divisor to a float
                CALL ITOF
                MOVE_D ARGUMENT2,ARGUMENT1
                MOVE_D ARGUMENT1,MARG2
                CALL OP_FP_DIV                  ; Divide fractional nominator part by its divisor

                MOVE_D ARGUMENT2,MARG1          ; Get the integer part of the mantissa
                CALL OP_FP_ADD                  ; Add it to the fractional part

                MOVE_D ARGUMENT2,ARGUMENT1      ; Save the number so far in ARGUMENT2
                CALL FP_POW10                   ; Compute the float to represent the exponent
                CALL OP_FP_MUL                  ; And apply it to the number so far...

                setal
                LDA MARG5                       ; Check to see if the float should be negative
                BEQ set_float_type              ; If not, just set the type

                LDA ARGUMENT1+2                 ; If so, set the sign bit
                ORA #$8000
                STA ARGUMENT1+2

set_float_type  setas
                LDA #TYPE_FLOAT                 ; Set the type to float... ready for returning!
                STA ARGTYPE1

                PLP
                RETURN
                .pend

;
; Parse a general number. This routine parses integers and floats
; Integers may be specified in binary, decimal, or hexadecimal format.
; Floats must be in decimal, include a dot and may have an optional exponent.
;
; Examples:
;   &h12ab - hex integer
;   -&b1101 - binary integer
;   123 - decimal integer
;   +3.14 - floating point
;   1.234e5 - floating point
;
; Inputs:
;   BIP = pointer to the first character of the number
;
; Outputs:
;   ARGUMENT1 = the value of the number
;   ARGTYPE1 = the type of the number (TYPE_INTEGER, TYPE_FLOAT)
;   BIP = pointer to the next character after the number
;
PARSENUM        .proc
                PHY
                PHP

                TRACE "PARSENUM"

                setaxl
                STZ ARGUMENT1       ; This will be the accumulator for building the number
                STZ ARGUMENT1+2
                STZ MARG1           ; This will be the integer portion of the mantissa for floats
                STZ MARG1+2
                STZ MARG5           ; MARG5 will be the negative flag for the number
                STZ MARG2           ; This will be the denominator of the fractional part of the mantissa
                STZ MARG2+2
                LDA #1
                STA MARG3           ; This will be the divisor of the fractional part of the mantissa
                STZ MARG3+2
                STZ MARG4           ; This will be the exponent of a float
                STZ MARG4+2
                STZ MARG6           ; MARG6 will be the negative flag for the exponent

s0              setas
                LDY #0
                LDA [BIP],Y         ; Get the first byte
                CMP #'+'
                BEQ s1_drop         ; '+' --> S1, drop
                CMP #'-'
                BEQ s1_negative     ; Flag that the number is negative
                CMP #'&'
                BEQ s2_drop         ; '&' --> S2, drop
                CALL ISNUMERAL
                BCC syntax_err
                BRL s7_shift        ; '0'-'9' --> S7, emit

syntax_err      THROW ERR_SYNTAX    ; Anything else: throw a syntax error

s1_negative     LDA #1              ; Set the negative flag for the mantissa
                STA MARG5

s1_drop         INY                 ; Drop the character...
                LDA [BIP],Y         ; Get the next
                CMP #'&'
                BEQ s2_drop         ; '&' --> S2, drop the '&'
                CALL ISNUMERAL
                BCC syntax_err     
                BRL s7_shift        ; '0'-'9' --> S7, shift

s2_drop         INY                 ; Drop the character
                LDA [BIP],Y         ; Get the next character
                CMP #'h'
                BEQ s3_drop         ; 'h', 'H' --> S3, drop
                CMP #'H'
                BEQ s3_drop
                CMP #'b'
                BEQ s5_drop         ; 'b', 'B' --> S5, drop
                CMP #'B'
                BEQ s5_drop
                BRA syntax_err

s3_drop         INY                 ; Drop the character
s3              LDA [BIP],Y         ; Get the next character
                CALL ISHEX          ; '0'-'9','A'-'F' --> S4, shift
                BCS s4_shift
                BRA syntax_err

s4_shift        CALL SHIFTHEX       ; Shift the hex digit in A onto ARGUMENT1
                INY
                LDA [BIP],Y         ; Get the next character
                CALL ISHEX
                BCS s4_shift        ; '0'-'9','A'-'F' --> S4, shift
                
ret_integer     setas
                LDA MARG5           ; check if the number should be negative
                BEQ set_int_type    ; If not, just set the type and return

                setal
                SEC                 ; If so, negate it
                LDA #0
                SBC ARGUMENT1
                STA ARGUMENT1
                LDA #0
                SBC ARGUMENT1+2
                STA ARGUMENT1+2

set_int_type    setas
                LDA #TYPE_INTEGER   ; Return an integer
                STA ARGTYPE1

stop            setal
                CLC
                TYA
                ADC BIP
                STA BIP
                LDA BIP+2
                ADC #0
                STA BIP+2
                setas
                
                PLP
                PLY
                RETURN

s5_drop         INY                     ; Drop the character
s5              LDA [BIP],Y             ; Get the next character
                CMP #'0'
                BEQ s6_shift            ; '0', '1' --> S6, shift
                CMP #'1'
                BEQ s6_shift
                BRL syntax_err

s6_shift        CALL SHIFTBIN           ; Shift the binary digit onto ARGUMENT1
                INY
                LDA [BIP],Y             ; Get the next character
                CMP #'0'                ; '0', '1' --> S6, shift
                BEQ s6_shift
                CMP #'1'
                BEQ s6_shift
                BRL ret_integer         ; Return integer

s7_shift        CALL SHIFTDEC           ; Shift the decimal digit onto ARGUMENT1
                INY
                LDA [BIP],Y             ; Get the next character
                CMP #'.'                ; '.' --> S8, drop and preserve mantissa
                BEQ s8_mantissa
                CALL ISNUMERAL          ; '0'-'9' --> S7, shift
                BCS s7_shift        
                BRL ret_integer         ; Return integer

s8_mantissa     ; Save the integer part of the mantissa and move to S8
                setal
                CALL ITOF               ; Convert the integer part of the mantissa to a simple float
                MOVE_D MARG1,ARGUMENT1  ; Save the integer part of the mantissa in MARG1
                STZ ARGUMENT1           ; ARGUMENT1 <-- 0, will be the decimal
                STZ ARGUMENT1+2
                setas
                BRA s8_drop

s8_shift        CALL SHIFTDEC           ; Shift the decimal digit onto ARGUMENT1

; multiply MARG3 (the divisor of the fractional part)... by 10
                setal
                LDA MARG3+2             ; high 16 bits
                STA @l M0_OPERAND_A
                LDA #10                 ; Multiply it by 10
                STA @l M0_OPERAND_B
                LDA @l M0_RESULT        ; And save it back to high 16 bits of MARG3
                STA MARG3+2

                LDA MARG3
                STA @l M0_OPERAND_A

                LDA #10                 ; Multiply it by 10
                STA @l M0_OPERAND_B
                
                LDA @l M0_RESULT        ; And save it back to MARG3
                STA MARG3
                LDA @l M0_RESULT+2
                CLC
                ADC MARG3+2
                STA MARG3+2
                setas

s8_drop         INY
                LDA [BIP],Y
                CMP #'e'                ; 'E' --> S9, drop
                BEQ s9_drop
                CMP #'E'
                BEQ s9_drop
                CALL ISNUMERAL          ; '0'-'9' --> S8, shift
                BCS s8_shift

                setal
                CALL ITOF               ; Convert the fractional part of the mantissa to a simple float
                MOVE_D MARG2,ARGUMENT1  ; Save decimal portion in MARG2
                STZ ARGUMENT1           ; ARGUMENT1 <-- 0, will be the exponent
                STZ ARGUMENT1+2
                CALL PACKFLOAT          ; Pack MARG1, MARG2, MARG3, and MARG4 into a float
                setas
                BRL stop

s9_drop         setal
                CALL ITOF               ; Convert the fractional part of the mantissa to a simple float
                MOVE_D MARG2,ARGUMENT1  ; Save decimal portion in MARG2
                STZ ARGUMENT1           ; ARGUMENT1 <-- 0, will be the exponent
                STZ ARGUMENT1+2
                setas

                INY
                LDA [BIP],Y             ; Get the next character
                CMP #'+'
                BEQ s10_drop            ; '+' --> S10, drop
                CMP #'-'
                BEQ s10_setneg          ; '-' --> S10, set exponent is negative
                CALL ISNUMERAL
                BCS S11_shift           ; '0'-'9' --> S11, shift
                BRL syntax_err

s10_setneg      LDA #1                  ; Set that the exponent should be negative
                STA MARG6

s10_drop        INY
                LDA [BIP],Y             ; Get the next character
                CALL ISNUMERAL          ; '0'-'9' --> S11, shift
                BCS s11_shift
                BRL syntax_err

s11_shift       CALL SHIFTDEC           ; Shift the decimal digit onto ARGUMENT1
                INY
                LDA [BIP],Y             ; Get the next character
                CALL ISNUMERAL          ; '0'-'9' --> S11, shift
                BCS s11_shift

                MOVE_D MARG4,ARGUMENT1  ; Save the exponent for packing
                CALL PACKFLOAT          ; Pack MARG1, MARG2, MARG3, and MARG4 into a float
                BRL stop

                .pend

ITOF            .proc
                PHP
                TRACE "ITOF"

.if SYSTEM = SYSTEM_C256
                CALL FIXINT_TO_FP       ; Use the C256 math coprocessor
.else
                ;
                ; Code for when there is no C256 math coprocessor
                ;

                setas
; exponent = 2                            ; local: byte _exponent = 127
                LDA #127+23
                STA SCRATCH             ; SCRATCH is the exponent

; negative = 1                            ; local: byte _negative = 0
                LDA #0
                STA SCRATCH+1           ; SCRATCH + 1 is the negative flag

                setaxl
                LDA ARGUMENT1           ; Check to see if the input is 0
                BNE non_zero
                LDA ARGUMENT1+2
                BNE non_zero

                setas
                LDA #TYPE_FLOAT         ; If so, just set the type to float
                STA ARGTYPE1
                BRL done

non_zero        LDA ARGUMENT1+2
                BPL is_positive         ; Check if the number is negative

                ; If negative, we need to convert it to positive and set the negative flag

                setal
                SEC                     ; ARGUMENT1 <-- ABS(ARGUMENT1)
                LDA #0
                SBC ARGUMENT1
                STA ARGUMENT1
                LDA #0
                SBC ARGUMENT1+2
                STA ARGUMENT1+2

                setas
                LDA #$80                ; _negative = true
                STA SCRATCH+1

is_positive     setal
                LDA ARGUMENT1+2         ; Check the high bits
                AND #$FF80
                BEQ shift_left          ; If zero... we need to shift the bits left
                CMP #$0080              ; Is the most significant 1 in the 1's digit?
                BEQ pack_fp             ; Yes: pack the FP up for return

shift_right     LSR ARGUMENT1+2         ; Shift the integer right one bit
                ROR ARGUMENT1

                setas          
                INC SCRATCH             ; exponent = exponent + 1
                setal

                LDA ARGUMENT1+2         ; Check to see if the most significant 1 is
                AND #$FF80              ; Now in the 1's position
                CMP #$0080
                BNE shift_right         ; If not, keep shifting right
                BRL pack_fp             ; If so, pack the floating point number

shift_left      ASL ARGUMENT1           ; Shift the integer left one bit
                ROL ARGUMENT1+2

                setas          
                DEC SCRATCH             ; exponent = exponent - 1
                setal

                LDA ARGUMENT1+2         ; Check to see if the most significant 1 is
                AND #$FF80              ; Now in the 1's position
                CMP #$0080
                BNE shift_left          ; If not, keep shifting

pack_fp         setas
                LDA ARGUMENT1+2         ; Clear a spot for the LSB of the exponent
                AND #$7F
                STA ARGUMENT1+2

                LDA SCRATCH             ; Set the exponent and sign
                LSR A
                ORA SCRATCH+1
                STA ARGUMENT1+3

                LDA #0                  ; Set the LSB of the exponent
                ROR A
                ORA ARGUMENT1+2
                STA ARGUMENT1+2

                LDA #TYPE_FLOAT         ; Set the type to float
                STA ARGTYPE1
.endif

done            TRACE "/ITOF"
                PLP
                RETURN
                .pend

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

not_zero        setal

.if SYSTEM = SYSTEM_C256
                CALL FP_TO_FIXINT
.else
                ; Has a number... so start shifting it into SCRATCH
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
.endif
done            RETURN
                .pend

;
; Compare two floating point numbers in ARGUMENT1 and ARGUMENT2
;
; Inputs:
;   ARGUMENT1 = floating point number
;   ARGUMENT2 = floating point number
;
; Outputs:
;   A = 0 if ARGUMENT1 = ARGUMENT2
;   A = -1 if ARGUMENT1 < ARGUMENT2
;   A = 1 if ARGUMENT1 > ARGUMENT2
;
FP_COMPARE      .proc
                PHX
                PHP

                setal
                LDA ARGUMENT1+2             ; Save ARGUMENT1 so we don't destroy it
                PHA
                LDA ARGUMENT1
                PHA

                CALL OP_FP_SUB              ; Subtract ARGUMENT2 from ARGUMENT1
                CALL FARG1EQ0               ; Check to see if they're equal
                BCS are_equal

                LDA ARGUMENT1+2             ; Check the high word
                BIT #$8000
                BNE is_lt                   ; ARGUMENT1 < ARGUMENT2

is_gt           LDA #1                      ; ARGUMENT1 > ARGUMENT2: return 1
                BRA ret_result

is_lt           LDA #$FFFF                  ; ARGUMENT1 > ARGUMENT2: return -1
                BRA ret_result

are_equal       LDA #0                      ; Equal: return 0

ret_result      PLX                         ; Restore ARGUMENT1
                STX ARGUMENT1
                PLX
                STX ARGUMENT1+2 

                PLP
                PLX
                RETURN
                .pend

; Compare two floating point numbers and return true if ARGUMENT1 < ARGUMENT2
OP_FP_LT        .proc
                PHP
                TRACE "OP_FP_LT"

                setaxl
                CALL FP_COMPARE
                CMP #$FFFF
                BNE ret_false

                CALL SET_TRUE
                BRA done

ret_false       CALL SET_FALSE

done            PLP
                RETURN
                .pend

; Compare two floating point numbers and return true if ARGUMENT1 > ARGUMENT2
OP_FP_GT        .proc
                PHP
                TRACE "OP_FP_GT"

                setaxl
                CALL FP_COMPARE
                CMP #1
                BNE ret_false

                CALL SET_TRUE
                BRA done

ret_false       CALL SET_FALSE

done            PLP
                RETURN
                .pend

; Compare two floating point numbers and return true if ARGUMENT1 = ARGUMENT2
OP_FP_EQ        .proc
                PHP
                TRACE "OP_FP_EQ"

                setaxl
                CALL FP_COMPARE
                CMP #0
                BNE ret_false

                CALL SET_TRUE
                BRA done

ret_false       CALL SET_FALSE

done            PLP
                RETURN
                .pend

; Compare two floating point numbers and return true if ARGUMENT1 <= ARGUMENT2
OP_FP_LTE       .proc
                PHP
                TRACE "OP_FP_LTE"

                setaxl
                CALL FP_COMPARE
                CMP #1
                BEQ ret_false

                CALL SET_TRUE
                BRA done

ret_false       CALL SET_FALSE

done            PLP
                RETURN
                .pend

; Compare two floating point numbers and return true if ARGUMENT1 >= ARGUMENT2
OP_FP_GTE       .proc
                PHP
                TRACE "OP_FP_GTE"

                setaxl
                CALL FP_COMPARE
                CMP #$FFFF
                BEQ ret_false

                CALL SET_TRUE
                BRA done

ret_false       CALL SET_FALSE

done            PLP
                RETURN
                .pend

; Compare two floating point numbers and return true if ARGUMENT1 != ARGUMENT2
OP_FP_NE        .proc
                PHP
                TRACE "OP_FP_NE"

                setaxl
                CALL FP_COMPARE
                CMP #0
                BEQ ret_false

                CALL SET_TRUE
                BRA done

ret_false       CALL SET_FALSE

done            PLP
                RETURN
                .pend

;
; Add the character in A to the next position in a temporary string
;
; Inputs:
;   ARGUMENT1 = pointer to the string to append to
;   A = the character to append
;   Y = index to the NULL byte terminating the string
;
STREMIT         .proc
                PHP

                TRACE "STREMIT"

                setas
                STA [ARGUMENT1],Y           ; Append the character
                INY                         ; Advance the character pointer in Y
                LDA #0                      ; And add the NULL
                STA [ARGUMENT1],Y

                PLP
                RETURN
                .pend

;
; Emit the signed byte in the accumulator
;
; Inputs:
;   ARGUMENT1 = the string to append to
;   Y = the index of the end of the string
;   A = the byte to convert and add
;
STREMITB        .proc
                PHX
                PHP

                TRACE "STREMITB"
                
                setas
                CMP #$80
                BLT emit_digits

                PHA
                LDA #'-'                    ; Print a minus sign
                CALL STREMIT
                PLA

                EOR #$FF                    ; And negate it
                INC A

emit_digits     setaxl
                AND #$00FF
                CMP #100
                BLT chk_tens

                ; Has a hundreds digit... divide by 100 to get it
                LDX #100
                CALL UINT_DIV_A_X           ; A = A / 100
                
                CLC
                ADC #'0'                    ; Convert to ASCII
                CALL STREMIT                ; Add it to the string..

                TXA                         ; Put the remainder in A

chk_tens        ; Has a tens digit... divide by 10 to get it
                LDX #10
                CALL UINT_DIV_A_X           ; A = A / 10

                CLC
                ADC #'0'                    ; Convert to ASCII
                CALL STREMIT                ; Add it to the string..

                TXA                         ; Put the remainder in A

ones_digit      ; Emit the ones digit
                CLC
                ADC #'0'                    ; Convert it to ASCII
                CALL STREMIT                ; Add it to the string..        

                PLP
                PLX
                RETURN
                .pend

;
; Find the end of the string
;
; Inputs:
;   ARGUMENT1 = pointer to the string
;
; Outputs:
;   Y = index to the NULL byte terminating the string
;
STRFINDEND      .proc
                PHP

                TRACE "STRFINDEND"

                setas
                setxl
                LDY #0
find_end        LDA [ARGUMENT1],Y           ; Scan to the end of the string
                BEQ done
                INY
                BRA find_end

done            PLP
                RETURN
                .pend

FP_D = 6        ; Number of mantissa digits

;
; Convert a floating point number to a string
;
; Inputs:
;   ARGUMENT1 = the floating point number to convert
;
; Outputs:
;   ARGUMENT1 = pointer to the ASCIIZ string representing that number
;
FTOS            .proc
                PHP

                TRACE "FTOS"

                setas
                setxl

                PEA #0                      ; This spot on the stack will be the negative flag
                PEA #0                      ; This spot on the stack will be K
                PEA #0                      ; This spot will be for the exponents

                .virtual #1,S
L_NEGATIVE      .word ?
L_K             .word ?
L_X1            .byte ?                     ; The binary exponent
L_EXP           .byte ?                     ; The decimal exponent
                .endv
 
                CALL FARG1EQ0               ; If N is zero, output a space, a zero and end.
                BCC chk_negative

                TRACE "is_zero"
                
                CALL TEMPSTRING

                setas
                LDY #0
                LDA #' '
                STA [STRPTR],Y
                INY
                LDA #'0'                    ; Return a "0"
                STA [STRPTR],Y
                INY
                LDA #0
                STA [STRPTR],Y
                BRL ret_result

chk_negative    setas
                LDA ARGUMENT1+3             ; If N is negative, output a minus sign and negate N
                BPL not_negative

                AND #$7F                    ; Negate the number
                STA ARGUMENT1+3

                LDA #1
                STA L_NEGATIVE              ; Set IsNegative to a TRUE value

not_negative    setal
                LDA #0                      ; Initialize K to 0, K is a 1-byte signed integer. (SCRATCH is K)
                STA L_K                     ; We're using a word here for convenience

                MOVE_D ARGUMENT2, ten_d_1   ; Compare N to 10^(D-1)
                CALL FP_COMPARE

                BIT #$8000                  ; Is N < 10^(D-1)?
                BNE shift_up            

shift_down      TRACE "shift_down"
                ; If N >= 10 ^ D, then divide by 10 until N < 10 ^ D, and increment K each time you divide by 10.
                CALL FP_DIV10

                LDA L_K
                INC A
                STA L_K                     ; Increment K

                CALL FP_COMPARE
                CMP #0                      ; Is N < 10^(D-1)?
                BGE shift_down              ; No: keep dividing
                BRL do_digits               ; Yes: we're ready to process digits
                
shift_up        TRACE "shift_up"
                ; If N < 10 ^ (D-1), then multiply N by 10 until N >= 10 ^ (D-1), and decrement K each time you multiply by 10.
                CALL FP_MUL10

                LDA L_K
                DEC A
                STA L_K                     ; Decrement K

                CALL FP_COMPARE
                CMP #$FFFF                  ; Is N >= 10 ^ (D-1)?
                BEQ shift_up                ; No: keep multiplying

do_digits       TRACE "do_digits"

                ; Unpack the exponent into X1
                setaxs
                LDA ARGUMENT1+2
                ASL A
                LDA ARGUMENT1+3
                ROL A
                STA L_X1

                ; With N in FP1 (i.e. the mantissa in FP1 and the exponent in X1) shift M1 right (150-X1) times. Now M1 contains
                ; a 3-byte (unsigned) integer (M1+0 is the high byte, M1+2 is the low byte), and 10 ^ (D-1) <= M1 <= 10 ^ D.
                SEC
                LDA #150                    ; X := 150 - X1
                SBC L_X1
                TAX
                BEQ emit_digits             ; If X = 0, just emit the digits

                LDA ARGUMENT1+2             ; Set the implied '1' MSB of the mantissa
                ORA #$80
                STA ARGUMENT1+2

shift_r         LSR ARGUMENT1+2             ; Shift the mantissa right
                ROR ARGUMENT1+1
                ROR ARGUMENT1
                DEX
                BNE shift_r                 ; Until X = 0

emit_digits     ; output the integer in M1, but put a decimal point between the first and second digit, then output "E", then the
                ; signed intger K+D-1.

                setxl
                setas
                STZ ARGUMENT1+3             ; Blank out the MSB
                LDA #TYPE_INTEGER           ; Make it an integer
                STA ARGTYPE1

                LDA L_NEGATIVE              ; Check IsNegative
                BEQ get_raw_digits          ; If FALSE, just convert the raw digits

                setal
                SEC                         ; Make the raw integer negative
                LDA #0
                SBC ARGUMENT1
                STA ARGUMENT1
                LDA #0
                SBC ARGUMENT1+2
                STA ARGUMENT1+2

get_raw_digits  CALL ITOS                   ; Convert the integer to a string (in ARGUMENT1)
                MOVE_D ARGUMENT1,STRPTR

                ; Make room for the decimal point...
                CALL STRFINDEND

                setas

                INY                         ; Move the NULL up one byte
                LDA #0
                STA [ARGUMENT1],Y

insert_loop     DEY                         ; Move to the character before the one we just moved
                DEY
                LDA [ARGUMENT1],Y           ; Get the character
                INY                         ; Move to the next space
                STA [ARGUMENT1],Y           ; Store the character here
                CPY #2                      ; Check to see if we just moved the 2nd character
                BNE insert_loop             ; If not, keep moving the characters

                LDA #'.'                    ; Insert the '.' in the space we openned
                STA [ARGUMENT1],Y

                setas
                CLC                         ; Compute the exponent
                LDA L_K
                ADC #(FP_D - 1)
                STA L_EXP
                BEQ done                    ; If it's 0, just return the number

                CALL STRFINDEND             ; Move to the end of the string
                LDA #'E'                    ; Append the "E"
                CALL STREMIT

                LDA L_EXP
                CALL STREMITB               ; Append the exponent to the string

                BRA done                    ; TODO: reformat integer... add E and exponent...

                ; Alternate (without exponent)

                ; 7. If K < 1-D, output a decimal point, then output -K-D zeros, then the integer M1.
                ; 8. If 1-D <= K < 0, output the integer M1, but put a decimal point between the (K+D)th digit and the (K+D+1)th digit.
                ; 9. If K >= 0, output the integer M1, followed by K zeros. 

ret_result      TRACE "ret_result"
                setal
                LDA STRPTR                  ; Return the temporary string we've assembled
                STA ARGUMENT1
                LDA STRPTR+2
                STA ARGUMENT1+2

done            setas
                LDA #TYPE_STRING
                STA ARGTYPE1

                setal
                TSC                         ; Remove the locals from the stack
                CLC
                ADC #6
                TCS
                PLP
                RETURN

ten_d_1         .dword $47c35000            ; 10^(FP_D-1), where FP_D=5
                .pend

;
; Evaluate a polynomial of the form: a_n*x^n + ... + a_2*x^2 + a_1*x + a_0
;
; This routine uses Horner's method to calculate the result of the polynomial
; https://en.wikipedia.org/wiki/Horner%27s_method
;
; Inputs:
;   ARGUMENT1 = the floating point "x" value for the polynomial
;   MTEMPPTR = a pointer to the list of coeffients a_n ... a_0, four bytes each
;   MCOUNT = the number of coefficients
;
; Outputs:
;   ARGUMENT1 = the result of the polynomial
;
FP_POLY2        .proc
                PHP

                TRACE "FP_POLY2"

locals          .virtual 1,S
L_B             .dword ?                    ; Temporary result variable
L_X             .dword ?                    ; Temporary copy of X
                .endv
                
                setaxl
                TSC                         ; Make room for the locals
                SEC
                SBC #SIZE(locals)
                TCS

                LDA ARGUMENT1+2             ; Save X to the stack
                STA L_X+2
                LDA ARGUMENT1
                STA L_X

                LDY #0                      ; Initialize b to the first coefficient
                LDA [MTEMPPTR],Y
                STA L_B
                INY
                INY
                LDA [MTEMPPTR],Y
                STA L_B+2
                INY
                INY

                DEC MCOUNT                  ; --i

loop            setas
                LDA #'.'
                CALL PRINTC
                
                setal
                LDA L_X                     ; ARGUMENT1 <-- X
                STA ARGUMENT1
                LDA L_X+2
                STA ARGUMENT1+2

                LDA L_B                     ; ARGUMENT2 <-- B
                STA ARGUMENT2
                LDA L_B+2
                STA ARGUMENT2+2

                CALL OP_FP_MUL              ; ARGUMENT1 <-- X*B

                LDA [MTEMPPTR],Y            ; ARGUMENT2 <-- a_i
                STA ARGUMENT2
                INY
                INY
                LDA [MTEMPPTR],Y
                STA ARGUMENT2+2
                INY
                INY

                CALL OP_FP_ADD              ; ARGUMENT1 <-- a_i + x*b

                LDA ARGUMENT1               ; b <-- a_i + x*b
                STA L_B
                LDA ARGUMENT1+2
                STA L_B+2

                setas              
                DEC MCOUNT                  ; Until --i = 0
                BNE loop

                setal
                LDA L_B                     ; Return b
                STA ARGUMENT1
                LDA L_B+2
                STA ARGUMENT1+2

                TSC                         ; Clean the locals off the stack
                CLC
                ADC #SIZE(locals)
                TCS

                PLP
                RETURN
                .pend

;
; Evaluate a polynomial of the form: a_n*x^n + ... + a_2*x^2 + a_1*x + a_0,
;   where a_i is 0, if i is even.
;
; This routine uses Horner's method to calculate the result of the polynomial
; https://en.wikipedia.org/wiki/Horner%27s_method
;
; Inputs:
;   ARGUMENT1 = the floating point "x" value for the polynomial
;   MTEMPPTR = a pointer to the list of coeffients a_n ... a_0, four bytes each
;   MCOUNT = the number of coefficients
;
; Outputs:
;   ARGUMENT1 = the result of the polynomial
;
FP_POLY1        .proc
                PHP

                TRACE "FP_POLY1"

                setas
                LDA #TYPE_FLOAT         ; ARGUMENT2 will be a float
                STA ARGTYPE2

                setaxl
                LDA ARGUMENT1+2         ; Save a copy of X to the stack and ARGUMENT2
                STA ARGUMENT2+2
                PHA
                LDA ARGUMENT1
                STA ARGUMENT2
                PHA

                CALL OP_FP_MUL          ; ARGUMENT1 <-- X^2

                CALL FP_POLY2           ; ARGUMENT1 <-- POLY2(table, X^2)

                PLA                     ; Get X back
                STA ARGUMENT2
                PLA
                STA ARGUMENT2+2

                CALL OP_FP_MUL          ; ARGUMENT1 <-- POLY2(table, X^2) * X

                PLP
                RETURN
                .pend

;
; Calculate the natural log of X
;
; Inputs:
;   ARGUMENT1 = X
;
; Outputs:
;   ARGUMENT1 = ln(X)
;
FP_LOG          .proc
                PHP

locals          .virtual 1,S
L_N             .byte ?             ; Exponent
                .endv
                SALLOC SIZE(locals)

                TRACE "FP_LOG"

                CALL IS_ARG1_Z      ; Is input 0.0?
                BNE compute

                setal               ; Yes: return 1.0
                LDA FP_1_0
                STA ARGUMENT1
                LDA FP_1_0+2
                STA ARGUMENT1+2

                BRL done
                
compute         setas
                LDA ARGUMENT1+2     ; Save the exponent
                ASL A
                LDA ARGUMENT1+3
                ROL A
                STA L_N

                LDA #$3F            ; Convert input to 1.0 > XF > 0.5
                STA ARGUMENT1+3
                LDA #$7F
                AND ARGUMENT1+2
                STA ARGUMENT1+2

                setal
                LDA FP_SQR_0_5
                STA ARGUMENT2
                LDA FP_SQR_0_5+2
                STA ARGUMENT2+2

                CALL OP_FP_ADD      ; XF + SQRT(0.5)

                LDA ARGUMENT1
                STA ARGUMENT2
                LDA ARGUMENT1+2
                STA ARGUMENT2+2

                LDA FP_SQR_2_0
                STA ARGUMENT1
                LDA FP_SQR_2_0+2
                STA ARGUMENT1+2

                CALL OP_FP_DIV      ; SQRT(2.0) / (XF + SQRT(0.5))

                LDA ARGUMENT1
                STA ARGUMENT2
                LDA ARGUMENT1+2
                STA ARGUMENT2+2

                LDA FP_1_0
                STA ARGUMENT1
                LDA FP_1_0+2
                STA ARGUMENT1+2

                CALL OP_FP_SUB      ; 1.0 - SQRT(2.0) / (XF + SQRT(0.5))

                ; Evaluate the polynomial approximation

                setas
                LDA #4              ; Set the number of coefficients
                STA MCOUNT

                setaxl
                LDA #<>log_coeff    ; Point to our coeffients
                STA MTEMPPTR
                LDA #`log_coeff
                STA MTEMPPTR+2

                CALL FP_POLY1       ; Evaluate the polynomial

                ; Add N

                LDA ARGUMENT1
                STA ARGUMENT2
                LDA ARGUMENT1+2
                STA ARGUMENT2+2

                setas
                SEC                 ; Express N as a sign extended INT
                LDA L_N
                SBC #127
                STA ARGUMENT1
                ASL A
                BCS n_is_neg
                
                STZ ARGUMENT1+1
                STZ ARGUMENT1+2
                STZ ARGUMENT1+3
                BRA convert

n_is_neg        LDA #$FF
                STA ARGUMENT1+1
                STA ARGUMENT1+2
                STA ARGUMENT1+3                

convert         CALL ITOF           ; Convert N to float
                CALL OP_FP_ADD      ; Add N to get the log

done            setas
                LDA #TYPE_FLOAT
                STA ARGTYPE1
                
                SFREE SIZE(locals)
                PLP
                RETURN

log_coeff       .dword $3ede56cb    ; a_7 = 0.43425594189
                .dword $3f139b0b    ; a_5 = 0.57658454124
                .dword $3f763893    ; a_3 = 0.96180075919
                .dword $4038aa3b    ; a_1 = 2.8853900731
                .pend

FP_1_0          .dword $3f800000    ; Floating point constant: 1.0
FP_SQR_2_0      .dword $3fb504f3    ; Floating point constant: sqrt(2.0)
FP_SQR_0_5      .dword $3f3504f3    ; Floating point constant: sqrt(0.2)
