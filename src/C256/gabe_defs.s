;GABE Control Registers

;$AFE880..$AFE887

GABE_MSTR_CTRL      = $AFE880
GABE_CTRL_PWR_LED   = $01     ; Controls the LED in the Front of the case (Next to the reset button)
GABE_CTRL_SDC_LED   = $02     ; Controls the LED in the Front of the Case (Next to SDCard)
GABE_CTRL_STS_LED0  = $04     ; Control Status LED0 (General Use) - C256 Foenix U Only
GABE_CTRL_STS_LED1  = $08     ; Control Status LED0 (General Use) - C256 Foenix U Only
GABE_CTRL_BUZZER    = $10     ; Controls the Buzzer
GABE_CTRL_WRM_RST   = $80     ; Warm Reset (needs to Setup other registers)

GABE_LED_FLASH_CTRL = $AFE881  ; Flashing LED Control
GABE_LED0_FLASH_CTRL = $01     ; 0- Automatic Flash 1 - Bypass Flash Timer (Use GABE_CTRL_STS_LED0 to manually control)
GABE_LED1_FLASH_CTRL = $02     ; 0- Automatic Flash 1 - Bypass Flash Timer (Use GABE_CTRL_STS_LED1 to manually control)

GABE_LD0_FLASH_FRQ0   = $10     ; 1 - Bypass Flash Timer (Use GABE_CTRL_STS_LED0 to manually control)
GABE_LD0_FLASH_FRQ1   = $20     ; 1 - Bypass Flash Timer (Use GABE_CTRL_STS_LED0 to manually control)
; 00 - 1Hz
; 01 - 2hz
; 10 - 4hz
; 11 - 5hz
GABE_LD1_FLASH_FRQ0   = $40     ; 1 - Bypass Flash Timer (Use GABE_CTRL_STS_LED0 to manually control)
GABE_LD1_FLASH_FRQ1   = $80     ; 1 - Bypass Flash Timer (Use GABE_CTRL_STS_LED0 to manually control)



GABE_RST_AUTH0      = $AFE882 ; Must Contain the BYTE $AD for Reset to Activate
GABE_RST_AUTH1      = $AFE883 ; Must Contain the BYTE $DE for Reset to Activate

; READ
GABE_RNG_DAT_LO     = $AFE884 ; Low Part of 16Bit RNG Generator
GABE_RNG_DAT_HI     = $AFE885 ; Hi Part of 16Bit RNG Generator

; WRITE
GABE_RNG_SEED_LO    = $AFE884 ; Low Part of 16Bit RNG Generator
GABE_RNG_SEED_HI    = $AFE885 ; Hi Part of 16Bit RNG Generator

; READ
GABE_RNG_STAT       = $AFE886 ;
GABE_RNG_LFSR_DONE  = $80     ; indicates that Output = SEED Database

; WRITE
GABE_RNG_CTRL       = $AFE886 ;
GABE_RNG_CTRL_EN    = $01     ; Enable the LFSR BLOCK_LEN
GABE_RNG_CTRL_DV    = $02     ; After Setting the Seed Value, Toggle that Bit for it be registered

GABE_SYS_STAT       = $AFE887 ;
GABE_SYS_STAT_MID0  = $01     ; Machine ID -- LSB
GABE_SYS_STAT_MID1  = $02     ; Machine ID -- 
GABE_SYS_STAT_MID2  = $04     ; Machine ID -- MSB
;Bit 2, Bit 1, Bit 0
;$000: FMX
;$100: FMX (Future C5A)
;$001: U 2Meg
;$101: U+ 4Meg U+
;$010: TBD (Reserved)
;$110: TBD (Reserved)
;$011: A2560 Dev
;$111: A2560 Keyboard
GABE_SYS_STAT_EXP   = $10     ; if Zero, there is an Expansion Card Preset

GABE_SYS_STAT_CPUA  = $40     ; Indicates the (8bit/16bit) Size of the Accumulator - Not Implemented
GABE_SYS_STAT_CPUX  = $80     ; Indicates the (8bit/16bit) Size of the Accumulator - Not Implemented

GABE_SUBVERSION_LO  = $AFE88A
GABE_SUBVERSION_HI  = $AFE88B
GABE_VERSION_LO     = $AFE88C
GABE_VERSION_HI     = $AFE88D
GABE_MODEL_LO       = $AFE88E
GABE_MODEL_HI       = $AFE88F
; OLD Machine ID Definition - Deprecated
; $00 = FMX - Development Platform
; $01 = C256 Foenix - Dev Platform
; $10 = C256 Foenix - User Version (65C816)
; $11 = TBD
