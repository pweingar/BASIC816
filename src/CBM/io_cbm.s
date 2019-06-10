;;;
;;; Core I/O Routines for CBM
;;;

SETLFS = $FFBA
OPEN = $FFC0
CHROUT = $FFD2
CHKOUT = $FFC9
CLALL = $FFE7

.section globals
CTOPUT      .byte ?
.send

INITIO      .proc
            PHP
            setaxs

            LDA #4      ; Channel #
            LDX #4      ; Primary address: printer
            LDY #$FF    ; No secondary address
            JSR SETLFS
            JSR OPEN

            LDA #4          ; Send to printer
            JSR CHKOUT

            PLP
            RETURN
            .pend

CLOSEIO     .proc
            PHP
            setaxs

            JSR CLALL

            PLP
            RETURN
            .pend

PUTC        .proc
            PHP
            PHD
            setxl
            PHX
            PHY

            setdp 0
            
            setaxs
            JSR CHROUT

            setxl
            PLY
            PLX
            PLD
            PLP
            RETURN
            .pend

; Print a new line
PRINTCR     .proc
            PHP
            setal
            PHA

            setas
            LDA #CHAR_CR
            CALL PRINTC

            setal
            PLA
            PLP
            RETURN
            .pend