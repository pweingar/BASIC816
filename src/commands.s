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

                CATCH ON_ERROR              ; Register the default error handler
                CALL S_CLR
                LD_L LASTLINE,BASIC_BOT     ; Delete all lines

                setal                       ; Set first "line" to null
                LDA #0
                LDY #0
loop            STA [LASTLINE],Y
                INY
                CPY #7
                BEQ loop

                STZ GOSUBDEPTH              ; Clear the depth of the GOSUB stack

                PLD
                PLP
                RETURN
                .pend

