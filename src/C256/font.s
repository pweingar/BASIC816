;;;
;;; Set up a font for BASIC
;;;

INITFONT        .proc
                PHP

                setas
                setxl
                LDX #$0000

loop            LDA @lBASIC_FONT,X    ; RAM Content
                STA @lFONT_MEMORY_BANK0,X ; Vicky FONT RAM Bank
                INX
                CPX #$0800
                BNE loop

                LDA #$7F
                STA @lVKY_TXT_CURSOR_CHAR_REG

                PLP
                RETURN
                .pend

;BASIC_FONT      .binary "resources/MSX_8x8.bin", 0, 2048
;BASIC_FONT      .binary "resources/AppleLikeFont.bin", 0, 2048
BASIC_FONT      .binary "resources/CBM-ASCII_8x8.bin", 0, 2048