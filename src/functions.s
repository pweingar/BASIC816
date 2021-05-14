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
; Negative -- special "function" to convert its argument to a negative number
;
; Negative is special, since it does not include parenthesis around the argument
;
FN_NEGATIVE     .proc
                PHP
                TRACE "FN_NEGATIVE"
                
                setas
                CALL EVALEXPR               ; Get the argument
                
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

done            TRACE "/FN_NEGATIVE"

                BRK

                PLP
                RETURN
                .pend

;
; MID$(text$, index, count) -- return the middle COUNT characters of TEXT starting at index
;
FN_MID          .proc
                FN_START "FN_MID"
                PHP

                setaxl

                CALL EVALEXPR               ; Evaluate the string
                ; CALL POPARGUMENT
                CALL ASS_ARG1_STR

save_string     setal
                LDA ARGUMENT1+2             ; Save the pointer for later
                PHA
                LDA ARGUMENT1
                PHA

                CALL SKIPWS

                setas
                LDA [BIP]                   ; Expect a comma
                CMP #','
                BEQ skip_comma1
                JMP syntax_err

skip_comma1     CALL INCBIP

                CALL EVALEXPR               ; Evaluate the index
                ; CALL POPARGUMENT
                CALL ASS_ARG1_INT16         ; Make sure it is a 16 bit integer

                setal
                LDA ARGUMENT1               ; Save the index
                PHA

                CALL SKIPWS

                setas
                LDA [BIP]                   ; Expect a comma
                CMP #','
                BEQ skip_comma2
                JMP syntax_err

skip_comma2     CALL INCBIP

                CALL EVALEXPR               ; Evaluate the count
                ; CALL POPARGUMENT
                CALL ASS_ARG1_INT16         ; Make sure it is a 16 bit integer

                MOVE_L MCOUNT,ARGUMENT1     ; MCOUNT := count of characters to return

                setal
                PLA                         ; Restore index
                STA ARGUMENT2               ; ... to ARGUMENT2
                LDA #0
                STA ARGUMENT2+2

                PLA                         ; Restore string
                STA ARGUMENT1               ; ... to ARGUMENT1
                PLA
                STA ARGUMENT1+2
                LD_B ARGTYPE1,TYPE_STRING

                CALL STRSUBSTR              ; And compute the substring
                
done            FN_END
                PLP
                RETURN

syntax_err      THROW ERR_SYNTAX            ; Throw a syntax error
range_err       THROW ERR_RANGE             ; Throw a range error
                .pend

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
                PHP

                CALL EVALEXPR       ; Get the number to convert
                ; CALL POPARGUMENT
                CALL ASS_ARG1_STR   ; Make sure the source is a string

                setal
                STZ SCRATCH
                STZ SCRATCH+2

                setaxs              ; Throw an error if it's not an integer

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

                PLP
                FN_END
                RETURN
                .pend

;
; HEX$(value) -- compute the hexadecimal form of the integer parameter
;
FN_HEX          .proc
                FN_START "FN_HEX"
                PHP

                CALL EVALEXPR       ; Get the number to convert
                ; CALL POPARGUMENT
                CALL ASS_ARG1_INT

                CALL TEMPSTRING     ; Get a temporary string

                setaxs
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

                PLP
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
                CALL ASS_ARG1_INT   ; Throw an error if it's not an integer

.if SYSTEM == SYSTEM_C256
                setas
                LDA ARGUMENT1+2                     ; Check to see if the request is to video memory
                CMP #`VRAM
                BLT simple_peek                     ; No: just do an ordinary PEEK
                CMP #$F0
                BGE simple_peek

                PHB                                 ; DBR := bank
                PHA
                PLB
                LDX ARGUMENT1                       ; X := address
                JSL FK_READVRAM                     ; Fetch the low byte
                PLB
                BRA save_result
.endif

simple_peek     setas
                LDA [ARGUMENT1]
save_result     STA ARGUMENT1
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
                CALL ASS_ARG1_INT   ; Throw an error if it's not an integer

.if SYSTEM == SYSTEM_C256
                ;
                ; For the C256, we cannot simply read from video RAM, we have to request the data
                ; with a load, which will trigger a request to Vicky to fetch the data. We then
                ; have to wait for the data to appear in Vicky's memory access FIFO.
                ;

                setas
                LDA ARGUMENT1+2                     ; Check to see if the request is to video memory
                CMP #`VRAM
                BLT simple_peek                     ; No: just do an ordinary PEEK
                CMP #$F0
                BGE simple_peek

                PHB                                 ; DBR := bank
                PHA
                PLB
                LDX ARGUMENT1                       ; X := address
                PHX
                JSL FK_READVRAM                     ; Fetch the low byte
                STA SCRATCH                         ; Save the low byte

                PLX
                INX
                PHX
                JSL FK_READVRAM                     ; Fetch the middle byte
                STA SCRATCH+1                       ; Save the middle byte

                PLX
                INX
                JSL FK_READVRAM                     ; Fetch the high byte
                PLB
                BRA save_result
.endif

simple_peek     setal
                LDA [ARGUMENT1]
                STA SCRATCH

                setas
                LDY #2
                LDA [ARGUMENT1],Y
save_result     STA ARGUMENT1+2
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
                CALL ASS_ARG1_INT   ; Throw an error if it's not an integer

.if SYSTEM == SYSTEM_C256
                ;
                ; For the C256, we cannot simply read from video RAM, we have to request the data
                ; with a load, which will trigger a request to Vicky to fetch the data. We then
                ; have to wait for the data to appear in Vicky's memory access FIFO.
                ;

                setas
                LDA ARGUMENT1+2                     ; Check to see if the request is to video memory
                CMP #`VRAM
                BLT simple_peek                     ; No: just do an ordinary PEEK
                CMP #$F0
                BGE simple_peek

                PHB                                 ; DBR := bank
                PHA
                PLB
                LDX ARGUMENT1                       ; X := address
                PHX
                JSL FK_READVRAM                     ; Fetch the low byte
                STA ARGUMENT1                       ; Save the low byte

                PLX
                INX
                JSL FK_READVRAM                     ; Fetch the high byte
                STA ARGUMENT1+1
                PLB
                setal
                BRA done
.endif

simple_peek     setal
                LDA [ARGUMENT1]
                STA ARGUMENT1
done            STZ ARGUMENT1+2

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
                setas
                LDA ARGTYPE1        ; Check the type
                CMP #TYPE_INTEGER
                BEQ abs_int         ; If integer, get the absolute value of the integer
                CMP #TYPE_FLOAT
                BEQ abs_float       ; If float, get the absolute value of the float

type_err        THROW ERR_TYPE      ; Otherwise, throw a type error

                ; Absolute value of an integer

abs_int         setal
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
                BRA done

                ; Absolute value of a floating point number

abs_float       setas
                LDA ARGUMENT1+3     ; Just clear the sign bit
                AND #$7F
                STA ARGUMENT1+3

done            FN_END
                RETURN
                .pend

;
; SGN(value) -- Return the sign of the number: 0 => 0, <0 => -1, >0 => +1
;
FN_SGN          .proc
                FN_START "FN_SGN"

                ; TODO: add support for floats

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

;
; INT(value) -- Convert a floating point to an integer
;
FN_INT          .proc
                FN_START "FN_INT"

                CALL EVALEXPR       ; Evaluate the first expression
                CALL ASS_ARG1_INT   ; Make sure the input is a float

done            FN_END
                RETURN
                .pend

;
; LOG(value) -- Compute the natural logrithm of value
;
FN_LOG          .proc
                FN_START "FN_LOG"

                CALL EVALEXPR       ; Evaluate the first expression
                CALL ASS_ARG1_FLOAT ; Make sure the input is a float
                CALL FP_LOG         ; Compute the natural log

done            FN_END
                RETURN
                .pend

;
; SIN(value) -- Compute the sine of value
;
FN_SIN          .proc
                FN_START "FN_SIN"

                CALL EVALEXPR       ; Evaluate the first expression
                CALL ASS_ARG1_FLOAT ; Make sure the input is a float
                CALL FP_SIN         ; Compute the natural log

done            FN_END
                RETURN
                .pend

;
; COS(value) -- Compute the cosine of value
;
FN_COS          .proc
                FN_START "FN_COS"

                CALL EVALEXPR       ; Evaluate the first expression
                CALL ASS_ARG1_FLOAT ; Make sure the input is a float
                CALL FP_COS         ; Compute the natural log

done            FN_END
                RETURN
                .pend

;
; TAN(value) -- Compute the tangent of value
;
FN_TAN          .proc
                FN_START "FN_TAN"

                CALL EVALEXPR       ; Evaluate the first expression
                CALL ASS_ARG1_FLOAT ; Make sure the input is a float
                CALL FP_TAN         ; Compute the natural log
done            FN_END
                RETURN
                .pend

;
; LN(value) -- Compute the natural log of value
;
FN_LN          .proc
                FN_START "FN_LN"

                CALL EVALEXPR       ; Evaluate the first expression
                CALL ASS_ARG1_FLOAT ; Make sure the input is a float
                CALL FP_LN          ; Compute the natural log

done            FN_END
                RETURN
                .pend

;
; ACOS(value) -- inverse of COS
;
FN_ACOS          .proc
                FN_START "FN_ACOS"
                CALL EVALEXPR
                CALL ASS_ARG1_FLOAT
                CALL FP_ACOS
done            FN_END
                RETURN
                .pend

;
; ASIN(value) -- inverse of SIN
;
FN_ASIN         .proc
                FN_START "FN_ASIN"
                CALL EVALEXPR
                CALL ASS_ARG1_FLOAT
                CALL FP_ASIN
done            FN_END
                RETURN
                .pend

;
; ATAN(value) -- inverse of TAN
;
FN_ATAN         .proc
                FN_START "FN_ATAN"
                CALL EVALEXPR
                CALL ASS_ARG1_FLOAT
                CALL FP_ATAN
done            FN_END
                RETURN
                .pend

;
; EXP(value) -- e^x
;
FN_EXP          .proc
                FN_START "FN_EXP"
                CALL EVALEXPR
                CALL ASS_ARG1_FLOAT
                CALL FP_EXP
done            FN_END
                RETURN
                .pend

;
; SQR(value) -- square root
;

FN_SQR          .proc
                FN_START "FN_SQR"
                CALL EVALEXPR
                CALL ASS_ARG1_FLOAT
                CALL FP_SQR
done            FN_END
                RETURN
                .pend
