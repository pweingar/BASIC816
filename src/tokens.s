;;;
;;; Define BASIC tokens
;;;

;
; Token structure and macro
;

TOKEN       .struct name, length, precedence, eval, print
precedence  .byte \precedence
length      .byte \length
name        .word <>\name
eval        .word <>\eval
print       .word <>\eval
            .ends

DEFTOK      .macro  ; NAME, TYPE, PRECEDENCE, EVALUATE, PRINT
            .section data
TOKEN_TEXT  .null \1
            .send data
            .dstruct TOKEN,TOKEN_TEXT,len(\1),\2 | \3,\4,\5
            .endm

;
; Token routines
;

;
; Parse an integer
;
; Inputs:
;   BIP = pointer to the first digit of the number
;
; Outputs:
;   ARGUMENT1 = the value of the number read.
;
PARSEINT    .proc
            TRACE "PARSEINT"
            PHP
            PHD

            setdp GLOBAL_VARS

            setaxl
            STZ ARGUMENT1       ; Default to Not-a-value
            STZ ARGUMENT1+2
            setas
            STZ ARGTYPE1

loop        setas
            LDA [BIP]           ; Get the next character
            CALL ISNUMERAL      ; Is it a numeral?
            BCC done            ; No, we're done parsing
                
            CALL MULINT10       ; Yes: multiply ARGUMENT1 by 10

            SEC                 ; Convert the ASCII code to a number
            SBC #'0'

            setal               ; Add it to ARGUMENT1
            AND #$00FF
            CLC
            ADC ARGUMENT1
            STA ARGUMENT1
            LDA ARGUMENT1+2
            ADC #0
            STA ARGUMENT1+2

            CALL INCBIP         ; And move to the next byte
            BRA loop            ; And try to process it

done        PLD
            PLP
            RETURN
            .pend

;
; Convert all the keywords to tokens in a line of BASIC text
;
; Inputs:
;   CURLINE = the pointer to the beginning of the line of BASIC
;
TOKENIZE    .proc
            PHP
            PHD

            TRACE "TOKENIZE"

            setdp GLOBAL_VARS

            setaxl                  ; BIP := CURLINE
            LDA CURLINE
            STA BIP
            setas
            LDA CURLINE+2
            STA BIP+2

            CALL SKIPWS             ; Skip over whitespace

            LDA [BIP]               ; Do we have a numeral?
            CALL ISNUMERAL
            BCC mv_curline          ; No: adjust CURLINE and tokenize

            CALL PARSEINT           ; Try to parse the number
            setal                   ; LINENUM := result
            LDA ARGUMENT1
            STA LINENUM

            CALL SKIPWS

mv_curline  setal                   ; CURLINE := BIP (current position)
            LDA BIP
            STA CURLINE
            setas
            LDA BIP+2
            STA CURLINE+2

            setas
loop        CALL TKFINDTOKEN        ; Find the next token in the line
            CMP #0                  ; Did we find a token?
            BEQ done                ; No: return

            CALL TKWRITE            ; Yes: write the token to the line
            BRA loop                ; And try again

done        PLD
            PLP
            RETURN
            .pend

;
; Find a spot in the current BASIC input line that can be replaced with a token.
;
; Inputs:
;   CURLINE = pointer to the beginning of a line of BASIC text (NUL terminated)
;
; Outputs:
;   A = the token to write to the string (0 if none found)
;   BIP = the position requiring the token
;   CURTOKLEN = the length of the token keyword found
;   
TKFINDTOKEN .proc
            PHP
            PHD
            TRACE "TKFINDTOKEN"

            setdp GLOBAL_VARS

            setas
            LDA #$7F                ; Start off looking for any size token
            STA CURTOKLEN

next_size   setxl
            CALL TKNEXTBIG          ; Find the size of the token to find
            LDA CURTOKLEN           ; Are there any keywords left?
            BEQ done                ; No: return to caller

            setal                   ; Set BIP to the beginning of the line
            LDA CURLINE
            STA BIP
            setas
            LDA CURLINE+2
            STA BIP+2

            ; Check to see if there's room for the token keyword left in the string
check_len   setaxs
            LDY #0
nul_scan    LDA [BIP],Y
            BEQ next_size
            INY
            CPY CURTOKLEN
            BCC nul_scan
            setxl

            LDA [BIP]               ; Check the current character
            CMP #CHAR_DQUOTE        ; Is it a double quote?
            BNE try_match           ; No: go ahead and try to do the match

            CALL SKIPQUOTED         ; Yes: skip to after the next double quote
            BRA check_len           ; And check we have room for the token

            ; There is room for the token left in the string
try_match   CALL TKMATCH            ; Try to find the matching token
            CMP #0                  ; Did we get one?
            BNE done                ; Yes: return it

            CALL INCBIP             ; Move to the next character in the line
            BRA check_len           ; And try there

done        PLD
            PLP
            RETURN
            .pend

;
; Skip to the character after the first double quote
;
; Inputs:
;   BIP = pointer to the BASIC line where we need to skip over the next quote
;
SKIPQUOTED  .proc
            PHP
            setas

loop        CALL INCBIP             ; Advance the BIP
            LDA [BIP]
            BEQ done                ; If EOL, just return
            CMP #CHAR_DQUOTE        ; Is it a double quote?
            BNE loop                ; No: keep skipping

            CALL INCBIP             ; Skip one more byte
            LDA [BIP]
            BEQ done                ; And return if it's NUL

done        PLP
            RETURN
            .pend

;
; Try to find a matching token in the list of tokens
;
; Inputs:
;   BIP = start of window in the line of BASIC text to match
;   CURTOKLEN = length of window (tokens must be of this size)
;
; Outputs:
;   A = token that matches (0 if none)
;
TKMATCH     .proc
            PHP
            PHD
            setaxl
            PHX
            PHY

            setdp GLOBAL_VARS
                  
            LDA #<>TOKENS           ; Set INDEX to point to the first token record
            STA INDEX
            setas
            LDA #`TOKENS
            STA INDEX+2

            LDX #$80                ; Set the initial token ID
            
token_loop  setas
            LDY #TOKEN.length
            LDA [INDEX],Y           ; Get the length of the current token
            BEQ no_match            ; Is it 0? We're out of tokens... no match found
            CMP CURTOKLEN           ; Is it the same as the size of the window?
            BNE next_token          ; No: try the next token

            setaxl
            LDY #TOKEN.name
            LDA [INDEX],Y           ; Get the pointer to the token's name
            STA SCRATCH             ; Set SCRATCH to point to the token's name
            setas
            LDA #`DATA_BLOCK
            STA SCRATCH+2

            ;CALL PRSTSCRATCH        ; Print the token name

            ; Check to see if the window contains the token's name
            setxs
            LDY #0
cmp_loop    LDA [BIP],Y             ; Get the character in the window
            CMP [SCRATCH],Y         ; Compare to the character in the token
            BNE next_token          ; If they don't match, try the next token
            INY                     ; Move to the next character in the window
            CPY CURTOKLEN           ; Have we checked the whole window?
            BCC cmp_loop            ; No: check this next character

            ; We found the matching token
            TXA                     ; Move the token ID to A
no_match    setxl
            PLY
            PLX
            PLD
            PLP
            RETURN

next_token  setaxl                  ; Point INDEX to the next token record
            CLC
            LDA INDEX
            ADC #size(TOKEN)
            STA INDEX
            setas
            LDA INDEX+2
            ADC #0
            STA INDEX+2

            INX                     ; Increment the token ID
            BRA token_loop          ; And check that token
            .pend

;
; Given a token length in CURTOKLEN, set CURTOKLEN to
; the size of the next biggest token.
;
TKNEXTBIG   .proc
            PHP
            PHD
            PHB

            setdp GLOBAL_VARS

            setaxl                  ; Point INDEX to the first token record
            LDA #<>TOKENS
            STA INDEX
            LDA #`TOKENS
            STA INDEX+2

            STZ SCRATCH             ; Clear SCRATCH

loop        setas
            LDY #TOKEN.length
            LDA [INDEX],Y           ; Get the length of the token
            BEQ done                ; If length is 0, we're done
            CMP CURTOKLEN           ; Is it >= CURTOKLEN?
            BGE skip                ; Yes: skip to the next token
            CMP SCRATCH             ; No: is it < SCRATCH?
            BLT skip                ; Yes: skip to the next token
            STA SCRATCH             ; No: it's our new longest token!

skip        setal                   ; Point INDEX to the next token record
            CLC
            LDA INDEX
            ADC #size(TOKEN)
            STA INDEX
            LDA INDEX+2
            ADC #0
            STA INDEX+2

            BRA loop                ; And go around for another pass

done        setas                   ; Copy the length we found to CURTOKLEN
            LDA SCRATCH
            STA CURTOKLEN

            PLB
            PLD
            PLP
            RETURN
            .pend

;
; Collapse line
; Given a position in a BASIC line, replace the first byte
; with a token and shrink the line by the size of the token's keyword
;
; Inputs:
;   A = the token to write to the line
;   BIP = the address of the byte to change
;   CURTOKLEN = the length of the token's keyword
;
TKWRITE     .proc
            PHP
            TRACE "TKWRITE"
            PHD

            setdp GLOBAL_VARS

            setas
            STA [BIP]               ; Write the token to the line

            setal                   ; Set INDEX to the address of the first byte to overwrite
            CLC
            LDA BIP
            ADC #1
            STA INDEX
            LDA BIP+2
            ADC #0
            STA INDEX+2

            setxs
            LDY CURTOKLEN           ; Y will be the number of characters to move down
            DEY

copy_down   setas
            LDA [INDEX],Y           ; Get the byte to move down
            STA [INDEX]             ; Move it down
            BEQ done                ; We've reached the end of the line

            setal                   ; INDEX++
            CLC
            LDA INDEX
            ADC #1
            STA INDEX
            LDA INDEX+2
            ADC #0
            STA INDEX+2

            BRA copy_down

done        PLD
            PLP
            RETURN
            .pend

;
; Compute the address of the token record for a given operator token
;
; Inputs:
;   A = the operator token
;
; Outputs:
;   X = the bank relative address for the operator's token record
;
GETTOKREC   .proc
            PHP

            setaxl
            AND #$007F
            ASL A
            ASL A
            ASL A

            CLC
            ADC #<>TOKENS
            TAX                         ; X is now the data bank relative address of the token record

            PLP
            RETURN
            .pend

;
; Get the precedence of a token
;
; Inputs:
;   A = the token ID
;
; Outputs:
;   A = the precedence of the token
;
TOKPRECED   .proc
            PHP
            PHB
            PHD

            setdp GLOBAL_VARS
            setdbr `TOKENS

            setas
            setxl

            CALL GETTOKREC              ; Get the address of the token record into X
            LDA #TOKEN.precedence,B,X   ; Get the precedence

            setal
            AND #$000F                  ; Mask off the type code
            
            PLD
            PLB
            PLP
            RETURN
            .pend

;
; Get the address of the token's evaluation function
;
; Inputs:
;   A = the token ID
;
; Outputs:
;   A = the address (within the code bank) of the evaluation function
;
TOKEVAL     .proc
            PHP
            PHB
            PHD

            setdp GLOBAL_VARS
            setdbr `TOKENS

            setaxl
            CALL GETTOKREC              ; Get the address of the token record into X
            LDA #TOKEN.eval,B,X         ; Get the address of the evaluation function

            PLD
            PLB
            PLP
            RETURN
            .pend

;
; Return the token type for the given token
;
; Inputs:
;   A = the token ID
;
; Outputs:
;   A = the type of the token
;
TOKTYPE     .proc
            PHP
            PHB
            PHD

            setdp GLOBAL_VARS
            setdbr `TOKENS

            setas
            setxl

            CALL GETTOKREC              ; Get the address of the token record into X
            LDA #TOKEN.precedence,B,X   ; Get the precedence

            setal
            AND #$00F0                  ; Mask off the type code
            
            PLD
            PLB
            PLP
            RETURN
            .pend

;;;
;;; Token Table
;;;

TOK_EOL = $00

TOK_PLUS = $80
TOK_MINUS = $81
TOK_MULT = $82
TOK_DIVIDE = $83
TOK_MOD = $84

TOK_EQ = $87

TOK_LPAREN = $8C
TOK_RPAREN = $8D

TOK_PRINT = $8E
TOK_LET = $8F
TOK_GOTO = $90
TOK_END = $91
TOK_IF = $92
TOK_THEN = $93
TOK_ELSE = $94
TOK_ENDIF = $95

TOK_TY_OP = $00         ; The token is an operator
TOK_TY_CMD = $10        ; The token is a command (e.g. RUN, LIST, etc.)
TOK_TY_STMNT = $20      ; The token is a statement (e.g. INPUT, PRINT, DIM, etc.)
TOK_TY_FUNC = $30       ; The token is a function (e.g. SIN, COS, TAB, etc.)
TOK_TY_PUNCT = $40      ; The token is a punctuation mark (e.g. "(", ")")
TOK_TY_BYWRD = $50      ; The token is a by-word (e.g. STEP, TO, WEND, etc.)

TOKENS      DEFTOK "+", TOK_TY_OP, 3, OP_PLUS, 0
            DEFTOK "-", TOK_TY_OP, 3, OP_MINUS, 0
            DEFTOK "*", TOK_TY_OP, 2, OP_MULTIPLY, 0
            DEFTOK "/", TOK_TY_OP, 2, OP_DIVIDE, 0
            DEFTOK "MOD", TOK_TY_OP, 2, OP_MOD, 0
            DEFTOK "^", TOK_TY_OP, 0, 0, 0
            DEFTOK "<", TOK_TY_OP, 4, 0, 0
            DEFTOK "=", TOK_TY_OP, 4, 0, 0
            DEFTOK ">", TOK_TY_OP, 4, 0, 0
            DEFTOK "NOT", TOK_TY_OP, 5, 0, 0 
            DEFTOK "AND", TOK_TY_OP, 6, 0, 0 
            DEFTOK "OR", TOK_TY_OP, 7, 0, 0 
            DEFTOK "(", TOK_TY_PUNCT, $FF, 0, 0
            DEFTOK ")", TOK_TY_PUNCT, 0, 0, 0

            ; Statements
            DEFTOK "PRINT", TOK_TY_STMNT, 0, S_PRINT, 0
            DEFTOK "LET", TOK_TY_STMNT, 0, S_LET, 0
            DEFTOK "GOTO", TOK_TY_STMNT, 0, S_GOTO, 0
            DEFTOK "END", TOK_TY_STMNT, 0, S_END, 0
            DEFTOK "IF", TOK_TY_STMNT, 0, S_IF, 0
            DEFTOK "THEN", TOK_TY_BYWRD, 0, 0, 0
            DEFTOK "ELSE", TOK_TY_BYWRD, 0, 0, 0
            DEFTOK "ENDIF", TOK_TY_BYWRD, 0, 0, 0

            .word 0, 0, 0, 0