
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
;;      +-------------+
;; 01fd | param       |
;;      +-------------+
;; 01fb | param       |
;;      +-------------+
;; 01f9 | return addr |
;;      +-------------+<-+
;; 01f7 | local       |  |
;;      +-------------+  |
;; 01f5 | local       |  |
;;      +-------------+  |
;; 01f3 | SP (01f6)   |--+
;;      +-------------+
;; 01f1 | DP          | <-- DP (01f1)
;;      +-------------+
;; 01f0 |             | <-- SP (01f0)

ENTER       .macro locals           ; 36 cycles
            PHP                     ; 4
            setaxl                  ; 2
            PHX                     ; 4 - Save X
            TSX                     ; 2 - SP to X

.if \locals > 0
            SEC                     ; 2 - Add space for the locals
            TSC                     ; 2
            SBC #\locals            ; 3
            TCS                     ; 2
.endif

            PHX                     ; 4 - Save the old SP
            PHD                     ; 4 - Save the old DP

            TSC                     ; 2 - Calculate the new DP
            INC A                   ; 3
            TCD                     ; 2
            .endm

LEAVE       .macro                  ; 18 cycles
            setaxl                  ; 2
            LDA #2,D                ; 4
            TCS                     ; 2 - Restore the SP
            LDA #0,D                ; 4
            TCD                     ; 2 - Restore the DP
            PLX                     ; 4 - Recover the old X
            PLP
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
            .null \1,CHAR_CR
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

;
; Print trace message to the console if TRACE_LEVEL > 1
; Print the value of the 3 bytes in memory at the specified address
;
TRACE_L     .macro  ; name, address
.if TRACE_LEVEL > 0
        .if TRACE_LEVEL > 1
            JSR PRTRACE         ; Print the name of the trace point         
        .endif
            BRA continue
TESTNAME    .null \1,": "
continue
        .if TRACE_LEVEL > 1
            PHP
            setas
            LDA \2+2
            CALL PRHEXB
            LDA \2+1
            CALL PRHEXB
            LDA \2
            CALL PRHEXB
            PLP
            CALL PRINTCR
        .endif
.endif
            .endm

;
; Print trace message to the console if TRACE_LEVEL > 1
; Print the value of the 3 bytes in memory at the bank 0 address index by X
;
TRACE_X     .macro  ; name
.if TRACE_LEVEL > 0
        .if TRACE_LEVEL > 1
            JSR PRTRACE         ; Print the name of the trace point      
        .endif
            BRA continue
TESTNAME    .null \1,": "
continue
        .if TRACE_LEVEL > 1
            PHP
            setas
            LDA #2,B,X
            CALL PRHEXB
            LDA #1,B,X
            CALL PRHEXB
            LDA #0,B,X
            CALL PRHEXB
            PLP
            CALL PRINTCR
        .endif
.endif
            .endm

LDARG_EA    .macro dest,ea,type
            PHP
            setal
            LDA #<>\2
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

; Move a word (16 bit) value from address src to address dest
MOVE_W      .macro dest,src
            setal
            LDA \src
            STA \dest
            .endm

; Move a word to two different destination addresses
MOV2_W      .macro dest1, dest2, src
            setal
            LDA \src
            STA \dest1
            STA \dest2
            .endm

; Move a long (24 bit) value from address src to address dest
MOVE_L      .macro dest,src
            setal
            LDA \src
            STA \dest
            setas
            LDA \src+2
            STA \dest+2
            .endm

; Move a quadword (32 bit) value from address src to address dest
MOVE_Q      .macro dest,src
            setal
            LDA \2
            STA \1
            LDA \2+2
            STA \1+2
            .endm

LD_B        .macro dest,value
            setas
            LDA #<\2
            STA \1
            .endm

LD_W        .macro dest,value
            setal
            LDA #<>\2
            STA \1
            .endm

LD_L        .macro dest,value
            setal
            LDA #<>\2
            STA \1
            setas
            LDA #`\2
            STA \1+2
            .endm

LD_Q        .macro dest,value
            setal
            LDA #<>\2
            STA \1
            LDA #`\2
            STA \1+2
            .endm

; Load indirect long: dest := [[src] + offset]
LD_ind_L    .macro dest,src,offset
            setal
            LDY #\offset
            LDA [\src],Y
            STA \dest
            setas
            INY
            INY
            LDA [\src],Y
            STA \dest+2
            .endm

; Add two long variables
ADD_L       .macro ; dest,src1,src2
            setal
            CLC
            LDA \2
            ADC \3
            STA \1
            setas
            LDA \2+2
            ADC \3+2
            STA \1+2
            .endm

; Branch to dest if src1 < src2 (24-bit comparison)
BLT_L       .macro dest,src1,src2
            setas
            LDA \src1+2
            CMP \src2+2
            BLT do_branch

            setal
            LDA \src2
            CMP \src1
            BGE continue

do_branch   JMP \dest
continue
            .endm