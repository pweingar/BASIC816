;Internal VICKY Registers and Internal Memory Locations (LUTs)
MASTER_CTRL_REG_L	      = $AF0000

;Control Bits Fields
Mstr_Ctrl_Text_Mode_En  = $01       ; Enable the Text Mode
Mstr_Ctrl_Text_Overlay  = $02       ; Enable the Overlay of the text mode on top of Graphic Mode (the Background Color is ignored)
Mstr_Ctrl_Graph_Mode_En = $04       ; Enable the Graphic Mode
Mstr_Ctrl_Bitmap_En     = $08       ; Enable the Bitmap Module In Vicky
Mstr_Ctrl_TileMap_En    = $10       ; Enable the Tile Module in Vicky
Mstr_Ctrl_Sprite_En     = $20       ; Enable the Sprite Module in Vicky
Mstr_Ctrl_GAMMA_En      = $40       ; this Enable the GAMMA correction - The Analog and DVI have different color value, the GAMMA is great to correct the difference
Mstr_Ctrl_Disable_Vid   = $80       ; This will disable the Scanning of the Video hence giving 100% bandwith to the CPU
MASTER_CTRL_REG_H	    = $AF0001

; Reserved - TBD
VKY_RESERVED_00         = $AF0002
VKY_RESERVED_01         = $AF0003

Border_Ctrl_Enable      = $01
BORDER_CTRL_REG         = $AF0004 ; Bit[0] - Enable (1 by default)  Bit[4..6]: X Scroll Offset ( Will scroll Left) (Acceptable Value: 0..7)
BORDER_COLOR_B          = $AF0005
BORDER_COLOR_G          = $AF0006
BORDER_COLOR_R          = $AF0007
BORDER_X_SIZE           = $AF0008 ; X-  Values: 0 - 32 (Default: 32)
BORDER_Y_SIZE           = $AF0009 ; Y- Values 0 -32 (Default: 32)

BACKGROUND_COLOR_B      = $AF0008 ; When in Graphic Mode, if a pixel is "0" then the Background pixel is chosen
BACKGROUND_COLOR_G      = $AF0009
BACKGROUND_COLOR_R      = $AF000A ;

VKY_TXT_CURSOR_CTRL_REG = $AF0010   ;[0]  Enable Text Mode
Vky_Cursor_Enable       = $01
Vky_Cursor_Flash_Rate0  = $02
Vky_Cursor_Flash_Rate1  = $04
Vky_Cursor_FONT_Page0   = $08       ; Pick Font Page 0 or Font Page 1
Vky_Cursor_FONT_Page1   = $10       ; Pick Font Page 0 or Font Page 1
VKY_TXT_RESERVED        = $AF0011   ; Not in Use
VKY_TXT_CURSOR_CHAR_REG = $AF0012

VKY_TXT_CURSOR_COLR_REG = $AF0013
VKY_TXT_CURSOR_X_REG_L  = $AF0014
VKY_TXT_CURSOR_X_REG_H  = $AF0015
VKY_TXT_CURSOR_Y_REG_L  = $AF0016
VKY_TXT_CURSOR_Y_REG_H  = $AF0017

TXT_CLR_START_DISPLAY_PTR = $AF0018 ; (0 to 255) (this Add a X Offset to the Display Start Address)

; Line Interrupt Registers
VKY_LINE_IRQ_CTRL_REG   = $AF001B ;[0] - Enable Line 0, [1] -Enable Line 1
VKY_LINE0_CMP_VALUE_LO  = $AF001C ;Write Only [7:0]
VKY_LINE0_CMP_VALUE_HI  = $AF001D ;Write Only [3:0]
VKY_LINE1_CMP_VALUE_LO  = $AF001E ;Write Only [7:0]
VKY_LINE1_CMP_VALUE_HI  = $AF001F ;Write Only [3:0]

; When you Read the Register
VKY_INFO_CHIP_NUM_L     = $AF001C
VKY_INFO_CHIP_NUM_H     = $AF001D
VKY_INFO_CHIP_VER_L     = $AF001E
VKY_INFO_CHIP_VER_H     = $AF001F

; Bit Field Definition for the Control Register
TILE_Enable             = $01
TILE_LUT0               = $02
TILE_LUT1               = $04
TILE_LUT2               = $08
TILESHEET_256x256_En    = $80   ; 0 -> Sequential, 1-> 256x256 Tile Sheet Striding

;Tile MAP Layer 0 Registers
TL0_CONTROL_REG         = $AF0100       ; Bit[0] - Enable, Bit[3:1] - LUT Select,
TL0_START_ADDY_L        = $AF0101       ; Not USed right now - Starting Address to where is the MAP
TL0_START_ADDY_M        = $AF0102
TL0_START_ADDY_H        = $AF0103
TL0_MAP_X_STRIDE_L      = $AF0104       ; The Stride of the Map
TL0_MAP_X_STRIDE_H      = $AF0105
TL0_MAP_Y_STRIDE_L      = $AF0106       ; The Stride of the Map
TL0_MAP_Y_STRIDE_H      = $AF0107
;TL0_RESERVED_0          = $AF0108
;TL0_RESERVED_1          = $AF0109
;TL0_RESERVED_2          = $AF010A
;TL0_RESERVED_3          = $AF010B
;TL0_RESERVED_4          = $AF010C
;TL0_RESERVED_5          = $AF010D
;TL0_RESERVED_6          = $AF010E
;TL0_RESERVED_7          = $AF010F
;Tile MAP Layer 1 Registers
TL1_CONTROL_REG         = $AF0108       ; Bit[0] - Enable, Bit[3:1] - LUT Select,
TL1_START_ADDY_L        = $AF0109       ; Not USed right now - Starting Address to where is the MAP
TL1_START_ADDY_M        = $AF010A
TL1_START_ADDY_H        = $AF010B
TL1_MAP_X_STRIDE_L      = $AF010C       ; The Stride of the Map
TL1_MAP_X_STRIDE_H      = $AF010D
TL1_MAP_Y_STRIDE_L      = $AF010E       ; The Stride of the Map
TL1_MAP_Y_STRIDE_H      = $AF010F
;TL1_RESERVED_0          = $AF0118
;TL1_RESERVED_1          = $AF0119
;TL1_RESERVED_2          = $AF011A
;TL1_RESERVED_3          = $AF011B
;TL1_RESERVED_4          = $AF011C
;TL1_RESERVED_5          = $AF011D
;TL1_RESERVED_6          = $AF011E
;TL1_RESERVED_7          = $AF011F
;Tile MAP Layer 2 Registers
TL2_CONTROL_REG         = $AF0110       ; Bit[0] - Enable, Bit[3:1] - LUT Select,
TL2_START_ADDY_L        = $AF0111       ; Not USed right now - Starting Address to where is the MAP
TL2_START_ADDY_M        = $AF0112
TL2_START_ADDY_H        = $AF0113
TL2_MAP_X_STRIDE_L      = $AF0114       ; The Stride of the Map
TL2_MAP_X_STRIDE_H      = $AF0115
TL2_MAP_Y_STRIDE_L      = $AF0116       ; The Stride of the Map
TL2_MAP_Y_STRIDE_H      = $AF0117
;TL2_RESERVED_0          = $AF0128
;TL2_RESERVED_1          = $AF0129
;TL2_RESERVED_2          = $AF012A
;TL2_RESERVED_3          = $AF012B
;TL2_RESERVED_4          = $AF012C
;TL2_RESERVED_5          = $AF012D
;TL2_RESERVED_6          = $AF012E
;TL2_RESERVED_7          = $AF012F
;Tile MAP Layer 3 Registers
TL3_CONTROL_REG         = $AF0118       ; Bit[0] - Enable, Bit[3:1] - LUT Select,
TL3_START_ADDY_L        = $AF0119       ; Not USed right now - Starting Address to where is the MAP
TL3_START_ADDY_M        = $AF011A
TL3_START_ADDY_H        = $AF011B
TL3_MAP_X_STRIDE_L      = $AF011C       ; The Stride of the Map
TL3_MAP_X_STRIDE_H      = $AF011D
TL3_MAP_Y_STRIDE_L      = $AF011E       ; The Stride of the Map
TL3_MAP_Y_STRIDE_H      = $AF011F
;TL3_RESERVED_0          = $AF0138
;TL3_RESERVED_1          = $AF0139
;TL3_RESERVED_2          = $AF013A
;TL3_RESERVED_3          = $AF013B
;TL3_RESERVED_4          = $AF013C
;TL3_RESERVED_5          = $AF013D
;TL3_RESERVED_6          = $AF013E
;TL3_RESERVED_7          = $AF013F
;Bitmap Registers
BM_CONTROL_REG          = $AF0140
BM_START_ADDY_L         = $AF0141
BM_START_ADDY_M         = $AF0142
BM_START_ADDY_H         = $AF0143
BM_X_SIZE_L             = $AF0144
BM_X_SIZE_H             = $AF0145
BM_Y_SIZE_L             = $AF0146
BM_Y_SIZE_H             = $AF0147
BM_RESERVED_0           = $AF0148
BM_RESERVED_1           = $AF0149
BM_RESERVED_2           = $AF014A
BM_RESERVED_3           = $AF014B
BM_RESERVED_4           = $AF014C
BM_RESERVED_5           = $AF014D
BM_RESERVED_6           = $AF014E
BM_RESERVED_7           = $AF014F

;Sprite Registers
; Bit Field Definition for the Control Register
SPRITE_Enable             = $01
SPRITE_LUT0               = $02 ; This is the LUT that the Sprite will use
SPRITE_LUT1               = $04
SPRITE_LUT2               = $08 ; Only 4 LUT for Now, So this bit is not used.
SPRITE_DEPTH0             = $10 ; This is the Layer the Sprite will be Displayed in
SPRITE_DEPTH1             = $20
SPRITE_DEPTH2             = $40

; Sprite 0 (Highest Priority)
SP00_CONTROL_REG        = $AF0200
SP00_ADDY_PTR_L         = $AF0201
SP00_ADDY_PTR_M         = $AF0202
SP00_ADDY_PTR_H         = $AF0203
SP00_X_POS_L            = $AF0204
SP00_X_POS_H            = $AF0205
SP00_Y_POS_L            = $AF0206
SP00_Y_POS_H            = $AF0207

; Sprite 1
SP01_CONTROL_REG        = $AF0208
SP01_ADDY_PTR_L         = $AF0209
SP01_ADDY_PTR_M         = $AF020A
SP01_ADDY_PTR_H         = $AF020B
SP01_X_POS_L            = $AF020C
SP01_X_POS_H            = $AF020D
SP01_Y_POS_L            = $AF020E
SP01_Y_POS_H            = $AF020F

; Sprite 2
SP02_CONTROL_REG        = $AF0210
SP02_ADDY_PTR_L         = $AF0211
SP02_ADDY_PTR_M         = $AF0212
SP02_ADDY_PTR_H         = $AF0213
SP02_X_POS_L            = $AF0214
SP02_X_POS_H            = $AF0215
SP02_Y_POS_L            = $AF0216
SP02_Y_POS_H            = $AF0217

; Sprite 3
SP03_CONTROL_REG        = $AF0218
SP03_ADDY_PTR_L         = $AF0219
SP03_ADDY_PTR_M         = $AF021A
SP03_ADDY_PTR_H         = $AF021B
SP03_X_POS_L            = $AF021C
SP03_X_POS_H            = $AF021D
SP03_Y_POS_L            = $AF021E
SP03_Y_POS_H            = $AF021F

; Sprite 4
SP04_CONTROL_REG        = $AF0220
SP04_ADDY_PTR_L         = $AF0221
SP04_ADDY_PTR_M         = $AF0222
SP04_ADDY_PTR_H         = $AF0223
SP04_X_POS_L            = $AF0224
SP04_X_POS_H            = $AF0225
SP04_Y_POS_L            = $AF0226
SP04_Y_POS_H            = $AF0227

; Sprite 5
SP05_CONTROL_REG        = $AF0228
SP05_ADDY_PTR_L         = $AF0229
SP05_ADDY_PTR_M         = $AF022A
SP05_ADDY_PTR_H         = $AF022B
SP05_X_POS_L            = $AF022C
SP05_X_POS_H            = $AF022D
SP05_Y_POS_L            = $AF022E
SP05_Y_POS_H            = $AF022F

; Sprite 6
SP06_CONTROL_REG        = $AF0230
SP06_ADDY_PTR_L         = $AF0231
SP06_ADDY_PTR_M         = $AF0232
SP06_ADDY_PTR_H         = $AF0233
SP06_X_POS_L            = $AF0234
SP06_X_POS_H            = $AF0235
SP06_Y_POS_L            = $AF0236
SP06_Y_POS_H            = $AF0237

; Sprite 7
SP07_CONTROL_REG        = $AF0238
SP07_ADDY_PTR_L         = $AF0239
SP07_ADDY_PTR_M         = $AF023A
SP07_ADDY_PTR_H         = $AF023B
SP07_X_POS_L            = $AF023C
SP07_X_POS_H            = $AF023D
SP07_Y_POS_L            = $AF023E
SP07_Y_POS_H            = $AF023F

; Sprite 8
SP08_CONTROL_REG        = $AF0240
SP08_ADDY_PTR_L         = $AF0241
SP08_ADDY_PTR_M         = $AF0242
SP08_ADDY_PTR_H         = $AF0243
SP08_X_POS_L            = $AF0244
SP08_X_POS_H            = $AF0245
SP08_Y_POS_L            = $AF0246
SP08_Y_POS_H            = $AF0247

; Sprite 9
SP09_CONTROL_REG        = $AF0248
SP09_ADDY_PTR_L         = $AF0249
SP09_ADDY_PTR_M         = $AF024A
SP09_ADDY_PTR_H         = $AF024B
SP09_X_POS_L            = $AF024C
SP09_X_POS_H            = $AF024D
SP09_Y_POS_L            = $AF024E
SP09_Y_POS_H            = $AF024F

; Sprite 10
SP10_CONTROL_REG        = $AF0250
SP10_ADDY_PTR_L         = $AF0251
SP10_ADDY_PTR_M         = $AF0252
SP10_ADDY_PTR_H         = $AF0253
SP10_X_POS_L            = $AF0254
SP10_X_POS_H            = $AF0255
SP10_Y_POS_L            = $AF0256
SP10_Y_POS_H            = $AF0257

; Sprite 11
SP11_CONTROL_REG        = $AF0258
SP11_ADDY_PTR_L         = $AF0259
SP11_ADDY_PTR_M         = $AF025A
SP11_ADDY_PTR_H         = $AF025B
SP11_X_POS_L            = $AF025C
SP11_X_POS_H            = $AF025D
SP11_Y_POS_L            = $AF025E
SP11_Y_POS_H            = $AF025F

; Sprite 12
SP12_CONTROL_REG        = $AF0260
SP12_ADDY_PTR_L         = $AF0261
SP12_ADDY_PTR_M         = $AF0262
SP12_ADDY_PTR_H         = $AF0263
SP12_X_POS_L            = $AF0264
SP12_X_POS_H            = $AF0265
SP12_Y_POS_L            = $AF0266
SP12_Y_POS_H            = $AF0267

; Sprite 13
SP13_CONTROL_REG        = $AF0268
SP13_ADDY_PTR_L         = $AF0269
SP13_ADDY_PTR_M         = $AF026A
SP13_ADDY_PTR_H         = $AF026B
SP13_X_POS_L            = $AF026C
SP13_X_POS_H            = $AF026D
SP13_Y_POS_L            = $AF026E
SP13_Y_POS_H            = $AF026F

; Sprite 14
SP14_CONTROL_REG        = $AF0270
SP14_ADDY_PTR_L         = $AF0271
SP14_ADDY_PTR_M         = $AF0272
SP14_ADDY_PTR_H         = $AF0273
SP14_X_POS_L            = $AF0274
SP14_X_POS_H            = $AF0275
SP14_Y_POS_L            = $AF0276
SP14_Y_POS_H            = $AF0277

; Sprite 15
SP15_CONTROL_REG        = $AF0278
SP15_ADDY_PTR_L         = $AF0279
SP15_ADDY_PTR_M         = $AF027A
SP15_ADDY_PTR_H         = $AF027B
SP15_X_POS_L            = $AF027C
SP15_X_POS_H            = $AF027D
SP15_Y_POS_L            = $AF027E
SP15_Y_POS_H            = $AF027F

; Sprite 16
SP16_CONTROL_REG        = $AF0280
SP16_ADDY_PTR_L         = $AF0281
SP16_ADDY_PTR_M         = $AF0282
SP16_ADDY_PTR_H         = $AF0283
SP16_X_POS_L            = $AF0284
SP16_X_POS_H            = $AF0285
SP16_Y_POS_L            = $AF0286
SP16_Y_POS_H            = $AF0287

; Sprite 17
SP17_CONTROL_REG        = $AF0288
SP17_ADDY_PTR_L         = $AF0289
SP17_ADDY_PTR_M         = $AF028A
SP17_ADDY_PTR_H         = $AF028B
SP17_X_POS_L            = $AF028C
SP17_X_POS_H            = $AF028D
SP17_Y_POS_L            = $AF028E
SP17_Y_POS_H            = $AF028F

; DMA Controller $AF0400 - $AF04FF
VDMA_CONTROL_REG        = $AF0400

; Bit Field Definition
VDMA_CTRL_Enable        = $01
VDMA_CTRL_1D_2D         = $02     ; 0 - 1D (Linear) Transfer , 1 - 2D (Block) Transfer
VDMA_CTRL_TRF_Fill      = $04     ; 0 - Transfer Src -> Dst, 1 - Fill Destination with "Byte2Write"
VDMA_CTRL_Int_Enable    = $08     ; Set to 1 to Enable the Generation of Interrupt when the Transfer is over.
VDMA_CTRL_Start_TRF     = $80     ; Set to 1 To Begin Process, Need to Cleared before, you can start another

VDMA_BYTE_2_WRITE       = $AF0401 ; Write Only - Byte to Write in the Fill Function
VDMA_STATUS_REG         = $AF0401 ; Read only

;Status Bit Field Definition
VDMA_STAT_Size_Err      = $01     ; If Set to 1, Overall Size is Invalid
VDMA_STAT_Dst_Add_Err   = $02     ; If Set to 1, Destination Address Invalid
VDMA_STAT_Src_Add_Err   = $04     ; If Set to 1, Source Address Invalid
VDMA_STAT_VDMA_IPS      = $80     ; If Set to 1, VDMA Transfer in Progress (this Inhibit CPU Access to Mem)
                                  ; Let me repeat, don't Access the Video Memory then there is a VDMA in progress
VDMA_SRC_ADDY_L         = $AF0402 ; Pointer to the Source of the Data to be stransfered
VDMA_SRC_ADDY_M         = $AF0403 ; This needs to be within Vicky's Range ($00_0000 - $3F_0000)
VDMA_SRC_ADDY_H         = $AF0404

VDMA_DST_ADDY_L         = $AF0405 ; Destination Pointer within Vicky's video memory Range
VDMA_DST_ADDY_M         = $AF0406 ; ($00_0000 - $3F_0000)
VDMA_DST_ADDY_H         = $AF0407

; In 1D Transfer Mode
VDMA_SIZE_L             = $AF0408 ; Maximum Value: $40:0000 (4Megs)
VDMA_SIZE_M             = $AF0409
VDMA_SIZE_H             = $AF040A
VDMA_IGNORED            = $AF040B

; In 2D Transfer Mode
VDMA_X_SIZE_L           = $AF0408 ; Maximum Value: 65535
VDMA_X_SIZE_H           = $AF0409
VDMA_Y_SIZE_L           = $AF040A ; Maximum Value: 65535
VDMA_Y_SIZE_H           = $AF040B

VDMA_SRC_STRIDE_L       = $AF040C ; Always use an Even Number ( The Engine uses Even Ver of that value)
VDMA_SRC_STRIDE_H       = $AF040D ;
VDMA_DST_STRIDE_L       = $AF040E ; Always use an Even Number ( The Engine uses Even Ver of that value)
VDMA_DST_STRIDE_H       = $AF040F ;

; Mouse Pointer Graphic Memory
MOUSE_PTR_GRAP0_START   = $AF0500 ; 16 x 16 = 256 Pixels (Grey Scale) 0 = Transparent, 1 = Black , 255 = White
MOUSE_PTR_GRAP0_END     = $AF05FF ; Pointer 0
MOUSE_PTR_GRAP1_START   = $AF0600 ;
MOUSE_PTR_GRAP1_END     = $AF06FF ; Pointer 1

MOUSE_PTR_CTRL_REG_L    = $AF0700 ; Bit[0] Enable, Bit[1] = 0  ( 0 = Pointer0, 1 = Pointer1)
MOUSE_PTR_CTRL_REG_H    = $AF0701 ;
MOUSE_PTR_X_POS_L       = $AF0702 ; X Position (0 - 639) (Can only read now) Writing will have no effect
MOUSE_PTR_X_POS_H       = $AF0703 ;
MOUSE_PTR_Y_POS_L       = $AF0704 ; Y Position (0 - 479) (Can only read now) Writing will have no effect
MOUSE_PTR_Y_POS_H       = $AF0705 ;
MOUSE_PTR_BYTE0         = $AF0706 ; Byte 0 of Mouse Packet (you must write 3 Bytes)
MOUSE_PTR_BYTE1         = $AF0707 ; Byte 1 of Mouse Packet (if you don't, then )
MOUSE_PTR_BYTE2         = $AF0708 ; Byte 2 of Mouse Packet (state Machine will be jammed in 1 state)
                                  ; (And the mouse won't work)
C256F_MODEL_MAJOR       = $AF070B ;
C256F_MODEL_MINOR       = $AF070C ;
FPGA_DOR                = $AF070D ;
FPGA_MOR                = $AF070E ;
FPGA_YOR                = $AF070F ;

;                       = $AF0800 ; the RTC is Here
;                       = $AF1000 ; The SuperIO Start is Here
;                       = $AF13FF ; The SuperIO Start is Here

FG_CHAR_LUT_PTR         = $AF1F40
BG_CHAR_LUT_PTR		    = $AF1F80

GRPH_LUT0_PTR		        = $AF2000
GRPH_LUT1_PTR		        = $AF2400
GRPH_LUT2_PTR		        = $AF2800
GRPH_LUT3_PTR		        = $AF2C00
GRPH_LUT4_PTR		        = $AF3000
GRPH_LUT5_PTR		        = $AF3400
GRPH_LUT6_PTR		        = $AF3800
GRPH_LUT7_PTR		        = $AF3C00

GAMMA_B_LUT_PTR		      = $AF4000
GAMMA_G_LUT_PTR		      = $AF4100
GAMMA_R_LUT_PTR		      = $AF4200

TILE_MAP0       		    = $AF5000     ;$AF5000 - $AF57FF
TILE_MAP1               = $AF5800     ;$AF5800 - $AF5FFF
TILE_MAP2               = $AF6000     ;$AF6000 - $AF67FF
TILE_MAP3               = $AF6800     ;$AF6800 - $AF6FFF

FONT_MEMORY_BANK0       = $AF8000     ;$AF8000 - $AF87FF
FONT_MEMORY_BANK1       = $AF8800     ;$AF8800 - $AF8FFF
CS_TEXT_MEM_PTR         = $AFA000
CS_COLOR_MEM_PTR        = $AFC000


BTX_START               = $AFE000     ; BEATRIX Registers
BTX_END                 = $AFFFFF
