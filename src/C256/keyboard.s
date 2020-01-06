;;;
;;; Wrapper for basic I/O functions
;;;

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
                TRACE "IGETKEY"

                JSL FK_GETCHW

                RETURN
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
