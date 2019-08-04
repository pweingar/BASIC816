;;;
;;; Custom statements for the C256
;;;

; BLOAD path,destination
; BSAVE path,source
; LOAD path
; SAVE path

; SETLUTCOLOR lut,index,red,green,blue,alpha
;       Set the RGBA value for the given index of a given color LUT. LUT values are:
;           0 = graphics LUT 0
;           1 = graphics LUT 1
;           2 = graphics LUT 2
;           3 = graphics LUT 3
;           4 = graphics LUT 4
;           5 = graphics LUT 5
;           6 = graphics LUT 6
;           7 = graphics LUT 7
;           8 = text foreground LUT
;           9 = text background LUT
;           10 = gamma correction LUT

; GRAPHICS show_text,show_sprites,show_tiles,show_pixmap,gamma
;       Control which graphics blocks are enabled:
;           show_text = text system is showing (overlay if any other block is enabled)
;           show_sprites = sprite system is enabled
;           show_tiles = tile map system is enabled
;           show_pixmap = bitmap / pixelmap graphics enabled
;           gamma = enable gamma correction

; VCOPY dest_addr,src_addr,length
;           Copy length bytes of video memory from src_addr to dest_addr
;           NOTE: VCOPY will pause execution if a Vicky is already busy with a VDMA operation.
;               Otherwise, it will return immediately while the copy happens in the background.

; VCOPY dest_addr,dest_stride,src_addr,src_stride,width,height
;           Copy a block of video memory from src_addr to dest_addr
;               dest_addr = the address of the first byte to write (must be within video RAM)
;               src_addr = the address of the first byte to read (must be within video RAM)
;               width = the number of pixels horizontally to copy
;               height = the number of pixels vertically to copy
;               dest_stride = the number of bytes to skip between rows in the destination block
;               src_stride = the number of bytes to skip between rows in the source block
;           NOTE: VCOPY will pause execution if a Vicky is already busy with a VDMA operation.
;               Otherwise, it will return immediately while the copy happens in the background.

;; Pixmap
; PLOT x,y,color
;       Set the color of the pixel at (x, y)
; LINE x0,y0,x1,y1,color
;       Draw a line from (x0, y0) to (x1, y1) in the specified color
; BOX x0,y0,x1,y1,color,filled
;       Draw a box with corners (x0, y0) and (x1, y1) in the specified color. Optionally fill it.
; CIRCLE x0,y0,x1,y1,color,filled
;       Draw an ellipse inscribing a box with corners (x0, y0) and (x1, y1) in the specified color. Optionally fill it.
; STENCIL x,y,vblock
;       Draw the image data stored in vblock to the screen, with its upper-left pixel at (x, y)
; TEXT x, y, message, color [, font_addr]
;       Print the message on the pixmap with the upper left corner of the message at (x,y).
;       Optional: take the characters from the font at font_addr in video memory

;; Sprite
; SPRITE number,lut,layer,vblock
;       Set up a sprite, specifying it's color LUT, rendering layer, and the video block containing its pixel data
; SPRITELOC sprite,x,y
;       Move the sprite so it's upper-left corner is at (x, y)
; SPRITESHOW number,boolean
;       Control whether or not the sprite is visible
; COLLISION%(number)
;       Check to see if the sprite is colliding with another object

;; Tile
; TILESET number,lut,address,striding
;       Set up a tileset, specifying its color LUT, and the video block containing its pixel data
;       striding = 
; SETTILE number,column,row,tile
;       Set which tile to display at position (column, row) in the tileset
; TILESCROLL number,x,y
;       Set the horizontal and vertical scrolling of the tileset
; TILESHOW number,visible
;       Set whether or not the given tileset is visible

;
; Set the time on the real time clock
; SETTIME hour,minute,second
;
S_SETTIME       .proc
                PHP
                TRACE "S_SETTIME"

                setas

                CALL EVALEXPR           ; Get the hour number
                CALL ASS_ARG1_BYTE      ; Make sure it's a byte
                CALL DIVINT10           ; Separate both digits
                LDA ARGUMENT1           ; Take the tens digit
                ASL A                   ; Shift it 4 bits
                ASL A
                ASL A
                ASL A
                ORA ARGUMENT2           ; And add in the ones digit
                STA SCRATCH

                LDA #','
                CALL EXPECT_TOK

                CALL EVALEXPR           ; Get the minute number
                CALL ASS_ARG1_BYTE      ; Make sure it's a byte
                CALL DIVINT10           ; Separate both digits
                LDA ARGUMENT1           ; Take the tens digit
                ASL A                   ; Shift it 4 bits
                ASL A
                ASL A
                ASL A
                ORA ARGUMENT2           ; And add in the ones digit
                STA SCRATCH+1

                LDA #','
                CALL EXPECT_TOK

                CALL EVALEXPR           ; Get the second number
                CALL ASS_ARG1_BYTE      ; Make sure it's a byte
                CALL DIVINT10           ; Separate both digits
                LDA ARGUMENT1           ; Take the tens digit
                ASL A                   ; Shift it 4 bits
                ASL A
                ASL A
                ASL A
                ORA ARGUMENT2           ; And add in the ones digit
                STA SCRATCH+2

                LDA @lRTC_CTRL          ; Pause updates to the clock registers
                ORA #%00001000
                STA @lRTC_CTRL

                LDA SCRATCH             ; Save the hour...
                STA @lRTC_HRS

                LDA SCRATCH+1           ; Minutes...
                STA @lRTC_MIN

                LDA SCRATCH+2           ; And seconds to the RTC
                STA @lRTC_SEC

                LDA @lRTC_CTRL          ; Re-enable updates to the clock registers
                AND #%11110111
                STA @lRTC_CTRL

                PLP
                RETURN
                .pend

;
; Set the date on the real time clock
; SETDATE day,month,year
;
S_SETDATE       .proc
                PHP
                TRACE "S_SETDATE"

                setas

                CALL EVALEXPR           ; Get the day number
                CALL ASS_ARG1_BYTE      ; Make sure it's a byte
                CALL DIVINT10           ; Separate both digits
                LDA ARGUMENT1           ; Take the tens digit
                ASL A                   ; Shift it 4 bits
                ASL A
                ASL A
                ASL A
                ORA ARGUMENT2           ; And add in the ones digit
                STA SCRATCH

                LDA #','
                CALL EXPECT_TOK

                CALL EVALEXPR           ; Get the month number
                CALL ASS_ARG1_BYTE      ; Make sure it's a byte
                CALL DIVINT10           ; Separate both digits
                LDA ARGUMENT1           ; Take the tens digit
                ASL A                   ; Shift it 4 bits
                ASL A
                ASL A
                ASL A
                ORA ARGUMENT2           ; And add in the ones digit
                STA SCRATCH+1

                LDA #','
                CALL EXPECT_TOK

                CALL EVALEXPR           ; Get the year number
                CALL ASS_ARG1_BYTE      ; Make sure it's a byte
                CALL DIVINT10           ; Separate both digits
                LDA ARGUMENT1           ; Take the tens digit
                ASL A                   ; Shift it 4 bits
                ASL A
                ASL A
                ASL A
                ORA ARGUMENT2           ; And add in the ones digit
                STA SCRATCH+2

                LDA @lRTC_CTRL          ; Pause updates to the clock registers
                ORA #%00001000
                STA @lRTC_CTRL

                LDA SCRATCH             ; Save the day...
                STA @lRTC_DAY

                LDA SCRATCH+1           ; Month...
                STA @lRTC_MONTH

                LDA SCRATCH+2           ; And year to the RTC
                STA @lRTC_YEAR

                LDA @lRTC_CTRL          ; Re-enable updates to the clock registers
                AND #%11110111
                STA @lRTC_CTRL

                PLP
                RETURN
                .pend


;
; Set the text foreground color
; SETFGCOLOR index
;
; Inputs:
;   ARGUMENT1 = the index of the foreground color
;
S_SETFGCOLOR    .proc
                PHP
                TRACE "S_SETFGCOLOR"

                ; TODO: convert float arguments to integer

                CALL EVALEXPR       ; Get the red component
                CALL ASS_ARG1_BYTE  ; Assert that the result is a byte value

                setas
                LDA ARGUMENT1       ; Covert the color number to the right position
                AND #$0F
                .rept 4
                ASL A
                .next

                STA SCRATCH
                LDA @lCURCOLOR      ; Mask off the old foreground color
                AND #$0F
                ORA SCRATCH            ; And add in the new one
                STA @lCURCOLOR

                PLP
                RETURN
                .pend

;
; Set the text background color
; SETBGCOLOR index
;
; Inputs:
;   ARGUMENT1 = the index of the background color
;
S_SETBGCOLOR    .proc
                PHP
                TRACE "S_SETBGCOLOR"

                ; TODO: convert float arguments to integer

                CALL EVALEXPR       ; Get the red component
                CALL ASS_ARG1_BYTE  ; Assert that the result is a byte value

                setas
                LDA ARGUMENT1       ; Make sure the index is just 4 bits
                AND #$0F

                STA SCRATCH
                LDA @lCURCOLOR      ; Mask off the old background color
                AND #$F0
                ORA SCRATCH            ; And add in the new one
                STA @lCURCOLOR

                PLP
                RETURN
                .pend

; Set the border color give red, green, and blue components
; SETBRDCOLOR red, green, blue
S_SETBRDCOLOR   .proc
                PHP
                TRACE "S_SETBRDCOLOR"

                ; TODO: convert float arguments to integer

                CALL EVALEXPR       ; Get the red component
                CALL ASS_ARG1_BYTE  ; Assert that the result is a byte value

                setas
                LDA ARGUMENT1       ; Save the red component to the stack
                PHA

                LDA #','
                CALL EXPECT_TOK     ; Try to find the comma

                CALL EVALEXPR       ; Get the green component
                CALL ASS_ARG1_BYTE  ; Assert that the result is a byte value

                LDA ARGUMENT1       ; Save the green component to the stack
                PHA

                LDA #','
                CALL EXPECT_TOK     ; Try to find the comma

                CALL EVALEXPR       ; Get the blue component
                CALL ASS_ARG1_BYTE  ; Assert that the result is a byte value

                LDA ARGUMENT1
                STA @lBORDER_COLOR_B    ; Set the border color
                PLA
                STA @lBORDER_COLOR_G
                PLA
                STA @lBORDER_COLOR_R            

                PLP
                RETURN
                .pend
