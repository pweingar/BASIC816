;;;
;;; Read-eval-print loop... this is the user's main interface to the interpreter
;;;

;
; Print the READY prompt
;
PRREADY         .proc
                PHB
                PHP

                setdbr `MREADY
                LDX #<>MREADY
                CALL PRINTS

                PLP
                PLB
                RETURN

                .databank BASIC_BANK 
                .pend

;
; Read a line from the user
;
READLINE        .proc
                PHP
                TRACE "READLINE"

                setaxs
read_loop       JSL GETKEYE
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
                CALL PROCESS        ; Tokenize and handle the line
                BCS no_ready_loop
                BRA ready_loop
                .pend

.section data
MREADY          .null 13,"READY",13
.send