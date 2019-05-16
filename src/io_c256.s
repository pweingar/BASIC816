;;;
;;; I/O Routines specific to the C256 Foenix
;;;
;;; Where possible, BASIC816 will use I/O routines corresponding to the 
;;; C256 Foenix Kernel. Glue routines that are needed to work on the
;;; C256 will go here. Otherwise, we just need the kernel jump table.
;;;

;
; C256 Foenix Kernel
;
FK_CLRSCREEN = $1900A8      ; Clear the screen
FK_PUTC = $190018           ; Foenix kernel routine to print a character to the currently selected channel
FK_PUTS  = $19001C          ; Print a string to the currently selected channel

.include "uart.s"

INITIO      .proc
            setas

            LDA #DEV_UART
            STA BCONSOLE

            setal
            LDA #1              ; Select COM1
            JSL UART_SELECT
            JSL UART_INIT       ; And initialize it

            ;JSL FK_CLRSCREEN

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

            JSL FK_PUTC
            
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
            CALL PUTC
            LDA #CHAR_LF
            CALL PUTC

            setal
            PLA
            PLP
            RETURN
            .pend