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

.if SYSTEM == SYSTEM_C256
.include "C256/functions_c256.s"
.endif

;
; RIGHT$(text$, count) -- return the right COUNT characters of TEXT
;
FN_RIGHT        .proc
                FN_START "FN_RIGHT"
                PHP

                setaxl

                CALL EVALEXPR               ; Evaluate the string

                setas
                LDA ARGTYPE1
                CMP #TYPE_STRING
                BEQ save_string
                JMP type_mismatch           ; Type mismatch if it's not a string

save_string     setal
                LDA ARGUMENT1+2             ; Save the pointer for later
                PHA
                LDA ARGUMENT1
                PHA

                CALL SKIPWS

                setas
                LDA [BIP]                   ; Expect a comma
                CMP #','
                BEQ skip_comma
                JMP syntax_err

skip_comma      CALL INCBIP

                CALL EVALEXPR               ; Evaluate the count

                setas
                LDA ARGTYPE1
                CMP #TYPE_INTEGER
                BNE type_mismatch           ; Type mismatch if it's not an integer

                ; TODO: Convert FLOAT to INTEGER

                MOVE_W MCOUNT,ARGUMENT1     ; Move the argument to the count of character to return

                setal
                PLA                         ; Recover the string pointer
                STA ARGUMENT1
                PLA
                STA ARGUMENT1+2
                LD_B ARGTYPE1,TYPE_STRING

                ; Y := length of the string
                setas
                LDY #0
count_loop      LDA [ARGUMENT1],Y
                BEQ count_done
                INY
                BRA count_loop

count_done      setal
                TYA                         ; ARGUMENT2 := LENGTH - MCOUNT
                SEC
                SBC MCOUNT
                BMI index0                  ; if ARGUMENT2 < 0, set ARGUMENT2 := 0
                STA ARGUMENT2
                LDA #0                      ; Set ARGUMENT2[23..16] := 0
                STA ARGUMENT2+2
                BRA slice

index0          LDA #0                      ; 0 is the floor for the index
                STA ARGUMENT2
                STA ARGUMENT2+2

slice           LD_B ARGTYPE2,TYPE_INTEGER
                CALL STRSUBSTR              ; And compute the substring
                
done            FN_END
                PLP
                RETURN

type_mismatch   THROW ERR_TYPE              ; Throw a type-mismatch error
syntax_err      THROW ERR_SYNTAX            ; Throw a syntax error
range_err       THROW ERR_RANGE             ; Throw a range error
                .pend

;
; LEFT$(text$, count) -- return the left COUNT characters of TEXT
;
FN_LEFT         .proc
                FN_START "FN_LEFT"
                PHP

                setaxl

                CALL EVALEXPR               ; Evaluate the string

                setas
                LDA ARGTYPE1
                CMP #TYPE_STRING
                BEQ save_string
                JMP type_mismatch           ; Type mismatch if it's not a string

save_string     setal
                LDA ARGUMENT1+2             ; Save the pointer for later
                PHA
                LDA ARGUMENT1
                PHA

                CALL SKIPWS

                setas
                LDA [BIP]                   ; Expect a comma
                CMP #','
                BEQ skip_comma
                JMP syntax_err

skip_comma      CALL INCBIP

                CALL EVALEXPR               ; Evaluate the count

                setas
                LDA ARGTYPE1
                CMP #TYPE_INTEGER
                BNE type_mismatch           ; Type mismatch if it's not an integer

                ; TODO: Convert FLOAT to INTEGER

                MOVE_W MCOUNT,ARGUMENT1     ; Move the argument to the count of character to return

                LD_Q ARGUMENT2,0            ; Set index to 0
                LD_B ARGTYPE2,TYPE_INTEGER

                setal
                PLA                         ; Recover the string pointer
                STA ARGUMENT1
                PLA
                STA ARGUMENT1+2

                LD_B ARGTYPE1,TYPE_STRING

                CALL STRSUBSTR              ; And compute the substring
                
done            FN_END
                PLP
                RETURN

type_mismatch   THROW ERR_TYPE              ; Throw a type-mismatch error
syntax_err      THROW ERR_SYNTAX            ; Throw a syntax error
range_err       THROW ERR_RANGE             ; Throw a range error
                .pend

;
;VAL(value$) -- convert a string to an integer
;
FN_VAL          .proc
                FN_START "FN_VAL"

                CALL EVALEXPR       ; Get the number to convert

                setxl               ; Throw an error if it's not an integer
                setas
                LDA ARGTYPE1
                CMP #TYPE_STRING
                BNE type_mismatch

                setal
                LDA BIP             ; preserve BIP for later
                STA SAVEBIP
                LDA BIP+2
                STA SAVEBIP+2

                LDA ARGUMENT1       ; Temporarily point BIP to the string to parse
                STA BIP
                LDA ARGUMENT1+2
                STA BIP+2

                CALL PARSEINT

                LDA SAVEBIP         ; Restore BIP
                STA BIP
                LDA SAVEBIP+2
                STA BIP+2

                FN_END
                RETURN

type_mismatch   THROW ERR_TYPE      ; Throw a type-mismatch error
                .pend

;
; STR$(value) -- convert an integer to a decimal string
;
FN_STR          .proc
                FN_START "FN_STR"
                PHP

                CALL EVALEXPR       ; Get the number to convert

                ; TODO: process FLOAT

                setxl               ; Throw an error if it's not an integer
                setas
                LDA ARGTYPE1
                CMP #TYPE_INTEGER
                BNE type_mismatch  

                CALL ITOS           ; Convert the number to a temporary string

                setal
                LDA STRPTR          ; Prepare the return result
                STA ARGUMENT1
                LDA STRPTR+2
                STA ARGUMENT1+2

                setas
                LDA #TYPE_STRING
                STA ARGTYPE1

                CALL STRCPY         ; And preserve a copy to the heap

                PLP
                FN_END
                RETURN

type_mismatch   THROW ERR_TYPE      ; Throw a type-mismatch error
                .pend

;
; DEC(value$) -- convert a hexadecimal string to an integer
;
FN_DEC          .proc
                FN_START "FN_DEC"

                CALL EVALEXPR       ; Get the number to convert

                setal
                STZ SCRATCH
                STZ SCRATCH+2

                setaxs              ; Throw an error if it's not an integer
                LDA ARGTYPE1
                CMP #TYPE_STRING
                BNE type_mismatch  

                ; Skip leading spaces and dollar signs
                LDY #0
skip_loop       LDA [ARGUMENT1],Y
                CMP #CHAR_SP
                BEQ skip_char
                CMP #'$'
                BNE loop

skip_char       INY
                BRA skip_loop

loop            LDA [ARGUMENT1],Y   ; Check the character
                CALL ISHEX          ; Is it a hex digit?
                BCC ret_result      ; No: return what we have so far

                setal
                .rept 4
                ASL SCRATCH         ; Shift the result over one digit
                ROL SCRATCH+2
                .next

                setas
                CALL HEX2BIN        ; Convert it to its value
                ORA SCRATCH
                STA SCRATCH         ; And add it to the result

                INY
                BRA loop            ; And try the next character

ret_result      setal
                LDA SCRATCH         ; Return the result
                STA ARGUMENT1
                LDA SCRATCH+2
                STA ARGUMENT1+2

                setas
                LDA #TYPE_INTEGER
                STA ARGTYPE1

                FN_END
                RETURN

type_mismatch   THROW ERR_TYPE      ; Throw a type-mismatch error
                .pend

;
; HEX$(value) -- compute the hexadecimal form of the integer parameter
;
FN_HEX          .proc
                FN_START "FN_HEX"

                CALL EVALEXPR       ; Get the number to convert

                ; TODO: convert FLOAT to INTEGER

                setaxs              ; Throw an error if it's not an integer
                LDA ARGTYPE1
                CMP #TYPE_INTEGER
                BNE type_mismatch  

                CALL TEMPSTRING     ; Get a temporary string

                LDY #$FF            ; Terminate the string
                LDA #0
                STA [STRPTR],Y
                DEY

loop            LDA ARGUMENT1       ; Write the low digit
                AND #$0F
                TAX
                LDA @lHEXDIGITS,X
                STA [STRPTR],Y
                DEY

                LDA ARGUMENT1       ; Write the high digit
                AND #$F0
                LSR A
                LSR A
                LSR A
                LSR A
                TAX
                LDA @lHEXDIGITS,X
                STA [STRPTR],Y
                DEY

                LDA ARGUMENT1+1     ; Shift value by one byte
                STA ARGUMENT1
                LDA ARGUMENT1+2
                STA ARGUMENT1+1
                LDA ARGUMENT1+3
                STA ARGUMENT1+2
                LDA #0
                STA ARGUMENT1+3

                LDA ARGUMENT1       ; Is the argument 0?
                BNE loop            ; No: keep converting
                LDA ARGUMENT1+1
                BNE loop
                LDA ARGUMENT1+2
                BNE loop

                TYA                 ; Get the index of the first free char
                SEC                 ; Add 1 to get to the first character of the string
                ADC STRPTR          ; And add the whole thing to the temp string pointer
                STA ARGUMENT1       ; And return it as the result
                LDA STRPTR+1
                STA ARGUMENT1+1
                LDA STRPTR+2
                STA ARGUMENT1+2
                LDA STRPTR+3
                STA ARGUMENT1+3

                LDA #TYPE_STRING    ; And make the type STRING
                STA ARGTYPE1

                CALL STRCPY         ; Allocate a copy on the heap

                FN_END
                RETURN

type_mismatch   THROW ERR_TYPE      ; Throw a type-mismatch error
                .pend

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
; PEEKL(ADDR) -- Read the 24-bit value at ADDR
;
FN_PEEKL        .proc
                FN_START "FN_PEEKL"

                CALL EVALEXPR       ; Evaluate the first expression

                ; TODO: convert float to integer

                setas               ; Throw an error if it's not an integer
                LDA ARGTYPE1
                CMP #TYPE_INTEGER
                BNE type_mismatch

                setal
                LDA [ARGUMENT1]
                STA SCRATCH

                setas
                LDY #2
                LDA [ARGUMENT1],Y
                STA ARGUMENT1+2
                STZ ARGUMENT1+3

                setal
                LDA SCRATCH
                STA ARGUMENT1

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