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