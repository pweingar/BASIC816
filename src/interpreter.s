;;;
;;; Core of the BASIC interpreter
;;;

ST_RUNNING = $80            ; The interpreter is running a full program
ST_INTERACT = $00           ; The interpreter is in interactive mode

.section globals
STATE       .byte ?         ; The state of the interpreter ()
ERROR       .byte ?         ; The type of the error
HANDLEERR   .long ?         ; Pointer to the error handler
LINENUM     .word ?         ; The current line number
LASTLINE    .long ?         ; Pointer to the next free space over the BASIC program
EXECACTION  .byte ?         ; The action the exection routines should take to get their next statement
                            ; One of EXEC_CONT, EXEC_STOP, or EXEC_GOTO. Default is EXEC_CONT, but may be
                            ; set to EXEC_STOP or EXEC_GOTO by the statements.
.send

;
; Line format:
; LINK      .word ?         ; 2 Byte offset to next line in the program
; NUMBER    .word ?         ; 2 Byte line number
; TOKENS    .byte ?         ; Tokenized text of the line
; EOL       .byte 0         ; end of line indicator (NULL)
;

LINE_LINK = 0               ; Offset to the link to the next line
LINE_NUMBER = 2             ; Offset to the line number
LINE_TOKENS = 4             ; Offset to the first token
LINE_MINLEN = 6             ; Minimum length of a line

; EXECLINE status codes
EXEC_CONT = 0               ; Continue advancing the current line
EXEC_STOP = 1               ; Stop execution of the program
EXEC_GOTO = 2               ; Transfer execution to a new CURLINE that is already set

; Point to a new error handler
CATCH       .macro ; handler
            PHP
            setal
            LDA #<>\1
            STA @lHANDLEERR
            setas
            LDA #`\1
            STA @lHANDLEERR+2
            PLP
            .endm

; Throw an error of type errcode
THROW       .macro ; errcode
            PHP
            PHD
            setdp <>GLOBAL_VARS
            setas
            LDA #\1
            STA ERROR
            PLD
            PLP
            JMP [HANDLEERR]
            .endm

;
; Set the status of the interpreter to running
;
SETRUN      .proc
            PHP
            PHD

            setdp <>GLOBAL_VARS
            setas
            LDA #ST_RUNNING
            STA STATE

            PLD
            PLP
            RETURN
            .pend

;
; Set the status of the interpreter to interactive
;
SETINTERACT .proc
            PHP
            PHD

            setdp <>GLOBAL_VARS
            setas
            LDA #ST_INTERACT
            STA STATE

            PLD
            PLP
            RETURN
            .pend

;
; Initialize the interpreter
;
INITINTERP  .proc
            PHP
            PHD

            setdp <>GLOBAL_VARS

            CALL SETINTERACT            ; Set mode to interactive
            
            setal
            STZ LINENUM                 ; Clear the current line number
        
            CALL CMD_NEW                ; Clear out the program and variable space
            
            PLD
            PLP
            RETURN
            .pend

;
; Default error handler.
; Print the error message, reset the stacks, and launch the command line
;
ON_ERROR    .proc
            TRACE "ON_ERROR"

            setas
            setxl
            LDA ERROR
            ASL A
            TAY

            LDX ERRORMSG,Y
            CALL PRINTS

ERRLOCK     JMP ERRLOCK

ERRORMSG    .word <>MSG_OK
            .word <>MSG_SYNTAX
            .word <>MSG_MEMORY
            .word <>MSG_TYPE
            .word <>MSG_NOTFND
            .word <>MSG_NOLINE

MSG_OK      .null "OK"
MSG_SYNTAX  .null "SYNTAX"
MSG_MEMORY  .null "OUT OF MEMORY"
MSG_TYPE    .null "TYPE MISMATCH"
MSG_NOTFND  .null "NOT FOUND"
MSG_NOLINE  .null "LINE NUMBER NOT FOUND"
            .pend

;
; Increment the BASIC Instruction Pointer
;
INCBIP      .proc
            PHP
            PHD

            setdp <>GLOBAL_VARS

            INC_L BIP

            PLD
            PLP
            RETURN
            .pend

;
; Skip any white space found in the current BASIC line
;
SKIPWS      .proc
            PHP
            PHD

            setdp <>GLOBAL_VARS

            setas
loop        LDA [BIP]
            BEQ done            ; If character is 0, we've reached the end of the line

            CMP #CHAR_SP        ; Skip if it's a space
            BEQ skip_char

            CMP #CHAR_TAB       ; Skip if it's a TAB
            BEQ skip_char

            BRA done            ; Otherwise, we're done and BIP points to a non-whitespace

skip_char   CALL INCBIP
            BRA loop

done        PLD
            PLP
            RETURN
            .pend

; Skip to the next colon or end-of-line marker
SKIPSTMT    .proc
            PHP

            setas
loop        LDA [BIP]           ; Check the current character
            BEQ done            ; Is it EOL? Yes, we're done
            CMP #':'            ; Is it a colon?
            BEQ done            ; Yes, we're done
            CALL INCBIP         ; Otherwise, point to the next character of the line
            BRA loop            ; and check it...

done        PLP
            RETURN
            .pend

; Expect the next non-whitespace byte to be the token in A
; Point BIP to the character immediately after the token
; Throw a syntax error if anything else
EXPECT_TOK  .proc
            PHP

            setas

            PHA
            CALL SKIPWS         ; Skip over leading white space
            PLA

            setas
            CMP [BIP]           ; Check the character at BIP
            BNE syntax_err      ; Throw a syntax error

            CALL INCBIP         ; Skip over the token
            CALL SKIPWS

            PLP
            RETURN
            
syntax_err  THROW ERR_SYNTAX
            .pend

;
; Execute a statement or command
;
; Inputs:
;   BIP = pointer to the line fragment to interpret
;
; Output:
;   BIP = pointer to the remaining line to execute (points to a delimiter, or 0)
;   EXECACTION = execution status to indicate how the interpreter should handle finding the next statement to run
;       EXEC_CONT - Execute the next statement
;       EXEC_GOTO - CURLINE has been set to the new line to start executing
;       EXEC_STOP - the interpreter should stop execution and return to the command parser
;
EXECSTMT    .proc
            PHP
            PHD
            PHB
            TRACE "EXECSTMT"

            setdp <>GLOBAL_VARS

            setas               ; Set EXECACTION to EXEC_CONT, the default behavior
            LDA #EXEC_CONT      ; This will tell EXECLINE and EXECPROG to procede in a
            STA EXECACTION      ; linear fashion through the program

            CALL SKIPWS
            LDA [BIP]
            BNE else
            JMP done            ; If the current byte is 0, we're at the end of the line, just return

else        CALL ISALPHA        ; Is it alphabetic?
            BCS is_variable     ; Yes: we may have a LET statement

            LDA [BIP]           ; Check to see if it's any other non-token
            BPL error           ; Yes: it's a syntax error

            CALL TOKTYPE        ; Get the token type

            CMP #TOK_TY_STMNT   ; Is it a statement?
            BNE else2     
            JMP ok_to_exec      ; Yes: it's ok to try to execute it

else2       LDA STATE           ; Check to see if we're in interactive mode
            BPL is_interact

            ; Interpreter is running a program. Only statements are allowed. 

error       THROW ERR_SYNTAX    ; Throw a syntax error

is_variable CALL S_LET          ; Try to execute a LET statement
            JMP done

STSTUB      setdbr `GLOBAL_VARS
            JMP (JMP16PTR)      ; Annoying JMP to get around the fact we don't have an indirect JSR

is_interact CMP #TOK_TY_CMD     ; Is it a command?
            BNE error           ; If not, it's an error

ok_to_exec  LDA [BIP]           ; Get the original token again
            CALL TOKEVAL        ; Get the execution vector for the statement or command
            setal
            STA JMP16PTR        ; Store it in the jump pointer
            CALL INITEVALSP     ; Initialize expression evaluation stack and arguments
            CALL INCBIP

            CALL STSTUB         ; And call the subroutine to execute the statement or command

done        PLB
            PLD
            PLP
            RETURN
            .pend

;
; Execute line
;
; Inputs:
;   CURLINE = pointer to the line to execute
;
; Outputs:
;   EXECACTION = execution status to indicate how the interpreter should handle finding a new line to execute:
;       EXEC_CONT - Execute the next line program
;       EXEC_GOTO - CURLINE has been set to the new line to start executing
;       EXEC_STOP - the interpreter should stop execution and return to the command parser
;
EXECLINE    .proc
            PHP

            setal
            LDY #LINE_NUMBER            ; Set the current line number
            LDA [CURLINE],Y
            STA LINENUM
            TRACE_A "EXECLINE"

            CLC                         ; Set the BASIC Instruction Pointer to the first byte of the line
            LDA CURLINE
            ADC #LINE_TOKENS
            STA BIP
            setas
            LDA CURLINE+2
            ADC #0
            STA BIP+2

exec_loop   CALL EXECSTMT               ; Try to execute a statement

            setas                       ; Check EXECACTION (set by statements)
            LDA EXECACTION
            CMP #EXEC_CONT              ; If it's not EXEC_CONT, exit to the caller
            BNE done

            setas
            CALL SKIPWS                 ; Skip any whitespace
            LDA [BIP]                   ; Get the current character in the line
            BEQ done                    ; If it's NULL, we're done

            CMP #':'                    ; If it's colon, we have more statements
            BEQ skip_loop               ; Skip over it and try to execute the next one

            TRACE "THROW ERR_SYNTAX"
            THROW ERR_SYNTAX            ; Something unexpected... throw syntax error

skip_loop   CALL INCBIP                 ; Skip over the colon
            BRA exec_loop               ; And try to execute another statement

done        TRACE "EXECLINE DONE"
            PLP
            RETURN
            .pend

;
; Starting with the line indicated by CURLINE, execute the BASIC program.
;
; Inputs:
;   CURLINE = the pointer to the line to start executing
;
EXECPROGRAM .proc
            PHP
            TRACE "EXECPROGRAM"
            setas                       ; Set interpreter state to RUNNING
            LDA #ST_RUNNING
            STA STATE

            setaxl
exec_loop   LDY #LINE_NUMBER
            LDA [CURLINE],Y             ; Get the line number of the current line
            BEQ done                    ; If it's 0, we are finished running code (implicit END)

            CALL EXECLINE               ; Execute the current line

            setas
            LDA EXECACTION              ; Check the EXECACTION from the last line
            CMP #EXEC_STOP              ; Stop execution of the program?
            BEQ done
            CMP #EXEC_GOTO              ; Transfer execution to a new CURLINE that is already set
            BEQ exec_loop

            ; Queue the next line in the program to execute
            setal                       ; CURLINE := CURLINE + [CURLINE].LINK
            LDY #LINE_LINK
            CLC
            LDA CURLINE
            ADC [CURLINE],Y
            STA CURLINE
            setas
            LDA CURLINE+2
            ADC #0
            STA CURLINE+2

            BRA exec_loop               ; And try to execute that line

done        setas
            LDA #ST_INTERACT            ; Set interpreter state to RUNNING
            STA STATE
            PLP
            RETURN
            .pend

;
; Find a specific line in the program
;
; Inputs:
;   CURLINE = pointer to the current line being processed (should be BASIC_BOT if none)
;   ARGUMENT1 = the number of the line to find
;
; Outputs:
;   C is set if the line was found, clear otherwise
;   CURLINE = the pointer to the beginning of the line (if found)
;
FINDLINE    .proc
            PHP
            setal
            LDA CURLINE
            TRACE_A "FINDLINE"

            MOVE_L INDEX,CURLINE        ; INDEX := CURLINE

            setal
            LDA LINENUM                 ; Compare the target to the current line number
            CMP ARGUMENT1
            BEQ ret_true                ; If they're the same, just return true
            BGE next_line               ; If LINENUM < target line, it must be after the current line

            LDA #<>BASIC_BOT            ; INDEX points to the first line of the program
            STA INDEX
            setas
            LDA #`BASIC_BOT
            STA INDEX+2

            setal
check_nmbrs LDY #LINE_NUMBER            ; Get the number of the possible target line
            LDA [INDEX],Y
            CMP ARGUMENT1               ; Compare it to the target line number
            BEQ found
            BGE ret_false               ; If the line number > target line number, the line is not present

next_line   setal                       ; The line may still be further in the program
            LDY #LINE_LINK              ; INDEX := INDEX + [INDEX].LINK
            CLC
            LDA INDEX
            ADC [INDEX],Y
            STA SCRATCH
            setas
            LDA INDEX+2
            ADC #0
            STA INDEX+2
            setal
            LDA SCRATCH
            STA INDEX
            BRA check_nmbrs             ; And go back to check the new line INDEX is pointing to

found       MOVE_L CURLINE,INDEX        ; INDEX points to the line we want, so....
                                        ; CURLINE := INDEX

ret_true    PLP                         ; Return true to indicate we've found the line
            SEC
            RETURN

ret_false   PLP
            CLC
            RETURN
            .pend

;
; Move lines in the BASIC program down by a number of bytes
;
; Inputs:
;   INDEX = lowest address in the destination range
;   SCRATCH = lowest address in the source range
;   BIP = highest source address to move
;
MVPROGDN    .proc
            PHP
            TRACE "MVPROGDN"

            setas
mvd_loop    LDA [SCRATCH]       ; Move a byte
            STA [INDEX]

            setal               ; Check to see if we've moved the last byte
            LDA SCRATCH
            CMP BIP
            BNE increment
            setas
            LDA SCRATCH+2
            CMP BIP+2
            BEQ done            ; Yes: return

increment   INC_L SCRATCH       ; No: increment SCRATCH
            INC_L INDEX         ; Increment INDEX

            BRA mvd_loop        ; And try again         

done        PLP
            RETURN
            .pend

;
; Move lines in the BASIC program up by a number of bytes
;
; Inputs:
;   INDEX = highest address in the destination range
;   SCRATCH = highest address in the source range
;   BIP = lowest source address to move
;
MVPROGUP    .proc
            PHP
            TRACE "MVPROGUP"

            setas
mvu_loop    LDA [SCRATCH]       ; Move a byte
            STA [INDEX]

            setal               ; Check to see if we've moved the last byte
            LDA SCRATCH
            CMP BIP
            BNE decrement
            setas
            LDA SCRATCH+2
            CMP BIP+2
            BEQ done            ; Yes: return

decrement   DEC_L SCRATCH       ; No: increment SCRATCH
            DEC_L INDEX         ; Increment INDEX
 
            BRA mvu_loop        ; And try again  

            PLP
            RETURN
            .pend

;
; Delete a line from the BASIC program
;
; Inputs:
;   ARGUMENT1 = the number of the line to delete
;
DELLINE     .proc
            PHP
            TRACE "DELLINE"

            LD_L CURLINE,BASIC_BOT
            CALL FINDLINE
            BCC done

            MOVE_L INDEX,CURLINE    ; INDEX := address of found line

            LDY #LINE_LINK          ; SCRATCH := INDEX + [INDEX].LINK (address of the following line)
            setal
            CLC
            LDA INDEX
            ADC [INDEX],Y
            STA SCRATCH
            setas
            LDA INDEX+2
            ADC #0
            STA SCRATCH+2

            setal                   ; BIP := address of last byte in the program
            CLC
            LDA LASTLINE
            ADC #LINE_TOKENS
            STA BIP
            setas
            LDA LASTLINE+2
            ADC #0
            STA BIP+2

            LDY #LINE_LINK          ; LASTLINE := LASTLINE - [INDEX].LINK
            setal
            SEC
            LDA LASTLINE
            SBC [INDEX],Y
            STA LASTLINE
            setas
            LDA LASTLINE+2
            SBC #0
            STA LASTLINE+2

            CALL MVPROGDN           ; Move the block of memory down

done        PLP
            RETURN
            .pend

;
; Add an already tokenized line to the BASIC program
;
; Inputs:
;   A = the line number
;   CURRLINE = pointer to the tokenized line (without the line number)
;   
;
ADDLINE     .proc
            PHP
            TRACE "ADDLINE"

            setaxl
            LDY #LINE_NUMBER    ; Set the line number of the new line
            STA [LASTLINE],Y

            CLC                 ; Point INDEX to the position to store the tokens
            LDA LASTLINE
            ADC #LINE_TOKENS
            STA INDEX
            setas
            LDA LASTLINE+2
            ADC #0
            STA INDEX+2

            setas
            LDY #0
copy_loop   LDA [CURLINE],Y     ; Copy the tokenized line to its place in the code
            STA [INDEX],Y
            BEQ copy_done
            INY
            BRA copy_loop

copy_done   setal               ; Calculate the offset to the next line
            TYA
            CLC
            ADC #LINE_TOKENS+1
            STA SCRATCH

            setal
            LDY #LINE_LINK      ; Set link to the offset to the next line
            LDA SCRATCH
            STA [LASTLINE],Y

            setal               ; LASTLINE := pointer to "next" line
            CLC
            LDA LASTLINE
            ADC SCRATCH
            STA SCRATCH
            setas
            LDA LASTLINE+2
            ADC #0
            STA LASTLINE+2
            setal
            LDA SCRATCH
            STA LASTLINE

            setal
            LDY #0
            LDA #0
blank_loop  STA [LASTLINE],Y    ; Set the "line" after the last line to nulls
            INY
            CPY #LINE_TOKENS+1
            BNE blank_loop

            PLP
            RETURN
            .pend