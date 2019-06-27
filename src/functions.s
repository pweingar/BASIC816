;;;
;;; Implement functions
;;;
;;; All functions will be called by the expression evaluator
;;;

;
; Common things a function needs to do at the start
;
; Inputs:
;   BIP = pointer to the byte right after the token for the function
;
; Outputs:
;   BIP = pointer to the byte immediately after the open paren
;
FN_START        .macro              ; name
                TRACE \1
                setas
                LDA #TOK_LPAREN
                CALL EXPECT_TOK     ; Skip any whitespace before the open parenthesis

                LDA #TOK_FUNC_OPEN  ; Push the "operator" marker for the start of the function
                CALL PHOPERATOR
                .endm

;
; Common things a function needs to do at the start
;
; Inputs:
;   BIP = pointer to the byte right after the argument to the function
;
; Outputs:
;   BIP = pointer to the byte immediately after the close paren
;
FN_END          .macro
                setas
                CALL INCBIP
                .endm

;
; LEN(S$) -- Compute the length of a string
;
FN_LEN          .proc
                FN_START "FN_LEN"

                CALL EVALEXPR       ; Evaluate the first expression

                setas               ; Throw an error if it's not a string
                LDA ARGTYPE1
                CMP #TYPE_STRING
                BNE type_mismatch

                PHB                 ; Set the data bank to the data bank of the string
                LDA ARGUMENT1+2
                PHA
                PLB

                setxl
                LDX ARGUMENT1       ; And point X to the string data

                CALL STRLEN         ; Calculate the string length
                PLB                 ; Restore the old data bank

                STY ARGUMENT1       ; Save the length to ARGUMENT1
                setal
                STZ ARGUMENT1+2

                setas
                LDA #TYPE_INTEGER   ; And set the type to INTEGER
                STA ARGTYPE1

                FN_END
                RETURN

type_mismatch   THROW ERR_TYPE      ; Throw a type-mismatch error
                .pend

;
; PEEK(ADDR) -- Read the 8-bit value at ADDR
;
FN_PEEK         .proc
                FN_START "FN_PEEK"

                CALL EVALEXPR       ; Evaluate the first expression

                ; TODO: convert float to integer

                setas               ; Throw an error if it's not an integer
                LDA ARGTYPE1
                CMP #TYPE_INTEGER
                BNE type_mismatch

                setas
                LDA [ARGUMENT1]
                STA ARGUMENT1
                STZ ARGUMENT1+1
                STZ ARGUMENT1+2
                STZ ARGUMENT1+13

                FN_END
                RETURN

type_mismatch   THROW ERR_TYPE      ; Throw a type-mismatch error
                .pend

;
; PEEKW(ADDR) -- Read the 16-bit value at ADDR
;
FN_PEEKW        .proc
                FN_START "FN_PEEKW"

                CALL EVALEXPR       ; Evaluate the first expression

                ; TODO: convert float to integer

                setas               ; Throw an error if it's not an integer
                LDA ARGTYPE1
                CMP #TYPE_INTEGER
                BNE type_mismatch

                setal
                LDA [ARGUMENT1]
                STA ARGUMENT1
                STZ ARGUMENT1+2

                FN_END
                RETURN

type_mismatch   THROW ERR_TYPE      ; Throw a type-mismatch error
                .pend

;
; CHR$(value) -- convert the integer value to a single character string
;
; NOTE: the string returned is in the TEMPBUF, and is temporary
; it can be over-written at pretty much any time.
;
FN_CHR          .proc
                FN_START "FN_CHR"

                CALL EVALEXPR       ; Evaluate the first expression

                ; TODO: convert float to integer

                setas               ; Throw an error if it's not a string
                LDA ARGTYPE1
                CMP #TYPE_INTEGER
                BNE type_mismatch

                CALL TEMPSTRING

                LDA ARGUMENT1       ; Get the numberic value
                STA [STRPTR]        ; And save it as the first character
                LDA #0              ; Null terminate the string
                LDY #1
                STA [STRPTR],Y

                setal               ; And return the temporary string
                LDA STRPTR
                STA ARGUMENT1
                LDA STRPTR+2
                STA ARGUMENT1+2
                
                setas
                LDA #TYPE_STRING
                STA ARGTYPE1

                FN_END
                RETURN
type_mismatch   THROW ERR_TYPE      ; Throw a type-mismatch error
                .pend

;
; Return the ASCII code for the first character of the string
;
FN_ASC          .proc
                FN_START "FN_CHR"

                CALL EVALEXPR       ; Evaluate the first expression

                setas               ; Throw an error if it's not a string
                LDA ARGTYPE1
                CMP #TYPE_STRING
                BNE type_mismatch

                LDA [ARGUMENT1]     ; Get the character
                STA ARGUMENT1       ; Save its code to ARGUMENT1
                STZ ARGUMENT1+1
                STZ ARGUMENT1+2
                STZ ARGUMENT1+3

                LDA #TYPE_INTEGER   ; And set the return type to integer
                STA ARGTYPE1

                FN_END
                RETURN
type_mismatch   THROW ERR_TYPE      ; Throw a type-mismatch error
                .pend

;
; Return a string of X spaces, where X is the number in ARGUMENT1
;
FN_SPC          .proc
                FN_START "FN_SPC"

                CALL EVALEXPR       ; Evaluate the first expression

                ; TODO: convert from FLOAT

                setas               ; Throw an error if it's not a string
                LDA ARGTYPE1
                CMP #TYPE_INTEGER
                BNE type_mismatch

                setas
                LDA ARGUMENT1+3     ; Throw an error if ARGUMENT1 is negative or > 255
                BNE err_limit
                LDA ARGUMENT1+2
                BNE err_limit
                LDA ARGUMENT1+1
                BNE err_limit

                setxl
                CALL TEMPSTRING     ; Get the temporary string
                LDY ARGUMENT1       ; Get the length

                setas
                LDA #0
                STA [STRPTR],Y      ; Write the NULL at the end of the string
                DEY
                BMI done

                LDA #CHAR_SP
loop            STA [STRPTR],Y      ; Write a space
                DEY
                BPL loop            ; And keep writing until we're done

done            LDA #TYPE_STRING    ; And set the return type to STRING
                STA ARGTYPE1

                setal
                LDA STRPTR          ; Write the pointer to the return results
                STA ARGUMENT1
                LDA STRPTR+2
                STA ARGUMENT1+2

                FN_END
                RETURN
type_mismatch   THROW ERR_TYPE      ; Throw a type-mismatch error
err_limit       THROW ERR_RANGE     ; Throw an argument range error
                .pend

;
; Return a string of X TABs, where X is the number in ARGUMENT1
;
FN_TAB          .proc
                FN_START "FN_TAB"

                CALL EVALEXPR       ; Evaluate the first expression

                ; TODO: convert from FLOAT

                setas               ; Throw an error if it's not a string
                LDA ARGTYPE1
                CMP #TYPE_INTEGER
                BNE type_mismatch

                setas
                LDA ARGUMENT1+3     ; Throw an error if ARGUMENT1 is negative or > 255
                BNE err_limit
                LDA ARGUMENT1+2
                BNE err_limit
                LDA ARGUMENT1+1
                BNE err_limit

                setxl
                CALL TEMPSTRING     ; Get the temporary string
                LDY ARGUMENT1       ; Get the length

                setas
                LDA #0
                STA [STRPTR],Y      ; Write the NULL at the end of the string
                DEY
                BMI done

                LDA #CHAR_TAB
loop            STA [STRPTR],Y      ; Write a space
                DEY
                BPL loop            ; And keep writing until we're done

done            LDA #TYPE_STRING    ; And set the return type to STRING
                STA ARGTYPE1

                setal
                LDA STRPTR          ; Write the pointer to the return results
                STA ARGUMENT1
                LDA STRPTR+2
                STA ARGUMENT1+2

                FN_END
                RETURN
type_mismatch   THROW ERR_TYPE      ; Throw a type-mismatch error
err_limit       THROW ERR_RANGE     ; Throw an argument range error
                .pend

;
; ABS(value) -- Return the absolute value of a number
;
FN_ABS          .proc
                FN_START "FN_ABS"

                CALL EVALEXPR       ; Evaluate the first expression

                ; TODO: handle floats

                setas               ; Throw an error if it's not an integer
                LDA ARGTYPE1
                CMP #TYPE_INTEGER
                BNE type_mismatch

                setal
                LDA ARGUMENT1+2     ; Is it positive already?
                BPL done            ; Yes: we don't need to do anythign further

                EOR #$FFFF          ; Otherwise, take the two's compliment
                STA ARGUMENT1+2     ; Of ARGUMENT1
                LDA ARGUMENT1
                EOR #$FFFF
                CLC
                ADC #1
                STA ARGUMENT1       ; And save it back to ARGUMENT1
                LDA ARGUMENT1+2
                ADC #0
                STA ARGUMENT1+2

done            FN_END
                RETURN
type_mismatch   THROW ERR_TYPE      ; Throw a type-mismatch error
                .pend

;
; SGN(value) -- Return the sign of the number: 0 => 0, <0 => -1, >0 => +1
;
FN_SGN          .proc
                FN_START "FN_SGN"

                CALL EVALEXPR       ; Evaluate the first expression

                ; TODO: handle floats

                setas               ; Throw an error if it's not an integer
                LDA ARGTYPE1
                CMP #TYPE_INTEGER
                BNE type_mismatch

                setal
                LDA ARGUMENT1+2
                BMI is_negative     ; Negative: return -1
                BNE is_positive     ; Is it not 0? Then return 1

                LDA ARGUMENT1       ; Is the lower word 0?
                BEQ done            ; Yes: the whole thing is zero: return 0

is_positive     LDA #0              ; It's positive: return 1
                STA ARGUMENT1+2
                LDA #1
                STA ARGUMENT1
                BRA done

is_negative     LDA #$FFFF          ; It's negative: return -1
                STA ARGUMENT1+2
                STA ARGUMENT1

done            FN_END
                RETURN
type_mismatch   THROW ERR_TYPE      ; Throw a type-mismatch error
                .pend