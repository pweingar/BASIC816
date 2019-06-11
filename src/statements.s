;;;
;;; Core BASIC Statements
;;;

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

                setas

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
                JMP error

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

                setas               ; Push the ending value
                LDA ARGTYPE1
                CALL PHRETURNB
                setal
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

                CALL SKIPWS
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

                setaxl

                ; Get the final value

                LDY RETURNSP                    ; Y := pointer to first byte of the FOR record
                INY                             ; RETURNSP points to the first free slot, so move up 2 bytes
                INY

                LDA #FOR_RECORD.FINAL,B,Y       ; ARGUMENT2 := FOR_RECORD.FINAL
                STA ARGUMENT2
                LDA #FOR_RECORD.FINAL+2,B,Y
                STA ARGUMENT2+2
                setas
                LDA #FOR_RECORD.FINALTYPE,B,Y
                STA ARGTYPE2

                ; Get the variable and its current value

                LDA #FOR_RECORD.VARIBLE,B,Y     ; TOFIND := FOR_RECORD.VARIABLE
                STA TOFIND
                LDA #FOR_RECORD.VARIBLE+2,B,Y
                setas
                STA TOFIND+2
                LDA #FOR_RECORD.VARTYPE,B,Y
                STA TOFINDTYPE

                CALL VAR_REF                    ; Get the value of the variable

                LDX #ARGUMENT1
                CALL PHARGUMENT                 ; Save the value for later

                CALL OP_MINUS                   ; Are they equal?
                CALL IS_ARG1_Z
                BEQ end_loop                    ; Yes: end the loop

                ; Not at end, so add the increment, reassign, and loop

loop_back       TRACE "loop back"

                LDX #ARGUMENT1
                CALL PLARGUMENT                 ; Restore the value of the variable

                LDY RETURNSP
                INY
                INY

                LDA #FOR_RECORD.INCREMENT,B,Y   ; ARGUMENT2 := FOR_RECORD.INCREMENT
                STA ARGUMENT2
                LDA #FOR_RECORD.INCREMENT+2,B,Y
                STA ARGUMENT2+2
                setas
                LDA #FOR_RECORD.INCTYPE,B,Y
                STA ARGTYPE2

                CALL OP_PLUS                    ; Add the increment to the current value
                CALL VAR_SET                    ; Assign the new value to the variable

                LDY RETURNSP
                INY
                INY
                
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

                LDA CURLINE+2               ; Save the current line for later
                PHA
                LDA CURLINE
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
                BCS else            ; If we didn't find a name, thrown an error
                JMP error

else            CALL SKIPWS         ; Scan for an "="
                setas
                LDA [BIP]
                CMP #TOK_EQ
                BNE error           ; If not found: signal an syntax error

                CALL INCBIP         ; Otherwise, skip over it
                CALL EVALEXPR       ; Evaluate the expression
                CALL VAR_SET        ; Attempt to set the value of the variable

                TRACE "S_LET DONE"

                PLP
                RETURN

error           THROW ERR_SYNTAX    ; Throw a syntax error
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

is_more         CALL SKIPWS         ; Skip any whitespace
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
