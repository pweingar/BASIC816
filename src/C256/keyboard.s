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

; not_cr          CMP #K_LEFT         ; Is it the left cursor?
;                 BNE not_left
;                 CPX #0              ; Are we all the way to the left?
;                 BEQ getchar         ; Yes: ignore it
;                 DEX                 ; Move the cursor back
;                 BRA echo            ; And echo it

; not_left        CMP #K_RIGHT        ; Is it the right arrow?
;                 BNE not_right
;                 LDA @lIOBUF,X       ; Check the current character
;                 BEQ getchar         ; If it's already blank, we're as far right as we go
;                 CPX #79             ; Are we at the end of the line?
;                 BEQ getchar         ; Yes: ignore it
;                 INX                 ; Otherwise: advance the cursor
;                 BRA echo            ; And print the code

not_cr
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
                ;TRACE "IGETKEY"
                PHX
                PHY
                PHB
                PHD
                PHP

                JSL FK_GETCHW

                PLP
                PLD
                PLB
                PLY
                PLX
                RETURN
                .pend

GK_ST_INIT = 0      ; GETKEYE state: initial
GK_ST_ESC = 1       ; GETKEYE state: ESC seen
GK_ST_CSI = 2       ; GETKEYE state: CSI "ESC[" seen
GK_ST_CODE = 3      ; GETKEYE state: We're at the command code in the sequence
GK_ST_MODS = 4      ; GETKEYE state: We're at the modifier code in the sequence

;
; Send an ANSI command code
;
; Inputs:
;   A = the command code to send to the console
; 
SEND_ANSI       .proc
                PHP

                setaxs
                PHA
                LDA #CHAR_ESC           ; Print ESC
                CALL PRINTC

                LDA #'['                ; Print [
                CALL PRINTC

                PLA                     ; Print the command code
                CALL PRINTC

                PLP
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
                PHD
                PHB
                PHP
                ;TRACE "GETKEYE"

                setdbr 0
                setdp GLOBAL_VARS

locals          .virtual 1,S
l_character     .byte ?                 ; The character returned by the input stream
l_state         .byte ?                 ; Current state of the input parser
l_code          .byte ?                 ; Code number for any escaped input sequence
l_modifiers     .byte ?                 ; Modifier bit field for any escaped input sequence
                .endv
                SALLOC SIZE(locals)

                setas
get_reset       LDA #0                  ; Initialize state, code, and modifiers
                STA l_state
                STA l_code
                STA l_modifiers

loop            CALL GETKEY             ; Get a key from the input stream
                CMP #0                  ; Is it 0?
                BEQ loop                ; Yes: keep waiting

                STA l_character         ; Save the character
                
                LDA l_state             ; What is the current state?
                BNE chk_st_esc         

                ; Initial state... echo character unless it's ESC

                LDA l_character         ; Get the character back
                CMP #CHAR_BS            ; Is it a backspace?
                BNE not_bs

                CALL PRINTC             ; Print the backspace
                LDA #'P'
                CALL SEND_ANSI          ; Send the ANSI code for DCH
                BRA loop                ; And keep waiting for a keypress

not_bs          CMP #CHAR_CR            ; Is it a carriage return?
                BEQ send                ; Yes: print and return it
                
                CMP #CHAR_ESC           ; Is it ESC?
                BNE send                ; No: just print it out

                LDA #GK_ST_ESC          ; Yes: move to the ESC state
                STA l_state
                BRA loop                ; And get the next character in the sequence
                
send            CALL PRINTC             ; Echo the character to the console

done            LDA l_character         ; Save the character so we can return it
                STA SCRATCH
                
                SFREE SIZE(locals)      ; Clean the locals from the stack

                setas
                LDA SCRATCH             ; Restore the character we're returning
                PLP
                PLD
                PLB
                RETURN

chk_st_esc      CMP #GK_ST_ESC          ; Are we in the ESC state?
                BNE chk_st_csi          ; No: check to see if we're in CSI state

                ; ESC state: check for [ to enter CSI

                LDA l_character         ; Get the character
                CMP #'['                ; Is it "["?
                BEQ go_st_csi           ; Yes: go to the CSI state 
                BRL get_reset           ; Reset the state machine and keep reading characters

go_st_csi       LDA #GK_ST_CSI          ; Yes: move to the CSI state
                STA l_state
                BRL loop

chk_st_csi      CMP #GK_ST_CSI          ; Are we in the CSI state?
                BNE chk_st_code         ; No: check to see if we're in the code state

                ; CSI state: check for a 'A'..'D' or '0'..'9'

                LDA l_character         ; Check the character
                CMP #'A'                ; Is it in 'A'..'D'?
                BLT not_letter
                CMP #'D'+1
                BGE not_letter

                ; Is 'A'..'D'...

                LDA l_character         ; Yes: it's a cursor key, send the sequence to the screen
                CALL SEND_ANSI
                BRL get_reset           ; Reset the state machine and keep reading characters

not_letter      CMP #'0'                ; Is it in range '0'..'9'?
                BLT not_csi_digit
                CMP #'9'+1
                BGE not_csi_digit       ; No: handle it being invalid

                SEC                     ; Yes: convert to a value
                SBC #'0'
                STA l_code              ; And save it to the code variable

                LDA #GK_ST_CODE         ; Move to the CODE state
                STA l_state
                BRL loop

not_csi_digit   BRL get_reset           ; Bad sequence: reset and keep reading characters

chk_st_code     CMP #GK_ST_CODE         ; Is it the  state?
                BNE done

                ; CODE state: read digits... end on semicolon or tilda

                LDA l_character         ; Check the character

                CMP #'0'                ; Is it in the range '0'..'9'
                BLT not_digits_2
                CMP #'9'+1
                BGE not_digits_2
                
                ; We have a digit... multiply the code by ten and add it

                LDA l_code              ; Multiply l_code by 2
                ASL A
                STA SCRATCH
                ASL A                   ; Multiply l_code by 8
                ASL A
                CLC
                ADC SCRATCH             ; Add to get l_code * 10

                LDA l_character         ; Convert the digit to a number
                SEC
                SBC #'0'

                CLC                     ; And add to l_code
                ADC SCRATCH
                STA l_code

                BRL loop                ; And keep processing the sequence

not_digits_2    ; CMP #';'                ; Is it the semicolon?
                ; BNE not_semi

                ; LDA #GK_ST_MODS         ; Yes: Move to the MODIFIERS state
                ; STA l_state
                ; BRL loop

not_semi        CMP #'~'                ; No: Is it the tilda?
                BEQ end_sequence        ; Yes: we've gotten the end of the sequence
                BRL get_reset           ; No: we've got a bad sequence... for now just reset and keep looping

                ; We have a complete code here... interpret it and send the correct sequence...

end_sequence    LDA l_code              ; Get the code
                CMP #ANSI_IN_INS        ; Is it INSERT?
                BEQ do_ins              ; Yes: process the insert
                CMP #ANSI_IN_DEL        ; Is it DELETE?
                BEQ do_del              ; Yes: process the delete

                ; TODO: handle HOME, END, F12?

                BRL get_reset           ; Code is not one we handle, just return

do_ins          LDA #'@'                ; Send the ANSI ICH command
                BRA snd_ansi

do_del          LDA #'P'                ; Send the ANSI DCH command
snd_ansi        CALL SEND_ANSI
                BRL get_reset           ; Reset and keep getting characters
                .pend
