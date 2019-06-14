;;;
;;; Wrapper for C256 screen editor code
;;;

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
CLSCREEN    .proc
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
;   $11 = move the cursor up
;   $1D = move the cursor right
;   $91 = move the cursor down
;   $9D = move the cursor left
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
            BCC printc          ; [$20..$7E]: print it
            CMP #$A0
            BCS printc          ; [$A0..$FF]: print it

check_ctrl1 CMP #K_DOWN         ; If the down arrow key was pressed
            BEQ go_down         ; ... move the cursor down one row
            CMP #K_LEFT         ; If the left arrow key was pressed
            BEQ go_left         ; ... move the cursor left one column
            BRA done

check_ctrl0 CMP #CHAR_BS        ; Print a backspace and let the kernel handle it
            BEQ printc
            CMP #CHAR_CR        ; If the carriage return was pressed
            BEQ do_cr           ; ... move cursor down and to the first column
            CMP #K_UP           ; If the up arrow key was pressed
            BEQ go_up           ; ... move the cursor up one row
            CMP #K_RIGHT        ; If the right arrow key was pressed
            BEQ go_right        ; ... move the cursor right one column

            BRA done            ; Ignore anything else

do_cr       LDX #0              ; Handle a carriage return
            BRA cursor_down

go_down     LDX CURSORX         ; Move the cursor down one row
cursor_down LDY CURSORY
            INY
            CPY LINES_VISIBLE
            BCC set_xy

            DEY
            JSL FK_LOCATE

            CALL SCROLLUP       ; Scroll the screen up one row, if we're on the bottom
            BRA done

go_up       LDX CURSORX         ; Move the cursor up one row
            LDY CURSORY
            BEQ done
            DEY
            BRA set_xy

go_right    LDX CURSORX         ; Move the cursor right one column
            LDY CURSORY
            INX
            CPX COLS_VISIBLE
            BCC set_xy
            BRA done

go_left     LDX CURSORX         ; Move the cursor left one column
            BEQ done
            DEX
            LDY CURSORY
            BRA set_xy

set_xy      JSL FK_LOCATE       ; Set the cursor position
            BRA done

            ; TODO: make this more robust for variable screen sizes
            
printc      LDY CURSORY         ; Check to see if the character
            CPY #51             ; Is in the last cell...
            BLT do_putc         ; If not, we can return to the caller
            LDX CURSORX
            CPX #71
            BLT do_putc

            CALL SCROLLUP       ; Otherwise scroll

            LDX #0              ; And reposition the cursor
            JSL FK_LOCATE

do_putc     JSL FK_PUTC

done        PLP
            PLD
            PLY
            PLX
            RETURN
            .pend

;
; Copy the current line on the screen to the input buffer
; Trim whitespace from the end of the line to make input buffer null-terminated
;
SCRCOPYLINE .proc
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