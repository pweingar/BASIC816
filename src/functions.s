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