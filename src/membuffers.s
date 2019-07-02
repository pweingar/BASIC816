;;;
;;; Memory buffers to abstract I/O
;;;

.section globals
OBUFFER     .long ?     ; Pointer to the current text memory buffer for output
OBUFFSIZE   .word ?     ; Maximum size of output text memory buffer
OBUFFIDX    .word ?     ; Index into the current output buffer

IBUFFER     .long ?     ; Pointer to the current text memory buffer for input
IBUFFSIZE   .word ?     ; Number of bytes written to the buffer
IBUFFIDX    .word ?     ; Index into the current input buffer (next available character)
.send

;
; Read a line from the IBUFFER to the input buffer
; (Yes, yes, I know the naming here is terrible)
; TODO: rename the input buffer to something else? Line buffer?
;
; Inputs:
;   IBUFFER = pointer to the first character of the input buffer
;   IBUFFSIZE = the number of bytes in the buffer
;   IBUFFIDX = the number of the next available character
;
; Outputs:
;   IBUFFER = pointer to the line read from the input buffer, ready for tokenization
;
IBUFF_READLINE  .proc
                PHX
                PHP

                setxl
                LDX #0

                setas
loop            CALL IBUFF_GETC
                BCC end_of_line         ; Was the buffer empty: treat it as end of line
                BEQ end_of_line         ; Got a null? treat it as end of line
                CMP #CHAR_CR            ; Is it a newline?
                BEQ end_of_line         ; Yes: treat it as end of line

                STA @lINPUTBUF,X        ; Save the character
                CMP #0                  ; Is it a NULL?
                BEQ end_of_line         ; Yes: treat it as an end of buffer
                INX
                BRA loop

end_of_line     LDA #0                  ; End the line with a NULL
                STA @lINPUTBUF,X

                PLP
                PLX
                RETURN
                .pend

;
; Check to see if the IBUFFER is empty
;
; Inputs:
;   IBUFFER = pointer to the first character of the input buffer
;   IBUFFSIZE = the number of bytes in the buffer
;   IBUFFIDX = the number of the next available character
;
; Affects:
;   Index register widths
;   X
;
; Outputs:
;   N is set if there is data still, clear if it is empty
;
IBUFF_EMPTY     .proc
                setxl
                LDX IBUFFIDX
                CPX IBUFFSIZE
                RETURN
                .pend

;
; Read a character from the input buffer
;
; Inputs:
;   IBUFFER = pointer to the first character of the input buffer
;   IBUFFSIZE = the number of bytes in the buffer
;   IBUFFIDX = the number of the next available character
;
; Outputs:
;   A = the character read
;   C is set if a character was read, clear if there was nothing ready yet
;
IBUFF_GETC      .proc
                PHY
                PHP

                setdp GLOBAL_VARS

                setas
                setxl
                LDY IBUFFIDX        ; Is the index >= the size?
                CPY IBUFFSIZE
                BPL ret_false       ; Yes: we're at the end of the buffer, return false

                LDA [IBUFFER],Y     ; No: Get the next character

                setal
                AND #$00FF          ; Make sure the high byte is empty
                INC IBUFFIDX        ; And point to the next character

ret_true        PLP
                PLY
                SEC
                RETURN

ret_false       PLP
                PLY
                CLC
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