;;;
;;; Core of the BASIC interpreter
;;;

ST_RUNNING = $80            ; The interpreter is running a full program
ST_INTERACT = $00           ; The interpreter is in interactive mode

.section globals
STATE       .byte ?         ; The state of the interpreter ()
ERROR_NUM   .byte ?         ; The type of the error
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
EXEC_RETURN = 3             ; Transfer execution back to a line that was on the stack

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
            setdp <>GLOBAL_VARS
            setas
            LDA #\1
            STA @lERROR_NUM
            JMP [HANDLEERR]
            .endm

;
; Default error handler.
; Print the error message, reset the stacks, and launch the command line
;
ON_ERROR    .proc
            TRACE "ON_ERROR"

            setas
            setxl

            CALL PRINTCR            ; Newline

            LDA @lERROR_NUM         ; Calculate index to the error message pointer
            ASL A
            setal
            AND #$00FF
            TAY

            setdbr `ERRORMSG        ; Print the error message
            LDX ERRORMSG,Y
            CALL PRINTS

            setal                   ; Check to see if we have a current line number
            LDA LINENUM
            BEQ skip_at

            LDX #<>MSG_AT           ; If so... print " AT "
            CALL PRINTS
            setdbr BASIC_BANK
                
            setal
            LDA @lLINENUM           ; ... and then the line number
            STA @lARGUMENT1
            LDA #0
            STA @lARGUMENT1+2
            CALL PR_INTEGER
            CALL PRINTCR

skip_at

.if UNITTEST
ERRLOCK     JMP ERRLOCK
.else
            JMP INTERACT
.endif

ERRORMSG    .word <>MSG_OK
            .word <>MSG_BREAK
            .word <>MSG_SYNTAX
            .word <>MSG_MEMORY
            .word <>MSG_TYPE
            .word <>MSG_NOTFND
            .word <>MSG_NOLINE
            .word <>MSG_UNDFLOW
            .word <>MSG_OVRFLOW
            .word <>MSG_RANGE
            .word <>MSG_ARG

MSG_AT      .null " at"

MSG_OK      .null "OK"
MSG_BREAK   .null "Break"
MSG_SYNTAX  .null "Syntax error"
MSG_MEMORY  .null "Out of memory"
MSG_TYPE    .null "Type mismatch"
MSG_NOTFND  .null "Variable not found"
MSG_NOLINE  .null "Line number not found"
MSG_UNDFLOW .null "Stack underflow"
MSG_OVRFLOW .null "Stack overflow"
MSG_RANGE   .null "Out of range"
MSG_ARG     .null "Illegal argument"
            .pend

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
; Put the interpreter into the correct state for running a program
;
; Sets up the error handler to the default
; Resets the heap and clears all variables
; Sets the GOSUB depth to 0
; 
CLRINTERP   .proc
            PHD
            PHP

            setdp <>GLOBAL_VARS
            CATCH ON_ERROR              ; Register the default error handler
            CALL S_CLR                  ; Erase all variables
            CALL S_RESTORE              ; Reset DATAPTR to the beginning
            STZ GOSUBDEPTH              ; Clear the depth of the GOSUB stack

            PLP
            PLD
            RETURN
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
            TRACE "SKIPSTMT"

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

;
; Skip to the next instance of the token in TARGETTOK at the current lexical depth
; FOR and DO increase the lexical depth, NEXT and LOOP decrease it.
; It is a syntax error if the lexical depth goes negative or if the token is not found.
;
; Inputs:
;   TARGETTOK = the token to find
;   BIP = pointer to the current position in the program
;   CURLINE = pointer to the start of the current line
;
; Outputs:
;   BIP = pointer to the current position in the program (the token found)
;   CURLINE = pointer to the start of the current line (with the token)
;
SKIPTOTOK   .proc
            PHP
            TRACE "SKIPTOTOK"

            setas
            STZ NESTING

loop        LDA [BIP]           ; Get the character
            BEQ end_of_line     ; EOL? Yes: move to the next line
            CMP TARGETTOK       ; Is it the one we want?
            BEQ check_depth     ; Yes: check the depth

            CMP #TOK_FOR        ; Is it a FOR?
            BEQ inc_nesting     ; Yes: increment NESTING
            CMP #TOK_DO         ; Is it a DO?
            BEQ inc_nesting     ; Yes: increment NESTING

            CMP #TOK_NEXT       ; Is it a NEXT?
            BEQ dec_nesting     ; Yes: decrement NESTING
            CMP #TOK_LOOP       ; Is it a LOOP?
            BEQ dec_nesting     ; Yes: decrement NESTING 

incloop     CALL INCBIP         ; Otherwise: Point to the next character
            BRA loop            ; and keep scanning

end_of_line CALL NEXTLINE       ; Go to the next line
            setal
            LDA LINENUM         ; Check the line number
            BEQ syntax_err1     ; If it's zero, we reached the end of the program
                                ; so we need to signal a syntax error
            setas
            BRA loop            ; And keep scanning

inc_nesting TRACE "inc"
            INC NESTING         ; Track that we have entered a lexical scope for a FOR/DO
            BRA incloop          

dec_nesting TRACE "dec"
            DEC NESTING         ; Track that we have left a lexical scope for a FOR/DO
            BMI syntax_err2     ; If the depth goes <0, throw a syntax error
            BRA incloop

check_depth TRACE "check_depth"
            LDA SKIPNEST        ; Check to see if nesting matters
            BMI found           ; No: just return that we found the token

            LDA NESTING         ; Get the nesting depth
            BEQ found           ; If it's zero, we found our token
            BRA incloop         ; Otherwise: it's a token for an enclosed FOR/DO, keep scanning

found       TRACE "found"
            CALL INCBIP         ; Point to the character right after the token
            PLP
            RETURN
syntax_err1 TRACE "SKIP SYNTAX 1"
            THROW ERR_SYNTAX
syntax_err2 TRACE "SKIP SYNTAX 2"
            THROW ERR_SYNTAX
            .pend

;
; Move to the next line in the program
;
; Note: the line can be the end-of-program line marker
; in which case, LINENUM will be set to 0.
;
; Inputs:
;   CURLINE = pointer to the current line
;
; Outputs:
;   CURLINE = pointer to the new current line
;   LINENUM = the line number for the new current line
;   BIP = pointer to the first character of the new current line
;
NEXTLINE    .proc
            PHP

            setaxl
            LDY #LINE_LINK
            LDA [CURLINE],Y     ; Get the offset to the next line
            STA SCRATCH

            CLC                 ; Compute the new CURLINE
            LDA CURLINE         ; CURLINE := [CURLINE].LINE_LINK
            ADC SCRATCH
            STA CURLINE
            LDA CURLINE+2
            ADC #0
            STA CURLINE+2

            LDY #LINE_NUMBER    ; Set the LINENUM to the new current line's number
            LDA [CURLINE],Y     ; LINENUM := [CURLINE].LINE_NUMBER
            STA LINENUM

            CLC                 ; Point BIP to the first character of the line
            LDA CURLINE         ; BIP := CURLINE + LINE_TOKENS
            ADC #LINE_TOKENS
            STA BIP
            LDA CURLINE+2
            ADC #0
            STA BIP+2

            PLP
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
; Scan to an optional token in TARGETTOK in the current statement.
; Point BIP to the character immediately after the token.
; If the token is not found before a colon or eno of line is found,
; return with carry clear. Otherwise return with carry set.
;
; Inputs:
;   TARGETTOK = token to find
;   BIP = pointer to the BASIC code
;
; Outputs:
;   C is set if the token was found within the current statement
;   C is clear otherwise
;   BIP = pointer to the character after the token or a colon or end of line
;
OPT_TOK     .proc
            PHP

            setas
            CALL SKIPWS         ; Skip over leading white space

            setas
loop        LDA [BIP]           ; Check the character at BIP
            BEQ ret_false       ; If end-of-line, return false
            CMP #':'
            BEQ ret_false       ; If colon, return false
            CMP TARGETTOK
            BEQ ret_true        ; If matches, return true

            CALL INCBIP         ; Skip over the token
            BRA loop

ret_true    PLP
            SEC
            RETURN

ret_false   PLP
            CLC
            RETURN
            .pend

;
; Set A to the next available non-whitespace
;
; NOTE: the BIP will not be changed by this call
;
; Inputs:
;   BIP = pointer to the byte to start scanning from
;
; Outputs:
;   A = the token found (0 for EOL or end-of-statement)
;
PEEK_TOK    .proc
            PHY
            PHP

            setas
            LDY #0
            
loop        LDA [BIP],Y
            BEQ done
            CMP #':'
            BEQ ret_null
            CMP #CHAR_SP
            BNE done

            INY
            BRA loop

ret_null    LDA #0

done        PLP
            PLY
            RETURN
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

            CALL INITEVALSP     ; Make sure the evaluatio stacks are empty

            setas               ; Set EXECACTION to EXEC_CONT, the default behavior
            LDA #EXEC_CONT      ; This will tell EXECLINE and EXECPROG to procede in a
            STA EXECACTION      ; linear fashion through the program
            
check_break LDA KEYFLAG         ; Check the keyboard flags
            BMI throw_break     ; If MSB: user pressed an interrupt key, stop the program

            LDA [BIP]           ; If we happen to have a colon, just skip over it.
            CMP #':'            ; This can happen with FOR/NEXT
            BNE eat_ws
            CALL INCBIP

eat_ws      CALL SKIPWS
            LDA [BIP]
            BNE else
            JMP done            ; If the current byte is 0, we're at the end of the line, just return

else        CALL ISALPHA        ; Is it alphabetic?
            BCS is_variable     ; Yes: we may have a LET statement

            LDA [BIP]           ; Check to see if it's any other non-token
            BPL error           ; Yes: it's a syntax error

            TRACE "CHECK TOKTYPE"

            CALL TOKTYPE        ; Get the token type
            STA SCRATCH         ; Save the type for later

            CMP #TOK_TY_STMNT   ; Is it a statement?
            BNE else2     
            JMP ok_to_exec      ; Yes: it's ok to try to execute it

else2       LDA STATE           ; Check to see if we're in interactive mode
            BEQ is_interact
            TRACE "STATE = RUNNING"

            ; Interpreter is running a program. Only statements are allowed. 

error       THROW ERR_SYNTAX    ; Throw a syntax error

throw_break THROW ERR_BREAK     ; Throw a BREAK

is_variable CALL S_LET          ; Try to execute a LET statement
            JMP done

STSTUB      setdbr `GLOBAL_VARS
            JMP (JMP16PTR)      ; Annoying JMP to get around the fact we don't have an indirect JSR

is_interact LDA SCRATCH         ; Get the token type
            CMP #TOK_TY_CMD     ; Is it a command?
            BNE error           ; If not, it's an error

ok_to_exec  TRACE "ok_to_exec"
            LDA [BIP]           ; Get the original token again
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
; Execute an interactive command line
;
; NOTE: uses the internals of EXECLINE
;
; Inputs:
;   CURLINE = pointer to the line to execute
;
EXECCMD     .proc
            PHP
            TRACE "EXECCMD"

            CLI

            CALL SETINTERACT
            CALL INITRETURN             ; Reset the RETURN stack

            setas
            STZ KEYFLAG                 ; Clear the key flag... interrupt handler will raise MSB
                                        ; if the user presses an interrupt key (CTRL-C)

            setal                  
            LDA CURLINE         ; Set the BASIC Instruction Pointer to the first byte of the line
            STA BIP
            LDA CURLINE+2
            STA BIP+2

            JMP exec_loop
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
EXECLINE    PHP

            setal
            LDY #LINE_NUMBER            ; Set the current line number
            LDA [CURLINE],Y
            STA LINENUM
            TRACE_A "EXECLINE"

            setas
            LDA EXECACTION              ; If the last EXEC action was RETURN
            CMP #EXEC_RETURN            ; BIP has already been set, so...
            BEQ exec_loop               ; Skip over setting the BIP to the beginning of the line

            setal
            CLC                         ; Set the BASIC Instruction Pointer to the first byte of the line
            LDA CURLINE
            ADC #LINE_TOKENS
            STA BIP
            setas
            LDA CURLINE+2
            ADC #0
            STA BIP+2

exec_loop   setal
            CALL EXECSTMT               ; Try to execute a statement

            setas                       ; Check EXECACTION (set by statements)
            LDA EXECACTION
            
            CMP #EXEC_RETURN
            BEQ exec_loop

            CMP #EXEC_CONT              ; If it's not EXEC_CONT, exit to the caller
            BNE exec_done

            setas
            CALL SKIPWS                 ; Skip any whitespace
            LDA [BIP]                   ; Get the current character in the line
            BEQ exec_done               ; If it's NULL, we're done

            CMP #':'                    ; If it's colon, we have more statements
            BEQ skip_loop               ; Skip over it and try to execute the next one

            TRACE "THROW ERR_SYNTAX"
            THROW ERR_SYNTAX            ; Something unexpected... throw syntax error

skip_loop   CALL INCBIP                 ; Skip over the colon
            BRA exec_loop               ; And try to execute another statement

exec_done   TRACE_L "EXECLINE DONE", BIP
            PLP
            RETURN

;
; Starting with the line indicated by CURLINE, execute the BASIC program.
;
; Inputs:
;   CURLINE = the pointer to the line to start executing
;
EXECPROGRAM .proc
            PHP
            TRACE "EXECPROGRAM"

            CLI

            setas                       ; Set interpreter state to RUNNING
            LDA #ST_RUNNING
            STA STATE

            STZ KEYFLAG                 ; Clear the key flag... interrupt handler will raise MSB
                                        ; if the user presses an interrupt key (CTRL-C)

            CALL INITRETURN             ; Reset the RETURN stack

            setaxl
            STZ GOSUBDEPTH              ; Clear the count of GOSUBs

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
            CMP #EXEC_RETURN            ; Transfer execution to the CURLINE and BIP that is already set
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
            setaxl
            TRACE_L "FINDLINE", ARGUMENT1

            ; MOVE_L INDEX,CURLINE        ; INDEX := CURLINE

            setal
            ; LDA LINENUM                 ; Compare the target to the current line number
            ; CMP ARGUMENT1
            ; BEQ ret_true                ; If they're the same, just return true
            ; BGE next_line               ; If LINENUM < target line, it must be after the current line

            LDA #<>BASIC_BOT            ; INDEX points to the first line of the program
            STA INDEX
            LDA #`BASIC_BOT
            STA INDEX+2

            setal
check_nmbrs LDY #LINE_NUMBER            ; Get the number of the possible target line
            LDA [INDEX],Y
            BEQ ret_false               ; If new line number is 0, we got to the
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

mvd_loop    setas
            LDA [SCRATCH]       ; Move a byte
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

mvu_loop    setas
            LDA [SCRATCH]       ; Move a byte
            STA [INDEX]

            setal               ; Check to see if we've moved the last byte
            LDA SCRATCH
            CMP BIP
            BNE decrement
            LDA SCRATCH+2
            CMP BIP+2
            BEQ done            ; Yes: return

decrement   DEC_L SCRATCH       ; No: increment SCRATCH
            DEC_L INDEX         ; Increment INDEX
 
            BRA mvu_loop        ; And try again  

done        PLP
            RETURN
            .pend

;
; Delete a line from the BASIC program
;
; Inputs:
;   INDEX = the line to delete
;
DELLINE     .proc
            PHP
            TRACE "DELLINE"

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

done        CALL S_CLR              ; Deleting a line resets variables

            PLP
            RETURN
            .pend

;
; Append an already tokenized line to the end of the BASIC program
;
; Inputs:
;   A = the line number
;   CURRLINE = pointer to the tokenized line (without the line number)
;   
;
APPLINE     .proc
            PHP
            TRACE "APPLINE"

            setdp GLOBAL_VARS

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

            CALL S_CLR          ; Adding a line resets variables

            PLP
            RETURN
            .pend

;
; Find the point where a line should be inserted into the program memory space
;
; Inputs:
;   LINENUM = the number of the line to be inserted
;
; Outputs:
;   INDEX = the location in memory where the line should go
;   A = indicator of what was found:
;       0 = LINENUM was not found before the end of the program
;       1 = INDEX shows where the line should be inserted
;       2 = INDEX shows where a line with the same LINENUM is (delete and insert)
;
FINDINSPT   .proc
            PHD
            PHP
            TRACE "FINDINSPT"

            setdp GLOBAL_VARS
            setaxl

            LDA #<>BASIC_BOT
            STA INDEX
            LDA #`BASIC_BOT
            STA INDEX+2

loop        LDY #LINE_NUMBER
            LDA [INDEX],Y
            BEQ found_end           ; Got to end without finding it

            CMP LINENUM
            BEQ found_line          ; LINENUM = [INDEX].LINE_NUMBER: return we found the exact line
            BGE found_spot          ; LINENUM > [INDEX].LINE_NUMBER: return we found spot to insert

            LDY #LINE_LINK
            CLC                     ; Move INDEX to the next line
            LDA INDEX
            ADC [INDEX],Y
            STA SCRATCH
            LDA INDEX+2
            ADC #0
            STA INDEX+2
            LDA SCRATCH
            STA INDEX

            BRA loop                ; And check that line

found_end   LDA #0                  ; Return that we reached the end of the program
            PLP
            PLD
            RETURN

found_spot  LDA #1                  ; Return that we the found the spot to insert the line
            PLP                     ; But that it wasn't already there
            PLD
            RETURN

found_line  LDA #2                  ; Return that we found the line
            PLP
            PLD
            RETURN
            .pend

;
; Insert a tokenized line into the BASIC program.
;
; Inputs:
;   INDEX = the spot to insert the line
;   CURLINE = pointer to the first byte of the tokenized line
;   LINENUM = the number of the line to insert
;
INSLINE     .proc
            PHP
            TRACE "INSLINE"

            setaxl

            ; Calculate number of bytes to move the BASIC program into SCRATCH2
            LDA #LINE_TOKENS+1  ; Set SCRATCH2 to the size of the line header with the end-of-line
            STA SCRATCH2

            LDY #0
count_loop  setas
            LDA [CURLINE],Y     ; Get the byte of the line
            BEQ shift_prog      ; If it's end-of-line, SCRATCH2 is the length
            setal
            INC SCRATCH2
            INY
            BRA count_loop      ; Count and continue

            ; Open a spot in the BASIC program

shift_prog  setal

            LDA INDEX           ; BIP = the address of the first byte for the new line
            STA BIP
            LDA INDEX+2
            STA BIP+2

            CLC                 ; SCRATCH = address of highest byte to copy
            LDA LASTLINE
            ADC #LINE_TOKENS
            STA SCRATCH
            LDA LASTLINE+2
            ADC #0
            STA SCRATCH+2

            CLC                 ; Adjust LASTLINE to its new position after the insert
            LDA LASTLINE
            ADC SCRATCH2
            STA LASTLINE
            LDA LASTLINE+2
            ADC #0
            STA LASTLINE+2

            CLC                 ; INDEX = address of the highest location to copy into
            LDA LASTLINE
            ADC #LINE_TOKENS
            STA INDEX
            LDA LASTLINE+2
            ADC #0
            STA INDEX+2

            CALL MVPROGUP       ; Whew... actually move the program space up

            ; Copy the line to the BASIC program

            setal
            LDA SCRATCH2
            LDY #LINE_LINK
            STA [BIP],Y         ; [BIP].LINK_LINK = length of the new line

            LDA LINENUM
            LDY #LINE_NUMBER
            STA [BIP],Y         ; [BIP].LINE_NUMBER = number of the new line

            CLC                 ; Point BIP to the first byte of the new line
            LDA BIP
            ADC #LINE_TOKENS
            STA BIP
            LDA BIP+2
            ADC #0
            STA BIP+2

            LDY #0
            setas
copy_loop   LDA [CURLINE],Y     ; Get the byte of the tokenized line
            STA [BIP],Y         ; Copy it to its correct location in the program
            BEQ done            ; If it was end-of-line byte, we're done
            INY
            BRA copy_loop       ; Otherwise, continue with the next

done        CALL S_CLR          ; Inserting a line resets variables

            PLP
            RETURN
            .pend

;
; Add a tokenized line to the BASIC program.
;
; If there is already a line with that number, it will be deleted.
; If there is a line with a greater line number, the line will be
; inserted into the correct location. Otherwise, the line will be
; appended to the end of the program.
;
; Inputs:
;   A = the number of the line to add
;   CURLINE = pointer to the first byte of the line (without line number)
;
ADDLINE     .proc
            PHP
            TRACE "ADDLINE"

            setaxl
            STA LINENUM

            CALL FINDINSPT      ; Try to find where the line goes
            CMP #0
            BEQ do_append       ; End-of-program found, add the line to the end
            CMP #1
            BEQ do_insert       ; Spot was found: insertion required

            ; Otherwise: we found a line with the same line number

            setal
            LDA INDEX
            PHA
            LDA INDEX+2
            PHA
            CALL DELLINE        ; Delete the line
            PLA
            STA INDEX+2
            PLA
            STA INDEX

            LDA CURLINE         ; Check to see if there is any non-whitespace on the line
            STA BIP
            LDA CURLINE+2
            STA BIP+2
            CALL SKIPWS
            setas
            LDA [BIP]
            BEQ done            ; If not, we're done

do_insert   CALL INSLINE        ; Insert the line
            BRA done

do_append   LDA LINENUM
            CALL APPLINE        ; Append the line to the end of the program

done        PLP
            RETURN
            .pend