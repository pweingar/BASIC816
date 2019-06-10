;;;
;;; Wrapper for basic I/O functions
;;;

.include "interrupts.s"
.include "keyboard_def.s"

KEY_BUFFER       = $000F00 ;64 Bytes keyboard buffer
KEY_BUFFER_SIZE  = $0080   ;128 Bytes (constant) keyboard buffer length
KEY_BUFFER_END   = $000F7F ;1 Byte  Last byte of keyboard buffer
KEY_BUFFER_CMD   = $000F83 ;1 Byte  Indicates the Command Process Status
COMMAND_SIZE_STR = $000F84 ; 1 Byte
COMMAND_COMP_TMP = $000F86 ; 2 Bytes
KEYBOARD_SC_FLG  = $000F87 ;1 Bytes that indicate the Status of Left Shift, Left CTRL, Left ALT, Right Shift
KEYBOARD_SC_TMP  = $000F88 ;1 Byte, Interrupt Save Scan Code while Processing
KEY_BUFFER_RPOS  = $000050  ;2 byte: index of the first key to read
KEY_BUFFER_WPOS  = $000052  ;2 byte: index of the first key to write

;
; Get a character from the keyboard input buffer
; Blocks if there are no keys in the buffer.
;
; Outputs:
;   A = the key read
;
GETKEY          .proc
                PHX
                PHD
                PHP

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

done            PLP                     ; Restore status and interrupts
                PLD
                PLX
                RTL

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
                JSL GETKEY
                PHA
                CALL PRINTC
                PLA
                RTL
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
                      .text $64, $66, $67, $68, $6A, $6B, $6C, $3B, $27, $60, $00, $5C, $7A, $78, $63, $76    ; $20
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
                      