;;;
;;; Custom statements for the C256
;;;

GR_LUT_BLUE = 0
GR_LUT_GREEN = 1
GR_LUT_RED = 2
GR_LUT_ALPHA = 3
GR_DEFAULT_COLS = 640               ; Default number of columns in the display
GR_DEFAULT_ROWS = 480               ; Default number of rows in the display
GR_MAX_LUT = 8                      ; The number of LUTs Vicky supports
SP_MAX = 18                         ; The number of sprites Vicky supports
SP_REG_SIZE = 8                     ; The number of bytes in a sprite's register block
SP_CONTROL = 0                      ; Offset of the control regsiter for a sprite
SP_ADDR = 1                         ; Offset of the pixmap address for a sprite
SP_X_COORD = 4                      ; Offset of the X coordinate for a sprite
SP_Y_COORD = 6                      ; Offset of the Y coordinate for a sprite

.section variables
GR_PM_ADDR      .dword ?            ; Address of the pixmap (from CPU's perspective)
GR_PM_VRAM      .dword ?            ; Address of the pixmap (relative to start of VRAM)
GR_MAX_COLS     .word ?             ; Width the display in pixels
GR_MAX_ROWS     .word ?             ; Height of the display in pixels
GR_TOTAL_PIXELS .word ?             ; Total number of pixels in the display
GR_TEMP         .word ?             ; A temporary word for graphics commands
GS_SP_CONTROL   .fill SP_MAX        ; Shadow registers for the sprite controls
.send

; BLOAD path,destination
; BSAVE path,source
; LOAD path
; SAVE path

; SETCOLOR lut,index,red,green,blue,alpha
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

; GRAPHICS mode
;       Control which graphics blocks are enabled by writing to Vicky's master control register

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
; SPRITEAT number,x,y
;       Move the sprite so it's upper-left corner is at (x, y)
; SPRITESHOW number,boolean,layer
;       Control whether or not the sprite is visible

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
                PHA

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
                PHA

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
                PHA

                LDA @lRTC_CTRL          ; Pause updates to the clock registers
                ORA #%00001100
                STA @lRTC_CTRL

                PLA                     ; And seconds to the RTC
                STA @lRTC_SEC

                PLA                     ; Minutes...
                STA @lRTC_MIN

                PLA                     ; Save the hour...
                STA @lRTC_HRS

                LDA @lRTC_CTRL          ; Re-enable updates to the clock registers
                AND #%11110111
                STA @lRTC_CTRL

                CALL SKIPSTMT

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
                PHA

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
                PHA

                LDA #','
                CALL EXPECT_TOK

                CALL EVALEXPR           ; Get the year number
                CALL ASS_ARG1_INT       ; Make sure it's an integer
                CALL DIVINT100          ; Separate the ones and tens from the century

                setal
                LDA ARGUMENT1           ; Get the century
                STA MTEMP               ; Save it in MTEMP

                LDA ARGUMENT2           ; Separate the 10s from the 1s digits
                STA ARGUMENT1
                CALL DIVINT10
                setas
                LDA ARGUMENT1           ; Take the tens digit
                ASL A                   ; Shift it 4 bits
                ASL A
                ASL A
                ASL A
                ORA ARGUMENT2           ; And add in the ones digit
                PHA                     ; Save the 10s and 1s in BCD

                setal
                LDA MTEMP               ; Separate the 100s from the 1000s digits
                STA ARGUMENT1
                CALL DIVINT10
                setas
                LDA ARGUMENT1           ; Take the tens digit
                ASL A                   ; Shift it 4 bits
                ASL A
                ASL A
                ASL A
                ORA ARGUMENT2           ; And add in the ones digit
                PHA                     ; Save the 100s and 1000s in BCD               

                LDA @lRTC_CTRL          ; Pause updates to the clock registers
                ORA #%00001100
                STA @lRTC_CTRL

                PLA                     ; Set the century
                STA @lRTC_CENTURY

                PLA                     ; And year to the RTC
                STA @lRTC_YEAR

                PLA                     ; Month...
                STA @lRTC_MONTH

                PLA                     ; Save the day...
                STA @lRTC_DAY

                LDA @lRTC_CTRL          ; Re-enable updates to the clock registers
                AND #%11110111
                STA @lRTC_CTRL

                CALL SKIPSTMT

                PLP
                RETURN
                .pend


;
; Set the text foreground color
; TEXTCOLOR foreground, background
;
; Inputs:
;   ARGUMENT1 = the index of the foreground color
;
S_TEXTCOLOR     .proc
                PHP
                TRACE "S_TEXTCOLOR"

                CALL EVALEXPR       ; Get the foreground index
                CALL ASS_ARG1_BYTE  ; Assert that the result is a byte value

                setas
                LDA ARGUMENT1       ; Covert the color number to the foreground position
                AND #$0F
                .rept 4
                ASL A
                .next
                STA @lMARG1

                LDA #','
                CALL EXPECT_TOK     ; Try to find the comma

                CALL EVALEXPR       ; Get the background index
                CALL ASS_ARG1_BYTE  ; Assert that the result is a byte value

                LDA ARGUMENT1       ; Covert the color number to the background position
                AND #$0F

                ORA @lMARG1         ; Add in the foreground
                STA @lCURCOLOR      ; And save the new color combination

                PLP
                RETURN
                .pend

;
; Set the text background color
; SETBGCOLOR red, green, blue
;
S_SETBGCOLOR    .proc
                PHP
                TRACE "S_SETBGCOLOR"

                setas

                CALL EVALEXPR               ; Get the red component
                CALL ASS_ARG1_BYTE          ; Assert that the result is a byte value

                LDA ARGUMENT1               ; Save the red component to the stack
                PHA

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the green component
                CALL ASS_ARG1_BYTE          ; Assert that the result is a byte value

                LDA ARGUMENT1               ; Save the green component to the stack
                PHA

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the blue component
                CALL ASS_ARG1_BYTE          ; Assert that the result is a byte value

                LDA ARGUMENT1               ; And set the actual color
                STA @lBACKGROUND_COLOR_B
                PLA
                STA @lBACKGROUND_COLOR_G
                PLA
                STA @lBACKGROUND_COLOR_R

                PLP
                RETURN
                .pend

; Set the border color give red, green, and blue components
; SETBORDER visible [, red, green, blue]
S_SETBORDER     .proc
                PHP
                TRACE "S_SETBORDER"

                setas

                CALL EVALEXPR               ; Get the visible component
                CALL ASS_ARG1_INT           ; Assert that the result is an integer value

                LDA ARGUMENT1
                BEQ hide_border

                LDA #Border_Ctrl_Enable     ; Enable the border
                STA @lBORDER_CTRL_REG

                LDA #BORDER_WIDTH           ; Set the border width
                STA BORDER_X_SIZE
                STA BORDER_Y_SIZE

                SEC
                LDA @lCOLS_PER_LINE         ; Make sure the screen size is right
                SBC #8
                STA @lCOLS_VISIBLE

                SEC
                LDA @lLINES_MAX
                SBC #8
                STA @lLINES_VISIBLE

                BRA get_color

hide_border     LDA #0                      ; Hide the border
                STA @lBORDER_CTRL_REG

                LDA @lCOLS_PER_LINE         ; Make sure the screen size is right
                STA @lCOLS_VISIBLE
                LDA @lLINES_MAX
                STA @lLINES_VISIBLE

get_color       LDA #','
                STA TARGETTOK
                CALL OPT_TOK                ; Is there a comma?
                BCC done                    ; No: we're done

                CALL INCBIP
                CALL EVALEXPR               ; Get the red component
                CALL ASS_ARG1_BYTE          ; Assert that the result is a byte value

                LDA ARGUMENT1               ; Save the red component to the stack
                PHA

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the green component
                CALL ASS_ARG1_BYTE          ; Assert that the result is a byte value

                LDA ARGUMENT1               ; Save the green component to the stack
                PHA

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the blue component
                CALL ASS_ARG1_BYTE          ; Assert that the result is a byte value

                LDA ARGUMENT1
                STA @lBORDER_COLOR_B        ; Set the border color
                PLA
                STA @lBORDER_COLOR_G
                PLA
                STA @lBORDER_COLOR_R            

done            PLP
                RETURN
                .pend

; Set the color in a color look up table give red, green, and blue components
; SETCOLOR lut, color, red, green, blue
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
S_SETCOLOR      .proc
                PHP
                TRACE "S_SETCOLOR"

                setal

                ; Step #1... calculate the address of the LUT to update

                CALL EVALEXPR       ; Get the LUT #
                CALL ASS_ARG1_BYTE  ; Assert that the result is a byte value

                LDA #`GRPH_LUT0_PTR ; Get the bank Vicky is in (should always be $AF)
                STA MTEMPPTR+2      ; MTEMPPTR will be our pointer to the LUT entry

                LDA ARGUMENT1       ; Compute the offset to the LUT address
                CMP #10
                BGE bad_argument    ; Otherwise, throw exception
                ASL A
                TAX                 ; Put it in X

                LDA @llut_address,X ; Get the address of the LUT
                STA MTEMPPTR        ; Put it in MTEMPPTR 

                ; Step #2... calculate the address of the specific color to change


                LDA #','
                CALL EXPECT_TOK     ; Try to find the comma

                CALL EVALEXPR       ; Get the color index
                CALL ASS_ARG1_BYTE  ; Assert that the result is a byte value

                LDA ARGUMENT1       ; color index *= 4
                ASL A               ; Since each color has four bytes of data
                ASL A

                CLC                 ; Add the color offset to MTEMPPTR
                ADC MTEMPPTR
                STA MTEMPPTR        ; Which now points to the color entry

                ; Step #3... set the red component

                LDA #','
                CALL EXPECT_TOK     ; Try to find the comma

                CALL EVALEXPR       ; Get the red component
                CALL ASS_ARG1_BYTE  ; Assert that the result is a byte value

                LDY #GR_LUT_RED
                LDA ARGUMENT1
                setas
                STA [MTEMPPTR],Y    ; Save the red component to the color entry

                ; Step #4... set the green component

                LDA #','
                CALL EXPECT_TOK     ; Try to find the comma

                CALL EVALEXPR       ; Get the green component
                CALL ASS_ARG1_BYTE  ; Assert that the result is a byte value

                LDY #GR_LUT_GREEN
                LDA ARGUMENT1
                setas
                STA [MTEMPPTR],Y    ; Save the green component to the color entry

                ; Step #5... set the blue component

                LDA #','
                CALL EXPECT_TOK     ; Try to find the comma

                CALL EVALEXPR       ; Get the blue component
                CALL ASS_ARG1_BYTE  ; Assert that the result is a byte value

                LDY #GR_LUT_BLUE
                LDA ARGUMENT1
                setas
                STA [MTEMPPTR],Y    ; Save the blue component to the color entry

                PLP
                RETURN
bad_argument    THROW ERR_ARGUMENT  ; Throw an illegal argument exception
lut_address     .word <>GRPH_LUT0_PTR
                .word <>GRPH_LUT1_PTR
                .word <>GRPH_LUT2_PTR
                .word <>GRPH_LUT3_PTR
                .word <>GRPH_LUT4_PTR
                .word <>GRPH_LUT5_PTR
                .word <>GRPH_LUT6_PTR
                .word <>GRPH_LUT7_PTR
                .word <>FG_CHAR_LUT_PTR
                .word <>BG_CHAR_LUT_PTR
                .pend



; Set the graphics mode to use... this really just sets the bits of
; the Vicky chip's master control register.
;
; GRAPHICS mode
; TODO: allow for variable screen sizes: GRAPHICS mode [, width, height]
S_GRAPHICS      .proc
                PHX
                PHY
                PHP
                TRACE "S_GRAPHICS"

                CALL EVALEXPR               ; Get the red component
                CALL ASS_ARG1_INT           ; Assert that the result is a byte value

                LDA ARGUMENT1
                STA @lMASTER_CTRL_REG_L     ; Set the border color

                .rept 7
                LSR A
                .next
                AND #$00FF
                ASL A
                TAX                         ; X is index into the size tables

                ; Set the screen size

                setal
                LDA gr_columns,X            ; Set the columns
                STA @lGR_MAX_COLS

                LDA gr_rows,X               ; Set the rows
                STA @lGR_MAX_ROWS

                LDA @lGR_MAX_COLS           ; Get the current columns
                STA @lM1_OPERAND_A

                LDA @lGR_MAX_ROWS           ; Get the current rows
                STA @lM1_OPERAND_B

                LDA @lM1_RESULT             ; Multiply them to get the total pixels
                STA @lGR_TOTAL_PIXELS
                setas
                LDA @lM1_RESULT+2
                STA @lGR_TOTAL_PIXELS+2

                setal
                LDA col_count,X             ; Get the number of columns in the text mode
                STA @lCOLS_PER_LINE
                STA @lCOLS_VISIBLE

                LDA row_count,X             ; Get the number of columns in the text mode
                STA @lLINES_MAX
                STA @lLINES_VISIBLE

                setas
                LDA @lBORDER_CTRL_REG
                BIT #Border_Ctrl_Enable
                BEQ reset_cursor

with_border     setal
                LDA colb_count,X            ; Get the number of columns in the text mode
                STA @lCOLS_VISIBLE

                LDA rowb_count,X            ; Get the number of columns in the text mode
                STA @lLINES_VISIBLE

reset_cursor    setal
                LDA @lCURSORX
                TAX
                LDA @lCURSORY
                TAY
                CALL CURSORXY

                PLP
                PLY
                PLX
                RETURN
gr_columns      .word 640,800,320,400
gr_rows         .word 480,600,240,300
col_count       .word 80,100,40,50
row_count       .word 60,75,30,50
colb_count      .word 72,92,32,42
rowb_count      .word 52,67,22,52
                .pend


; Set the pixmap base address
; PIXMAP visible, lut, address
S_PIXMAP        .proc
                PHP
                TRACE "S_PIXMAP"

                setal
                CALL EVALEXPR               ; Get the visible flag
                CALL ASS_ARG1_BYTE          ; Assert that the result is a byte value
                MOVE_W MARG1,ARGUMENT1      ; Save it to MARG1

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma
                CALL EVALEXPR               ; Get the LUT #
                CALL ASS_ARG1_BYTE          ; Assert that the result is a byte value

                setas
                LDA MARG1                   ; Check the visible flag
                BNE is_visible              ; If <> 0, it's visible

                LDA ARGUMENT1               ; Get the LUT #
                ASL A                       ; Shift it into position for the register
                BRA wr_bm_reg               ; And go to write it

is_visible      LDA ARGUMENT1               ; Get the LUT #
                SEC     
                ROL A                       ; And shift it into position, and set enable bit

wr_bm_reg       STA @lBM_CONTROL_REG        ; Write to the bitmap control register         

                setal
                LDA #','
                STA TARGETTOK
                CALL OPT_TOK                ; Is there a comma?
                BCS get_address             ; Yes: parse the address

                setal
                LDARG_EA ARGUMENT1,VRAM,TYPE_INTEGER
                BRA set_address

get_address     setal
                CALL INCBIP
                CALL EVALEXPR               ; Get the address

                ; Rebase the address to the start of VRAM
set_address     setas
                SEC
                LDA ARGUMENT1+2
                STA @lGR_PM_ADDR+2          ; Save the address for later use                

                SBC #`VRAM
                BMI bad_address             ; If it's negative, throw an error
                STA @lBM_START_ADDY_H
                STA @lGR_PM_VRAM+2

                LDA ARGUMENT1               
                STA @lGR_PM_ADDR            ; Save the address for later use
                STA @lBM_START_ADDY_L       ; Set the register in Vicky
                STA @lGR_PM_VRAM
                LDA ARGUMENT1+1             ; Otherwise, set the register in Vicky
                STA @lBM_START_ADDY_M
                STA @lGR_PM_VRAM+1
                STA @lGR_PM_ADDR+1

                LDA #0
                STA @lGR_PM_VRAM+3
                STA @lGR_PM_ADDR+3

                setal
                LDA @lGR_MAX_COLS           ; Set the bitmap size
                STA @lBM_X_SIZE_L
                LDA @lGR_MAX_ROWS
                STA @lBM_Y_SIZE_L

                PLP
                RETURN
bad_address     THROW ERR_ARGUMENT          ; Throw an illegal argument exception
                .pend

; Clear the current pixmap memory
; CLRPIXMAP
S_CLRPIXMAP     .proc
                PHP
                TRACE "S_CLRPIXMAP"

                ; We're going to use Vicky's VDMA capabilities to fill the screen here.
                ; This should be MUCH faster than the CPU can do it.

                setal
                LDA @lGR_PM_VRAM            ; Set the start address and the # of pixels to write
                STA @lVDMA_DST_ADDY_L
                LDA @lGR_TOTAL_PIXELS
                STA @lVDMA_SIZE_L
                setas
                LDA @lGR_PM_VRAM+2
                STA @lVDMA_DST_ADDY_H
                LDA @lGR_TOTAL_PIXELS+2
                STA @lVDMA_SIZE_H

                LDA #0                      ; Set the color to write
                STA @lVDMA_BYTE_2_WRITE

                ; Ask Vicky to do a 1-D fill operation
                LDA #VDMA_CTRL_Enable | VDMA_CTRL_TRF_Fill | VDMA_CTRL_Start_TRF
                STA @lVDMA_CONTROL_REG

wait            LDA @lVDMA_STATUS_REG       ; Wait until Vicky is done
                BMI wait

                LDA #0                      ; Clear the control register so it can be used later
                STA @lVDMA_CONTROL_REG

done            PLP
                RETURN
                .pend

COLOR = MARG1
X0 = MARG2
Y0 = MARG3
X1 = MARG4
Y1 = MARG5
DX = MARG6
;SX = DX+2
DY = MARG7
;SY = DY+2
ERR = MARG8
ERR2 = MARG9

.section globals
SX      .word ?
SY      .word ?
.send

;
; Draw a pixel on the pixmap
;
; Inputs:
;   X0 = column number (x-coordinate)
;   X1 = row number (y-coordinate)
;   COLOR = color index (0 - 255)
;
; Affects:
;   SCRATCH, MTEMPPTR, M and X
;
PLOT            .proc
                PHP
                setal
                LDA Y0                      ; Get the row          
                STA @lM1_OPERAND_A
                LDA @lGR_MAX_COLS          
                STA @lM1_OPERAND_B          ; Multiply by the number of columns in the pixmap

                CLC                         ; Add the column
                LDA @lM1_RESULT
                ADC X0
                STA SCRATCH
                LDA @lM1_RESULT+2
                ADC #0
                STA SCRATCH+2               ; SCRATCH is offset of pixel in the pixmap

                CLC                         ; Add the address of the first pixel
                LDA SCRATCH
                ADC @lGR_PM_ADDR
                STA MTEMPPTR
                LDA SCRATCH+2
                ADC @lGR_PM_ADDR+2
                STA MTEMPPTR+2              ; MTEMPPTR := pixmap + pixel offset

                setas
                LDA COLOR                   ; Get the color
                STA [MTEMPPTR]              ; And write the color to the pixel

                PLP
                RETURN
                .pend

;
; Draw a line from (X0,Y0) to (X1,Y1)
;
; Used the algorithm at: https://rosettacode.org/wiki/Bitmap/Bresenham%27s_line_algorithm#C
;
; Inputs:
;   X0 = the first X coordinate
;   Y0 = the first Y coordinate
;   X1 = the second X coordinate
;   Y1 = the second Y coordinate
;   COLOR = the color of the line
;
; Affects:
;   X0, Y0, DX, DY, SX, SY, ERR, ERR2
;
LINE            .proc
                setal

                LDA #1                      ; Assume SX = 1
                STA SX

                SEC                         ; DX := ABS(X1 - X0)
                LDA X1
                SBC X0
                STA DX
                BPL abs_Y                   ; If DX < 0 {

                EOR #$FFFF                  ; DX := -DX
                INC A
                STA DX

                LDA #$FFFF                  ; SX := -1
                STA SX                      ; }

abs_Y           LDA #1                      ; Assume SY = 1
                STA SY

                SEC                         ; DY := ABS(Y1 - Y0)
                LDA Y1
                SBC Y0
                STA DY
                BPL calc_ERR                ; If DY < 0 {

                EOR #$FFFF                  ; DY := -DY
                INC A
                STA DY

                LDA #$FFFF                  ; SY := -1
                STA SY                      ; }

calc_ERR        LDA DY                      ; (DY < DX)
                CMP DX
                BGE else

                LDA DX                      ; TRUE CASE: ERR := DX
                BRA shiftERR

else            LDA DY                      ; FALSE CASE: ERR := -DY
                EOR #$FFFF
                INC A

shiftERR        PHA
                ASL A
                PLA
                ROR A                       ; ERR := ERR / 2
                STA ERR

                                            ; while (1) {
loop            CALL PLOT                   ; PLOT(X0, Y0, COLOR)

                LDA X0                      ; break if X0=X1 and Y0=Y1
                CMP X1
                BNE calc_ERR2

                LDA Y0
                CMP Y1
                BEQ done

calc_ERR2       LDA ERR                     ; ERR2 := ERR
                STA ERR2

                LDA DX                      ; if (ERR2 > -DX) {
                EOR #$FFFF
                INC A
                CMP ERR2
                BPL check_DY
                BEQ check_DY

                SEC                         ; ERR -= DY
                LDA ERR
                SBC DY
                STA ERR

                CLC                         ; X0 += SX
                LDA X0
                ADC SX
                STA X0                      ; }

check_DY        LDA ERR2                    ; if (ERR2 < DY) {
                CMP DY
                BPL loop
                BEQ loop

                CLC                         ; ERR += DX
                LDA ERR
                ADC DX
                STA ERR

                CLC                         ; Y0 += SY
                LDA Y0
                ADC SY
                STA Y0                      ; }

                BRA loop                    ; }

done            RETURN
                .pend

;
; Fill a block of the pixmap with a color
;
; Inputs:
;   X0 = the first X coordinate
;   Y0 = the first Y coordinate
;   X1 = the second X coordinate
;   Y1 = the second Y coordinate
;   COLOR = the color of the line
;
FILL            .proc
                PHP
                TRACE "FILL"

                ; We're going to use Vicky's VDMA capabilities to fill the screen here.
                ; This should be MUCH faster than the CPU can do it.

                LDA #0                      ; Clear the control register so it can be used later
                STA @lVDMA_CONTROL_REG

                setal
                LDA Y0                      ; Get the row          
                STA @lM1_OPERAND_A
                LDA @lGR_MAX_COLS          
                STA @lM1_OPERAND_B          ; Multiply by the number of columns in the pixmap

                CLC                         ; Add the column
                LDA @lM1_RESULT
                ADC X0
                STA SCRATCH
                setas
                LDA @lM1_RESULT+2
                ADC #0
                STA SCRATCH+2

                setal
                CLC                         ; Set the destination address
                LDA @lGR_PM_VRAM
                ADC SCRATCH
                STA @lVDMA_DST_ADDY_L
                setas
                LDA @lGR_PM_VRAM+2
                ADC SCRATCH+2
                STA @lVDMA_DST_ADDY_H

                setal          
                SEC                         ; Set the width of the FILL operation
                LDA X1
                SBC X0
                STA SCRATCH
                STA @lVDMA_X_SIZE_L

                SEC
                LDA @lGR_MAX_COLS
                ;SBC SCRATCH
                STA @lVDMA_DST_STRIDE_L     ; And the destination stride

                SEC                         ; Set the height of the FILL operation
                LDA Y1
                SBC Y0        
                STA @lVDMA_Y_SIZE_L

                LDA #1
                STA @lVDMA_SRC_STRIDE_L     ; And the source stride

                setas
                LDA @lCOLOR                 ; Set the color to write
                STA @lVDMA_BYTE_2_WRITE

                ; Ask Vicky to do a 2-D fill operation
                LDA #VDMA_CTRL_Enable | VDMA_CTRL_TRF_Fill | VDMA_CTRL_Start_TRF | VDMA_CTRL_1D_2D
                STA @lVDMA_CONTROL_REG

wait            LDA @lVDMA_STATUS_REG       ; Wait until Vicky is done
                BMI wait

                LDA #0                      ; Clear the control register so it can be used later
                STA @lVDMA_CONTROL_REG

done            PLP                
                RETURN
                .pend


; Draw a pixel on the pixmap
; PLOT x, y, color_index
S_PLOT          .proc
                PHP
                TRACE "S_PLOT"

                setdp <>GLOBAL_VARS
                setdbr 0
                setaxl

                CALL EVALEXPR               ; Get the x coordinate
                CALL ASS_ARG1_INT           ; Make sure it's an integer
                LDA ARGUMENT1
                STA MARG1                   ; Save it to MARG1       

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the y coordinate
                CALL ASS_ARG1_INT           ; Make sure it's an integer
                LDA ARGUMENT1
                STA MARG2                   ; Save it to MARG2

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the color index            
                CALL ASS_ARG1_BYTE          ; Make sure it's a byte
                LDA ARGUMENT1
                STA MARG3                   ; Save it to MARG3

                CALL PLOT                   ; And draw the pixel

                PLP
                RETURN
                .pend

; Draw a pixel on the pixmap
; LINE x0, y0, x1, y1, color
S_LINE          .proc
                PHP
                TRACE "S_LINE"

                setdp <>GLOBAL_VARS
                setdbr 0
                setaxl

                CALL EVALEXPR               ; Get the x0 coordinate
                CALL ASS_ARG1_INT           ; Make sure it's an integer
                LDA ARGUMENT1
                STA X0                      ; Save it to X0       

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the y0 coordinate
                CALL ASS_ARG1_INT           ; Make sure it's an integer
                LDA ARGUMENT1
                STA Y0                      ; Save it to Y0

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the x1 coordinate
                CALL ASS_ARG1_INT           ; Make sure it's an integer
                LDA ARGUMENT1
                STA X1                      ; Save it to X1     

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the y1 coordinate
                CALL ASS_ARG1_INT           ; Make sure it's an integer
                LDA ARGUMENT1
                STA Y1                      ; Save it to Y1

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the color index            
                CALL ASS_ARG1_BYTE          ; Make sure it's a byte
                LDA ARGUMENT1
                STA COLOR                   ; Save it to COLOR

                CALL LINE                   ; Otherwise, use the generic line routine

done            PLP
                RETURN
                .pend

; Draw a pixel on the pixmap
; FILL x0, y0, x1, y1, color
S_FILL          .proc
                PHP
                TRACE "S_FILL"

                setdp <>GLOBAL_VARS
                setdbr 0
                setaxl

                CALL EVALEXPR               ; Get the x0 coordinate
                CALL ASS_ARG1_INT           ; Make sure it's an integer
                LDA ARGUMENT1
                STA X0                      ; Save it to X0       

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the y0 coordinate
                CALL ASS_ARG1_INT           ; Make sure it's an integer
                LDA ARGUMENT1
                STA Y0                      ; Save it to Y0

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the x1 coordinate
                CALL ASS_ARG1_INT           ; Make sure it's an integer
                LDA ARGUMENT1
                STA X1                      ; Save it to X1     

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the y1 coordinate
                CALL ASS_ARG1_INT           ; Make sure it's an integer
                LDA ARGUMENT1
                STA Y1                      ; Save it to Y1

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the color index            
                CALL ASS_ARG1_BYTE          ; Make sure it's a byte
                LDA ARGUMENT1
                STA COLOR                   ; Save it to COLOR

                CALL FILL                   ; Otherwise, use the block fill routine
done            PLP
                RETURN
                .pend

;;
;; Sprite statements and support routines
;;

;
; Set MTEMPPTR to the starting address of a sprite, given its number
;
; Inputs:
;   ARGUMENT1 = the number of the sprite desired (0 - 8)
;
SPADDR          .proc
                PHP

                setas
                LDA ARGUMENT1               ; Get the sprite number
                CMP #SP_MAX
                BGE error

                ASL A                       ; Multiply it by 8 (the size of s sprite block)
                ASL A
                ASL A

                CLC                         ; Add it to the address of the first
                ADC #<SP00_CONTROL_REG      ; sprite block
                STA MTEMPPTR
                LDA #>SP00_CONTROL_REG
                ADC #0
                STA MTEMPPTR+1
                LDA #`SP00_CONTROL_REG
                ADC #0
                STA MTEMPPTR+2
                STZ MTEMPPTR+3              ; And save that to MTEMPPTR

                PLP
                RETURN
error           THROW ERR_RANGE             ; Throw a range error
                .pend

;
; SPRITE number, lut, address
;       Set up a sprite, specifying it's color LUT, and the address of its pixel data
;
S_SPRITE        .proc
                PHP
                TRACE "S_SPRITE"

                setas

                CALL EVALEXPR               ; Get the sprite's number
                CALL ASS_ARG1_BYTE          ; Make sure it's a byte
                CALL SPADDR                 ; Compute the address of the sprite's block     
                LDA ARGUMENT1
                STA @lGR_TEMP               ; Save sprite number in GR_TEMP

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the LUT for the sprite
                CALL ASS_ARG1_BYTE          ; Make sure it's a byte
                LDA ARGUMENT1
                CMP #GR_MAX_LUT             ; Check that it's in range
                BGE error                   ; If not: throw an error
                PHA                         ; Save it for later

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the address of the sprite's pixmap
                CALL ASS_ARG1_INT           ; Make sure it's an integer

                setal

                SEC                         ; Adjust address to be in Vicky's space
                LDA ARGUMENT1
                SBC #<>VRAM
                STA ARGUMENT1
                LDA ARGUMENT1+2
                SBC #`VRAM
                STA ARGUMENT1+2
                BMI error                   ; If negative, throw an error

                setal
                LDA ARGUMENT1               ; Save the lower word of the address
                LDY #SP_ADDR
                STA [MTEMPPTR],Y
                setas
                LDA ARGUMENT1+2
                INY
                INY
                STA [MTEMPPTR],Y            ; Save the upper byte of the address

                LDA @lGR_TEMP
                TAX
                LDA GS_SP_CONTROL,X         ; Get the sprite control register
                AND #%11110001              ; Filter off the current LUT
                STA SCRATCH

                PLA                         ; Get the LUT back
                ASL A                       ; Sift it into the LUT position
                AND #%00001110              ; Make sure we don't have anything wrong there
                ORA SCRATCH                 ; Combine it with what's in the sprite's control
                STA [MTEMPPTR]              ; And set the register's bits
                STA GS_SP_CONTROL,X         ; And the shadow register

                PLP
                RETURN
error           THROW ERR_RANGE             ; Throw a range exception
                .pend

;
; SPRITEAT number, x, y
;       Move the sprite so it's upper-left corner is at (x, y)
;
S_SPRITEAT      .proc
                PHP
                TRACE "S_SPRITEAT"

                setal
                CALL EVALEXPR               ; Get the sprite's number
                CALL ASS_ARG1_BYTE          ; Make sure it's a byte
                CALL SPADDR                 ; Compute the address of the sprite's block     

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the X coordinate for the sprite
                CALL ASS_ARG1_INT           ; Make sure it's an integer

                LDA ARGUMENT1
                LDY #SP_X_COORD             ; Save the X coordinate for the sprite
                STA [MTEMPPTR],Y 

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the Y coordinate for the sprite
                CALL ASS_ARG1_INT           ; Make sure it's an integer

                LDA ARGUMENT1
                LDY #SP_Y_COORD             ; Save the Y coordinate for the sprite
                STA [MTEMPPTR],Y            

                PLP
                RETURN
                .pend

;
; SPRITESHOW number, boolean [,layer]
;       Control whether or not the sprite is visible
;       Optionally set the layer for the sprite
;
S_SPRITESHOW    .proc
                PHP
                TRACE "S_SPRITESHOW"

                setal
                CALL EVALEXPR               ; Get the sprite's number
                CALL ASS_ARG1_BYTE          ; Make sure it's a byte
                CALL SPADDR                 ; Compute the address of the sprite's block 
                LDA ARGUMENT1
                STA GR_TEMP                 ; GR_TEMP := sprite #

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the visibility
                CALL ASS_ARG1_INT           ; Make sure it's an integer
                LDA ARGUMENT1
                PHA                         ; And save it
   
                LDA #','
                STA TARGETTOK
                CALL OPT_TOK                ; Is there a comma?
                BCS get_layer               ; Yes: get the layer

no_layer        LDA @lGR_TEMP
                TAX
                LDA @lGS_SP_CONTROL,X       ; Get the current control register value
                AND #$FE                    ; Filter out the enable bit
                STA SCRATCH

                PLA                         ; Get the desired enable bit
                AND #$01                    ; Make sure it's just the bit
                ORA SCRATCH                 ; Combine it with the current values
                STA @lGS_SP_CONTROL,X       ; And save it
                STA [MTEMPPTR]              ; ... and to Vicky
                BRA done

get_layer       setas
                CALL INCBIP
                CALL EVALEXPR               ; Get the sprite's layer
                CALL ASS_ARG1_BYTE          ; Make sure it's a byte
                LDA ARGUMENT1
                CMP #8                      ; Make sure it's in range
                BGE error                   ; If not, throw an out of range error
                
                ASL A                       ; If it's ok... shift it into position
                ASL A
                ASL A
                ASL A
                STA SCRATCH                 ; And save it in SCRATCH

                PLA                         ; Get the desired enable bit
                AND #$01                    ; Make sure it's just the bit
                ORA SCRATCH                 ; Combine it with the current values
                STA SCRATCH

                LDA @lGR_TEMP
                TAX
                LDA GS_SP_CONTROL,X         ; Get the current control register value
                AND #%10001110              ; Filter out the enable and layer bits
                ORA SCRATCH                 ; Combine with the provided layer and enable
                STA [MTEMPPTR]              ; And set the bits in Vicky
                STA GS_SP_CONTROL,X         ; And to the shadow registers

done            PLP
                RETURN
error           THROW ERR_RANGE             ; Throw an out of range error
                .pend