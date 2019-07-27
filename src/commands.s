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

                CALL PRINTCR
                CALL LISTPROG

                PLP
                RETURN
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
                LDA #<>SAMPLE               ; Set the start of the input buffer
                STA IBUFFER
                setas
                LDA #`SAMPLE
                STA IBUFFER+2

                setal
                LDA #SAMPLE_EOF - SAMPLE    ; Set the size of the input buffer
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

SAMPLE          .null "10 POKE $AF0000,PEEK($AF0000) OR $2E"
                .null "20 FOR V=0 TO 31:FOR U=0 TO 31"
                .null "30 POKE $B10000 + V * 32 + U,V"
                .null "40 NEXT:NEXT"
                .null "50 POKE $AF0200,1"
                .null "60 POKEW $AF0201,0:POKE $AF0203,1"
                .null "70 POKEW $AF0204,100:POKEW $AF0206,100"
                .null "80 FOR C = 1 to 31:BLUE = $AF2400 + C*4"
                .null "90 POKE BLUE, 255 - C*8"
                .null "100 POKE BLUE + 1, C*8"
                .null "110 POKE BLUE + 2, 0"
                .null "120 POKE BLUE + 3, $FF"
                .null "130 NEXT"
SAMPLE_EOF      .byte $00,$00,$00