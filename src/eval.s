;;;
;;; Routines to evaluate BASIC
;;;

;
; Evaluate expressions using the Dijkstra Shunting-yard Algorithm
;
; See: http://csis.pace.edu/~murthy/ProgrammingProblems/16_Evaluation_of_infix_expressions
;

;
; Initialize the evaluation stacks
;
; Set the arguments to non-a-value
;
INITEVALSP  .proc
            PHP

            setal
            LDA #ARGUMENT_TOP
            STA ARGUMENTSP

            LDA #OPERATOR_TOP
            STA OPERATORSP

            ; Set ARGUMENT1 and ARGUMENT2 to non-values
            LDA #$FFFF
            STA ARGUMENT1
            STA ARGUMENT1+2
            STA ARGUMENT2
            STA ARGUMENT2+2
            
            setas
            STA ARGTYPE1
            STA ARGTYPE2

            PLP
            RETURN
            .pend

;
; Push the value in an argument variable to the argument stack
;
; Argument stack grows DOWN from a starting point
;
; Inputs:
;   X = pointer to the argument to push
;   ARGUMENTSP = the argument stack pointer
;
PHARGUMENT  .proc
            TRACE_X "PHARGUMENT"
            PHP
            PHD
            PHB

            setdp GLOBAL_VARS
            setdbr `GLOBAL_VARS

            setaxl
            PHY

            LDY ARGUMENTSP

            LDA #0,B,X
            STA #0,B,Y
            LDA #2,B,X
            STA #2,B,Y

            setas
            LDA #4,B,X
            STA #4,B,Y

            setal
            SEC
            TYA
            SBC #ARGUMENT_SIZE
            STA ARGUMENTSP

            PLY
            PLB
            PLD
            PLP
            RETURN
            .pend

;
; Pull a value from the argument stack and into an argument variable
;
; Argument stack grows DOWN from a starting point
;
; Inputs:
;   X = pointer to the argument variable to fill
;   ARGUMENTSP = the argument stack pointer
;
PLARGUMENT  .proc
            PHP
            PHD
            PHB
            TRACE "PLARGUMENT"

            setdp GLOBAL_VARS
            setdbr `GLOBAL_VARS

            setaxl
            PHY

            CLC
            LDA ARGUMENTSP
            ADC #ARGUMENT_SIZE
            STA ARGUMENTSP
            TAY

            LDA #0,B,Y
            STA #0,B,X
            LDA #2,B,Y
            STA #2,B,X            

            setas
            LDA #4,B,Y
            STA #4,B,X

            LDA #0,B,X
            TRACE_X "PLARGUMENT"

            PLY
            PLB
            PLD
            PLP
            RETURN
            .pend

;
; Remove the top item from the argument stack
;
POPARGUMENT .proc
            PHP
            TRACE "POPARGUMENT"
            setal

            CLC
            LDA ARGUMENTSP
            ADC #ARGUMENT_SIZE
            STA ARGUMENTSP

            PLP
            RETURN
            .pend

;
; Push an operator onto the operator stack.
;
; Inputs:
;   A = the operator's token code
;   OPERATORSP = the operator stack pointer
;
PHOPERATOR  .proc
            TRACE_A "PHOPERATOR"
            PHP
            PHD
            PHB

            setdp GLOBAL_VARS
            setdbr `GLOBAL_VARS

            setas
            setxl
            PHY

            LDY OPERATORSP
            STA #0,B,Y
            DEY
            STY OPERATORSP

done        PLY
            PLB
            PLD
            PLP
            RETURN
            .pend

;
; Pull an operator from the operator stack.
;
; Inputs:
;   OPERATORSP = the operator stack pointer
;
; Outputs:
;   A = the operator token code
;
PLOPERATOR  .proc
            PHP
            PHD
            PHB

            setdp GLOBAL_VARS
            setdbr `GLOBAL_VARS

            setas
            setxl
            PHY

            LDY OPERATORSP
            INY
            STY OPERATORSP
            LDA #0,B,Y

            setal
            AND #$00FF

            TRACE_A "PLOPERATOR"

            PLY
            PLB
            PLD
            PLP
            RETURN
            .pend

;
; Flag the beginning of processing function and array parameter lists.
; Pushes TOK_FUNC_OPEN "token" to the operator stack to save the position prior
; to evaluating the function or array reference.
;
OPENPARAMS  .proc
            PHP
            TRACE "OPENPARAMS"

            setas
            LDA #TOK_FUNC_OPEN  ; Push the "operator" marker for the start of the function
            CALL PHOPERATOR

            PLP
            RETURN
            .pend

;
; Close out the processing of function and array parameter lists.
; Removes TOK_FUNC_OPEN from the operator stack.
;
CLOSEPARAMS .proc
            PHY
            PHP
            PHB
            TRACE "CLOSEPARAMS"

            setdbr 0

            setas
            LDY OPERATORSP      ; Peek at the top operator
            LDA #1,B,Y
            CMP #TOK_FUNC_OPEN  ; Is it the marker for the start of a parameter list
            BNE error           ; No: there's a problem

            setal
            INC OPERATORSP      ; Yes: remove it from the operator stack.

            PLB
            PLP
            PLY
            RETURN
error       THROW ERR_SYNTAX    ; Throw a syntax error (TODO: is this the right error type?)
            .pend

;
; Return true if the current operator's precedence is lower than the current top
; of the operator stack. Return false if nothing is on the stack, or the top of
; stack is lower precendence.
;
; Inputs:
;   A = the token of the current operator
;   OPERATORSP = the operator stack pointer
;
; Outputs:
;   C is set if the condition is true, clear otherwise.
;
OPHIGHPREC  .proc
            PHA
            PHP
            PHD
            PHB

            TRACE_A "OPHIGHPREC"

            setdp GLOBAL_VARS
            setdbr `GLOBAL_VARS

            setas

            LDY OPERATORSP
            CPY #OPERATOR_TOP       ; Is the stack empty?
            BEQ is_false            ; Yes: return false

            CALL TOKPRECED          ; Get the precedence for the passed operator
            STA SCRATCH             ; Save it for later comparison

            LDA #1,B,Y              ; Get the operator at the top of the stack
            CALL TOKPRECED          ; Get the precedence for the operator at TOS

            CMP SCRATCH             ; Compare the priorities (0 = highest priority)
            BEQ is_false            ; A = SCRATCH, return false
            BCC is_true             ; A < SCRATCH (A is higher priority), return false

is_false    setal
            PLB
            PLD
            PLP
            PLA
            CLC
            RETURN

is_true     setal
            PLB                     ; A > SCRATCH (A is lower priority), return true
            PLD
            PLP
            PLA
            SEC
            RETURN
            .pend

;
; Evaluate a number
;
; NOTE: at the moment, this just parses simple integers.
; It will have to be updated to parsing floating point numbers.
;
; Inputs:
;   BIP = pointer to the first digit of the number
;
; Outputs:
;   ARGUMENT1 = the value of the number read.
;
EVALNUMBER  .proc
            TRACE "EVALNUMBER"
            JMP PARSEINT            
            .pend

;
; Build the array index buffer for array references and sets
;
; Inputs:
;   BIP
;   ARRIDXBUF
;
ARR_GETIDX  .proc
            PHP
            TRACE "ARR_GETIDX"

            ; Build the array index buffer
            setas
            LDA #0
            STA @lARRIDXBUF     ; Set the dimension to 0

            LDX #1
eval_index  CALL EVALEXPR       ; Evaluate the index
            CALL ASS_ARG1_INT16 ; Make sure it works out to be an integer

            setal
            LDA ARGUMENT1       ; Save the index to the array index buffer
            STA @lARRIDXBUF,X

            setas
            LDA @lARRIDXBUF     ; Increment the index count
            INC A
            BMI arg_err         ; If more than 127 dimensions, throw a range error
            STA @lARRIDXBUF
            INX
            INX

            CALL SKIPWS         ; Skip any whitespace

            setas
            LDA [BIP]           ; Check the next character
            CMP #TOK_RPAREN     ; Is it ")"
            BEQ clean_op        ; Yes: cleanup the argument stack
            CMP #','            ; Is it a comma?
            BNE syntax_err      ; No: throw a syntax error

skip_comma  CALL INCBIP         ; Skip the comma
            BRA eval_index      ; And grab the next index

clean_op    CALL INCBIP         ; Skip the trailing ")"
            TRACE "/ARR_GETIDX"

            PLP
            RETURN
syntax_err  THROW ERR_SYNTAX
arg_err     THROW ERR_ARGUMENT
            .pend

;
; Attempt to evaluate a variable reference
;
EVALREF     .proc
            PHP
            TRACE_L "EVALREF", BIP

get_name    CALL VAR_FINDNAME   ; Try to find the variable name
            BCC syntax_err      ; If we didn't find a name, thrown an error

            setas
            LDA TOFINDTYPE      ; Check the type of the variable
            AND #$80            ; Is it an array?
            BNE is_array        ; Yes: look for the indexes

            CALL VAR_REF        ; No: Get the value of the variable (scalar)
            JMP done

is_array    setas
            LDA #TOK_LPAREN
            CALL EXPECT_TOK     ; Skip any whitespace before the open parenthesis

            CALL OPENPARAMS     ; Start processing the array indexes

            ; Build the array index buffer
            PHARRIDX            ; Save the previous array index buffer
            CALL ARR_GETIDX
            CALL ARR_REF        ; And grab the value from the array
            PLARRIDX            ; Restore the old array index buffer

            CALL CLOSEPARAMS    ; Stop procssing the array indexes

done        PLP
            RETURN
syntax_err  THROW ERR_SYNTAX
            .pend

;
; Evaluate a string literal
;
EVALSTRING  .proc
            PHP
            PHD
            TRACE "EVALSTRING"

            setdp GLOBAL_VARS

            setas
            setxl
            CALL INCBIP         ; Move BIP past the initial quote
            LDY #0              ; Ywill be our length counter

count_loop  LDA [BIP],Y         ; Get the character
            BEQ error           ; If it's end-of-line, throw an error
            CMP #CHAR_DQUOTE    ; Is it the ending double-quote?
            BEQ found_end       ; Yes: Y should be the length
            INY
            BRA count_loop

found_end   STY SCRATCH         ; Save the length to SCRATCH

            setas
            LDA #TYPE_STRING    ; Set the type to allocate to STRING
            LDX SCRATCH         ; And the length to the length of the string literal
            INX
            CALL TEMPSTRING     ; Get a temporary string

            LDY #0
copy_loop   CPY SCRATCH         ; Have we copied all the characters?
            BEQ done            ; Yes: we're done
            LDA [BIP]           ; No: get the next character
            STA [STRPTR],Y      ; And copy it to the allocated string
            INY
            CALL INCBIP
            BRA copy_loop       ; And try the next character

error       THROW ERR_SYNTAX    ; Throw a syntax error

done        LDA #0
            STA [STRPTR],Y

            MOVE_D ARGUMENT1,STRPTR ; Save the pointer to the string in ARGUMENT1
            LDA #TYPE_STRING    ; And set the type of ARGUMENT1 to string
            STA ARGTYPE1

            CALL INCBIP         ; Skip over the closing quote

            PLD
            PLP
            RETURN
            .pend

;
; Evaluate a function
;
; Inputs:
;   BIP = pointer to the token for the function
;
; Outputs:
;   ARGUMENT1 = the value of the function
;   BIP = pointer to the first byte after the function call
;
EVAL_FUNC   .proc
            PHP
            TRACE "EVAL_FUNC"

            setas
            LDA [BIP]           ; Get the token

            setal
            AND #$00FF
            CALL TOKEVAL        ; Get the subroutine to evaluate the function
            STA JMP16PTR

            CALL OPENPARAMS     ; Start processing the function argument list

            setdbr 0
            CALL OPSTUB         ; Call the opcode's evaluation function via the indirection stub

            CALL CLOSEPARAMS    ; Stop processing the function argument list

            PLP
            RETURN

OPSTUB      CALL INCBIP         ; Skip past the token
            JMP (JMP16PTR)      ; Annoying JMP to get around the fact we don't have an indirect JSR
            .pend

;
; Process an operator on top of the stack
;
; Inputs:
;   OPERATORSP = points to the operator to process
;   ARGUMENTSP = points to TWO arguments for the operator
;
; Outputs:
;   ARGUMENTSP = points to the result of the operator
;
PROCESSOP   .proc
            TRACE "PROCESSOP"
            PHA
            PHP
            PHD
            PHB

            setdp GLOBAL_VARS

            setaxl
            CALL PLOPERATOR     ; Pull the operator from the stack
            BIT #$80            ; Check if it's really a token
            BPL bad_token       ; No: it's a bad token

            PHA

            CALL TOKEVAL        ; Get the address of the token's evaluation function
            STA JMP16PTR

            PLA
            CALL TOKARITY       ; Get the token's arity
            CMP #1              ; Check the operator's arity
            BEQ pull_arg1       ; If it's 1 just pull one argument from the stack

            setaxl
            LDX #<>ARGUMENT2    ; Pull argument 2 from the stack
            CALL PLARGUMENT

pull_arg1   setaxl
            LDX #<>ARGUMENT1    ; Pull argument 1 from the stack
            CALL PLARGUMENT

            setdbr 0
            CALL OPSTUB         ; Call the opcode's evaluation function via the indirection stub

            LDX #<>ARGUMENT1    ; Get return result in argument 1
            CALL PHARGUMENT     ; And push it back to the argument stack

            PLB
            PLD
            PLP
            PLA
            RETURN

bad_token   BRK
            NOP

OPSTUB      JMP (JMP16PTR)      ; Annoying JMP to get around the fact we don't have an indirect JSR
            .pend

;
; Try to evaluate an expression
;
; Inputs:
;   BIP = pointer to the first character to check for the expression
;   OPERATORSP = pointer to current position in the operator stack
;   ARGUMENTSP = pointer to the current position in the argument stack
;
; Outputs:
;   ARGUMENTSP = top contains the value of the expression
;
EVALEXPR    .proc
            PHP
            TRACE_L "EVALEXPR", BIP

            setdp GLOBAL_VARS
            setdbr `GLOBAL_VARS

            setxl
            PHX

get_char    setas
            LDA [BIP]           ; Get the character
            BNE else1           
            JMP proc_stack      ; Handle end of line, if we see it
else1       BMI is_token        ; If MSB is set, it's a token

            CMP #' '            ; Is it a space?
            BNE else2           
            JMP next_char       ; Yes: Skip to the next character

else2       CMP #'9'+1          ; Check to see if we have digits
            BCS else3           ; No: treat as the end of the line
            CMP #'0'
            BCS is_digit

else3       CMP #'&'            ; Check for a hexadecimal prefix
            BEQ is_digit

            CMP #'"'            ; Is it a double-quote?
            BNE else4
            JMP is_string       ; Yes: process the string

            ; TODO: what happens here? For the moment, treat it as end-of-line
else4       CMP #'Z'+1          ; Check to see if we have upper case alphabetics
            BCS check_lc        ; No: check for lower case
            CMP #'A'
            BCC check_lc
            JMP is_alpha

check_lc    CMP #'z'+1          ; Check to see if we have lower case alphabetics
            BCS else5           ; No: treat as the end of the line
            CMP #'a'
            BCC else5
            JMP is_alpha

else5       JMP proc_stack

            ; A token has been seen
is_token    CMP #TOK_LPAREN     ; Is it an LPAREN
            BEQ is_lparen       ; Yes: handle the LPAREN

            CMP #TOK_RPAREN     ; Is it an RPAREN?
            BEQ is_rparen       ; Yes: handle the RPAREN

            CALL TOKTYPE        ; Get the token type
            CMP #TOK_TY_FUNC    ; Is it a function?
            BNE chk_op          ; No: check if it's an operator

            CALL EVAL_FUNC      ; Yes: evaluate the function
            LDX #<>ARGUMENT1
            CALL PHARGUMENT     ; And push it to the argument stack
            JMP get_char

chk_op      CMP #TOK_TY_OP      ; Is it an operator?
            BNE proc_stack      ; No: we're finished processing

            LDA [BIP]           ; Yes: Get the token back

chk_prec    LDX OPERATORSP      ; Is the operator stack empty?
            CPX #<>OPERATOR_TOP
            BEQ push_op         ; Yes: push the operator

            CALL OPHIGHPREC     ; Check to see if operator has a higher precedence than the top of operator stack
            BCS process1        ; No: we should process the top operator

push_op     CALL PHOPERATOR     ; Yes: should push the operator
            BRA next_char       ; And go to the next character

            ; Digit has been seen... read a number literal and push it
            ; to the argument stack
is_digit    setal
            CALL PARSENUM       ; Try to evaluate the number
got_number  LDX #<>ARGUMENT1
            CALL PHARGUMENT     ; And push it to the argument stack
            BRA get_char

            ; Process the top operator
process1    CALL PROCESSOP      ; Process the operator at the top of the stack
            BRA chk_prec        ; And check what to do with the current operator

            ; Handle an LPAREN token
is_lparen   CALL PHOPERATOR     ; Push the LPAREN to the operator stack
            BRA next_char

            ; Handle the RPAREN token by processing the stack until we get to the "("
is_rparen   setas

            LDY OPERATORSP      ; Is the operator stack empty?
            CPY #<>OPERATOR_TOP
            BEQ done            ; Yes: we're done evaluating things
                                ; (this is a close paren for a function, maybe)

paren_loop  LDY OPERATORSP      ; Peek at the top operator
            LDA #1,B,Y
            CMP #TOK_FUNC_OPEN  ; Is it the LPAREN of a function?
            BEQ done            ; Yes: treat it as an empty stack
            CMP #TOK_LPAREN     ; Is it an LPAREN?
            BEQ done_rparen     ; Yes: we're finished processing

            CALL PROCESSOP
            BRA paren_loop

done_rparen CALL PLOPERATOR     ; We've found the LPAREN... pop it off the stack

next_char   CALL INCBIP         ; Point to the next character
            JMP get_char

            ; Process all the operators on the stack and quit
proc_stack  TRACE "proc_stack"
            LDX OPERATORSP      ; Is the operator stack empty?
            CPX #<>OPERATOR_TOP
            BGE done            ; Yes: return to the caller
            LDA #1,B,X
            CMP #TOK_FUNC_OPEN  ; Is top operator a function open?
            BEQ done            ; Yes: treat as end of expression

            CALL PROCESSOP      ; No: process the operator stack
            BRA proc_stack

            ; We found a string... read it
is_string   CALL EVALSTRING     ; Get the pointer to the evaluated string
            TRACE "/EVALSTRING"
            LDX #<>ARGUMENT1
            CALL PHARGUMENT     ; And push it to the argument stack
            JMP get_char

            ; We found an alphabetic character... treat it as a variable reference
is_alpha    CALL EVALREF        ; Attempt to evaluate the variable reference
            LDX #<>ARGUMENT1
            CALL PHARGUMENT     ; And push it to the argument stack
            JMP get_char     

done        LDX #<>ARGUMENT1    ; Make sure the result is off the stack
            CALL PLARGUMENT     ; And in ARGUMENT1

            TRACE "/EVALEXPR"
            PLX
            PLP
            RETURN
            .pend