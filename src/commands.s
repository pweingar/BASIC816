;;;
;;; Top-level BASIC commands
;;;

;
; Enter the monitor
;
CMD_MONITOR     BRK
                NOP
                RETURN

;
; Clear the program area and all variables
;
CMD_NEW         .proc
                PHP
                TRACE "CMD_NEW"
                PHD

                setdp GLOBAL_VARS

                setaxl

                LD_L LASTLINE,BASIC_BOT     ; Delete all lines

                setaxl
                LDA #0
                LDY #LINE_LINK
                STA [LASTLINE],Y
                LDY #LINE_NUMBER
                STA [LASTLINE],Y
                LDY #LINE_TOKENS
                STA [LASTLINE],Y

                CALL CLRINTERP              ; Set the interpreter state to the default

                PLD
                PLP
                RETURN
                .pend

;
; Attempt to run a program
;
CMD_RUN         .proc
                PHB
                PHP

                TRACE "CMD_RUN"

                setal
                LDA #<>BASIC_BOT            ; Point to the first line of the program
                STA CURLINE
                LDA #`BASIC_BOT
                STA CURLINE + 2

                CALL CLRINTERP              ; Set the interpreter state to the default
                CALL EXECPROGRAM

                PLP
                PLB
                RETURN
                .pend

;
; List the program
;
CMD_LIST        .proc
                PHP
                TRACE "CMD_LIST"

                setal

                STZ MARG1               ; MARG1 is starting line number, default 0

                LDA #$7FFF
                STA MARG2               ; MARG2 is ending line number, default MAXINT

                CALL PRINTCR

                CALL PEEK_TOK
                AND #$00FF
                CMP #0                  ; If no arguments...
                BEQ call_list           ; ... just list with the defaults
                CMP #TOK_MINUS          ; If just "- ###"...
                BEQ parse_endline       ; ... try to parse the end line number

                CALL SKIPWS
                CALL PARSEINT           ; Try to get the starting line
                LDA ARGUMENT1           ; And save it to MARG1
                STA MARG1

                CALL PEEK_TOK
                AND #$00FF
                CMP #0                  ; If no arguments...
                BEQ call_list           ; ... just list with the defaults
                CMP #TOK_MINUS
                BNE error               ; At this point, if not '-', it's a syntax error
          
parse_endline   CALL EXPECT_TOK         ; Try to eat the '-'

                CALL SKIPWS
                CALL PARSEINT           ; Try to get the ending line
                LDA ARGUMENT1           ; And save it to MARG2
                STA MARG2

call_list       LDA CURLINE+2           ; Save CURLINE
                PHA
                LDA CURLINE
                PHA

                LDA BIP+2               ; Save BIP
                PHA
                LDA BIP
                PHA


                CALL LISTPROG

                PLA
                STA BIP
                PLA
                STA BIP+2

                PLA
                STA CURLINE
                PLA
                STA CURLINE+2

                PLP
                RETURN
error           THROW ERR_SYNTAX        ; Throw a syntax error
                .pend

;
; Attempt to LOAD a file from storage
;
CMD_LOAD        .proc
                PHP

                CALL CMD_NEW                ; Erase any program we already had

                ; TODO: process file name, address, etc.
                ; TODO: actually load the file!

                setaxl
                LDA #<>FAKEFILE             ; Set the start of the input buffer
                STA IBUFFER
                setas
                LDA #`FAKEFILE
                STA IBUFFER+2

                setal
                LDA @lFAKEFILESIZE          ; Set the size of the input buffer
                STA IBUFFSIZE

                ; Read and process each line
read_line       CALL IBUFF_EMPTY            ; Check to see if the buffer is empty
                BPL end_of_file             ; Yes: we're done

                CALL IBUFF_READLINE         ; Read the line
                CALL PROCESS                ; Process the line
                BRA read_line

end_of_file     PLP
                RETURN
                .pend
