;;;
;;; Read-eval-print loop... this is the user's main interface to the interpreter
;;;

CHAR_DIR = '#'
CHAR_BRUN = '|'

;
; Expand INPUTBUF... translate the first character to a command shortcut
; If the input string > 1 character, wrap the original string in quotes
;
; Inputs:
;   INPUTBUF = the string to expand
;   MCOUNT = the length of the substitution string
;   MARG1 = pointer to the string to use for the expansion
;
EXPANDLINE      .proc
                PHD
                PHP

                setdp GLOBAL_VARS

                setas
                setxl
                LDX #0
count_loop      LDA INPUTBUF,X              ; Count the number of characters in the input
                BEQ save_size
                INX
                BRA count_loop

save_size       STX SCRATCH                 ; Save the size in SCRATCH

                setaxl
                TXA
                CMP #2                      ; Are there arguments?
                BLT start_copy              ; No: just replace the whole string

                ; Make room for the new string

                DEC A
                CLC
                ADC #<>INPUTBUF
                TAX                         ; X <-- INPUTBUF + len(INPUTBUF) - 1

                CLC                         ; Y <-- INPUTBUF + len(INPUTBUF) - 1 + len(substitution)
                ADC MCOUNT
                TAY

                LDA SCRATCH
                DEC A

                PHB
                MVP #`INPUTBUF,#`INPUTBUF   ; Make room for the substitition
                PLB

start_copy      setal
                LDX MARG1                   ; Source is data to copy
                LDY #<>INPUTBUF             ; Destination is input buffer
                LDA MCOUNT                  ; Number of bytes to copy

                PHB
                MVN #`EXPANDLINE,#`INPUTBUF ; Copy the data
                PLB

                setas
                LDA SCRATCH                 ; Check again to see if we need quotes
                CMP #2
                BLT done

                LDX MCOUNT                  ; If so, add a quote mark here
                LDA #CHAR_DQUOTE
                STA INPUTBUF,X

skip_to_end     INX                         ; Move to the end of the input string
                LDA INPUTBUF,X
                BNE skip_to_end

                LDA #CHAR_DQUOTE            ; Add the quote to the end of the string
                STA INPUTBUF,X
                LDA #0                      ; And terminate with a NULL
                INX
                STA INPUTBUF,X

done            PLP
                PLD
                RETURN
                .pend

;
; Scan the line before processing it to convert shortcuts to commands:
;   #PATH --> DIR"PATH"
;   |PATH --> BRUN"PATH"
;
; Inputs:
;   INPUTBUF = the buffer containing the line to process
;
; Outputs:
;   INPUTBUF = the buffer containing the expanded shortcuts
;
PREPROCESS      .proc
                PHX
                PHY
                PHB
                PHD
                PHP
                
                setdp GLOBAL_VARS
                
                setas
                setxl

                LDA INPUTBUF            ; Check the first character
                CMP #CHAR_DIR           ; Is it the DIR character?
                BEQ expand_dir          ; Yes: expand the DIR command into place
                CMP #CHAR_BRUN          ; Is it the BRUN character?
                BEQ expand_brun         ; Yes: expand the BRUN command into place

done            PLP
                PLD
                PLB
                PLY
                PLX
                RETURN

expand_dir      setal
                LDA #3                  ; Set size of substitution value
                STA MCOUNT

                LDA #<>dir_text         ; Set pointer to substitution value
                STA MARG1

                CALL EXPANDLINE         ; Expand the short cut
                BRA done

expand_brun     setal
                LDA #4                  ; Set size of substitution value
                STA MCOUNT

                LDA #<>brun_text        ; Set pointer to substitution value
                STA MARG1

                CALL EXPANDLINE         ; Expand the short cut
                BRA done

dir_text        .null "DIR"             ; Expansion of the DIR character
brun_text       .null "BRUN"            ; Expansion of the BRUN character
                .pend

;
; Print the READY prompt
;
PRREADY         .proc
                PHB
                PHP

                CALL ENSURETEXT         ; Make sure we have text displayed

                setdbr `MPROMPT         ; Print the prompt
                LDX #<>MPROMPT
                CALL PRINTS

                PLP
                PLB
                RETURN

                .databank BASIC_BANK 
                .pend

;
; Read a line from the user
;
IREADLINE       .proc
                PHP
                TRACE "READLINE"

                setaxs

                LDA #1
                CALL SHOWCURSOR

read_loop       CALL GETKEYE
                BEQ done
                CMP #CHAR_CR
                BEQ done
                BRA read_loop

done            PLP
                RETURN
                .pend

;
; Attempt to process a line
;
; Outputs:
;   C is clear if the READY prompt should be printed, set otherwise
;
PROCESS         .proc
                PHD
                PHP
                TRACE "PROCESS"

                setdp GLOBAL_VARS
                setaxl

                STZ LINENUM

                LDA #<>INPUTBUF         ; Attempt to tokenize the line that was read
                STA CURLINE
                LDA #`CURLINE
                STA CURLINE+2
                CALL TOKENIZE

                setal
                LDA LINENUM             ; Did we get a line number?
                BNE update_line         ; Yes: attempt to add it to the program

                CALL EXECCMD            ; Attempt to execute the line
                BRA done                

update_line     CALL ADDLINE            ; Add the line to the program
no_prompt       PLP
                PLD
                SEC
                RETURN
                
done            PLP
                PLD
                CLC
                RETURN
                .pend       

;
; Print a READY prompt and allow the user to input a a line
;
INTERACT        .proc
                setaxl
                LDX #<>STACK_END
                TXS

ready_loop      CALL PRREADY        ; Print the READY prompt
no_ready_loop   CALL READLINE       ; Read characters until the user presses RETURN
                CALL SCRCOPYLINE    ; Copy the line the cursor is on to the INPUTBUF

                LDA #0              ; Hide the cursor
                CALL SHOWCURSOR

                CALL PREPROCESS     ; Handle any syntactic sugar expansions
                CALL PROCESS        ; Tokenize and handle the line
                BCS no_ready_loop
                BRA ready_loop
                .pend

.section data
MPROMPT         .null 13,"READY",13
.send