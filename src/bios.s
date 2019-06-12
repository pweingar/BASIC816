;;;
;;; Core I/O Functions
;;;

.if SYSTEM == SYSTEM_C64
.include "CBM/io_cbm.s"
.elsif SYSTEM == SYSTEM_C256
.include "C256/io_c256.s"
.endif

DEV_SCREEN = $80        ; Use the screen and keyboard for the console device
DEV_UART = $40          ; Use UART for console device
DEV_BUFFER = $20        ; Use the current text memory buffer for output or input

.section globals
BCONSOLE    .byte ?     ; Device for BASIC console
SAVE_A      .byte ?     ; Save spot for the A register
OBUFFER     .long ?     ; Pointer to the current text memory buffer for output
OBUFFSIZE   .word ?     ; Maximum size of output text memory buffer
OBUFFIDX    .word ?     ; Index into the current output buffer
.send

;
; Send the character in A to the conole
;
; Inputs:
;   A = the character to print
;   BCONSOLE = the device number for the console
;
PRINTC      .proc
            PHP
            setas
            setxl
            PHX
            PHY

            STA @lSAVE_A

            LDA @lBCONSOLE      ; Check to see if we should send to an output buffer
            BIT #DEV_BUFFER
            BEQ check_scrn      ; No... move on to the hardware screen
            
            LDA @lSAVE_A
            CALL OBUFF_PUTC     ; Yes... print the character to the buffer

check_scrn  BIT #DEV_SCREEN     ; Check to see if the screen is selected
            BEQ send_uart
            LDA @lSAVE_A
            CALL SCREEN_PUTC    ; Yes... Send the character to the screen

send_uart   BIT #DEV_UART       ; Check to see if the UART is active
            BEQ done
            LDA @lSAVE_A
            JSL UART_PUTC       ; Yes... send the character to the UART

            LDA @lSAVE_A        ; If sending a CR to the serial port
            CMP #CHAR_CR
            BNE done
            LDA #CHAR_LF        ; Send a linefeed after
            JSL UART_PUTC

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
; Write a character to the current output text buffer (unless the index is at the end of the buffer)
;
; Inputs:
;   A = the character to write
;   OBUFFER = pointer to the beginning of the buffer
;   OBUFFIDX = index to the current writable position in the buffer
;   OBUFFSIZE = size of the current output buffer
;
OBUFF_PUTC      .proc
                PHB

                setas
                STA SAVE_A

                setdp GLOBAL_VARS

                setal               ; Check to make sure a buffer is set
                LDA OBUFFER
                BNE has_buffer
                setas
                LDA OBUFFER+2
                BEQ done

has_buffer      setxl
                LDY OBUFFIDX        ; Check to make sure there is room
                CPY OBUFFSIZE
                BEQ done            ; If not, exit silently
                
                setas
                LDA SAVE_A
                STA [OBUFFER],Y     ; Write the character to the buffer

                INY                 ; Increment the index
                STY OBUFFIDX

done            PLB
                RETURN
                .pend

;
; Terminate the string in the output buffer and turn off the output buffer
;
OBUFF_CLOSE     .proc
                PHP
            
                setas
                LDA #0
                CALL OBUFF_PUTC                 ; Terminate the string in the output buffer

                LDA BCONSOLE
                AND #~DEV_BUFFER                ; Turn off the output buffer
                STA BCONSOLE

                PLP
                RETURN
                .pend

;
; Write a null-terminated string to a memory buffer
;
; Inputs:
;   B = data bank of the string
;   X = pointer to the string to print
OBUFF_PUTS      .proc
                PHP
                setaxl
                PHA
                PHX

                setas
loop            LDA #0,B,X          ; Get the character
                BEQ done            ; If it's NULL, we're done
                CALL OBUFF_PUTC     ; Otherwise, send it to the current buffer
                INX
                BRA loop

done            setaxl
                PLX
                PLA
                PLP
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

HEXDIGITS   .text "0123456789ABCDEF"


