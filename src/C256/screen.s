;;;
;;; Wrapper for C256 screen editor code
;;;

;
; Show or hide the cursor
;
; Inputs:
;   A = cursor visiblity. 0 = hide, any other value = show
;
ISHOWCURSOR .proc
            PHP
            setas
            CMP #0
            BEQ hide

show        LDA @lVKY_TXT_CURSOR_CTRL_REG
            ORA #Vky_Cursor_Enable
            BRA setit

hide        LDA @lVKY_TXT_CURSOR_CTRL_REG
            AND #~Vky_Cursor_Enable
            
setit       STA @lVKY_TXT_CURSOR_CTRL_REG
            PLP
            RETURN
            .pend

;
; Set the location of the cursor.
;
; Inputs:
;   X = the column of the cursor
;   Y = the row of the cursor
;
ICURSORXY   .proc
            PHP

            JSL FK_LOCATE

            PLP
            RETURN
            .pend

;
; Kernel routines needed
;

;
; Scroll the screen up by one line
; (Stefany's hand coded version)
;
SCROLLUP    .proc
            ; Scroll the screen up by one row
            ; Place an empty line at the bottom of the screen.
            ; TODO: use DMA to move the data
            PHA
            PHX
            PHY
            PHP

            setxl
            setas
            LDX #$0000
SCROLLUPTEXTLOOP

            LDA @lCS_TEXT_MEM_PTR + 128, X
            STA @lCS_TEXT_MEM_PTR, X
            LDA @lCS_COLOR_MEM_PTR + 128, X
            STA @lCS_COLOR_MEM_PTR, X
            INX
            CPX #$1F80
            BNE SCROLLUPTEXTLOOP
            LDX #$0000
SCROLLUPLINELASTLINE
            LDA #$20
            STA @lCS_TEXT_MEM_PTR + $1F80, X
            LDA @lCS_COLOR_MEM_PTR + $1F00, X
            STA @lCS_COLOR_MEM_PTR + $1F80, X
            INX
            CPX #$80
            BNE SCROLLUPLINELASTLINE

            PLP
            PLY
            PLX
            PLA
            RETURN
            .pend

;
; Clear the screen and move the cursor to the home position
;
ICLSCREEN   .proc
            PHA
            PHX
            PHY
            PHD
            PHP

            setas
            setxl

            LDX #0

loop        LDA #$20
            STA @lCS_TEXT_MEM_PTR,X     ; Write a space in the text cell
            LDA @lCURCOLOR
            STA @lCS_COLOR_MEM_PTR,X    ; Set the color to green on black

            INX                         ; Move to the next character cell
            CPX #$2000
            BNE loop

            setdp 0

            LDX #0                      ; Set cursor to upper-left corner
            LDY #0
            JSL FK_LOCATE

            PLP
            PLD
            PLY
            PLX
            PLA
            RETURN
            .pend

;
; Write a character to the screen. Handle simple command codes.
;
; Codes supported:
;   $08 = backspace
;   $0D = carriage return (newline)
;   $0F = insert a space at the cursor
;   $11 = move the cursor up
;   $1D = move the cursor right
;   $91 = move the cursor down
;   $9D = move the cursor left
;   $7F = delete the character under the cursor
;
; Otherwise, codes in [$00..$1F] and [$7F..$9F] will be ignored
; as unprintable characters.
;
; Inputs:
;   A = the character to write
;
WRITEC      .proc
            PHX
            PHY
            PHD
            PHP

            setdp 0

            setas
            setxl
            CMP #CHAR_LF        ; Linefeed moves cursor down one line
            BEQ go_down
            CMP #$20
            BCC check_ctrl0     ; [$00..$1F]: check for arrows
            CMP #$7F
            BEQ do_del
            BCS check_A0        ; [$20..$7E]: print it
            JMP printc
check_A0    CMP #$A0
            BCC check_ctrl1
            BRL printc          ; [$A0..$FF]: print it

check_ctrl1 CMP #K_DOWN         ; If the down arrow key was pressed
            BEQ go_down         ; ... move the cursor down one row
            CMP #K_LEFT         ; If the left arrow key was pressed
            BEQ go_left         ; ... move the cursor left one column
            BRL done

check_ctrl0 CMP #CHAR_TAB       ; If it's a TAB...
            BEQ do_TAB          ; ... move to the next TAB stop
            CMP #CHAR_BS        ; If it's a backspace...
            BEQ backspace       ; ... move the cursor back and replace with a space
            CMP #CHAR_CR        ; If the carriage return was pressed
            BEQ do_cr           ; ... move cursor down and to the first column
            CMP #K_UP           ; If the up arrow key was pressed
            BEQ go_up           ; ... move the cursor up one row
            CMP #K_RIGHT        ; If the right arrow key was pressed
            BEQ go_right        ; ... move the cursor right one column
            CMP #CHAR_INS       ; If the insert key was pressed
            BEQ do_ins          ; ... insert a space
            BRL done            ; Ignore anything else

do_del      CALL SCRSHIFTLL     ; Shift the current line left one space into the cursor
            BRA done

do_ins      CALL SCRSHIFTLR     ; Shift the current line right one space from the cursor
            BRA done

backspace   LDA #CHAR_BS        ; Move the cursor back
            JSL FK_PUTC
            CALL SCRSHIFTLL     ; Shift the current line left one space into the cursor
            BRA done

do_cr       LDX #0              ; Handle a carriage return
            BRA cursor_down

go_down     LDX CURSORX         ; Move the cursor down one row
cursor_down LDY CURSORY
            INY
            BRA set_xy

go_up       LDX CURSORX         ; Move the cursor up one row
            LDY CURSORY
            BEQ done
            DEY
            BRA set_xy

go_right    LDX CURSORX         ; Move the cursor right one column
            LDY CURSORY
            INX
            BRA set_xy

go_left     LDX CURSORX         ; Move the cursor left one column
            BEQ done
            DEX
            LDY CURSORY
            BRA set_xy

do_TAB      setal
            LDA CURSORX         ; Get the current column
            AND #$FFF8          ; See which group of 8 it's in
            CLC
            ADC #$0008          ; And move it to the next one
            TAX
            LDY CURSORY

set_xy      CPX COLS_VISIBLE    ; Check if we're still on screen horizontally
            BCC check_row       ; Yes: check the row
            LDX #0              ; No: move to the first column...
            INY                 ; ... and the next row

check_row   CPY LINES_VISIBLE   ; Check if we're still on the screen vertically
            BCC do_locate       ; Yes: reposition the cursor

            CALL SCROLLUP       ; No: scroll the screen
            DEY                 ; And set the row to the last one   

do_locate   JSL FK_LOCATE       ; Set the cursor position
            BRA done

            ; TODO: make this more robust for variable screen sizes
            
printc      JSL FK_PUTC         ; Print the character

            LDY CURSORY         ; Check to see if the character
            CPY #51             ; Is in the last cell...
            BLT done            ; If not, we can return to the caller
            LDX CURSORX
            CPX #71
            BLT done

            CALL SCROLLUP       ; Otherwise scroll

            LDX #0              ; And reposition the cursor
            JSL FK_LOCATE    

done        PLP
            PLD
            PLY
            PLX
            RETURN
            .pend

; Shift all the characters on the current line left one cell, starting from the character to the right of the cursor
SCRSHIFTLL  .proc
            PHX
            PHY
            PHP

            setaxl
            LDA CURSORPOS       ; Get the current cursor position
            TAY                 ; Set it as the destination
            TAX
            INX                 ; And set the next cell as the source

            SEC                 ; Calculate the length of the block to move
            LDA #127            ; as 127 - X
            SBC CURSORX

            MVN $AF, $AF        ; And move the block

            PLP
            PLY
            PLX
            RETURN
            .pend

; Shift all the characters on the current line right one cell, starting from the character to the right of the cursor
; The character under the cursor should be replaced with a space.
SCRSHIFTLR  .proc
            PHP

            setaxl
            LDA CURSORPOS       ; Get the current cursor position
            AND #$FF80          ; Mask off the column bits
            ORA #$007F          ; And compute the address of the last cell
            TAY                 ; And set that as the destination address
            DEC A               ; Compute the address of the character to the left
            TAX                 ; And make it the source

            SEC                 ; Calculate the length of the block to move
            LDA #127            ; as 127 - X
            SBC CURSORX

            MVP $AF, $AF        ; And move the block

            LDA #CHAR_SP        ; Put a blank space at the cursor position
            CALL PRINTC
            LDA #K_LEFT
            CALL PRINTC

            PLP
            RETURN
            .pend

;
; Copy the current line on the screen to the input buffer
; Trim whitespace from the end of the line to make input buffer null-terminated
;
ISCRCPYLINE .proc
            PHX
            PHY
            PHD
            PHP

            setdp GLOBAL_VARS
            setaxl

            ; Calculate the address of the first character of the line
            LDA @lSCREENBEGIN       ; Set INDEX to the first byte of the text screen
            STA INDEX
            setas
            LDA @lSCREENBEGIN+2
            setal
            AND #$00FF
            STA INDEX+2

            LDA #128                ; Calculate the offset to the current line
            STA @lM1_OPERAND_A
            LDA @lCURSORY
            DEC A
            STA @lM1_OPERAND_B

            CLC                     ; And add it to INDEX
            LDA INDEX
            ADC @lM1_RESULT
            STA INDEX
            LDA INDEX+2
            ADC #0
            STA INDEX+2

            setas
            LDY #0
            LDX #0
copy_loop   LDA [INDEX],Y           ; Copy a byte from the screen to the input buffer
            STA @lINPUTBUF,X
            INX
            INY
            CPY #128
            BNE copy_loop

            DEX

trim_loop   LDA @lINPUTBUF,X        ; Replace spaces at the end with NULLs
            CMP #CHAR_SP
            BNE done

            LDA #0
            STA @lINPUTBUF,X

            DEX
            BPL trim_loop

done        PLP
            PLD
            PLY
            PLX
            RETURN

            .dpage BASIC_BANK
            .pend