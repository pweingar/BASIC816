;;;
;;; Core BASIC Statements
;;;

.if SYSTEM == SYSTEM_C256
.include "C256/statements_c256.s"
.endif

; Call a machine language subroutine. Return from subroutines must be long (RTL)
; CALL address [,a_value [,x_value [,y_value]]]
S_CALL          .proc
                PHP
                TRACE "S_CALL"

                CALL EVALEXPR       ; Get the address
                CALL ASS_ARG1_INT   ; Assure the address is an integer

                setas
                LDA #$5C            ; Set the opcode for JML
                STA MJUMPINST
                setal               ; Set the JML address to the argument
                LDA ARGUMENT1
                STA MJUMPADDR
                setas
                LDA ARGUMENT1+2
                STA MJUMPADDR+2

                ; Get the optional value for A

                setas
                LDA #','
                STA TARGETTOK
                CALL OPT_TOK        ; Is there a comma?
                BCC launch          ; Not present... go ahead and launch
                CALL INCBIP

                CALL EVALEXPR       ; Otherwise, get value for A
                CALL ASS_ARG1_INT16 ; Make sure it's a 16-bit integer
                setal
                LDA ARGUMENT1
                STA MARG1           ; Save it to MARG1

                ; Get the optional value for X

                setas
                LDA #','
                STA TARGETTOK
                CALL OPT_TOK        ; Is there a comma?
                BCC launch          ; Not present... go ahead and launch
                CALL INCBIP

                CALL EVALEXPR       ; Otherwise, get value for X
                CALL ASS_ARG1_INT16 ; Make sure it's a 16-bit integer
                setal
                LDA ARGUMENT1
                STA MARG2           ; Save it to MARG2

                ; Get the optional value for Y

                setas
                LDA #','
                STA TARGETTOK
                CALL OPT_TOK        ; Is there a comma?
                BCC launch          ; Not present... go ahead and launch
                CALL INCBIP

                CALL EVALEXPR       ; Otherwise, get value for Y
                CALL ASS_ARG1_INT16 ; Make sure it's a 16-bit integer
                setal
                LDY ARGUMENT1
launch          LDX MARG2
                LDA MARG1
                JSL MJUMPINST       ; Call the subroutine indicated

                CALL SKIPSTMT       ; Skip to the ending colon or end of line

                PLP
                RETURN
type_err        THROW ERR_TYPE
                .pend

; Dimmension an array DIM A(i_0, i_1, ... i_n)
S_DIM           .proc
                PHP
                TRACE "S_DIM"

                setas

                CALL SKIPWS

                CALL VAR_FINDNAME   ; Try to find the variable name
                BCC syntax_err      ; If we didn't get a variable, throw a syntax error

                LDA #TOK_LPAREN     ; Verify we have a left parenthesis
                CALL EXPECT_TOK

                LDA #TOK_FUNC_OPEN  ; Push the "operator" marker for the start of the function
                CALL PHOPERATOR

                LDX #1

                LDA #0
                STA @lARRIDXBUF     ; Set the dimension count to 0

dim_loop        CALL EVALEXPR       ; Evaluate the count
                CALL ASS_ARG1_INT16 ; Make sure it is an integer

                setal
                LDA ARGUMENT1
                STA @lARRIDXBUF,X   ; And store it in the buffer

                setas
                LDA @lARRIDXBUF     ; Add to the dimension count
                INC A
                STA @lARRIDXBUF
                BMI overflow        ; If > 127 throw an error

                INX
                INX

                CALL SKIPWS         ; Skip any whitespace
                LDA [BIP]           ; Check the character
                CMP #','            ; Is it a comma?
                BEQ skip_comma      ; Yes: get the next dimension
                CMP #TOK_RPAREN     ; No: is it a ")"?
                BNE syntax_err      ; No: throw a syntax error

                CALL INCBIP         ; Yes: we're done... skip the parenthesis

                CALL ARR_ALLOC      ; Allocate the array

                setal
                LDA CURRBLOCK       ; Set up the pointer to the array
                STA ARGUMENT1
                setas
                LDA CURRBLOCK+2
                STA ARGUMENT1+2
                STZ ARGUMENT1+3

                LDA TOFINDTYPE      ; Get the type of the values
                ORA #$80            ; Make sure we change the type to array
                STA TOFINDTYPE      ; And save it back for searching
                STA ARGTYPE1        ; And for the value to set

                CALL VAR_SET        ; And set the variable

                PLP
                RETURN
skip_comma      CALL INCBIP
                JMP dim_loop

syntax_err      THROW ERR_SYNTAX
overflow        THROW ERR_ARGUMENT
                .pend

; Read data from data statements
; READ variable, variable, ...
S_READ          .proc
                PHP
                TRACE "S_READ"

varloop         CALL SKIPWS

                setas
                LDA [BIP]
                BEQ done            ; If EOL, we're done
                CMP #':'
                BEQ done            ; If colon, we're done

                CALL ISALPHA        ; Check to see if it's the start of a variable
                BCC syntax_err      ; No: it's a syntax error

                CALL VAR_FINDNAME   ; Try to find the variable name
                BCC syntax_err      ; If we didn't get a variable, throw a syntax error

                CALL NEXTDATA       ; Try to get the next data item into ARGUMENT1
                CALL VAR_SET        ; Attempt to set the value to the variable

                CALL SKIPWS
                LDA [BIP]           ; Get the next non-space
                BEQ done            ; EOL? We're done
                CMP #':'            ; Colon? We're done
                BEQ done
                CMP #','            ; Comma?
                BNE syntax_err      ; Nope: syntax error

                CALL INCBIP         ; Yes... check for another variable
                BRA varloop
                
done            PLP
                RETURN
syntax_err      THROW ERR_SYNTAX
                .pend

; Helper subroutine... try to find and parse the next literal in a DATA statement
; Throw error if we're out
NEXTDATA        .proc
                PHP
                TRACE "NEXTDATA"

                LDA BIP+2           ; Save BIP
                STA SAVEBIP+2
                LDA BIP
                STA SAVEBIP

                LDA CURLINE+2       ; Save CURLINE
                STA SAVELINE+2
                LDA CURLINE
                STA SAVELINE  

                ; Check if DATABIP is set
                setal
                LDA DATABIP+2
                BNE data_set
                LDA DATABIP
                BEQ scan_start      ; No: scan for a DATA statement

data_set        LDA DATABIP         ; Move BIP to the DATA statement
                STA BIP
                LDA DATABIP+2
                STA BIP+2

                LDA DATALINE        ; Set CURLINE from DATALINE
                STA CURLINE
                LDA DATALINE+2
                STA CURLINE+2

                setas
                LDA [BIP]           ; Check character at BIP
                BEQ scan_DATA       ; EOL? scan for a DATA statement
                CMP #':'            ; Colon?
                BEQ scan_DATA       ; ... scan for a DATA statement
                CMP #','            ; Comma?
                BNE skip_parse      ; No: skip leading WS and try to parse
                CALL INCBIP         ; Yes: move to the next char

skip_parse      CALL SKIPWS         ; Skip white space

                LDA [BIP]
                CMP #CHAR_DQUOTE    ; Is it a quote?
                BEQ read_string     ; Yes: process the string
                CALL ISNUMERAL      ; Is it a numeral?
                BCS read_number     ; Yes: process the number

syntax_err      THROW ERR_SYNTAX    ; Otherwise: throw syntax error

scan_start      TRACE "scan_start"
                setal
                LDA #<>BASIC_BOT    ; Point CURLINE to the first line
                STA CURLINE
                LDA #`BASIC_BOT
                STA CURLINE+2

                CLC
                LDA CURLINE         ; Point BIP to the first possible token
                ADC #LINE_TOKENS
                STA BIP
                LDA CURLINE+2
                ADC #0
                STA BIP+2

                ; Scan for a DATA statement
scan_data       TRACE "scan_data"
                setas
                LDA #$80            ; We don't want to process nesting
                STA SKIPNEST

                LDA #TOK_DATA       ; We're looking for a DATA token
                STA TARGETTOK

                CALL SKIPTOTOK      ; Try to find the DATA token
                BRA skip_parse

                ; Read a string literal
read_string     CALL EVALSTRING     ; Try to read a string
                BRA done

                ; Read an integer literal
read_number     CALL EVALNUMBER     ; Try to read a number

                TRACE "got number"

done            setal
                LDA BIP             ; Save BIP to DATABIP
                STA DATABIP
                LDA BIP+2
                STA DATABIP+2

                LDA CURLINE         ; Save CURLINE to DATALINE
                STA DATALINE
                LDA CURLINE+2
                STA DATALINE+2

                LDA SAVELINE        ; Restore CURLINE
                STA CURLINE
                LDA SAVELINE+2
                STA CURLINE+2

                LDA SAVEBIP         ; Restore BIP
                STA BIP
                LDA SAVEBIP+2
                STA BIP+2

                PLP
                RETURN
                .pend

; Store date for later reads. When executed, just goes to the end of the statement
S_DATA          .proc
                TRACE "S_DATA"
                CALL SKIPSTMT
                RETURN
                .pend

; Reset the DATA pointer to the beginning
S_RESTORE       .proc
                TRACE "S_RESTORE"
                STZ DATABIP         ; Just set DATABIP to 0
                STZ DATABIP+2       ; The next READ will move it to the first DATA
                STZ DATALINE        ; Set DATALINE to 0
                STZ DATALINE+2
                RETURN
                .pend

; Clear the screen and move the cursor to the home position
S_CLS           .proc
                CALL CLSCREEN
                RETURN
                .pend

; Write an 24-bit value to an address in memory
; POKEL <address>,<value>
S_POKEL         .proc

                CALL EVALEXPR       ; Get the address

                setal
                LDA ARGUMENT1+2     ; And save it to the stack
                PHA
                LDA ARGUMENT1
                PHA

                setas
                LDA [BIP]
                CMP #','
                BNE syntax_err
                CALL INCBIP

                CALL EVALEXPR       ; Get the value

                setal
                LDA ARGUMENT1+3
                BNE range_err

                PLA                 ; Pull the target address from the stack
                STA INDEX           ; and into INDEX
                PLA
                STA INDEX+2

                setal
                LDA ARGUMENT1
                STA [INDEX]         ; And write it to the address

                setas
                LDY #2
                LDA ARGUMENT1+2
                STA [INDEX],Y

                RETURN
syntax_err      THROW ERR_SYNTAX
range_err       THROW ERR_RANGE
                .pend

; Write an 16-bit value to an address in memory
; POKEW <address>,<value>
S_POKEW         .proc

                CALL EVALEXPR       ; Get the address

                setal
                LDA ARGUMENT1+2     ; And save it to the stack
                PHA
                LDA ARGUMENT1
                PHA

                setas
                LDA [BIP]
                CMP #','
                BNE syntax_err
                CALL INCBIP

                CALL EVALEXPR       ; Get the value

                setal
                LDA ARGUMENT1+2
                BNE range_err

                PLA                 ; Pull the target address from the stack
                STA INDEX           ; and into INDEX
                PLA
                STA INDEX+2

                setal
                LDA ARGUMENT1
                STA [INDEX]         ; And write it to the address

                RETURN
syntax_err      THROW ERR_SYNTAX
range_err       THROW ERR_RANGE
                .pend

; Write an 8-bit value to an address in memory
; POKE <address>,<value>
S_POKE          .proc

                CALL EVALEXPR       ; Get the address

                setal
                LDA ARGUMENT1+2     ; And save it to the stack
                PHA
                LDA ARGUMENT1
                PHA

                setas
                LDA [BIP]
                CMP #','
                BNE syntax_err
                CALL INCBIP

                CALL EVALEXPR       ; Get the value

                setas
                LDA ARGUMENT1+1     ; Make sure the value is from 0 - 255
                BNE range_err

                setal
                LDA ARGUMENT1+2
                BNE range_err

                PLA                 ; Pull the target address from the stack
                STA INDEX           ; and into INDEX
                PLA
                STA INDEX+2

                setas
                LDA ARGUMENT1
                STA [INDEX]         ; And write it to the address

                RETURN
syntax_err      THROW ERR_SYNTAX
range_err       THROW ERR_RANGE
                .pend

; Stop execution in such a manner that CONT can restart it.
S_STOP          .proc
                THROW ERR_BREAK     ; Throw a BREAK exception
                .pend

; Start a remark or comment in the code
; Everything in the program until the next end-of-line will be ignored
S_REM           .proc
                PHP

                setas
rem_loop        LDA [BIP]
                BEQ done

                CALL INCBIP
                BRA rem_loop

done            PLP
                RETURN
                .pend

; Break out of an enclosing DO loop
S_EXIT          .proc
                PHP

                PLP
                RETURN
                .pend

; Start a loop that may be ended conditionally
; DO [WHILE <conditional expr> | UNTIL <conditional expr>]
;
; Pushes to the return stack:
;   return CURLINE (4)
;   return BIP (4 bytes) <= "top" of stack
;
S_DO            .proc
                PHP
                ; TRACE "S_DO"

                ; ; Save the current line to the RETURN stack

                ; setal
                ; LDA CURLINE+2
                ; CALL PHRETURN
                ; LDA CURLINE
                ; CALL PHRETURN

                ; ; Save the BIP for right after FOR to the RETURN stack
                ; LDA BIP+2           ; Save current BIP
                ; PHA
                ; LDA BIP
                ; PHA

                ; CALL SKIPSTMT       ; Skip to the next statement
                ; LDA BIP+2           ; Save the BIP for the next statement to the RETURN stack
                ; CALL PHRETURN
                ; LDA BIP
                ; CALL PHRETURN

                ; PLA                 ; Restore the original BIP
                ; STA BIP
                ; PLA
                ; STA BIP+2

                PLP
                RETURN
                .pend

;
; Structure of the record DO pushes to the RETURN stack
; (in order of how the parameters will appear in memory on the stack)
;
DO_RECORD       .struct
BIP             .dword  ?
CURLINE         .dword  ?
                .ends

; Close a DO loop
; LOOP [WHILE <conditional expr> | UNTIL <conditional expr>]
;
; Expects the return stack to contain:
;   return CURLINE (4)
;   return BIP (4 bytes) <= "top" of stack
;
S_LOOP          .proc
                PHP
                ; PHB
                ; TRACE "S_LOOP"

                ; setdbr 0

                ; setaxl
                ; LDY RETURNSP
                ; INY
                ; INY

                ; LDA #DO_RECORD.CURLINE,Y        ; Pull the CURLINE for the matching DO
                ; STA CURLINE
                ; LDA #DO_RECORD.CURLINE+2,Y
                ; STA CURLINE_2

                ; LDA #DO_RECORD.BIP,Y            ; Pull the BIP for the matching DO
                ; STA BIP
                ; LDA #DO_RECORD.BIP+2,Y
                ; STA BIP+2

                ; setas                           ; jump back to that spot
                ; LDA #EXEC_RETURN
                ; STA EXECACTION

                ; PHB
                PLP
                RETURN
                .pend

;
; Iterate over a variable from an initial value to an ending value
; FOR <variable> = <initial expr> TO <final expr> [STEP <increment>]
;
; Pushes to the return stack:
;   return CURLINE (4)
;   return BIP (4 bytes),
;   <variable> (4 bytes),
;   <final value> (6 bytes),
;   <increment> (6 bytes) <== "top" of stack
;
S_FOR           .proc
                PHP
                TRACE "S_FOR"

                ; Save the current line to the RETURN stack

                setal
                LDA CURLINE+2
                CALL PHRETURN
                LDA CURLINE
                CALL PHRETURN

                ; Save the BIP for right after FOR to the RETURN stack
                LDA BIP+2           ; Save current BIP
                PHA
                LDA BIP
                PHA

                CALL SKIPSTMT       ; Skip to the next statement
                LDA BIP+2           ; Save the BIP for the next statement to the RETURN stack
                CALL PHRETURN
                LDA BIP
                CALL PHRETURN

                PLA                 ; Restore the original BIP
                STA BIP
                PLA
                STA BIP+2

                ; Find the set the initial value of the index variable

                CALL SKIPWS

get_name        CALL VAR_FINDNAME   ; Try to find the variable name
                BCS push_name       ; If we didn't find a name, thrown an error

                THROW ERR_NOTFOUND

push_name       setas               ; Push the search record for the index variable
                LDA TOFINDTYPE      ; To the return stack
                CALL PHRETURNB
                LDA TOFIND+2
                CALL PHRETURNB
                setal
                LDA TOFIND
                CALL PHRETURN

else            CALL SKIPWS         ; Scan for an "="
                setas
                LDA [BIP]
                CMP #TOK_EQ
                BNE syntax_err      ; If not found: signal an syntax error

                LDA TOFINDTYPE      ; Verify type of variable
                CMP #TYPE_INTEGER   ; Is it integer?
                BEQ process_initial ; Yes: it's ok
                CMP #TYPE_FLOAT     ; Is it floating point?
                BEQ process_initial ; Yes: it's ok

process_initial CALL INCBIP         ; Otherwise, skip over it
                CALL EVALEXPR       ; Evaluate the expression
                CALL VAR_SET        ; Attempt to set the value of the variable

                ; Process the limit value
                setas
                LDA #TOK_TO         ; Expect the next token to be TO
                CALL EXPECT_TOK

                CALL EVALEXPR       ; Evaluate the limit value

                ; TODO: assert that we have a number

                setal               ; Push the ending value
                LDA ARGTYPE1
                CALL PHRETURN
                LDA ARGUMENT1+2
                CALL PHRETURN
                LDA ARGUMENT1
                CALL PHRETURN

                ; Process the optional STEP
                setas
                LDA #TOK_STEP
                STA TARGETTOK
                CALL OPT_TOK        ; Seek an optional STEP token
                BCC default_inc     ; Not found: set a default increment of 1

                CALL INCBIP
                CALL EVALEXPR       ; Evaluate the next expression

                setas
                LDA ARGTYPE1        ; Push the result as the increment
                CALL PHRETURN
                setal
                LDA ARGUMENT1+2
                CALL PHRETURN
                LDA ARGUMENT1
                CALL PHRETURN
                BRA done

default_inc     setal               ; Push 1 as the increment
                LDA #TYPE_INTEGER
                CALL PHRETURN
                LDA #0
                CALL PHRETURN
                LDA #1
                CALL PHRETURN

done            PLP
                RETURN
syntax_err      THROW ERR_SYNTAX
                .pend

;
; Structure of the record FOR pushes to the RETURN stack
; (in order of how the parameters will appear in memory on the stack)
;
FOR_RECORD      .struct
INCREMENT       .dword  ?
INCTYPE         .word   ?
FINAL           .dword  ?
FINALTYPE       .word   ?
VARIBLE         .dword  ?
VARTYPE         .word   ?
BIP             .dword  ?
CURLINE         .dword  ?
                .ends

;
; Close a FOR loop
;
; Expects a return stack looking like this:
;   return CURLINE (4)
;   return BIP (4 bytes),
;   <variable> (4 bytes),
;   <final value> (6 bytes),
;   <increment> (6 bytes) <== "top" of stack
;
S_NEXT          .proc
                PHP
                PHB
                TRACE "S_NEXT"

                setdbr 0
                setdp GLOBAL_VARS

                setaxl

                ; Get the final value

                LDY RETURNSP                    ; Y := pointer to first byte of the FOR record
                INY                             ; RETURNSP points to the first free slot, so move up 2 bytes
                INY

                ; Get the variable and its current value
                setal
                LDA #FOR_RECORD.VARIBLE,B,Y     ; TOFIND := FOR_RECORD.VARIABLE
                STA TOFIND
                LDA #FOR_RECORD.VARIBLE+2,B,Y
                setas
                STA TOFIND+2
                LDA #FOR_RECORD.VARTYPE,B,Y
                STA TOFINDTYPE

                setal
                PHY
                CALL VAR_REF                    ; Get the value of the variable
                PLY

                setal
                LDA #FOR_RECORD.INCREMENT,B,Y   ; ARGUMENT2 := FOR_RECORD.INCREMENT
                STA ARGUMENT2
                LDA #FOR_RECORD.INCREMENT+2,B,Y
                STA ARGUMENT2+2
                setas
                LDA #FOR_RECORD.INCTYPE,B,Y
                STA ARGTYPE2

                setal
                PHY
                CALL OP_PLUS                    ; Add the increment to the current value
                CALL VAR_SET                    ; Assign the new value to the variable
                PLY

                setal
                LDA #FOR_RECORD.FINAL,B,Y       ; ARGUMENT2 := FOR_RECORD.FINAL
                STA ARGUMENT2
                LDA #FOR_RECORD.FINAL+2,B,Y
                STA ARGUMENT2+2
                setas
                LDA #FOR_RECORD.FINALTYPE,B,Y
                STA ARGTYPE2

                setal
                LDA #FOR_RECORD.INCREMENT+2,B,Y ; Check the increment's sign
                BMI going_down

going_up        CALL OP_LTE                     ; Is current =< limit?
                CALL IS_ARG1_Z
                BEQ end_loop                    ; No: end the loop
                BRA loop_back                   ; Yes: loop back

going_down      CALL OP_GTE                     ; Is current >= limit?
                CALL IS_ARG1_Z
                BEQ end_loop                    ; No: end the loop

                ; Not at end, so add the increment, reassign, and loop

loop_back       TRACE "loop back"
               
                setal                           ; Set the BIP to the correct spot (right after the FOR)
                LDA #FOR_RECORD.BIP,B,Y
                STA BIP
                LDA #FOR_RECORD.BIP+2,B,Y
                STA BIP+2

                ; Set the CURLINE to the correct spot (right after the FOR)
                LDA #FOR_RECORD.CURLINE,B,Y     ; CURLINE := FOR_RECORD.CURLINE
                STA CURLINE
                LDA #FOR_RECORD.CURLINE+2,B,Y
                STA CURLINE+2

                setas                           ; Set the action to RETURN to the spot
                LDA #EXEC_RETURN
                STA EXECACTION

                BRA done

                ; Got to the end of the loop, cleanup the RETURN stack

end_loop        TRACE "end_loop"

                LDX #ARGUMENT1
                CALL PLARGUMENT                 ; Restore the value of the variable

                setal
                CLC
                LDA RETURNSP
                ADC #size(FOR_RECORD)           ; Move pointer by number of bytes in a FOR record
                STA RETURNSP
                LDA RETURNSP+2
                ADC #0
                STA RETURNSP+2

done            PLB
                PLP
                RETURN
                .pend

; Jump to a subroutine. Push BIP, CURLINE, and LINENUM to stack
; RETURN will pull them back
S_GOSUB         .proc
                PHP
                TRACE "S_GOSUB"

                LDA CURLINE                 ; Save the current line for later
                PHA
                LDA CURLINE+2
                PHA

                CALL SKIPWS

                CALL PARSEINT               ; Get an integer line number

                LDA ARGUMENT1               ; Check the number
                BEQ syntax_err              ; If 0, no number was found... syntax error

                CALL FINDLINE               ; Try to find the line
                BCC not_found               ; If not found... LINE NOT FOUND error

                TRACE "found"

                setas                       ; Tell the interpreter to restart at the selected line
                LDA #EXEC_GOTO
                STA EXECACTION

                CALL SKIPSTMT               ; Skip to the next statement

                setal
                PLA                         ; Save the old value of CURLINE to the RETURN stack
                CALL PHRETURN
                PLA
                CALL PHRETURN

                LDA BIP+2                   ; Save the BASIC Instruction Pointer to the RETURN stack
                CALL PHRETURN
                LDA BIP
                CALL PHRETURN

                INC GOSUBDEPTH              ; Increase the count of GOSUBs on the stack

                PLP
                RETURN
syntax_err      PLA
                PLA
                THROW ERR_SYNTAX
not_found       PLA
                PLA
                THROW ERR_NOLINE
                .pend

; RETURN from a subroutine call... pulls BIP, CURLINE, and LINENUM from the stack
S_RETURN        .proc
                PHP
                TRACE "S_RETURN"

                setaxl
                LDA GOSUBDEPTH              ; Check that there is at least on GOSUB on the stack
                BEQ underflow               ; No? It's a stack underflow error

                CALL PLRETURN               ; Restore BIP, and CURLINE from the return stack
                STA BIP
                CALL PLRETURN
                STA BIP+2
                CALL PLRETURN
                STA CURLINE
                CALL PLRETURN
                STA CURLINE+2

                DEC GOSUBDEPTH              ; Indicate we've popped that GOSUB off the stack

                setas                       ; Tell the interpreter to restart at the selected line
                LDA #EXEC_RETURN
                STA EXECACTION

                PLP
                RETURN
underflow       TRACE "underflow"
                THROW ERR_STACKUNDER
                .pend

; Test an expression.
; If it's true (non-zero), execute statements after the THEN
; If if's false (zero), execute
;
; Modes:
; Simple - IF <test> THEN <line number>
S_IF            .proc
                PHP
                TRACE "S_IF"

                CALL EVALEXPR               ; Evaluate the expression
                CALL IS_ARG1_Z              ; Check to see if the result is FALSE (0)
                BEQ is_false                ; If so, handle the FALSE case

                setas
                LDA #TOK_THEN               ; Verify that the next token is THEN and eat it
                CALL EXPECT_TOK             ; If THEN is not the next token, it's a syntax error

                CALL PARSEINT               ; Get the line number
                CALL IS_ARG1_Z              ; Check that we got a valid one
                BEQ syntax_err              ; If not, we have a syntax error
                                            ; TODO: will need to be expanded to support other forms of IF

                CALL FINDLINE               ; Try to find the line
                BCC not_found               ; If not found... LINE NOT FOUND error

                TRACE "TRUE"

                setas                       ; Tell the interpreter to restart at the selected line
                LDA #EXEC_GOTO
                STA EXECACTION
                BRA done

is_false        TRACE "FALSE"
                CALL SKIPSTMT               ; Skip to the next EOL or ":"

done            PLP
                RETURN

syntax_err      THROW ERR_SYNTAX
not_found       THROW ERR_NOLINE
                .pend

; End the execution of the program
S_END           .proc
                PHP
                TRACE "S_END"

                setas                       ; Signal a stop to the interpreter
                LDA #EXEC_STOP
                STA EXECACTION

                PLP
                RETURN
                .pend

; Start executing the designated line
S_GOTO          .proc
                PHP
                TRACE "S_GOTO"

                CALL SKIPWS

                CALL PARSEINT               ; Get an integer line number

                LDA ARGUMENT1               ; Check the number
                BEQ syntax_err              ; If 0, no number was found... syntax error

                CALL FINDLINE               ; Try to find the line
                BCC not_found               ; If not found... LINE NOT FOUND error

                TRACE "foo"

                setas                       ; Tell the interpreter to restart at the selected line
                LDA #EXEC_GOTO
                STA EXECACTION

                PLP
                RETURN

syntax_err      THROW ERR_SYNTAX
not_found       THROW ERR_NOLINE
                .pend

; Reset heap and variables
S_CLR           .proc
                TRACE "S_CLR"

                CALL INITEVALSP             ; Initialize stacks
                CALL INITHEAP               ; Initialize the heap
                CALL INITVARS               ; Initialize the variables

                RETURN
                .pend

; Set a variable to a value
; Format:   LET name = expr
;           name = expr
S_LET           .proc
                PHP

                TRACE "S_LET"

                LDA [BIP]           ; Get the character
                BPL get_name        ; If it's not a token, try to find the variable name

                CALL INCBIP         ; Skip over the token

get_name        CALL VAR_FINDNAME   ; Try to find the variable name
                BCS check_array     ; If we didn't find a name, thrown an error
                JMP syntax_err

check_array     TRACE "check_array"
                setas
                CALL PEEK_TOK       ; Look ahead to the next token
                CMP #TOK_LPAREN     ; Is it a "("
                BNE get_value       ; No: it's a scalar assignment, look for the "="

                LDA #TOK_LPAREN
                CALL EXPECT_TOK     ; Skip any whitespace before the open parenthesis

                LDA #0
                STA @lARRIDXBUF     ; Blank out the array index buffer
                CALL ARR_GETIDX     ; Yes: get the array indexes

get_value       CALL SKIPWS         ; Scan for an "="
                TRACE "get_value"

                setas
                LDA [BIP]
                CMP #TOK_EQ
                BEQ found_eq        ; If not found: signal an syntax error
                JMP syntax_err

found_eq        CALL INCBIP         ; Otherwise, skip over it

                LDA TOFINDTYPE      ; Save the variable name for later
                PHA                 ; (it will get over-written by variable references)
                LDA TOFIND+2
                PHA
                LDA TOFIND+1
                PHA
                LDA TOFIND
                PHA                

                CALL EVALEXPR       ; Evaluate the expression

                PLA                 ; Restore the variable name
                STA TOFIND
                PLA
                STA TOFIND+1
                PLA
                STA TOFIND+2
                PLA
                STA TOFINDTYPE

                AND #$80            ; Is it an array we're setting?
                BEQ set_scalar      ; No: do a scalar variable set

                TRACE "set_array"
                CALL VAR_FIND       ; Try to find the array
                BCC notfound_err

                setal
                LDY #BINDING.VALUE
                LDA [INDEX],Y       ; Save the pointer to the array to CURRBLOCK
                STA CURRBLOCK
                setas
                INY
                INY
                LDA [INDEX],Y
                STA CURRBLOCK+2

                CALL ARR_SET        ; Yes: Set the value of the array cell
                BRA done            ; and we're finished!

set_scalar      TRACE "set_scalar"
                CALL VAR_SET        ; Attempt to set the value of the variable

done            TRACE_L "S_LET DONE", BIP

                PLP
                RETURN

syntax_err      THROW ERR_SYNTAX    ; Throw a syntax error
notfound_err    THROW ERR_NOTFOUND  ; Throw variable name not found
                .pend

; Print expressions to the screen
; Format: PRINT expr  -- print an expression followed by a newline
;         PRINT expr, [expr ...] -- print an expression followed by a TAB
;         PRINT expr; [expr ...]-- print an expression with no newline after
S_PRINT         .proc
                PHP
                TRACE "S_PRINT"
pr_loop         CALL EVALEXPR       ; Attempt to evaluate the expression following
                setas
                LDA ARGTYPE1        ; Get the type of the result
                CMP #TYPE_NAV       ; Is is NAV?
                BEQ check_nl        ; Yes: we are probably just printing a newline

                CMP #TYPE_STRING    ; Is it a string?
                BNE check_int       ; No: check to see if it's an integer
                CALL PR_STRING      ; Yes: print the string
                BRA check_nl

check_int       CMP #TYPE_INTEGER   ; Is it an integer?
                BNE check_float     ; No: check to see if it is a float
                CALL PR_INTEGER     ; Print the integer in ARGUMENT1
                BRA check_nl

check_float     ; TODO: process floats and any other printable types
                BRA done

                ; Check for the next non-whitespace... should be a null, colon, comma, or semicolon
check_nl        CALL SKIPWS
                LDA [BIP]
                BEQ pr_nl_exit      ; If it's nul, print a newline and return
                CMP #':'            ; If it's a colon
                BEQ pr_nl_exit      ; print a newline and return
                CMP #','            ; If it's a comma
                BEQ pr_comma        ; Print a TAB and try another expression
                CMP #';'            ; If it's a semicolon...
                BEQ is_more         ; Print nothing, and try another expression

                THROW ERR_SYNTAX    ; If we get here, we don't have a well formed statement

pr_comma        LDA #CHAR_TAB       ; Print a TAB
                CALL PRINTC

is_more         CALL INCBIP         ; Skip the separator
                CALL SKIPWS         ; Skip any whitespace
                LDA [BIP]           ; Get the character
                BEQ done            ; If it's NULL, return without printing a newline
                LDA #':'            ; If it's a colon
                BEQ done            ; ... return without printing a newline
                BRA pr_loop         ; Otherwise, we should have another expression, try to handle it

pr_nl_exit      CALL PRINTCR        ; Print the newline and finish

done            PLP
                RETURN
                .pend

;
; Print a string in ARGUMENT1
;
; Inputs:
;   ARGUMENT1 = pointer to a string to print
;
PR_STRING       .proc
                PHP
                PHB
                TRACE_L "PR_STRING",ARGUMENT1

                setdp GLOBAL_VARS

                setas
                setxl
                LDY #0

loop            LDA [ARGUMENT1],Y
                BEQ done
                CALL PRINTC
                INY
                BRA loop

                ; setas               ; Get the data bank for the string
                ; LDA ARGUMENT1+2
                ; PHA
                ; PLB

                ; setxl
                ; LDX ARGUMENT1     ; Get the pointer to the string
                ; CALL PRINTS         ; And print it

done            PLB
                PLP
                RETURN
                .pend

;
; Print an integer in ARGUMENT1
;
; Inputs:
;   ARGUMENT1 = pointer to a string to print
;
PR_INTEGER      .proc
                PHP

                setal
                CALL ITOS           ; Convert the integer to a string

                LDA STRPTR          ; Copy the pointer to the string to ARGUMENT1
                STA ARGUMENT1
                LDA STRPTR+2
                STA ARGUMENT1+2
                CALL PR_STRING      ; And print it

                PLP
                RETURN
                .pend
