;;;
;;; Code to bootstrap the interpreter on the C256 Foenix
;;;

; Override RESET vector to point to the start of BASIC

.section bootblock
COLDSTART   JML START

;
; Handler for BRK
;
HBREAK      CLC
            XCE

            setaxl              ; Save the core registers
            STA @lCPUA
            TXA
            STA @lCPUX
            TYA
            STA @lCPUY

            TDC
            STA @lCPUDP         ; Save DP

            setas
            PHB
            PLA
            STA @lCPUDBR        ; Save DBR

            PLA
            STA @lCPUFLAGS      ; Save the flags at the time of the BRK

            PLA                 ; Save the return address (assumes native mode)
            STA @lCPUPC
            PLA
            STA @lCPUPC+1
            PLA
            STA @lCPUPBR

            setal               ; Save the old stack
            TSC
            STA @lCPUSTACK

            CLI                 ; Enable interrupts
            JML MONITOR
.send

.section vectors
RESTART     .word <>COLDSTART
.send