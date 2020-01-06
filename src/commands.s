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
; LOAD "filename" [, address ]
;
CMD_LOAD        .proc
                PHP
                TRACE "CMD_LOAD"

                ; TODO: actually load the file!

                CALL EVALEXPR               ; Get the file name
                CALL ASS_ARG1_STR           ; Make sure it's a string

                setas
                setxl
                LDY #0
                LDX #0
copy_name       LDA [ARGUMENT1],Y           ; Copy the file name to the FS_PATH buffer
                STA @lFS_PATH,X
                BEQ done_name
                INX
                INY
                BRA copy_name

                ; TODO: allow for user-provided load address

done_name       setaxl
                LDA #<>LOADBLOCK            ; Set the start of the input buffer
                STA IBUFFER
                STA MARG2
                setas
                LDA #`LOADBLOCK
                STA IBUFFER+2
                STA MARG2+2

                setal
                STZ IBUFFIDX                ; Reset the input cursor to position 0

                CALL CMD_NEW                ; Erase any program we already had

                CALL FS_LOAD                ; Load the file into memory
                BCC not_found               ; Throw error if not found

                setal
                LDX #FS_FILEREC.SIZE
                LDA @lFS_FILE,X             ; Set the size of the input buffer
                STA IBUFFSIZE

                ; Read and process each line
read_line       CALL IBUFF_EMPTY            ; Check to see if the buffer is empty
                BPL end_of_file             ; Yes: we're done

                CALL IBUFF_READLINE         ; Read the line
                CALL PROCESS                ; Process the line

                setas
                LDA #'.'
                CALL PRINTC
                setal

                BRA read_line

end_of_file     PLP
                RETURN

not_found       THROW ERR_NOFILE
                .pend

;
; Print a directory listing
;
CMD_DIR         .proc
                PHP
                TRACE "CMD_DIR"

                setas

                CALL PRINTCR                ; Print a newline
                CALL FS_DIRFIRST            ; Get the first directory entry

list_file       LDX #FS_FILEREC.NAME
pr_name         LDA @lFS_FILE,X             ; Get a character from the name portion
                BEQ done_name               ; Go to the extension, if it's NUL
                CALL PRINTC                 ; Otherwise print it
                INX                         ; Advance to the next character
                CPX #8                      ; Unless we're done
                BNE pr_name                 ; ... try the next character

done_name       LDA #'.'                    ; Print the dot separator
                CALL PRINTC

                LDX #FS_FILEREC.EXTENSION
pr_ext          LDA @lFS_FILE,X             ; Get a character from the extension portion
                BEQ done_ext                ; Go to the extension, if it's NUL
                CALL PRINTC                 ; Otherwise print it
                INX                         ; Advance to the next character
                CPX #11                     ; Unless we're done
                BNE pr_ext                  ; ... try the next character

done_ext        CALL PRINTCR                ; Print a newline

                LDX #FS_FILEREC.NEXT
                LDA @lFS_FILE,X
                BNE has_more
                INX
                INX
                LDA @lFS_FILE,X
                BEQ done

has_more        CALL FS_DIRNEXT             ; Try to get the next entry

                BCS list_file               ; If we got one, try to print it out

done            PLP                         ; Otherwise, we're done
                RETURN
                .pend