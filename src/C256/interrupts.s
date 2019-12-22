;;;
;;; Interrupt handler
;;;

VIRQ = $00FFEE      ; IRQ vector for native mode

.include "interrupt_def.s"

.section bootblock

;
; Initialize the interrupt system
;
INITIRQ         .proc
                SEI

                setaxl

                LDA #<>HANDLEIRQ            ; Set the interrupt vector
                STA VIRQ

                ; Setup the Interrupt Controller
                ; For Now all Interrupt are Falling Edge Detection (IRQ)
                LDA #$FF
                STA @lINT_EDGE_REG0
                STA @lINT_EDGE_REG1
                STA @lINT_EDGE_REG2
                ; Mask all Interrupt @ This Point
                STA @lINT_MASK_REG0
                STA @lINT_MASK_REG1
                STA @lINT_MASK_REG2

                LDA @lINT_PENDING_REG1  ; Read the Pending Register &
                AND #FNX1_INT00_KBD
                STA @lINT_PENDING_REG1  ; Writing it back will clear the Active Bit
                ; Disable the Mask
                LDA @lINT_MASK_REG1
                AND #~FNX1_INT00_KBD
                STA @lINT_MASK_REG1

                CLI

                RTL
                .pend


;
; Handler for IRQs
;
HANDLEIRQ       .proc
                setaxl
                PHA
                PHX
                PHY
                PHB
                PHD

                setdbr 0
                setdp 0

                setas

                LDA @lINT_PENDING_REG1
                AND #FNX1_INT00_KBD
                CMP #FNX1_INT00_KBD
                BNE done
                STA @lINT_PENDING_REG1

                ; Keyboard Interrupt
                JSR KEYBOARD_INTERRUPT

done            setaxl
                PLD
                PLB
                PLY
                PLX
                PLA
                RTI
                .pend

KEYBOARD_INTERRUPT
                ldx #$0000
                setxs
                setas
                ; Clear the Pending Flag
                LDA @lINT_PENDING_REG1
                AND #FNX1_INT00_KBD
                STA @lINT_PENDING_REG1

IRQ_HANDLER_FETCH
                LDA KBD_INPT_BUF        ; Get Scan Code from KeyBoard
                STA KEYBOARD_SC_TMP     ; Save Code Immediately

                ; Check for Shift Press or Unpressed
NOT_SCROLLLOCK  CMP #$2A                ; Left Shift Pressed
                BNE NOT_KB_SET_LSHIFT
                BRL KB_SET_SHIFT
NOT_KB_SET_LSHIFT
                CMP #$AA                ; Left Shift Unpressed
                BNE NOT_KB_CLR_LSHIFT
                BRL KB_CLR_SHIFT
NOT_KB_CLR_LSHIFT
                ; Check for right Shift Press or Unpressed
                CMP #$36                ; Right Shift Pressed
                BNE NOT_KB_SET_RSHIFT
                BRL KB_SET_SHIFT
NOT_KB_SET_RSHIFT
                CMP #$B6                ; Right Shift Unpressed
                BNE NOT_KB_CLR_RSHIFT
                BRL KB_CLR_SHIFT
NOT_KB_CLR_RSHIFT
                ; Check for CTRL Press or Unpressed
                CMP #$1D                ; Left CTRL pressed
                BNE NOT_KB_SET_CTRL
                BRL KB_SET_CTRL
NOT_KB_SET_CTRL
                CMP #$9D                ; Left CTRL Unpressed
                BNE NOT_KB_CLR_CTRL
                BRL KB_CLR_CTRL

NOT_KB_CLR_CTRL
                CMP #$38                ; Left ALT Pressed
                BNE NOT_KB_SET_ALT
                BRL KB_SET_ALT
NOT_KB_SET_ALT
                CMP #$B8                ; Left ALT Unpressed
                BNE NOT_KB_CLR_ALT
                BRL KB_CLR_ALT

NOT_KB_CLR_ALT  CMP #$E0                ; Prefixed scan code
                BNE NOT_PREFIXED
                BRL KB_SET_PREFIX

NOT_PREFIXED    CMP #$45                ; Numlock Pressed
                BNE NOT_KB_SET_NUM
                BRL KB_TOG_NUMLOCK

NOT_KB_SET_NUM  CMP #$46                ; Scroll Lock Pressed
                BNE NOT_KB_SET_SCR
                BRL KB_TOG_SCRLOCK

NOT_KB_SET_SCR  CMP #$3A                ; Caps Lock Pressed
                BNE KB_UNPRESSED
                BRL KB_TOG_CAPLOCK

KB_UNPRESSED    AND #$80                ; See if the Scan Code is press or Depressed
                CMP #$80                ; Depress Status - We will not do anything at this point
                BNE KB_NORM_SC
                BRL KB_CHECK_B_DONE

KB_NORM_SC      LDA KEYBOARD_SC_TMP       ;
                TAX
                LDA KEYBOARD_SC_FLG     ; Check to See if the SHIFT Key is being Pushed
                AND #$10
                CMP #$10
                BEQ SHIFT_KEY_ON

                LDA KEYBOARD_SC_FLG     ; Check to See if the CTRL Key is being Pushed
                AND #$20
                CMP #$20
                BEQ CTRL_KEY_ON

                LDA KEYBOARD_SC_FLG     ; Check to See if the ALT Key is being Pushed
                AND #$40
                CMP #$40
                BEQ ALT_KEY_ON

                LDA KEYBOARD_SC_FLG     ; Check to See if the Prefix was picked up before
                AND #$80
                CMP #$80
                BEQ PREFIX_ON

                ; Pick and Choose the Right Bank of Character depending if the Shift/Ctrl/Alt or none are chosen
                LDA @lScanCode_Press_Set1, x
                BRL KB_WR_2_SCREEN

SHIFT_KEY_ON    LDA @lScanCode_Shift_Set1, x
                BRL KB_WR_2_SCREEN

CTRL_KEY_ON     LDA @lScanCode_Ctrl_Set1, x
                BRL KB_WR_2_SCREEN

ALT_KEY_ON      LDA @lScanCode_Alt_Set1, x
                BRL KB_WR_2_SCREEN

PREFIX_ON       LDA KEYBOARD_SC_FLG
                AND #$7F
                STA KEYBOARD_SC_FLG
                
                LDA @lScanCode_Prefix_Set1, x
                ; Write Character to Screen (Later in the buffer)
KB_WR_2_SCREEN  CMP #$18                ; Is it SysRq?
                BNE savechar
                JMP programmerKey       ; Yes: trigger the programmer key

savechar        PHA
                setxl
                JSL SAVECHAR2CMDLINE
                setas
                PLA
                JMP KB_CHECK_B_DONE

KB_SET_SHIFT    LDA KEYBOARD_SC_FLG
                ORA #$10
                STA KEYBOARD_SC_FLG

                JMP KB_CHECK_B_DONE

KB_CLR_SHIFT    LDA KEYBOARD_SC_FLG
                AND #$EF
                STA KEYBOARD_SC_FLG
                JMP KB_CHECK_B_DONE

KB_SET_CTRL     LDA KEYBOARD_SC_FLG
                ORA #$20
                STA KEYBOARD_SC_FLG
                JMP KB_CHECK_B_DONE

KB_CLR_CTRL     LDA KEYBOARD_SC_FLG
                AND #$DF
                STA KEYBOARD_SC_FLG
                JMP KB_CHECK_B_DONE

KB_SET_ALT      LDA KEYBOARD_SC_FLG
                ORA #$40
                STA KEYBOARD_SC_FLG
                JMP KB_CHECK_B_DONE

KB_CLR_ALT      LDA KEYBOARD_SC_FLG
                AND #$BF
                STA KEYBOARD_SC_FLG
                JMP KB_CHECK_B_DONE

KB_SET_PREFIX   LDA KEYBOARD_SC_FLG
                ORA #$80
                STA KEYBOARD_SC_FLG
                JMP KB_CHECK_B_DONE

KB_TOG_SCRLOCK  LDA KEYBOARD_LOCKS
                EOR #KB_SCROLL_LOCK         ; toggle the Scroll Lock flag
                STA KEYBOARD_LOCKS
                JMP KB_CHECK_B_DONE

KB_TOG_NUMLOCK  LDA KEYBOARD_LOCKS
                EOR #KB_NUM_LOCK            ; toggle the Num Lock flag
                STA KEYBOARD_LOCKS
                JMP KB_CHECK_B_DONE

KB_TOG_CAPLOCK  LDA KEYBOARD_LOCKS
                EOR #KB_CAPS_LOCK           ; toggle the Caps Lock flag
                STA KEYBOARD_LOCKS

KB_CHECK_B_DONE .as
                LDA STATUS_PORT
                AND #OUT_BUF_FULL           ; Test bit $01 (if 1, Full)
                CMP #OUT_BUF_FULL           ; if Still Byte in the Buffer, fetch it out
                BNE SET_LED
                JMP IRQ_HANDLER_FETCH

SET_LED         ; LDA #$ED                    ; Command to set LEDs
;                 STA KBD_CMD_BUF             ; Send the command
;                 JSR Poll_Inbuf              ; Wait for the keyboard to be ready
;                 LDA KEYBOARD_LOCKS          ; Get the current lock status
;                 STA KBD_DATA_BUF            ; And send it to the keyboard
;                 JSR Poll_Inbuf              ; Wait for the keyboard to be ready

KB_DONE         setaxl
                RTS

SAVECHAR2CMDLINE
                PHD
                setas

                PHA                     ; Save the character
                LDA KEYBOARD_LOCKS      ; Check the keyboard lock flags
                AND #KB_CAPS_LOCK       ; Is CAPS lock on?
                BEQ no_caps             ; No... just use the character as-is

                PLA                     ; Get the character back
                CMP #'a'                ; Is it < 'a'
                BLT check_break         ; Yes: just use as-is
                CMP #'z'+1              ; Is it > 'z'
                BGE check_break         ; Yes: just us as-is

                AND #%11011111          ; Conver to upper case
                BRA check_break

no_caps         PLA                     ; Restore the character

check_break     CMP #0
                BEQ done
                CMP #CHAR_CTRL_C        ; Is it CTRL-C?
                BEQ flag_break          ; Yes: flag a break

no_break        LDX KEY_BUFFER_WPOS     ; So the Receive Character is saved in the Buffer

                ; Save the Character in the Buffer
                CPX #KEY_BUFFER_SIZE    ; Make sure we haven't been overboard.
                BCS done                ; Stop storing - An error should ensue here...

                STA @lKEY_BUFFER, X
                INX
                STX KEY_BUFFER_WPOS
                LDA #$00
                STA @lKEY_BUFFER, X     ; Store a EOL in the following location for good measure

done            PLD
                RTL

;
; The user has pressed the "programmer's key" which should bring up the monitor
;
programmerKey   setaxl
                PLA                     ; Get and throw-away the return address to the interrupt handler
                PLD                     ; Restore the registers that were present when the handler was invoked
                PLB
                PLY
                PLX
                PLA
                JML HBREAK              ; And go to the BRK handler directly to open the monitor

flag_break      setas
                LDA #$80                ; Flag that an interrupt key has been pressed
                STA @lKEYFLAG           ; The interpreter should see this soon and throw a BREAK
                BRA done

Poll_Inbuf	    .as
                LDA STATUS_PORT		; Load Status Byte
                AND	#<INPT_BUF_FULL	; Test bit $02 (if 0, Empty)
                CMP #<INPT_BUF_FULL
                BEQ Poll_Inbuf
                RTS

.send