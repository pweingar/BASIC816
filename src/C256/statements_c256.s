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
SP_MAX = 64                         ; The number of sprites Vicky supports
SP_REG_SIZE = 8                     ; The number of bytes in a sprite's register block
SP_CONTROL = 0                      ; Offset of the control regsiter for a sprite
SP_ADDR = 1                         ; Offset of the pixmap address for a sprite
SP_X_COORD = 4                      ; Offset of the X coordinate for a sprite
SP_Y_COORD = 6                      ; Offset of the Y coordinate for a sprite

TILEMAP_REG_SIZE = 12               ; The number of bytes in a tile map's register set
TILESET_REG_SIZE = 4                ; The number of bytes in a tile set's register set

BM_MAX = 2                          ; Maximum number of bitmaps we support


.section variables
GR_BM0_ADDR     .dword ?            ; Address of bitmap 0 (from CPU's perspective)
GR_BM1_ADDR     .dword ?            ; Address of bitmap 1 (from CPU's perspective)
GR_BM0_VRAM     .dword ?            ; Address of bitmap 0 (relative to start of VRAM)
GR_BM1_VRAM     .dword ?            ; Address of bitmap 1 (relative to start of VRAM)
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

;; Pixmap
; PLOT x,y,color
;       Set the color of the pixel at (x, y)
; LINE x0,y0,x1,y1,color
;       Draw a line from (x0, y0) to (x1, y1) in the specified color
; FILL x0,y0,x1,y1,color
;       Fill a box with corners (x0, y0) and (x1, y1) in the specified color.

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

                JSL FK_SETSIZES
                BRA get_color

hide_border     LDA #0                      ; Hide the border
                STA @lBORDER_CTRL_REG

                JSL FK_SETSIZES

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

                setal
                LDA ARGUMENT1               ; Check to see if we're setting mode to 800x600 or 400x300
                BIT #$0100
                BNE set_mode                ; Yes: go ahead and set it

                LDA @l MASTER_CTRL_REG_L    ; Otherwise, check to see if we're already in 800x600 or 400x300
                BIT #$0100
                BEQ set_mode                ; No: just go ahead and set the mode

                setas
                LDA #0                      ; Yes: toggle back to 640x480...
                STA @l MASTER_CTRL_REG_H
                LDA #1                      ; And back to 800x600....
                STA @l MASTER_CTRL_REG_H

set_mode        setal
                LDA ARGUMENT1
                STA @l MASTER_CTRL_REG_L    ; Set the graphics mode

                .rept 7
                LSR A
                .next
                AND #$00FF
                ASL A
                TAX                         ; X is index into the size tables

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

                ; Set the screen size

                JSL FK_SETSIZES

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

;
; Find the address (to the CPU) to the bitmap given it's number
;
; Inputs:
;   ARGUMENT1 = the number of the bitmap plane (0 or 1)
;
; Outputs:
;   MTEMPPTR = pointer to the first byte for that bitmap (in SRAM)
;
BITMAP_SRAM     .proc
                PHX
                PHP

                setaxl
                LDA ARGUMENT1           ; Get the number
                CMP #BM_MAX
                BGE range_err           ; Make sure it's within range
                ASL A
                ASL A                   ; Multiply by 4 to calculate an address offset
                TAX

                LDA @l GR_BM0_ADDR,X    ; Get the low 16-bits of the address
                STA MTEMPPTR
                LDA @l GR_BM0_ADDR+2,X  ; Get the high bits of the address
                STA MTEMPPTR+2

                PLP
                PLX
                RETURN
range_err       THROW ERR_RANGE         ; Throw an out of range error
                .pend

;
; Find the address to the bitmap given it's number
;
; Inputs:
;   ARGUMENT1 = the number of the bitmap plane (0 or 1)
;
; Outputs:
;   MTEMPPTR = pointer to the first byte for that bitmap (in VRAM)
;
BITMAP_VRAM     .proc
                PHX
                PHP

                setaxl
                LDA ARGUMENT1           ; Get the number
                CMP #BM_MAX
                BGE range_err           ; Make sure it's within range
                ASL A
                ASL A                   ; Multiply by 4 to calculate an address offset
                TAX

                LDA @l GR_BM0_VRAM,X    ; Get the low 16-bits of the address
                STA MTEMPPTR
                LDA @l GR_BM0_VRAM+2,X  ; Get the high bits of the address
                STA MTEMPPTR+2

                PLP
                PLX
                RETURN
range_err       THROW ERR_RANGE         ; Throw an out of range error
                .pend

; Set the pixmap base address
; BITMAP number, visible, lut, address
S_BITMAP        .proc
                PHP
                TRACE "S_BITMAP"

                setal
                CALL EVALEXPR               ; Get the bitmap number
                CALL ASS_ARG1_BYTE          ; Assert that the result is a byte value
                setal
                LDA ARGUMENT1               ; Make sure it's in range
                CMP #BM_MAX
                BGE range_err               ; If not, throw an error
                STA MARG1                   ; If so, save it to MARG1

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma 
                CALL EVALEXPR               ; Get the visible flag
                CALL ASS_ARG1_BYTE          ; Assert that the result is a byte value
                MOVE_W MARG2,ARGUMENT1      ; Save it to MARG2

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma
                CALL EVALEXPR               ; Get the LUT #
                CALL ASS_ARG1_BYTE          ; Assert that the result is a byte value

                LDA MARG1                   ; Get the number back
                ASL A                       ; Multiply by 8 to get the offset to the registers
                ASL A
                ASL A
                TAX                         ; And save that offset to X

                setas
                LDA MARG2                   ; Check the visible flag
                BNE is_visible              ; If <> 0, it's visible

                LDA ARGUMENT1               ; Get the LUT #
                ASL A                       ; Shift it into position for the register
                BRA wr_bm_reg               ; And go to write it

is_visible      LDA ARGUMENT1               ; Get the LUT #
                SEC     
                ROL A                       ; And shift it into position, and set enable bit

wr_bm_reg       STA @l BM0_CONTROL_REG,X    ; Write to the bitmap control register      

                setal
                LDA #','
                STA TARGETTOK
                CALL OPT_TOK                ; Is there a comma?
                BCS get_address             ; Yes: parse the address

                setal
                LDARG_EA ARGUMENT1,VRAM,TYPE_INTEGER
                BRA set_address

range_err       THROW ERR_RANGE

get_address     setal
                CALL INCBIP
                CALL EVALEXPR               ; Get the address

                ; Rebase the address to the start of VRAM
set_address     setal
                LDA MARG1                   ; Get the bitmap number back
                ASL A                       ; Multiply by four to get the offset to the address variable
                ASL A
                TAX                         ; And put it in X

                LDA ARGUMENT1               ; Get the CPU-space address
                STA @l GR_BM0_ADDR,X        ; And save it to the correct GR_BM?_ADDR variable
                STA @l GR_BM0_VRAM,X
                STA MARG3                   ; And MARG3, temporarily
                LDA ARGUMENT1+2
                STA @l GR_BM0_ADDR+2,X

                SEC
                SBC #`VRAM                  ; Rebase the upper half of the address to Vicky memory space
                STA @l GR_BM0_VRAM+2,X
                STA MARG3+2                 ; And to MARG3

                LDA MARG1                   ; Get the bitmap number back
                ASL A                       ; Multiply by eight to get the offset to the registers
                ASL A
                ASL A
                TAX                         ; And put it in X

                setas
                LDA MARG3                   ; Get the address in Vicky space...
                STA @l BM0_START_ADDY_L,X   ; Save it to the Vicky registers
                LDA MARG3+1
                STA @l BM0_START_ADDY_M,X
                LDA MARG3+2
                STA @l BM0_START_ADDY_H,X

                LDA #0                      ; Default offset to (0, 0)
                STA @l BM0_X_OFFSET,X
                STA @l BM0_Y_OFFSET,X

                PLP
                RETURN
bad_address     THROW ERR_ARGUMENT          ; Throw an illegal argument exception
                .pend

; Clear the current pixmap memory
; CLRBITMAP number
S_CLRBITMAP     .proc
                PHP
                TRACE "S_CLRBITMAP"

                setal
                CALL EVALEXPR               ; Get the bitmap number
                CALL ASS_ARG1_BYTE          ; Assert that the result is a byte value
                CALL BITMAP_VRAM            ; Get the address of the bitmap into MTEMPPTR

                ; We're going to use Vicky's VDMA capabilities to fill the screen here.
                ; This should be MUCH faster than the CPU can do it.

                setal
                LDA MTEMPPTR                ; Set the start address and the # of pixels to write
                STA @lVDMA_DST_ADDY_L
                LDA @lGR_TOTAL_PIXELS       ; Set the size
                STA @lVDMA_SIZE_L
                setas
                LDA MTEMPPTR+2
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
;   MTEMPPTR = the address of the first byte of the bitmap
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
                ADC MTEMPPTR
                STA SCRATCH
                LDA SCRATCH+2
                ADC MTEMPPTR+2
                STA SCRATCH+2               ; SCRATCH := pixmap + pixel offset

                setas
                LDA COLOR                   ; Get the color
                STA [SCRATCH]               ; And write the color to the pixel

                PLP
                RETURN
                .pend

;
; Draw a line from (X0,Y0) to (X1,Y1)
;
; Used the algorithm at: https://rosettacode.org/wiki/Bitmap/Bresenham%27s_line_algorithm#C
;
; Inputs:
;   MTEMPPTR = the address of the first byte of the bitmap
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
;   MTEMPPTR = the address of the first byte of the bitmap
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
                LDA MTEMPPTR
                ADC SCRATCH
                STA @lVDMA_DST_ADDY_L
                setas
                LDA MTEMPPTR+2
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
; PLOT plane, x, y, color_index
S_PLOT          .proc
                PHP
                TRACE "S_PLOT"

                setdp <>GLOBAL_VARS
                setdbr 0
                setaxl

                CALL EVALEXPR               ; Get the bitmap number
                CALL ASS_ARG1_BYTE          ; Assert that the result is a byte value
                CALL BITMAP_SRAM            ; Get the address of the bitmap into MTEMPPTR

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the x coordinate
                CALL ASS_ARG1_INT           ; Make sure it's an integer
                LDA ARGUMENT1
                STA X0                      ; Save it to MARG2

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the y coordinate
                CALL ASS_ARG1_INT           ; Make sure it's an integer
                LDA ARGUMENT1
                STA Y0                      ; Save it to MARG3

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the color index            
                CALL ASS_ARG1_BYTE          ; Make sure it's a byte
                LDA ARGUMENT1
                STA COLOR                   ; Save it to MARG1

                CALL PLOT                   ; And draw the pixel

                PLP
                RETURN
                .pend

; Draw a pixel on the pixmap
; LINE plane, x0, y0, x1, y1, color
S_LINE          .proc
                PHP
                TRACE "S_LINE"

                setdp <>GLOBAL_VARS
                setdbr 0
                setaxl

                CALL EVALEXPR               ; Get the bitmap number
                CALL ASS_ARG1_BYTE          ; Assert that the result is a byte value
                CALL BITMAP_SRAM            ; Get the address of the bitmap into MTEMPPTR

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

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
; FILL plane, x0, y0, x1, y1, color
S_FILL          .proc
                PHP
                TRACE "S_FILL"

                setdp <>GLOBAL_VARS
                setdbr 0
                setaxl

                CALL EVALEXPR               ; Get the bitmap number
                CALL ASS_ARG1_BYTE          ; Assert that the result is a byte value
                CALL BITMAP_SRAM            ; Get the address of the bitmap into MTEMPPTR

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

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
;   ARGUMENT1 = the number of the sprite desired (0 - 63)
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
                setas
                STA [MTEMPPTR]              ; ... and to Vicky
                BRA done

get_layer       setal
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
                setas
                LDA GS_SP_CONTROL,X         ; Get the current control register value
                AND #%10001110              ; Filter out the enable and layer bits
                ORA SCRATCH                 ; Combine with the provided layer and enable
                STA [MTEMPPTR]              ; And set the bits in Vicky
                STA GS_SP_CONTROL,X         ; And to the shadow registers

done            PLP
                RETURN
error           THROW ERR_RANGE             ; Throw an out of range error
                .pend

;
; Calculate the address of a tile set's registers given its number
;
; Inputs:
;   ARGUMENT1 = the number of the tile set
;
; Outputs:
;   MTEMPPTR = the address of the first byte in the tile set's register space
;
TILESET_ADDR    .proc
                PHP

                setal
                LDA ARGUMENT1               ; Get the tile set number
                CMP #4                      ; Make sure it's 0 - 4
                BGE out_of_range            ; If not, throw a range error

                STA @w M0_OPERAND_A
                LDA #TILESET_REG_SIZE       ; Multiply it by the number of bytes in a tile set register set
                STA @w M0_OPERAND_B

                CLC                         ; Add to TILESET0_ADDY_L to get the final address
                LDA @w M0_RESULT
                ADC #<>TILESET0_ADDY_L
                STA MTEMPPTR
                LDA #`TILESET0_ADDY_L
                STA MTEMPPTR+2

                PLP
                RETURN

out_of_range    THROW ERR_RANGE             ; Throw an out of range error
                .pend

;
; Calculate the address of a tile map's registers given its number
;
; Inputs:
;   ARGUMENT1 = the number of the tile set
;
; Outputs:
;   MTEMPPTR = the address of the first byte in the tile map's register space
;
TILEMAP_ADDR    .proc
                PHP

                setal
                LDA ARGUMENT1               ; Get the tile map number
                CMP #4                      ; Make sure it's 0 - 4
                BGE out_of_range            ; If not, throw a range error

                STA @w M0_OPERAND_A
                LDA #TILEMAP_REG_SIZE       ; Multiply it by the number of bytes in a tile map register set
                STA @w M0_OPERAND_B

                CLC
                LDA @w M0_RESULT            ; Add to TL0_CONTROL_REG to get the final address                        
                ADC #<>TL0_CONTROL_REG
                STA MTEMPPTR
                LDA #`TL0_CONTROL_REG
                STA MTEMPPTR+2

                PLP
                RETURN

out_of_range    THROW ERR_RANGE             ; Throw an out of range error
                .pend

;
; TILESET number, lut, is_square, address
;   Defines a tileset (the collection of tiles that can be used by a tile map).
;       LUT is the color lookup table #
;       is_square is a boolean indicating if the map is arranged in 256x256 square
;       address is the address of the bitmap data (must be in video RAM)
;
S_TILESET       .proc
                PHP
                TRACE "S_TILESET"

                setal
                CALL EVALEXPR               ; Get the sprite's number
                CALL ASS_ARG1_BYTE          ; Make sure it's a byte
                CALL TILESET_ADDR           ; Compute the address of the tile set's block
                setal
                LDA MTEMPPTR+2              ; Save the address
                PHA
                LDA MTEMPPTR
                PHA

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the LUT
                CALL ASS_ARG1_BYTE          ; Make sure it's a byte
                setal
                LDA ARGUMENT1
                PHA                         ; And save it

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the square flag
                CALL ASS_ARG1_BYTE          ; Make sure it's a byte
                setal
                LDA ARGUMENT1
                PHA                         ; And save it               

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the address
                CALL ASS_ARG1_INT           ; Make sure it's an integer
                setal
                LDA ARGUMENT1
                STA MARG3                   ; Save it to MARG3
                LDA ARGUMENT1+2
                STA MARG3+2

                PLA                         ; Get the square flag back
                STA MARG2                   ; Save it to MARG2

                PLA                         ; Get the LUT
                STA MARG1                   ; Save it to MARG1

                PLA                         ; Get the register address
                STA MTEMPPTR                ; Save it to MTEMPPTR
                PLA
                STA MTEMPPTR+2

                ; PLA                         ; Get the register address
                ; STA MTEMPPTR                ; Save it to MTEMPPTR
                ; STA $020010
                ; PLA
                ; STA MTEMPPTR+2
                ; STA $020012

                ; LDA #0
                ; STA MTEMPPTR
                ; LDA #2
                ; STA MTEMPPTR+2

                LDA MARG3                   ; Get the bitmap address - the address of the start of VRAM
                STA [MTEMPPTR]              ; And save it to the registers
                setas
                SEC
                LDA MARG3+2
                SBC #`VRAM
                LDY #TILESET_ADDY_H
                STA [MTEMPPTR],Y
                setal

                LDA MARG2                   ; Check if is_square == 0?
                BNE is_square
                LDA MARG2+2
                BNE is_square

not_square      setas
                LDA MARG1                   ; Get the LUT
                AND #$07                    ; Force it to be in range
                LDY #TILESET_ADDY_CFG
                STA [MTEMPPTR],Y            ; Save it to the registers
                BRA done

is_square       setas
                LDA MARG1                   ; Get the LUT
                AND #$07                    ; Force it to be in range
                ORA #TILESET_SQUARE_256     ; Turn on the 256x256 flag
                LDY #TILESET_ADDY_CFG
                STA [MTEMPPTR],Y            ; Save it to the registers

done            PLP
                RETURN
                .pend

;
; TILEMAP number, width, height, address
;   Defines a tile map.
;       width = the number of tile columns in the map
;       height = the number of tile rows in the map
;       address = the address of the map itself (must be video RAM)
;
S_TILEMAP       .proc
                PHP
                TRACE "S_TILEMAP"

                setal
                CALL EVALEXPR               ; Get the sprite's number
                CALL ASS_ARG1_BYTE          ; Make sure it's a byte
                CALL TILEMAP_ADDR           ; Compute the address of the tile set's block
                setal
                LDA MTEMPPTR+2              ; Save the address
                PHA
                LDA MTEMPPTR
                PHA

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the width
                CALL ASS_ARG1_INT           ; Make sure it's an integer
                setal
                LDA ARGUMENT1
                PHA                         ; And save it

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the height
                CALL ASS_ARG1_INT           ; Make sure it's an integer
                setal
                LDA ARGUMENT1
                PHA                         ; And save it               

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the address
                CALL ASS_ARG1_INT           ; Make sure it's an integers
                setal
                LDA ARGUMENT1
                STA MARG3                   ; Save it to MARG3
                LDA ARGUMENT1+2
                STA MARG3+2

                PLA                         ; Get the height back
                STA MARG2                   ; Save it to MARG2

                PLA                         ; Get the width
                STA MARG1                   ; Save it to MARG1

                PLA                         ; Get the register address
                STA MTEMPPTR                ; Save it to MTEMPPTR
                PLA
                STA MTEMPPTR+2

                ; PLA                         ; Get the register address
                ; STA MTEMPPTR                ; Save it to MTEMPPTR
                ; STA $020010
                ; PLA
                ; STA MTEMPPTR+2
                ; STA $020012

                ; LDA #0
                ; STA MTEMPPTR
                ; LDA #2
                ; STA MTEMPPTR+2

                LDA MARG3                   ; Get the map address - the address of the start of VRAM
                LDY #TILEMAP_START_ADDY
                STA [MTEMPPTR],Y            ; And save it to the registers
                setas
                SEC
                LDA MARG3+2
                SBC #`VRAM
                INY
                INY
                STA [MTEMPPTR],Y
                setal

                LDA MARG1                   ; Set the width
                LDY #TILEMAP_TOTAL_X
                STA [MTEMPPTR],Y

                LDA MARG2                   ; Set the height
                LDY #TILEMAP_TOTAL_Y
                STA [MTEMPPTR],Y

                PLP
                RETURN
                .pend

;
; TILESHOW number, visible
;   Sets whether or not the tile map is visible
;       visible: boolean, true if the map should be visible
;
S_TILESHOW      .proc
                PHP
                TRACE "S_TILESHOW"

                setal
                CALL EVALEXPR               ; Get the sprite's number
                CALL ASS_ARG1_BYTE          ; Make sure it's a byte
                CALL TILEMAP_ADDR           ; Compute the address of the tile set's block
                setal
                LDA MTEMPPTR+2              ; Save the address
                PHA
                LDA MTEMPPTR
                PHA

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the visible flag
                CALL ASS_ARG1_INT           ; Make sure it's an integer
                setal

                PLA                         ; Get the register address
                STA MTEMPPTR                ; Save it to MTEMPPTR
                PLA
                STA MTEMPPTR+2

                ; PLA                         ; Get the register address
                ; STA MTEMPPTR                ; Save it to MTEMPPTR
                ; STA $020010
                ; PLA
                ; STA MTEMPPTR+2
                ; STA $020012

                ; LDA #0
                ; STA MTEMPPTR
                ; LDA #2
                ; STA MTEMPPTR+2

                LDA ARGUMENT1               ; CHeck the visible parameter
                BNE is_visible              ; If it's <> 0, make it visible

                setas
                LDA #0                      ; Control value for invisible
                BRA set_control

is_visible      setas
                LDA #TILEMAP_VISIBLE        ; Control value for visible

set_control     setas
                LDY #TILEMAP_CONTROL        ; Set the control register
                STA [MTEMPPTR],Y

                PLP
                RETURN
                .pend


;
; TILEAT number, x, y
;   Sets the window position and scroll of a tile map
;       x = the horizontal scroll/window value
;       y = the vertical scroll/window value
;
S_TILEAT        .proc
                PHP
                TRACE "S_TILEMAP"

                setal
                CALL EVALEXPR               ; Get the sprite's number
                CALL ASS_ARG1_BYTE          ; Make sure it's a byte
                CALL TILEMAP_ADDR           ; Compute the address of the tile set's block
                LDA MTEMPPTR+2              ; Save the address
                PHA
                LDA MTEMPPTR
                PHA

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the X position
                CALL ASS_ARG1_INT           ; Make sure it's an integer
                LDA ARGUMENT1
                PHA                         ; And save it

                LDA #','
                CALL EXPECT_TOK             ; Try to find the comma

                CALL EVALEXPR               ; Get the Y position
                CALL ASS_ARG1_INT           ; Make sure it's an integer
                LDA ARGUMENT1
                STA MARG2                   ; Save it to MARG2

                PLA                         ; Get the X position
                STA MARG1                   ; Save it to MARG1

                PLA                         ; Get the register address
                STA MTEMPPTR                ; Save it to MTEMPPTR
                PLA
                STA MTEMPPTR+2

                ; PLA                         ; Get the register address
                ; STA MTEMPPTR                ; Save it to MTEMPPTR
                ; STA $020010
                ; PLA
                ; STA MTEMPPTR+2
                ; STA $020012

                ; LDA #0
                ; STA MTEMPPTR
                ; LDA #2
                ; STA MTEMPPTR+2

                LDA MARG1                   ; Set the X position
                LDY #TILEMAP_WINDOW_X
                STA [MTEMPPTR],Y

                LDA MARG2                   ; Set the Y position
                LDY #TILEMAP_WINDOW_Y
                STA [MTEMPPTR],Y

                PLP
                RETURN
                .pend

;
; DMA Type Constants
;
DMA_LINEAR = 0                              ; Memory to copy is a continguous, linear range
DMA_RECT = 1                                ; Memory to copy is a rectangular block

;
; A structure to represent a section of memory to be the source or destination
; for a DMA operation.
;
DMA_BLOCK       .struct
MODE            .byte ?                     ; The type of transfer: 0 = LINEAR, 1 = RECTANGULAR
ADDR            .long ?                     ; The starting address for the data to transfer
SIZE            .long ?                     ; The number of bytes to transfer (for LINEAR sources)              
WIDTH           .word ?                     ; The width of the rectangle to copy (for RECTANGULAR)
HEIGHT          .word ?                     ; The height of the rectangle to copy (for RECTANGULAR sources)
STRIDE          .word ?                     ; The number of bytes to skip to get to the next line (for RECTANGULAR)
                .ends

DMA_SRC_2D = $01                            ; Source transfer should be 2D
DMA_DST_2D = $02                            ; Destination transfer should be 2D
DMA_SRC_SRAM = $10                          ; Flag indicating that the source is in SRAM ($00:0000 - $3F:FFFF)
DMA_DST_SRAM = $20                          ; Flag indicating that the destination is in SRAM ($00:0000 - $3F:FFFF)

.section variables
DMA_BLOCKS      .byte ?                     ; What blocks are involved
DMA_SRC         .dstruct DMA_BLOCK          ; Source for a DMA transfer
DMA_DEST        .dstruct DMA_BLOCK          ; Destination for a DMA transfer
.send

;
; Routine to actually perform a copy of memory data
;
; Inputs:
;   DMA_SRC = record of the source for the DMA operation
;   DMA_DEST = record of the destination for the DMA operation
;
DO_DMA          .proc
                PHD
                PHP

                setdp GLOBAL_VARS

                ; Set up source parameters
                setas
                LDA #0
                STA @l DMA_BLOCKS           ; Set mode to something neutral

                LDA @l DMA_SRC.ADDR+2       ; Check the bank
                CMP #`VRAM                  ; Is it in VRAM?
                BGE src_vram                ; Yes: leave the DMA_BLOCK bit alone

src_sram        STA @l SDMA_SRC_ADDY_H      ; Set the SDMA source address
                LDA @l DMA_SRC.ADDR+1
                STA @l SDMA_SRC_ADDY_M
                LDA @l DMA_SRC.ADDR
                STA @l SDMA_SRC_ADDY_L

                LDA #DMA_SRC_SRAM           ; Set the SRAM source block bit
                STA @l DMA_BLOCKS
                BRA src_mode

src_vram        SEC                         ; Convert to VRAM relative address
                SBC #`VRAM
                STA @l VDMA_SRC_ADDY_H      ; Set the VDMA source address
                LDA @l DMA_SRC.ADDR+1
                STA @l VDMA_SRC_ADDY_M
                LDA @l DMA_SRC.ADDR
                STA @l VDMA_SRC_ADDY_L

src_mode        LDA @l DMA_SRC.MODE         ; Determine if source is 1D or 2D
                BNE src_2d

                ; Set up 1D source parameters
src_1d          LDA @l DMA_BLOCKS           ; Check if the source is SRAM or VRAM
                BEQ src_1d_vram

                ; Set the 1D SRAM source information
src_1d_sram     LDA @l DMA_SRC.SIZE         ; It's SRAM, so set the SDMA size
                STA @l SDMA_SIZE_L
                LDA @l DMA_SRC.SIZE+1
                STA @l SDMA_SIZE_M
                LDA @l DMA_SRC.SIZE+2
                STA @l SDMA_SIZE_H
                BRL set_dst                 ; Go to set up the destination

                ; Set the 1D VRAM source information
src_1d_vram     LDA @l DMA_SRC.SIZE         ; It's VRAM, so set the VDMA size
                STA @l VDMA_SIZE_L
                LDA @l DMA_SRC.SIZE+1
                STA @l VDMA_SIZE_M
                LDA @l DMA_SRC.SIZE+2
                STA @l VDMA_SIZE_H
                BRL set_dst                 ; Go to set up the destination

                ; Set up 2D source parameters
src_2d          LDA @l DMA_BLOCKS
                ORA #DMA_SRC_2D             ; Set the bit to make the source a 2D transfer
                STA @l DMA_BLOCKS
                
                BIT #DMA_SRC_SRAM           ; Are we writing to SRAM
                BEQ src_2d_vram             ; No: set the 2d values in the VRAM source

                ; Set the 1D SRAM source information
src_2d_sram     LDA @l DMA_SRC.WIDTH        ; Set the source width
                STA @l SDMA_X_SIZE_L
                LDA @l DMA_SRC.WIDTH+1
                STA @l SDMA_X_SIZE_L+1

                LDA @l DMA_SRC.HEIGHT       ; Set the source height
                STA @l SDMA_Y_SIZE_L
                LDA @l DMA_SRC.HEIGHT+1
                STA @l SDMA_Y_SIZE_L+1

                LDA @l DMA_SRC.STRIDE       ; Set the source stride
                STA @l SDMA_SRC_STRIDE_L
                LDA @l DMA_SRC.STRIDE+1
                STA @l SDMA_SRC_STRIDE_L+1
                BRA set_dst

                ; Set the 2D SRAM source information
src_2d_vram     LDA @l DMA_SRC.WIDTH        ; Set the source width
                STA @l VDMA_X_SIZE_L
                LDA @l DMA_SRC.WIDTH+1
                STA @l VDMA_X_SIZE_L+1

                LDA @l DMA_SRC.HEIGHT       ; Set the source height
                STA @l VDMA_Y_SIZE_L
                LDA @l DMA_SRC.HEIGHT+1
                STA @l VDMA_Y_SIZE_L+1

                LDA @l DMA_SRC.STRIDE       ; Set the source stride
                STA @l VDMA_SRC_STRIDE_L
                LDA @l DMA_SRC.STRIDE+1
                STA @l VDMA_SRC_STRIDE_L+1

set_dst         ; Set up destination parameters
                setas
                LDA @l DMA_DEST.ADDR+2      ; Check the bank
                CMP #`VRAM                  ; Is it in VRAM?
                BGE dst_vram                ; Yes: leave the DMA_BLOCK bit alone

dst_sram        STA @l SDMA_DST_ADDY_H      ; Set the SDMA destination address
                LDA @l DMA_DEST.ADDR+1
                STA @l SDMA_DST_ADDY_M
                LDA @l DMA_DEST.ADDR
                STA @l SDMA_DST_ADDY_L

                LDA @l DMA_BLOCKS
                ORA #DMA_DST_SRAM           ; Set the bit to indicate the destination is SRAM
                STA @l DMA_BLOCKS 
                BRA dst_mode

dst_vram        SEC                         ; Convert to VRAM relative address
                SBC #`VRAM
                STA @l VDMA_DST_ADDY_H      ; Set the VDMA destination address
                LDA @l DMA_DEST.ADDR+1
                STA @l VDMA_DST_ADDY_M
                LDA @l DMA_DEST.ADDR
                STA @l VDMA_DST_ADDY_L               

                ; Determine if destination is 1D or 2D
dst_mode        LDA @l DMA_DEST.MODE        
                BNE dst_2d                  ; If 2D, set up the 2D destination parameters

                ; Set up 1D destination parameters
dst_1d          LDA @l DMA_BLOCKS           ; Check if the source is SRAM or VRAM
                BIT #DMA_DST_SRAM           ; Is the destination SRAM?
                BEQ dst_1d_vram
                
                ; Set up 1D SRAM destination parameters
dst_1d_sram     LDA @l DMA_DEST.SIZE
                STA @l SDMA_SIZE_L
                LDA @l DMA_DEST.SIZE+1
                STA @l SDMA_SIZE_L+1
                LDA @l DMA_DEST.SIZE+2
                STA @l SDMA_SIZE_H
                BRL start_xfer

                ; Set up 1D SRAM destination parameters
dst_1d_vram     LDA @l DMA_DEST.SIZE
                STA @l VDMA_SIZE_L
                LDA @l DMA_DEST.SIZE+1
                STA @l VDMA_SIZE_L+1
                LDA @l DMA_DEST.SIZE+2
                STA @l VDMA_SIZE_H
                BRL start_xfer

                ; Set up 2D destination parameters
dst_2d          LDA @l DMA_BLOCKS
                ORA #DMA_DST_2D             ; Set the bit to make the source a 2D transfer
                STA @l DMA_BLOCKS

                BIT #DMA_DST_SRAM           ; Are we writing to the SRAM?
                BEQ dst_2d_vram             ; No: set the 2D parameters for VRAM

                ; Set the 2D destination parameters for SRAM
dst_2d_sram     LDA @l DMA_DEST.WIDTH       ; Set the SRAM width
                STA @l SDMA_X_SIZE_L
                LDA @L DMA_DEST.WIDTH+1
                STA @l SDMA_X_SIZE_L+1

                LDA @l DMA_DEST.HEIGHT      ; Set the SRAM height
                STA @l SDMA_Y_SIZE_L
                LDA @L DMA_DEST.HEIGHT+1
                STA @l SDMA_Y_SIZE_L+1

                LDA @l DMA_DEST.STRIDE      ; Set the SRAM stride
                STA @l SDMA_DST_STRIDE_L
                LDA @L DMA_DEST.STRIDE+1
                STA @l SDMA_DST_STRIDE_L+1

                BRA start_xfer

                ; Set the 2D destination parameters for VRAM
dst_2d_vram     LDA @l DMA_DEST.WIDTH       ; Set the VRAM width
                STA @l VDMA_X_SIZE_L
                LDA @L DMA_DEST.WIDTH+1
                STA @l VDMA_X_SIZE_L+1

                LDA @l DMA_DEST.HEIGHT      ; Set the VRAM height
                STA @l VDMA_Y_SIZE_L
                LDA @L DMA_DEST.HEIGHT+1
                STA @l VDMA_Y_SIZE_L+1

                LDA @l DMA_DEST.STRIDE      ; Set the VRAM stride
                STA @l VDMA_DST_STRIDE_L
                LDA @L DMA_DEST.STRIDE+1
                STA @l VDMA_DST_STRIDE_L+1

                ; Determine what type of transfer we're doing
start_xfer      LDA @l DMA_BLOCKS
                AND #DMA_SRC_SRAM | DMA_DST_SRAM
                BEQ start_vdma_only
                CMP #DMA_SRC_SRAM
                BEQ start_s2v
                CMP #DMA_DST_SRAM
                BNE start_sdma_only
                BRL start_v2s

start_sdma_only ; Set the SDMA registers for a SDMA-only transfer

                LDA @l DMA_BLOCKS           ; Check the SDMA flags
                AND #DMA_SRC_2D | DMA_DST_2D
                BEQ sdma_1d_only            ; Source and Destination 1D...
                CMP #DMA_SRC_2D | DMA_DST_2D
                BEQ sdma_2d_only            ; Source and Destination 2D

                ; Cannot mix topographies within an SRAM->SRAM transfer                
                THROW ERR_ARGUMENT          ; Throw an illegal argument error

sdma_1d_only    LDA #SDMA_CTRL0_Enable      ; Set the bits for 1D, SRAM->SRAM
                BRA sdma_set_ctrl

                ; Set the bits for 2D, SRAM->SRAM
sdma_2d_only    LDA #SDMA_CTRL0_Enable | SDMA_CTRL0_1D_2D
sdma_set_ctrl   STA @l SDMA_CTRL_REG0
                BRL trig_sdma               ; And trigger the SDMA

start_vdma_only ; Set the VDMA registers for a VDMA-only transfer

                LDA @l DMA_BLOCKS           ; Check the SDMA flags
                AND #DMA_SRC_2D | DMA_DST_2D
                BEQ vdma_1d_only            ; Source and Destination 1D...
                CMP #DMA_SRC_2D | DMA_DST_2D
                BEQ vdma_2d_only            ; Source and Destination 2D...

                ; Cannot mix topographies within an VRAM->VRAM transfer                
                THROW ERR_ARGUMENT          ; Throw an illegal argument error

vdma_1d_only    LDA #VDMA_CTRL_Enable       ; Set the bits for 1D, VRAM->VRAM
                BRA vdma_set_ctrl

                ; Set the bits for 2D, VRAM->VRAM
vdma_2d_only    LDA #VDMA_CTRL_Enable | VDMA_CTRL_1D_2D
vdma_set_ctrl   STA @l VDMA_CONTROL_REG
                BRA trig_vdma               ; And trigger the VDMA

start_s2v       ; Set the DMA registers for SRAM -> VRAM transfer

                LDA @l DMA_BLOCKS           ; Set the SDMA flags
                AND #DMA_SRC_2D
                ASL A
                ORA #SDMA_CTRL0_Enable | SDMA_CTRL0_SysRAM_Src
                STA @l SDMA_CTRL_REG0

                LDA @l DMA_BLOCKS           ; Set the VDMA flags
                AND #DMA_DST_2D
                ORA #VDMA_CTRL_Enable | VDMA_CTRL_SysRAM_Src
                STA @l VDMA_CONTROL_REG
                BRA trig_vdma               ; And trigger the VDMA

start_v2s       ; Set the DMA registers for VRAM -> SRAM transfer
                LDA @l DMA_BLOCKS           ; Set the SDMA flags
                AND #DMA_DST_2D
                ORA #SDMA_CTRL0_Enable | SDMA_CTRL0_SysRAM_Dst
                STA @l SDMA_CTRL_REG0

                LDA @l DMA_BLOCKS           ; Set the VDMA flags
                AND #DMA_SRC_2D
                ASL A
                ORA #VDMA_CTRL_Enable | VDMA_CTRL_SysRAM_Dst
                STA @l VDMA_CONTROL_REG                    

trig_vdma       ; Trigger the VDMA part of the transfer
                LDA @l VDMA_CONTROL_REG
                ORA #VDMA_CTRL_Start_TRF    ; Trigger the VDMA
                STA @l VDMA_CONTROL_REG

                LDA @l DMA_BLOCKS           ; Check if we need SDMA
                AND #DMA_SRC_SRAM | DMA_DST_SRAM 
                BEQ wait_vdma               ; No: wait for VDMA to complete

trig_sdma       ; Trigger the SDMA part of the transfer

                LDA @l SDMA_CTRL_REG0
                ORA #SDMA_CTRL0_Start_TRF   ; Trigger the SDMA
                STA @l SDMA_CTRL_REG0
     
                NOP                         ; When the transfer is started the CPU will be put on Hold (RDYn)...
                NOP                         ; Before it actually gets to stop it will execute a couple more instructions
                NOP                         ; From that point on, the CPU is halted (keep that in mind)
                NOP                         ; No IRQ will be processed either during that time
                NOP

wait_vdma       LDA @l VDMA_STATUS_REG      ; Check the VDMA status
                BIT #VDMA_STAT_VDMA_IPS     ; If the transfer is still in process...
                BNE wait_vdma               ; Wait until it stops.

                LDA #$00                    ; Clear the TRF bits
                STA @l SDMA_CTRL_REG0
                STA @l VDMA_CONTROL_REG

                PLP
                PLD
                RETURN
                .pend

;
; Use DMA to copy a chunk of memory from one location to another.
; The statement is multi-purpose in that it supports transfers within and between system RAM
; and video RAM, and it also supports linear and rectangular copies.
;
; MEMCOPY LINEAR <src addr>, <size> TO LINEAR <dest addr>, <size>
; MEMCOPY LINEAR <src addr>, <size> TO RECT <dest addr>, <width>, <height>, <stride>
; MEMCOPY RECT <src addr>, <width>, <height>, <stride> TO LINEAR <dest addr>, <size>
; MEMCOPY RECT <src addr>, <width>, <height>, <stride> TO RECT <dest addr>, <width>, <height>, <stride>
;
S_MEMCOPY       .proc
                PHD
                PHP
                TRACE "S_MEMCOPY"

                setas
                setxl

                LDA #0
                LDX #0
clr_loop        STA @l DMA_SRC
                INX
                CPX #SIZE(DMA_BLOCK) * 2
                BNE clr_loop

                CALL PEEK_TOK                       ; Look for the next token
                CMP #TOK_LINEAR                     ; Is it LINEAR?
                BEQ src_linear                      ; Yes: go to process a linear source
                CMP #TOK_RECT                       ; Is it RECT?
                BEQ src_rect                        ; Yes: go to process a rectangular source

syntax_err      THROW ERR_SYNTAX                    ; Otherwise: throw a syntax error

                ; Process a linear source
src_linear      CALL EXPECT_TOK                     ; Eat the LINEAR keyword
                CALL EVALEXPR                       ; Get the source address
                CALL ASS_ARG1_INT                   ; Make sure it's an integer

                MOVE_L DMA_SRC.ADDR, ARGUMENT1      ; Set the source address

                LDA #','                            ; Get a comma
                CALL EXPECT_TOK
                CALL EVALEXPR                       ; Get the length of the data range to copy
                CALL ASS_ARG1_INT                   ; Make sure it's an integer

                MOVE_L DMA_SRC.SIZE, ARGUMENT1      ; Set the source size
                LD_B DMA_SRC.MODE, DMA_LINEAR       ; Set the source mode
                BRL process_to

                ; Process a rectangular source
src_rect        CALL EXPECT_TOK                     ; Eat the LINEAR keyword
                CALL EVALEXPR                       ; Get the source address
                CALL ASS_ARG1_INT                   ; Make sure it's an integer

                MOVE_L DMA_SRC.ADDR, ARGUMENT1      ; Set the source address

                LDA #','                            ; Get a comma
                CALL EXPECT_TOK
                CALL EVALEXPR                       ; Get the width of the data range to copy
                CALL ASS_ARG1_INT16                 ; Make sure it's a 16-bit integer

                ; Set the width and prepare for multiplication
                MOV2_W DMA_SRC.WIDTH, M0_OPERAND_A, ARGUMENT1

                LDA #','                            ; Get a comma
                CALL EXPECT_TOK
                CALL EVALEXPR                       ; Get the height of the data range to copy
                CALL ASS_ARG1_INT16                 ; Make sure it's a 16-bit integer

                ; Set the height and prepare for multiplication
                MOV2_W DMA_SRC.HEIGHT, M0_OPERAND_B, ARGUMENT1

                LDA #','                            ; Get a comma
                CALL EXPECT_TOK
                CALL EVALEXPR                       ; Get the stride of the data range to copy
                CALL ASS_ARG1_INT16                 ; Make sure it's a 16-bit integer

                MOVE_W DMA_SRC.STRIDE, ARGUMENT1    ; Set the stride    
                MOVE_L DMA_SRC.SIZE, M0_RESULT      ; Get WIDTH * HEIGHT
                LD_B DMA_SRC.MODE, DMA_RECT         ; Set the source mode

                ; Parse the TO keyword
process_to      setas
                LDA #TOK_TO
                CALL EXPECT_TOK                     ; Eat the TO token

                CALL PEEK_TOK                       ; Scan to the next token
                CMP #TOK_LINEAR                     ; Is it LINEAR?
                BEQ dest_linear                     ; Yes: go to process a linear destination
                CMP #TOK_RECT                       ; Is it RECT?
                BEQ dest_rect                       ; Yes: go to process a rectangular source

syntax_err2     THROW ERR_SYNTAX                    ; Otherwise: throw a syntax error 

                ; Process a linear transfer
dest_linear     CALL EXPECT_TOK                     ; Eat the LINEAR keyword
                CALL EVALEXPR                       ; Get the destination address
                CALL ASS_ARG1_INT                   ; Make sure it's an integer

                MOVE_L DMA_DEST.ADDR, ARGUMENT1     ; Set the destination address

                LDA #','                            ; Get a comma
                CALL EXPECT_TOK
                CALL EVALEXPR                       ; Get the length of the data range to copy
                CALL ASS_ARG1_INT                   ; Make sure it's an integer

                MOVE_L DMA_DEST.SIZE, ARGUMENT1     ; Set the destination size
                LD_B DMA_DEST.MODE, DMA_LINEAR      ; Set the destination mode
                BRL verify

                ; Process a rectangular destination
dest_rect       CALL EXPECT_TOK                     ; Eat the LINEAR keyword
                CALL EVALEXPR                       ; Get the source address
                CALL ASS_ARG1_INT                   ; Make sure it's an integer

                MOVE_L DMA_DEST.ADDR, ARGUMENT1     ; Set the source address

                LDA #','                            ; Get a comma
                CALL EXPECT_TOK
                CALL EVALEXPR                       ; Get the width of the data range to copy
                CALL ASS_ARG1_INT16                 ; Make sure it's a 16-bit integer

                ; Set the width and prepare for multiplication
                MOV2_W DMA_DEST.WIDTH, M0_OPERAND_A, ARGUMENT1

                LDA #','                            ; Get a comma
                CALL EXPECT_TOK
                CALL EVALEXPR                       ; Get the height of the data range to copy
                CALL ASS_ARG1_INT16                 ; Make sure it's a 16-bit integer

                ; Set the height and prepare for multiplication
                MOV2_W DMA_DEST.HEIGHT, M0_OPERAND_B, ARGUMENT1

                LDA #','                            ; Get a comma
                CALL EXPECT_TOK
                CALL EVALEXPR                       ; Get the stride of the data range to copy
                CALL ASS_ARG1_INT16                 ; Make sure it's a 16-bit integer

                MOVE_W DMA_DEST.STRIDE, ARGUMENT1   ; Set the stride
                MOVE_L DMA_DEST.SIZE, M0_RESULT     ; Get WIDTH * HEIGHT
                LD_B DMA_DEST.MODE, DMA_RECT        ; Set the destination mode

                ; Verify that the source and destination sizes are the same
verify          setal
                LDA @l DMA_SRC.SIZE
                CMP @l DMA_DEST.SIZE
                BNE size_err
                setas
                LDA @l DMA_SRC.SIZE+2
                CMP @l DMA_DEST.SIZE+2
                BNE size_err

                setal
                CALL DO_DMA                 ; Trigger the actual DMA operation

                PLP
                PLD
                RETURN
size_err        THROW ERR_ARGUMENT          ; Throw an illegal argument error
                .pend