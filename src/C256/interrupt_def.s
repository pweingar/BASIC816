; Pending Interrupt (Read and Write Back to Clear)
INT_PENDING_REG0 = $000140 ;
INT_PENDING_REG1 = $000141 ;
INT_PENDING_REG2 = $000142 ;
; Polarity Set
INT_POL_REG0     = $000144 ;
INT_POL_REG1     = $000145 ;
INT_POL_REG2     = $000146 ;
; Edge Detection Enable
INT_EDGE_REG0    = $000148 ;
INT_EDGE_REG1    = $000149 ;
INT_EDGE_REG2    = $00014A ;
; Mask
INT_MASK_REG0    = $00014C ;
INT_MASK_REG1    = $00014D ;
INT_MASK_REG2    = $00014E ;

; Interrupt Bit Definition
; Register Block 0
FNX0_INT00_SOF    = $01  ;Start of Frame @ 60FPS
FNX0_INT01_SOL    = $02  ;Start of Line (Programmable)
FNX0_INT02_TMR0   = $04  ;Timer 0 Interrupt
FNX0_INT03_TMR1   = $08  ;Timer 1 Interrupt
FNX0_INT04_TMR2   = $10  ;Timer 2 Interrupt
FNX0_INT05_RTC    = $20  ;Real-Time Clock Interrupt
FNX0_INT06_FDC    = $40  ;Floppy Disk Controller
FNX0_INT07_MOUSE  = $80  ; Mouse Interrupt (INT12 in SuperIO IOspace)
; Register Block 1
FNX1_INT00_KBD    = $01  ;Keyboard Interrupt
FNX1_INT01_SC0    = $02  ;Sprite 2 Sprite Collision
FNX1_INT02_SC1    = $04  ;Sprite 2 Tiles Collision
FNX1_INT03_COM2   = $08  ;Serial Port 2
FNX1_INT04_COM1   = $10  ;Serial Port 1
FNX1_INT05_MPU401 = $20  ;Midi Controller Interrupt
FNX1_INT06_LPT    = $40  ;Parallel Port
FNX1_INT07_SDCARD = $80  ;SD Card Controller Interrupt
; Register Block 2
FNX2_INT00_OPL2R  = $01  ;OPl2 Right Channel
FNX2_INT01_OPL2L  = $02  ;OPL2 Left Channel
FNX2_INT02_BTX_INT= $04  ;Beatrix Interrupt (TBD)
FNX2_INT03_SDMA   = $08  ;System DMA
FNX2_INT04_VDMA   = $10  ;Video DMA
FNX2_INT05_DACHP  = $20  ;DAC Hot Plug
FNX2_INT06_EXT    = $40  ;External Expansion
FNX2_INT07_ALLONE = $80  ; Not Used - Always 1
