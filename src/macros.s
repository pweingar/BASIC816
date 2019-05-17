
;
; Stack parameters and locals utilities
; 

setaxs      .macro
            SEP #$30
            .as
            .xs
            .endm

setas       .macro
            SEP #$20
            .as
            .endm

setxs       .macro
            SEP #$10
            .xs
            .endm

setaxl      .macro
            REP #$30
            .al
            .xl
            .endm

setal       .macro
            REP #$20
            .al
            .endm

setxl       .macro
            REP #$10
            .xl
            .endm

setdp       .macro
            PHP
            setal
            PHA
            LDA #\1
            TCD
            PLA
            PLP
            .dpage \1
            .endm

setdbr      .macro
            PHP
            setas
            PHA
            LDA #\1
            PHA
            PLB
            PLA
            PLP
            .databank \1
            .endm

LDDBR       .macro ; address
            PHP
            setal
            PHA
            setas
            LDA \1
            PHA
            PLB
            setal
            PLA
            PLP
            .endm

CALL        .macro
            JSR \1
            .endm

RETURN      .macro
            RTS
            .endm

;;
;; Calling convention #2
;;
;; This style saves the stack pointer prior to pushing arguments and
;; prior to setting up the stack frame onto the stack. This is more
;; expensive to run BUT allows the stack to be unwound knowing only
;; the correct value of the frame pointer
;;
;; 53 clocks of overhead per call, 25 bytes of code (plus 4 bytes per call on the stack)
;;

;;
;;      +-------------+<-+
;; 01fe | param       |  |
;;      +-------------+  |
;; 01fc | param       |  |
;;      +-------------+  |
;; 01fa | SP (01ff)   |--+
;;      +-------------+
;; 01f7 | return addr |
;;      +-------------+<-+
;; 01f5 | local       |  |
;;      +-------------+  |
;; 01f3 | SP (01f6)   |--+
;;      +-------------+
;; 01f1 | DP          | <-- DP (01f1)
;;      +-------------+
;; 01f0 |             | <-- SP (01f0)

LINK        .macro ; size   (28 clocks, 15 bytes)
            PHP
            setal           ; 3
            TSX             ; 2
            TSC             ; 2
            SEC             ; 2
            SBC #\1         ; 3
            TCS             ; 2 - Move stack down to make room for locals
            PHX             ; 4 - Save old SP
            PHD             ; 4 - Save old DP
            DEC A           ; 2 - Compute new DP
            DEC A           ; 2
            DEC A           ; 2
            TCD             ; 2
            .endm

UNLINK      .macro          ; 18 clocks, 8 bytes
            setal           ; 3
            LDA #2,D        ; 4 - Restore old SP
            TCS             ; 2
            LDA #0,D        ; 4 - Restore old DP
            TCD             ; 2
            PLP
            .endm

CLEAN       .macro          ; 7 clocks, 2 bytes
            PLA             ; 5
            TCS             ; 2
            .endm

;
; Print trace message to the console if TRACE_LEVEL > 1
;
TRACE       .macro  ; name
.if TRACE_LEVEL > 0
    .if TRACE_LEVEL > 1
            JSR PRTRACE         ; Print the name of the trace point
    .endif
            BRA continue
            .null \1,CHAR_CR,CHAR_LF
continue
.endif
            .endm

;
; Print trace message to the console if TRACE_LEVEL > 1
; Print the value of the accumulator with it in hex
;
TRACE_A     .macro  ; name
.if TRACE_LEVEL > 0
        .if TRACE_LEVEL > 1
            JSR PRTRACE         ; Print the name of the trace point            
        .endif
            BRA continue
TESTNAME    .null \1,": "
continue
        .if TRACE_LEVEL > 1
            CALL PRHEXB
            CALL PRINTCR
        .endif
.endif
            .endm

LDARG_EA    .macro dest,ea,type
            PHP
            setal
            LDA #\2
            STA \1
            LDA #`\2
            STA \1+2
            setas
            LDA #\3
            STA \1+4
            PLP
            .endm

; Increment the long (24-bit) value at addr
INC_L       .macro addr
            setal
            CLC
            LDA \1
            ADC #1
            STA \1
            setas
            LDA \1+2
            ADC #0
            STA \1+2
            .endm

; Decrement the long (24-bit) value at addr
DEC_L       .macro addr
            setal
            SEC
            LDA \1
            SBC #1
            STA \1
            setas
            LDA \1+2
            SBC #0
            STA \1+2
            .endm

; Move a long (24 bit) value from address src to address dest
MOVE_L      .macro dest,src
            setal
            LDA \2
            STA \1
            setas
            LDA \2+2
            STA \1+2
            .endm

LD_L        .macro dest,value
            setal
            LDA #<>\2
            STA \1
            setas
            LDA #`\2
            STA \1+2
            .endm