;;;
;;; Core BASIC Statements
;;;

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
                CALL PUTC

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

                setas               ; Get the data bank for the string
                LDA ARGUMENT1+2
                PHA
                PLB

                LDX ARGUMENT1       ; Get the pointer to the string
                CALL PRINTS         ; And print it

                PLB
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

                ; TODO: print a decimal representation of ARGUMENT1

                PLP
                RETURN
                .pend