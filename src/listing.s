;;;
;;; Routines for listing BASIC programs
;;;

;
; Print an entire line of BASIC
;
; Inputs:
;   BIP = pointer to the first byte to print
;
LISTLINE    .proc

loop        CALL LISTBYTE
            BCC loop

            RETURN
            .pend

;
; Print the current byte of the BASIC program and increment the BASIC instruction pointer
;
; Inputs:
;   BIP = pointer to the byte to print
;
; Outputs:
;   C is set if the current byte is 0, reset otherwise
LISTBYTE    .proc
            PHP
            PHD
            PHB

            setdp <>GLOBAL_VARS
            setdbr `GLOBAL_VARS

            setas
            setxl
            LDA [BIP]           ; Get the current byte
            BEQ end_of_line     ; If it's 0, return with C set
            BMI is_token        ; If it's 0x80 - 0xFF, it's a token

            CALL PUTC           ; Is not a token, just print the byte
            BRA done            ; And return

is_token    setal
            AND #$007F          ; Compute the index of the token
            ASL A               ; In the token table
            ASL A
            ASL A

            CLC
            ADC #<>TOKENS       ; Set INDEX to the address of the token
            STA INDEX
            LDA #`TOKENS
            ADC #0
            STA INDEX+2

            LDY #TOKEN.print    ; The PRINT address
            LDA [INDEX],Y       ; Get the address of the PRINT function
            BEQ pr_default      ; If it's 0: print the name

            STA INDEX           ; Set INDEX to the address of the PRINT function
            LDA #`LISTBYTE
            STA INDEX+2
            CALL call_pr        ; And call the print function
            BRA done

call_pr     JMP [INDEX]

pr_default  setdbr `TOKENS
            LDY #TOKEN.name
            LDA [INDEX],Y

            TAX
            CALL PRINTS

done        setal
            CALL INCBIP
            PLB
            PLD
            PLP
            CLC
            RETURN

end_of_line PLB
            PLD
            PLP
            SEC
            RETURN
            .pend

