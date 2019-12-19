;;;
;;; Wrapper for basic I/O functions
;;;

.include "interrupts.s"
.include "keyboard_def.s"

;
; Read a line of text from the user into INPUTBUF.
; This routine provides only a single-line editor and is intended for use by the INPUT command
;
IINPUTLINE      .proc
                PHP
                TRACE "IINPUTLINE"

                setxl
                setas
                LDA #1              ; Show the cursor
                CALL SHOWCURSOR

                ; Zero out the input buffer
                LDX #0
                LDA #0
zero_loop       STA @lIOBUF,X
                INX
                CPX #$100
                BNE zero_loop

                LDX #0
getchar         CALL GETKEY         ; Get a keypress
                CMP #CHAR_CR        ; Got a CR?
                BNE not_cr
                JMP endofline       ; Yes: we're done

not_cr          CMP #K_LEFT         ; Is it the left cursor?
                BNE not_left
                CPX #0              ; Are we all the way to the left?
                BEQ getchar         ; Yes: ignore it
                DEX                 ; Move the cursor back
                BRA echo            ; And echo it

not_left        CMP #K_RIGHT        ; Is it the right arrow?
                BNE not_right
                LDA @lIOBUF,X       ; Check the current character
                BEQ getchar         ; If it's already blank, we're as far right as we go
                CPX #79             ; Are we at the end of the line?
                BEQ getchar         ; Yes: ignore it
                INX                 ; Otherwise: advance the cursor
                BRA echo            ; And print the code

not_right       CMP #CHAR_BS        ; Is it a backspace?
                BNE not_bs

                CPX #0              ; Are we at the beginning of the line?
                BEQ getchar         ; yes: ignore the backspace
                
                PHX                 ; Save the cursor position
clr_loop        LDA @lIOBUF+1,X     ; Get the character above
                STA @lIOBUF,X       ; Save it to the current position
                BEQ done_clr        ; If we copied a NUL, we're done copying
                INX                 ; Otherwise, keep copying down
                CPX #$FF            ; Until we're at the end of the buffer
                BNE clr_loop
done_clr        PLX                 ; Restore the cursor position

                DEX                 ; No: move the cursor left
                BRA print_bs        ; And print the backspace

not_bs          CMP #$20            ; Is it in range 00 -- 1F?
                BLT getchar         ; Yes: ignore it

                ; A regular printable key was found
                STA @lIOBUF,X       ; Save it to the input buffer
                INX                 ; Move the cursor forward

echo            CALL PRINTC         ; Print the character
                BRA getchar         ; And get another...

                ; Print a backspace 
print_bs        LDA #CHAR_BS        ; Backspace character...
                CALL PRINTC         ; Print the character
                BRA getchar         ; And get another...

                ; We've finished the line... return to the caller
endofline       LDA #0              ; Hide the cursor
                CALL SHOWCURSOR

                PLP
                RETURN
                .pend

;
; Get a character from the keyboard input buffer
; Blocks if there are no keys in the buffer.
;
; Outputs:
;   A = the key read
;
IGETKEY         .proc
                PHX
                PHD
                PHP
                ;TRACE "IGETKEY"

                setdp KEY_BUFFER_RPOS

                setas
                setxl

                CLI                     ; Make sure interrupts can happen

get_wait        LDX KEY_BUFFER_RPOS     ; Is KEY_BUFFER_RPOS < KEY_BUFFER_WPOS
                CPX KEY_BUFFER_WPOS
                BCC read_buff           ; Yes: a key is present, read it
                BRA get_wait            ; Otherwise, keep waiting

read_buff       SEI                     ; Don't interrupt me!

                LDA @lKEY_BUFFER,X      ; Get the key

                INX                     ; And move to the next key
                CPX KEY_BUFFER_WPOS     ; Did we just read the last key?
                BEQ reset_indexes       ; Yes: return to 0 position

                STX KEY_BUFFER_RPOS     ; Otherwise: Update the read index

                CLI

done            PLP                     ; Restore status and interrupts
                PLD
                PLX
                RTS

reset_indexes   STZ KEY_BUFFER_RPOS     ; Reset read index to the beginning
                STZ KEY_BUFFER_WPOS     ; Reset the write index to the beginning
                BRA done
                .pend

;
;
; Get a character from the keyboard input buffer and echo it to the screen
; Blocks if there are no keys in the buffer.
;
; Outputs:
;   A = the key read
;
GETKEYE         .proc
                ;TRACE "GETKEYE"
                CALL GETKEY
                PHA
                CALL PRINTC
                PLA
                RETURN
                .pend

K_UP = $11      ; Keypad UP
K_RIGHT = $1D   ; Keypad Right
K_DOWN = $91    ; Keypad Down
K_LEFT = $9D    ; Keypad Left

ScanCode_Press_Set1   .text $00, $1B, $31, $32, $33, $34, $35, $36, $37, $38, $39, $30, $2D, $3D, $08, $09    ; $00
                      .text $71, $77, $65, $72, $74, $79, $75, $69, $6F, $70, $5B, $5D, $0D, $00, $61, $73    ; $10
                      .text $64, $66, $67, $68, $6A, $6B, $6C, $3B, $27, $60, $00, $5C, $7A, $78, $63, $76    ; $20
                      .text $62, $6E, $6D, $2C, $2E, $2F, $00, $2A, $00, $20, $00, $00, $00, $00, $00, $00    ; $30
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $11, $00, $00, $9D, $00, $1D, $00, $00    ; $40
                      .text $91, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $50
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $60
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $70

ScanCode_Shift_Set1   .text $00, $00, $21, $40, $23, $24, $25, $5E, $26, $2A, $28, $29, $5F, $2B, $08, $09    ; $00
                      .text $51, $57, $45, $52, $54, $59, $55, $49, $4F, $50, $7B, $7D, $0D, $00, $41, $53    ; $10
                      .text $44, $46, $47, $48, $4A, $4B, $4C, $3A, $22, $7E, $00, $5C, $5A, $58, $43, $56    ; $20
                      .text $42, $4E, $4D, $3C, $3E, $3F, $00, $2A, $00, $20, $00, $00, $00, $00, $00, $00    ; $30
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $40
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $50
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $60
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $70

ScanCode_Ctrl_Set1    .text $00, $1B, $31, $32, $33, $34, $35, $36, $37, $38, $39, $30, $2D, $3D, $08, $09    ; $00
                      .text $71, $77, $65, $72, $74, $79, $75, $69, $6F, $70, $5B, $5D, $0D, $00, $61, $73    ; $10
                      .text $64, $66, $67, $68, $6A, $6B, $6C, $3B, $27, $60, $00, $5C, $7A, $78, $03, $76    ; $20
                      .text $62, $6E, $6D, $2C, $2E, $2F, $00, $2A, $00, $20, $00, $00, $00, $00, $00, $00    ; $30
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $40
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $50
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $60
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $70

ScanCode_Alt_Set1     .text $00, $1B, $31, $32, $33, $34, $35, $36, $37, $38, $39, $30, $2D, $3D, $08, $09    ; $00
                      .text $71, $77, $65, $72, $74, $79, $75, $69, $6F, $70, $5B, $5D, $0D, $00, $61, $73    ; $10
                      .text $64, $66, $67, $68, $6A, $6B, $6C, $3B, $27, $60, $00, $5C, $7A, $78, $63, $76    ; $20
                      .text $62, $6E, $6D, $2C, $2E, $2F, $00, $2A, $00, $20, $00, $00, $00, $00, $00, $00    ; $30
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $40
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $50
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $60
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $70

ScanCode_NumLock_Set1 .text $00, $1B, $31, $32, $33, $34, $35, $36, $37, $38, $39, $30, $2D, $3D, $08, $09    ; $00
                      .text $71, $77, $65, $72, $74, $79, $75, $69, $6F, $70, $5B, $5D, $0D, $00, $61, $73    ; $10
                      .text $64, $66, $67, $68, $6A, $6B, $6C, $3B, $27, $60, $00, $5C, $7A, $78, $63, $76    ; $20
                      .text $62, $6E, $6D, $2C, $2E, $2F, $00, $2A, $00, $20, $00, $00, $00, $00, $00, $00    ; $30
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $40
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $50
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $60
                      .text $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00    ; $70
                      