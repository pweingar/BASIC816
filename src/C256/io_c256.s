;;;
;;; I/O Routines specific to the C256 Foenix
;;;
;;; Where possible, BASIC816 will use I/O routines corresponding to the 
;;; C256 Foenix Kernel. Glue routines that are needed to work on the
;;; C256 will go here. Otherwise, we just need the kernel jump table.
;;;

.include "kernel_c256.s"
.include "RTC_inc.s"
.if UARTSUPPORT = 1
.include "uart.s"
.endif
.include "keyboard.s"
.include "screen.s"
.include "font.s"
.include "files.s"

BORDER_WIDTH = 32               ; The width of the border (when it is on)
TEXT_COLS_WB = 72               ; Number of columns of text with the border enabled
TEXT_ROWS_WB = 52               ; Number of rows of text with the border enabled
TEXT_COLS_WOB = 80              ; Number of columns of text with no border enabled
TEXT_ROWS_WOB = 60              ; Number of rows of text with no border enabled

INITIO      .proc
            setas

            CALL INITFONT       ; Set up the BASIC font

            LDA #TEXT_COLS_WB   ; Make sure the screen size is right
            STA @lCOLS_VISIBLE  ; TODO: remove this when the kernel is correct
            LDA #TEXT_ROWS_WB
            STA @lLINES_VISIBLE

            LDA #BORDER_WIDTH   ; Set the border width
            STA BORDER_X_SIZE
            STA BORDER_Y_SIZE

            LDX #0              ; Clear all the sprite control shadow registers
            LDA #0
sp_loop     STA GS_SP_CONTROL,X
            INX
            CPX #SP_MAX
            BNE sp_loop

            ; DEV_SCREEN | DEV_UART
.if UNITTEST = 1
            LDA #DEV_UART
.else
            LDA #DEV_SCREEN
.endif
            STA @lBCONSOLE

            LDA #$F0
            STA @lCURCOLOR

.if UARTSUPPORT = 1
            setal
            LDA #1              ; Select COM1
            JSL UART_SELECT
            JSL UART_INIT       ; And initialize it
.endif

            JSL INITIRQ         ; Initialize the IRQs

done        RETURN
            .pend

;
; Sets ARGUMENT1 to the current time in BCD in the format 00HHMMSS
;
GETTIME     .proc
            PHP

            setas
            LDA @lRTC_CTRL          ; Pause updates to the clock registers
            ORA #%00001000
            STA @lRTC_CTRL

            LDA @lRTC_SEC           ; Copy the seconds in BCD
            STA ARGUMENT1

            LDA @lRTC_MIN           ; Copy the minutes in BCD
            STA ARGUMENT1+1

            LDA @lRTC_HRS           ; Copy the hour in BCD
            STA ARGUMENT1+2

            STZ @ARGUMENT1+3

            LDA @lRTC_CTRL          ; Re-enable updates to the clock registers
            AND #%11110111
            STA @lRTC_CTRL

            LDA #TYPE_INTEGER       ; Set the return type to integer because why not?
            STA ARGTYPE1

            PLP
            RETURN
            .pend

;
; Sets ARGUMENT1 to the current date in BCD in the format 00DDMMYY
;
GETDATE     .proc
            PHP

            setas
            LDA @lRTC_CTRL          ; Pause updates to the clock registers
            ORA #%00001000
            STA @lRTC_CTRL

            LDA @lRTC_YEAR          ; Copy the seconds in BCD
            STA ARGUMENT1

            LDA @lRTC_MONTH         ; Copy the minutes in BCD
            STA ARGUMENT1+1

            LDA @lRTC_DAY           ; Copy the hour in BCD
            STA ARGUMENT1+2

            STZ @ARGUMENT1+3

            LDA @lRTC_CTRL          ; Re-enable updates to the clock registers
            AND #%11110111
            STA @lRTC_CTRL

            LDA #TYPE_INTEGER       ; Set the return type to integer because why not?
            STA ARGTYPE1

            PLP
            RETURN
            .pend

;
; Send the character in A to the screen
;
; Inputs:
;   A = the character to print
;
SCREEN_PUTC .proc
            PHP
            setas
            PHA

            CALL WRITEC     ; TODO: replce with PUTC, once PUTC handles control characters
            
            PLA
            PLP
            RETURN
            .pend

;
; Send a string to the screen
;
; Inputs:
;   B = bank of the string to print
;   X = pointer to the string to print
;
SCREEN_PUTS .proc
            PHP
            setaxl
            PHX

            JSL FK_PUTS

done        setaxl
            PLX
            PLP
            RETURN
            .pend

; Print a new line
PRINTCR     .proc
            PHP
            setal
            PHA

            setas
            LDA #CHAR_CR
            CALL PRINTC

            setal
            PLA
            PLP
            RETURN
            .pend

; Stub to print a hex number... this is a long jump because I'm lazy
PRINTH      .proc
            PHP
            JSL FK_IPRINTH
            PLP
            RETURN
            .pend