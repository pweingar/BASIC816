;;;
;;; Utility Subroutines
;;;

;
; Print a null-terminated trace message
;
; The message to print is assumed to follow almost immediately after the call to trace
; It is assumed there will be an intervening branch i.e.:
;
;   JSR PRTRACE
;   BRA continue
;   .null "Hello"
; continue:
;
;
PRTRACE     .proc
            PHP
            PHB
            setaxl
            PHA
            PHX
            PHY

            setas
            LDA #CODE_BANK  ; Set data bank register to the core BASIC code bank
            PHA
            PLB

            setal
            LDA 9,S         ; Get the return address
            CLC
            ADC #3          ; Add 3 to skip over the following branch
            TAX

            CALL PRINTS     ; Try to print the string

done        setaxl
            PLY
            PLX
            PLA
            PLB
            PLP
            RTS
            .pend

;
; Check to see if A contains an alphabetic character
;
; Input:
;   A = the character to check
;
; Output:
;   C is set if the character is alphabetic, clear otherwise
;
ISALPHA     .proc
            PHP

            TRACE "ISALPHA"

            setas

            CMP #'Z'+1
            BGE not_upper
            CMP #'A'
            BGE is_alpha

not_upper   CMP #'z'+1
            BGE not_alpha
            CMP #'a'
            BGE is_alpha

not_alpha   TRACE "not alpha"
            PLP
            CLC
            RETURN

is_alpha    TRACE "is alpha"
            PLP
            SEC
            RETURN
            .pend

;
; Check to see if A contains a decimal numeral '0'..'9'
;
; Input:
;   A = the character to check
;
; Output:
;   C is set if the character is a numeral, clear otherwise
;
ISNUMERAL   .proc
            PHP
            TRACE_A "ISNUMERAL"

            setas

            CMP #'9'+1
            BGE ret_false
            CMP #'0'
            BGE ret_true

ret_false   PLP
            CLC
            RETURN

ret_true    PLP
            SEC
            RETURN
            .pend

;
; Check to see if the character in A is a hexadecimal digit ('0'..'9', 'A'..'F', 'a'..'f')
;
; Input:
;   A = the character to check
;
; Output:
;   C is set if the character is a numeral, clear otherwise
;
ISHEX       .proc
            PHP
            setas

            CMP #'9'+1
            BGE chk_lca2f
            CMP #'0'
            BGE ret_true

chk_lca2f   CMP #'f'+1
            BGE chk_uca2f
            CMP #'a'
            BGE ret_true            

chk_uca2f   CMP #'F'+1
            BGE ret_false
            CMP #'A'
            BGE ret_true  

ret_false   PLP
            CLC
            RETURN

ret_true    PLP
            SEC
            RETURN
            .pend

;
; Convert a hexadecimal digit in A to its binary equivalent
;
; Inputs:
;   A = the character to be converted ('0'..'9', 'a'..'f', 'A'..'F')
;   
; Outputs:
;   A = the binary number for the character (undefined if character is invalid)
;
HEX2BIN     .proc
            PHP

            setas
            CMP #'9'+1          ; Check to see if '0'..'9'
            BGE chk_lca2f
            CMP #'0'
            BGE conv_09         ; Yes: convert it

chk_lca2f   CMP #'f'+1
            BGE chk_uca2f
            CMP #'a'
            BGE conv_lcaf            

chk_uca2f   CMP #'F'+1
            BGE done
            CMP #'A'
            BGE conv_ucaf  

done        PLP
            RETURN

conv_09     SEC                 ; Convert digits '0'..'9'
            SBC #'0'
            BRA done

conv_lcaf   AND #%11011111      ; Convert to upper case
conv_ucaf   SEC
            SBC #'A'-10         ; Convert 'A'..'F'
            BRA done

            .pend

;
; Convert the character in A to uppercase
;
; Inputs:
;   A = the character to convert
;
; Outputs:
;   A = the character in upper case (if it was a letter, unchanged otherwise)
;
TOUPPERA    .proc
            PHP

            setas

            CMP #'z'+1
            BCS done
            CMP #'a'
            BCC done

            AND #%11011111

done        PLP
            RETURN
            .pend

;
; Convert a null-terminated string to upper case (in place)
;
; Inputs:
;   X = pointer to string
;
TOUPPER     .proc
            PHP
            setas
            setxl

loop        LDA #0,B,X
            BEQ done
            CALL TOUPPERA
            STA #0,B,X

continue    INX
            BRA loop

done        PLP
            RETURN
            .pend

;
; Multipl ARGUMENT1 by 10
;
; Inputs
;   ARGUMENT1 = integer value to multiply by 10
;
; Outputs:
;   ARGUMENT1 = the value multiplied by 10
;
MULINT10        .proc
                PHP
                PHD

                setdp GLOBAL_VARS

                setal
                PHA

; .if SYSTEM = SYSTEM_C256
;                 ; The C256 has a 16-bit hardware multiplier, so use it.
;                 LDA ARGUMENT1
;                 STA @lM1_OPERAND_A

;                 LDA #10
;                 STA @lM1_OPERAND_B

;                 LDA @lM1_RESULT
;                 STA ARGUMENT1
;                 LDA @lM1_RESULT+2
;                 STA ARGUMENT1+2
; .else
                ASL ARGUMENT1
                ROL ARGUMENT1+2
                LDA ARGUMENT1
                STA SCRATCH
                LDA ARGUMENT1+2
                STA SCRATCH+2

                ASL SCRATCH
                ROL SCRATCH+2
                ASL SCRATCH
                ROL SCRATCH+2

                CLC
                LDA ARGUMENT1
                ADC SCRATCH
                STA ARGUMENT1
                LDA ARGUMENT1+2
                ADC SCRATCH+2
                STA ARGUMENT1+2
; .endif

                PLA
                PLD
                PLP
                RETURN
                .pend

;
; Divide ARGUMENT1 by 10
;
; Inputs:
;   ARGUMENT1 = the number to divide
;
; Outputs:
;   ARGUMENT1 = the quotient
;   ARGUMENT2 = the remainder
;
DIVINT10        .proc
                PHP
                PHD
                TRACE "DIVINT10"

                setdp GLOBAL_VARS

                ; TODO: flesh out non-C256 division

.if SYSTEM = SYSTEM_C256
                setal
                LDA ARGUMENT1
                STA @lD1_OPERAND_B
                LDA #10
                STA @lD1_OPERAND_A

                LDA @lD1_RESULT
                STA ARGUMENT1
                STZ ARGUMENT1+2
                LDA @lD1_REMAINDER
                STA ARGUMENT2
                STZ ARGUMENT2+2

                setas
                LDA #TYPE_INTEGER
                STA ARGTYPE1
                STA ARGTYPE2
.endif

                PLD
                PLP
                RETURN
                .pend

;
; Divide ARGUMENT1 by 100
;
; Inputs:
;   ARGUMENT1 = the number to divide
;
; Outputs:
;   ARGUMENT1 = the quotient
;   ARGUMENT2 = the remainder
;
DIVINT100       .proc
                PHP
                PHD
                TRACE "DIVINT100"

                setdp GLOBAL_VARS

                ; TODO: flesh out non-C256 division

.if SYSTEM = SYSTEM_C256
                setal
                LDA ARGUMENT1
                STA @lD1_OPERAND_B
                LDA #100
                STA @lD1_OPERAND_A

                LDA @lD1_RESULT
                STA ARGUMENT1
                STZ ARGUMENT1+2
                LDA @lD1_REMAINDER
                STA ARGUMENT2
                STZ ARGUMENT2+2

                setas
                LDA #TYPE_INTEGER
                STA ARGTYPE1
                STA ARGTYPE2
.endif

                PLD
                PLP
                RETURN
                .pend

;
; Check to see if ARGUMENT1 is 0
;
; Inputs:
;   ARGUMENT1 = the value to check
;
; Outputs:
;   Z set if ARGUMENT1 is zero, clear otherwise
;
; NOTE: currently only handles integers and related values, not floats
;
IS_ARG1_Z       .proc
                PHP

                setal
                LDA ARGUMENT1
                BNE return_false
                LDA ARGUMENT1+2
                BNE return_false

return_true     PLP
                SEP #$02        ; Set Z
                RETURN

return_false    PLP
                REP #$02        ; Clear Z
                RETURN
                .pend

;
; Assert that ARGUMENT1 contains an integer. Throw a type mismatch error.
;
; TODO: if ARGUMENT1 is a float, convert it to an integer
;
; Inputs:
;   ARGUMENT1
;
ASS_ARG1_INT    .proc
                PHP
                TRACE "ASS_ARG1_INT"

                setas
                LDA ARGTYPE1            ; Verify that the type is INTEGER
                CMP #TYPE_INTEGER
                BNE TYPE_ERR

                PLP
                RETURN

TYPE_ERR        THROW ERR_TYPE
                .pend

;
; Assert that ARGUMENT1 contains a string. Throw a type mismatch error.
;
; Inputs:
;   ARGUMENT1
;
ASS_ARG1_STR    .proc
                PHP
                TRACE "ASS_ARG1_STR"

                setas
                LDA ARGTYPE1            ; Verify that the type is STRING
                CMP #TYPE_STRING
                BNE TYPE_ERR

                PLP
                RETURN

TYPE_ERR        THROW ERR_TYPE
                .pend

;
; Assert that ARGUMENT1 contains a 16-bit integer. Throw a type mismatch error or
; a range error if it won't fit in 16 bits.
;
; TODO: if ARGUMENT1 is a float, convert it to an integer
;
; Inputs:
;   ARGUMENT1
;
ASS_ARG1_INT16  .proc
                PHP
                TRACE "ASS_ARG1_INT16"

                setas
                LDA ARGTYPE1            ; Verify that the type is INTEGER
                CMP #TYPE_INTEGER
                BNE TYPE_ERR

                setal
                LDA ARGUMENT1+2         ; Validate it is 16-bit
                BNE range_err

                TRACE "/ASS_ARG1_INT16"
                PLP
                RETURN

TYPE_ERR        THROW ERR_TYPE
RANGE_ERR       THROW ERR_RANGE
                .pend

;
; Assert that ARGUMENT1 contains a byte. Throw a type mismatch error if it is not an
; integer and a range error if it is not between 0 and 255.
;
; TODO: if ARGUMENT1 is a float, convert it to an integer
;
; Inputs:
;   ARGUMENT1
;
ASS_ARG1_BYTE   .proc
                PHP

                setas
                LDA ARGTYPE1            ; Verify that the type is INTEGER
                CMP #TYPE_INTEGER
                BNE TYPE_ERR

                LDA ARGUMENT1+3         ; Validate that the value is in byte range
                BNE RANGE_ERR           ; If not... throw a range error
                LDA ARGUMENT1+2
                BNE RANGE_ERR
                LDA ARGUMENT1+1
                BNE RANGE_ERR

                PLP
                RETURN

TYPE_ERR        THROW ERR_TYPE
RANGE_ERR       THROW ERR_RANGE
                .pend