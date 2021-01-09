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
            CALL ASS_ARGS_NUMSTR    ; Make sure the types are the same
            CMP #TYPE_INTEGER       ; And dispatch on the type
            BEQ is_integer
            CMP #TYPE_FLOAT
            BEQ is_float
            CMP #TYPE_STRING
            BEQ is_string

type_error  THROW ERR_TYPE          ; If the types can't be cast...

is_string   CALL STRCONCAT          ; Yes: evaluate string concatenation
            BRA done

is_integer  CALL OP_INT_ADD         ; Yes: evaluate integer addition
            BRA done

is_float    CALL OP_FP_ADD          ; Yes: do a floating point add

done        PLP
            RETURN
            .pend

; Perform subtraction
OP_MINUS    .proc
            PHP

            TRACE "OP_MINUS"

            setas
            CALL ASS_ARGS_NUM       ; Make sure the types are the same
            CMP #TYPE_INTEGER       ; And dispatch on the type
            BEQ is_integer
            CMP #TYPE_FLOAT
            BEQ is_float

type_error  THROW ERR_TYPE

is_integer  CALL OP_INT_SUB         ; Yes: evaluate integer subtraction
            BRA done

is_float    CALL OP_FP_SUB          ; Yes: do a floating point subtraction

done        PLP
            RETURN
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

            TRACE "OP_MULTIPLY"

            setas
            CALL ASS_ARGS_NUM       ; Make sure the types are the same
            CMP #TYPE_INTEGER       ; And dispatch on the type
            BEQ is_integer
            CMP #TYPE_FLOAT
            BEQ is_float

type_error  THROW ERR_TYPE

is_integer  CALL OP_INT_MUL         ; Yes: evaluate integer multiplication
            BRA done

is_float    CALL OP_FP_MUL          ; Yes: do a floating point multiplication

done        PLP
            RETURN
            .pend

;
; Divide two numbers... note this will always return a floating point number
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

            CALL ASS_ARG1_FLOAT
            CALL ASS_ARG2_FLOAT

            CALL OP_FP_DIV

            RETURN
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
            PHP
            TRACE "OP_AND"

            CALL ASS_ARG1_INT       ; Make sure ARGUMENT1 is an integer
            CALL ASS_ARG2_INT       ; Make sure ARGUMENT2 is an integer

            setal
            LDA ARGUMENT1
            AND ARGUMENT2
            STA ARGUMENT1
            LDA ARGUMENT1+2
            AND ARGUMENT2+2
            STA ARGUMENT1+2

            PLP
            RETURN
            .pend

; Bitwise OR
OP_OR       .proc
            PHP
            TRACE "OP_OR"

            CALL ASS_ARG1_INT       ; Make sure ARGUMENT1 is an integer
            CALL ASS_ARG2_INT       ; Make sure ARGUMENT2 is an integer

            setal
            LDA ARGUMENT1
            ORA ARGUMENT2
            STA ARGUMENT1
            LDA ARGUMENT1+2
            ORA ARGUMENT2+2
            STA ARGUMENT1+2

done        PLP
            RETURN
            .pend

; Bitwise NOT
OP_NOT      .proc
            PHP
            TRACE "OP_NOT"

            CALL ASS_ARG1_INT       ; Make sure ARGUMENT1 is an integer

            setal
            LDA ARGUMENT1
            EOR #$FFFF
            STA ARGUMENT1
            LDA ARGUMENT1+2
            EOR #$FFFF
            STA ARGUMENT1+2

done        PLP
            RETURN
            .pend

;
; Less-than: is ARGUMENT1 < ARGUMENT2
;
; Outputs:
;   ARGUMENT1 = -1 if ARGUMENT1 was < ARGUMENT2, 0 otherwise
OP_LT       .proc
            PHP
            TRACE "OP_LT"

            setas
            CALL ASS_ARGS_NUMSTR    ; Make sure the types are the same
            CMP #TYPE_INTEGER       ; And dispatch on the type
            BEQ is_integer
            CMP #TYPE_FLOAT
            BEQ is_float
            CMP #TYPE_STRING
            BEQ is_string

type_error  THROW ERR_TYPE

is_string   CALL OP_STR_LT          ; Yes: evaluate the string operator
            BRA done

is_integer  CALL OP_INT_LT          ; Yes: evaluate the integer operator
            BRA done

is_float    CALL OP_FP_LT           ; Yes: evaluate the floating point operator

done        PLP
            RETURN
            .pend


;
; greater-than: is ARGUMENT1 > ARGUMENT2
;
; Outputs:
;   ARGUMENT1 = -1 if ARGUMENT1 was > ARGUMENT2, 0 otherwise
OP_GT       .proc
            PHP
            TRACE "OP_GT"

            setas
            CALL ASS_ARGS_NUMSTR    ; Make sure the types are the same
            CMP #TYPE_INTEGER       ; And dispatch on the type
            BEQ is_integer
            CMP #TYPE_FLOAT
            BEQ is_float
            CMP #TYPE_STRING
            BEQ is_string

type_error  THROW ERR_TYPE

is_string   CALL OP_STR_GT          ; Yes: evaluate the string operator
            BRA done

is_integer  CALL OP_INT_GT          ; Yes: evaluate the integer operator
            BRA done

is_float    CALL OP_FP_GT           ; Yes: evaluate the floating point operator

done        PLP
            RETURN
            .pend

;
; equal-to: is ARGUMENT1 = ARGUMENT2
;
; Outputs:
;   ARGUMENT1 = -1 if ARGUMENT1 was = ARGUMENT2, 0 otherwise
OP_EQ       .proc
            PHP
            TRACE "OP_EQ"

            setas
            CALL ASS_ARGS_NUMSTR    ; Make sure the types are the same
            CMP #TYPE_INTEGER       ; And dispatch on the type
            BEQ is_integer
            CMP #TYPE_FLOAT
            BEQ is_float
            CMP #TYPE_STRING
            BEQ is_string

type_error  THROW ERR_TYPE

is_string   CALL OP_STR_EQ          ; Yes: evaluate the string operator
            BRA done

is_integer  CALL OP_INT_EQ          ; Yes: evaluate the integer operator
            BRA done

is_float    CALL OP_FP_EQ           ; Yes: evaluate the floating point operator

done        PLP
            RETURN
            .pend

;
; not-equal-to: is ARGUMENT1 <> ARGUMENT2
;
; Outputs:
;   ARGUMENT1 = -1 if ARGUMENT1 was <> ARGUMENT2, 0 otherwise
OP_NE       .proc
            PHP
            TRACE "OP_NE"

            setas

            CALL ASS_ARGS_NUMSTR    ; Make sure the types are the same
            CMP #TYPE_INTEGER       ; And dispatch on the type
            BEQ is_integer
            CMP #TYPE_FLOAT
            BEQ is_float
            CMP #TYPE_STRING
            BEQ is_string

type_error  THROW ERR_TYPE

is_string   CALL OP_STR_NE          ; Yes: evaluate the string operator
            BRA done

is_integer  CALL OP_INT_NE          ; Yes: evaluate the integer operator
            BRA done

is_float    CALL OP_FP_NE           ; Yes: evaluate the floating point operator

done        PLP
            RETURN
            .pend

;
; greater-than-equal: is ARGUMENT1 >= ARGUMENT2
;
; Outputs:
;   ARGUMENT1 = -1 if ARGUMENT1 was >= ARGUMENT2, 0 otherwise
OP_GTE      .proc
            PHP
            TRACE "OP_GTE"

            setas
            CALL ASS_ARGS_NUMSTR    ; Make sure the types are the same
            CMP #TYPE_INTEGER       ; And dispatch on the type
            BEQ is_integer
            CMP #TYPE_FLOAT
            BEQ is_float
            CMP #TYPE_STRING
            BEQ is_string

type_error  THROW ERR_TYPE

is_string   CALL OP_STR_GTE         ; Yes: evaluate the string operator
            BRA done

is_integer  CALL OP_INT_GTE         ; Yes: evaluate the integer operator
            BRA done

is_float    CALL OP_FP_GTE          ; Yes: evaluate the floating point operator

done        PLP
            RETURN
            .pend

;
; less-than-equal: is ARGUMENT1 <= ARGUMENT2
;
; Outputs:
;   ARGUMENT1 = -1 if ARGUMENT1 was <= ARGUMENT2, 0 otherwise
OP_LTE      .proc
            PHP
            TRACE "OP_LTE"

            setas
            CALL ASS_ARGS_NUMSTR    ; Make sure the types are the same
            CMP #TYPE_INTEGER       ; And dispatch on the type
            BEQ is_integer
            CMP #TYPE_FLOAT
            BEQ is_float
            CMP #TYPE_STRING
            BEQ is_string

type_error  THROW ERR_TYPE

is_string   CALL OP_STR_LTE         ; Yes: evaluate the string operator
            BRA done

is_integer  CALL OP_INT_LTE         ; Yes: evaluate the integer operator
            BRA done

is_float    CALL OP_FP_LTE          ; Yes: evaluate the floating point operator

done        PLP
            RETURN
            .pend

;
; Negative -- special operator to convert its argument to a negative number
;
; Negative is special, since it does not include parenthesis around the argument
;
OP_NEGATIVE     .proc
                PHP
                TRACE "OP_NEGATIVE"
                
                setas               
                LDA ARGTYPE1                ; Check the type of the argument
                CMP #TYPE_INTEGER
                BEQ int_negate              ; If integer: negate the integer
                CMP #TYPE_FLOAT
                BEQ float_negate            ; If floating point: negate the floating point

type_error      THROW ERR_TYPE              ; Otherwise, throw an error

float_negate    setas
                LDA ARGUMENT1+3             ; Flip the sign bit of the floating point number
                EOR #$80
                STA ARGUMENT1+3
                BRA done

int_negate      setal
                LDA ARGUMENT1               ; Invert ARGUMENT1
                EOR #$FFFF
                STA ARGUMENT1
                LDA ARGUMENT1+2
                EOR #$FFFF
                STA ARGUMENT1+2

                INC ARGUMENT1               ; And increment to get two's complement
                BNE done
                INC ARGUMENT1+2

done            TRACE "/OP_NEGATIVE"
                PLP
                RETURN
                .pend