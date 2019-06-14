;;;
;;; Top-level BASIC commands
;;;

;
; Clear the program area and all variables
;
CMD_NEW         .proc
                PHP
                TRACE "CMD_NEW"
                PHD

                setdp GLOBAL_VARS

                setaxl

                CALL CLRINTERP              ; Set the interpreter state to the default

                LD_L LASTLINE,BASIC_BOT     ; Delete all lines

                setaxl
                LDA #0
                LDY #LINE_LINK
                STA [LASTLINE],Y
                LDY #LINE_NUMBER
                STA [LASTLINE],Y
                LDY #LINE_TOKENS
                STA [LASTLINE],Y

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

                CALL LISTPROG

                PLP
                RETURN
                .pend