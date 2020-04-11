;;;
;;; Core I/O Functions
;;;

.include "membuffers.s"

.if SYSTEM == SYSTEM_C64
.include "CBM/io_cbm.s"
.elsif SYSTEM == SYSTEM_C256
.include "C256/io_c256.s"
.endif

LINES_PER_PAGE = 10     ; The number of lines to print on a page before pausing

DEV_SCREEN = $80        ; Use the screen and keyboard for the console device
DEV_UART = $40          ; Use UART for console device
DEV_BUFFER = $20        ; Use the current text memory buffer for output or input

.section globals
BCONSOLE    .byte ?     ; Device for BASIC console
SAVE_A      .byte ?     ; Save spot for the A register
LINECOUNT   .byte ?     ; Counter for new lines to support pagination
.send

;
; Count calls to PAGINATE (one per line) and pause if we have printed a screen.
; Wait for the user to press a key.
;
PAGINATE    .proc
            PHP
            PHD

            setdp GLOBAL_VARS
            setas

            LDA LINECOUNT           ; Check the line count
            INC A
            STA LINECOUNT

            CMP @lLINES_VISIBLE
            BLT done                ; If < limit, just return

            CALL GETKEY             ; If >= limit, wait for a keypress
            STZ LINECOUNT           ; And reset the line count

done        PLD
            PLP
            RETURN
            .pend

;
; Send the character in A to the conole
;
; Inputs:
;   A = the character to print
;   BCONSOLE = the device number for the console
;
IPRINTC     .proc
            PHP
            setas
            setxl
            PHX
            PHY

            STA @lSAVE_A

chk_out     LDA @lBCONSOLE      ; Check to see if we should send to an output buffer
            AND #DEV_BUFFER
            BEQ check_scrn      ; No... move on to the hardware screen
            
            LDA @lSAVE_A
            CALL OBUFF_PUTC     ; Yes... print the character to the buffer

check_scrn  LDA @lBCONSOLE
            AND #DEV_SCREEN     ; Check to see if the screen is selected
            BEQ send_uart
            LDA @lSAVE_A
            CALL SCREEN_PUTC    ; Yes... Send the character to the screen

send_uart   LDA @lBCONSOLE
            AND #DEV_UART       ; Check to see if the UART is active
            BEQ done
            LDA @lSAVE_A
            CALL UART_PUTC      ; Yes... send the character to the UART

            LDA @lSAVE_A        ; If sending a CR to the serial port
            CMP #CHAR_CR
            BNE done
            LDA #CHAR_LF        ; Send a linefeed after
            CALL UART_PUTC

done        PLY
            PLX
            PLP
            RETURN
            .pend

;
; Send a null-terminated string to the console
;
; Inputs:
;   B = bank of the string to print
;   X = pointer to the string to print
;   BCONSOLE = the device number for the console
;
PRINTS      .proc
            PHP

            setas
loop        LDA #0,B,X
            BEQ done

            CALL PRINTC

            INX
            BRA loop

done        PLP
            RETURN
            .pend

;
; Print a 16-bit word as hex
;
PRHEXW      .proc
            PHP
            setal
            PHA

            PHA
            .rept 8
            LSR A
            .next
            CALL PRHEXB
            PLA

            AND #$00FF
            CALL PRHEXB

            PLA
            PLP
            RETURN
            .pend

;
; Print a byte as hex
;
; Inputs:
;   A = the byte to print
PRHEXB      .proc
            PHP
            setal
            PHA

            setas
            PHA
            LSR A
            LSR A
            LSR A
            LSR A
            CALL PRHEXN
            PLA

            CALL PRHEXN

            setal
            PLA
            PLP
            RETURN
            .pend

;
; Print a nybble as hex
;
; Inputs:
;   A = the nybble to print
;
PRHEXN      .proc
            PHP
            setaxl
            PHX

            AND #$000F
            TAX
            LDA @lHEXDIGITS,X
            CALL PRINTC

            PLX
            PLP
            RETURN
            .pend

.section data
HEXDIGITS   .text "0123456789ABCDEF"
.send


