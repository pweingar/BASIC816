;;;
;;; I/O Routines specific to the C256 Foenix
;;;
;;; Where possible, BASIC816 will use I/O routines corresponding to the 
;;; C256 Foenix Kernel. Glue routines that are needed to work on the
;;; C256 will go here. Otherwise, we just need the kernel jump table.
;;;

.include "kernel_c256.s"
.if UARTSUPPORT = 1
.include "uart.s"
.endif
.include "keyboard.s"
.include "screen.s"

INITIO      .proc
            setas

            LDA #72             ; Make sure the screen size is right
            STA @lCOLS_VISIBLE  ; TODO: remove this when the kernel is correct
            LDA #52
            STA @lLINES_VISIBLE

            LDA #32             ; Set the border width
            STA BORDER_X_SIZE
            STA BORDER_Y_SIZE

            ; DEV_SCREEN | DEV_UART
.if UNITTEST = 1
            LDA #DEV_UART
.else
            LDA #DEV_SCREEN
.endif
            STA @lBCONSOLE

            LDA #$20
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