;;;
;;; Assembler/Disassembler portion of monitor
;;;

;
; Macros
;

; Macro to register a mnemonic... at the moment this just takes the name
; Originally, it was going to take a type and basic opcode to help in assembly
; but I now think that's nonsense.
MNEMONIC    .macro ; text, type, opcode
            .null \1
            .endm

DEFMODE     .macro ; text, code
            .null \1
            .byte \2
            .endm

;
; Definitions
;

;
; Define the addressing modes...
; Address modes specified in the address mode table will be of the format: MXaaaaaa
; Where M will be set if the M bit is relevant to the operand of the instruction (e.g. LDA immediate, ORA immedate, etc.)
;       X will be set if the X bit is relevant to the operand of the instruction (e.g. LDX immediate, CPY immediate, etc.)
;   and aaaaa is the address mode enumeration below.
;
ADDR_DP_IND_X = 0       ; (dd,X)
ADDR_DP = 1             ; dd
ADDR_IMM = 2            ; #dd
ADDR_ABS = 3            ; dddd
ADDR_DP_IND_Y = 4       ; (dd),Y
ADDR_DP_X = 5           ; dd,X
ADDR_ABS_Y = 6          ; dddd,Y
ADDR_ABS_X = 7          ; dddd,X
ADDR_ACC = 8            ; A
ADDR_SP_R = 9           ; #d,S
ADDR_DP_LONG = 10       ; [dd]
ADDR_ABS_LONG = 11      ; dddddd
ADDR_SP_R_Y = 12        ; #dd,S,Y
ADDR_DP_Y_LONG = 13     ; [dd],Y
ADDR_ABS_X_LONG = 14    ; dddddd,X
ADDR_DP_IND = 15        ; (dd)
ADDR_ABS_X_ID = 16      ; (dddd,X)
ADDR_DP_Y = 17          ; dd,Y
ADDR_PC_REL = 18        ; PC relative
ADDR_IMPLIED = 19       ; Implied (no operand)
ADDR_XYC = 20           ; #dd, #dd
ADDR_ABS_IND = 21       ; (dddd)
ADDR_PC_REL_LONG = 22   ; PC relative ()
ADDR_ABS_IND_LONG = 23  ; [dddd]
OP_M_EFFECT = $80       ; Flag to indicate instruction is modified by M
OP_X_EFFECT = $40       ; Flag to indicate instruction is modified by X

;
; Assembler theory of operation
;
; The assembler expects that the separate words of the assemble command have already been parsed out
; The address to assemble to goes in MARG1
; The address of a NUL-terminated ASCII string for the mnemonic is in MARG2
; The address of a NUL-terminated ASCII string for the operand is in MARG3
;
; The assembler will search for the mnemonic in the mnemonic table.
; It will then try to do a simple pattern match of the operand against each of the address mode
; patterns until it finds a match. At that time, any hexadecimal digits in the operand are converted
; from ASCII to an actual number.
; The assembler then scans the table MNEMONIC_TAB for instances of the mnemonic found above. When it finds
; a match, it checks the correspondinging entry in ADDRESS_TAB to see if it matches the desired addressing more.
; If so, the index into ADDRESS_TAB is the opcode to write to memory. If not, the assembler keeps searching.
; If an opcode is found, the opcode is written to memory, as are te operand bytes (if any).
;

;
; Assemble an instruction, given the address, mnemonic, and operand fields
;
; Inputs:
;   MARG1 = address of instruction
;   MARG2 = pointer to NUL terminated string containing the mnemonic to assemble
;   MARG3 = pointer to NUL terminated string for the operand (if any)
;
IMASSEMBLE      .proc
                PHP
                PHB
                PHD

                setdp <>MONITOR_VARS    

                setas
                LDA MARG_LEN            ; Do we have at least 2 arguments?
                CMP #2
                BGE has_args            ; Yes: try to assemble the line
                JMP done                ; No: just return

has_args        setal
                LDA MARG1               ; Set the monitor cursor to the address
                STA MCURSOR
                LDA MARG1+2
                STA MCURSOR+2

                setal
                JSL AS_FIND_MNEMO       ; Find the address of the mnemonic
                CMP #$FFFF
                BEQ bad_mnemonic        ; If not found, print bad mnemonic error message
                STA MMNEMONIC

                setas
                LDA MARG_LEN            ; Check the number of arguments passed
                CMP #3                  ; Were all three arguments provided?
                BEQ get_operand         ; Yes: parse the operand

                LDA #ADDR_IMPLIED       ; No: assume address mode is implied
                STA MADDR_MODE
                BRA get_opcode

bad_mnemonic    CALL PRINTCR            ; Print the "bad mnemonic" error message
                setdbr `MERRBADMNEMO
                setxl
                LDX #<>MERRBADMNEMO
                CALL PRINTS
                JMP done

bad_operand     CALL PRINTCR            ; Print the "bad operand" error message
                setdbr `MERRBADOPER
                setxl
                LDX #<>MERRBADOPER
                CALL PRINTS
                JMP done

get_operand     setas
                JSL AS_FIND_MODE        ; Find the addressing mode of the operand
compare         CMP #$FF
                BEQ bad_operand         ; If not found, print bad operand error message
                STA MADDR_MODE
                
                CMP #ADDR_ABS           ; If mode is absolute or absolute long...
                BEQ check_for_pcrel     ; Check to see if the mnemonic is one of the branches
                CMP #ADDR_ABS_LONG
                BEQ check_for_pcrel                
                CMP #ADDR_IMPLIED       ; If mode is implied or accumulator, get the opcode
                BEQ get_opcode
                CMP #ADDR_ACC
                BEQ get_opcode

get_opcode      JSL AS_FIND_OPCODE      ; Find the opcode matching the two
                BCS save_opcode            
                JMP bad_mode            ; If opcode not found, print bad address mode error message

save_opcode     STA [MCURSOR]           ; Write the opcode to the address
                JSL M_INC_CURSOR        ; And point to the next byte

                setdbr 0                ; Go back to bank 0

                setal
                LDA MCURSOR             ; Make MTEMPPTR a pointer to the machine code we're assembling
                STA MTEMPPTR
                LDA MCURSOR+2
                STA MTEMPPTR+2

                setas
                LDA MADDR_MODE          ; Check the address mode again
                CMP #ADDR_PC_REL        ; If it's PC relative
                BEQ compute_rel         ; Convert the address to an offset
                CMP #ADDR_PC_REL_LONG
                BEQ compute_rel
                CMP #ADDR_XYC           ; MVP/MVN addressing mode?
                BEQ emit_2

                AND #%00111111          ; Filter out the mode bits
                CMP #ADDR_IMM           ; Is it immediate?
                BNE fixed_length        ; Yes: emit it as an immediate (variable length)
                JMP emit_imm

fixed_length    setal
                AND #$00FF
                TAX
                setas
get_length      LDA ADDR_LENGTH,X       ; Get the number of bytes in the addressing mode
                CMP #$03
                BEQ emit_3
                CMP #$02
                BEQ emit_2
                CMP #$01
                BEQ emit_1
                BRA next_line

check_for_pcrel setal
                LDA MMNEMONIC
                CMP #<>MN_BRA
                BEQ is_pcrel
                CMP #<>MN_BRL
                BEQ is_pcrel_long
                CMP #<>MN_BCC
                BEQ is_pcrel
                CMP #<>MN_BCS
                BEQ is_pcrel
                CMP #<>MN_BEQ
                BEQ is_pcrel
                CMP #<>MN_BMI
                BEQ is_pcrel
                CMP #<>MN_BNE
                BEQ is_pcrel
                CMP #<>MN_BPL
                BEQ is_pcrel
                JMP get_opcode

is_pcrel        setas
                LDA #ADDR_PC_REL
                STA MADDR_MODE
                JMP get_opcode

is_pcrel_long   setas
                LDA #ADDR_PC_REL_LONG
                STA MADDR_MODE
                JMP get_opcode

                ; Handle PC relative addresses
compute_rel     JSL AS_PC_OFFSET        ; Try to compute the offset
                BCC bad_offset          ; If failed, it's a bad offset operand

emit_rel        CMP #$02                ; If the offset is two bytes
                BEQ emit_2              ; Emit those two bytes
                BRA emit_1              ; Otherwise emit just the one

emit_3          LDY #2                  ; Write bank byte of operand
                LDA MPARSEDNUM,Y
                STA [MTEMPPTR],Y
                JSL M_INC_CURSOR

emit_2          LDY #1                  ; Write high byte of operand
                LDA MPARSEDNUM,Y
                STA [MTEMPPTR],Y
                JSL M_INC_CURSOR

emit_1          LDY #0                  ; Write low byte of operand
                LDA MPARSEDNUM,Y
                STA [MTEMPPTR],Y
                JSL M_INC_CURSOR

                ; Print "A bb:hhll "
next_line       setas

                LDA #'A'
                CALL PRINTC
                LDA #' '
                CALL PRINTC

                LDX MCURSOR
                STX MTEMP
                LDX MCURSOR+2
                STX MTEMP+2  

                JSL M_PR_ADDR

                LDA #' '
                CALL PRINTC

                BRA done

bad_mode        CALL PRINTCR            ; Print the "bad addressing mode" error message
                setdbr `MERRBADMODE
                setxl
                LDX #<>MERRBADMODE
                CALL PRINTS
                BRA done

bad_offset      CALL PRINTCR            ; Print the "bad offset" error message
                setdbr `MERRBADOFFSET
                setxl
                LDX #<>MERRBADOFFSET
                CALL PRINTS
                BRA done

emit_imm        LDA MADDR_MODE          ; Check to see if long immediate was used
                AND #%11000000
                BNE emit_2              ; Yes: emit two bytes
                JMP emit_1              ; No: emit one byte

done            PLD
                PLB
                PLP
                RTL
                .pend

MERRBADMODE     .null "Addressing mode not defined for that instruction.",CHAR_CR
MERRBADMNEMO    .null "Bad mnemonic.",CHAR_CR
MERRBADOPER     .null "Bad operand.",CHAR_CR
MERRBADOFFSET   .null "Relative offset is too large.",CHAR_CR

;
; Convert an absolute address to a PC-relative address
;
; Inputs:
;   MADDR_MODE = address mode
;   MPARSEDNUM = address to convert
;   MCURSOR = PC to serve as base of conversion
;
; Returns:
;   MPARSEDNUM = offset
;   A = number of bytes in offset (1, or 2)
;   C = set on failure (offset too large), clear otherwise
;
AS_PC_OFFSET    .proc
                PHP
                PHD

                setdp <>MONITOR_VARS

                setas
                LDA MADDR_MODE          ; Check to see if it 1 byte or 2 byte relative
                CMP #ADDR_PC_REL
                BEQ is_short

                setal
                CLC                     ; Branch is long. Compute where MCURSOR will be
                LDA MCURSOR             ; with two branch offset bytes
                ADC #2
                BRA compute_cursor

is_short        setal
                CLC                     ; Branch is short. Computer where MCURSOR will be
                LDA MCURSOR             ; with one branch offset byte
                ADC #1
compute_cursor  STA MTEMP
                LDA MCURSOR+2
                ADC #0
                STA MTEMP+2

                SEC                     ; MPARSEDNUM = MPARSEDNUM - MTEMP (MCURSOR after the instruction)
                LDA MPARSEDNUM
                SBC MTEMP
                STA MPARSEDNUM
                LDA MPARSEDNUM+2
                SBC MTEMP+2
                STA MPARSEDNUM+2

                ; Check to see if offset is too big
                setas
                LDA MADDR_MODE
                CMP #ADDR_PC_REL_LONG
                BEQ check_long

                LDA MPARSEDNUM          ; Short offset... check if it's negative
                BMI check_short_neg

                LDA MPARSEDNUM+1        ; Positive short offset... upper two bytes
                BNE failure             ; Must be 0 or it's an overflow
                LDA MPARSEDNUM+2
                BNE failure

                LDA #1                  ; Short offset is 1 byte
                BRA success

check_short_neg LDA MPARSEDNUM+1        ; Negative short offset... upper two bytes
                CMP #$FF                ; Must be $FF or it's an  overflow
                BNE failure             
                LDA MPARSEDNUM+2
                CMP #$FF
                BNE failure
                BRA success

check_long      LDA MPARSEDNUM+1        ; Long offset... check if it's negative
                BMI check_long_neg

                LDA MPARSEDNUM+2        ; Positive long offset... upper byte
                BNE failure             ; Must be 0 or it's an overflow
                BRA success

check_long_neg  LDA MPARSEDNUM+2        ; Negative offset... upper two bytes
                CMP #$FF                ; Must be $FF or it's and overflow
                BNE failure

                LDA #2                  ; Long offset is 2 bytes             
                BRA success

failure         PLD
                PLP
                CLC
                RTL


success         PLD
                PLP
                SEC
                RTL
                .pend

;
; Shift the hex digit in A (as an ASCII character) onto the
; hexadecimal number in MPARSEDNUM.
;
; Inputs:
;   A = an ASCII character for a hex digit
;
AS_SHIFT_HEX    .proc
                PHP
                PHD
                setxl
                PHX

                setdp <>MONITOR_VARS

                setas
                
                LDX #0
seek_loop       CMP @lHEXDIGITS,X   ; Check the passed character against the hex digits
                BEQ found

                INX                 ; Go to the next hex digit
                CPX #$10            ; Are we out of digits?
                BEQ done            ; Yes... just return
                BRA seek_loop

found           setal               ; X = the value of the hex digit
                .rept 4             ; Shift MPARSEDNUM left one hex digit
                ASL MPARSEDNUM
                ROL MPARSEDNUM+2
                .next

                setas               ; And add the X to the shifted MPARSEDNUM
                TXA
                ORA MPARSEDNUM
                STA MPARSEDNUM

done            PLX
                PLD
                PLP
                RTL
                .pend

;
; Find the opcode for a combination of mnemonic and addressing mode
;
; Inputs:
;   MMNEMONIC = address of the mnemonic
;   MADDR_MODE = address mode byte
;
; Outputs:
;   A = opcode, if found
;   C is set if opcode found, clear if not found
;   P is changed (M set, X clear)
;
AS_FIND_OPCODE  .proc
                PHD
                PHB
                setdp <>MONITOR_VARS
                setdbr `MNEMONIC_TAB

                setas
                LDA MADDR_MODE
                AND #%00111111
                STA MTEMP

                setaxl
                LDX #0
                LDY #0

mnemonic_loop   LDA MNEMONIC_TAB,X      ; Get the mnemonic from the opcode table
                BEQ not_found           ; If it's 0, we did not find the mnemonic
                CMP MMNEMONIC           ; Does it match the passed mnemonic?
                BNE next_opcode         ; No: go to the next opcode

check_mode      setas                   ; Yes: check to see if the address mode matches
                LDA ADDRESS_TAB,Y       ; Get the corresponding address mode
                AND #%00111111          ; Filter out effect bits
                CMP MTEMP
                BEQ found               ; Yes: we found the opcode
                setal

next_opcode     INX                     ; Point to the next mnemonic in the table
                INX
                INY
                BRA mnemonic_loop       ; And check it

found           TYA
                SEC                     ; Set carry to show success
                PLB
                PLD
                RTL

not_found       CLC                     ; Clear carry to show failure
                PLB
                PLD
                RTL
                .pend

;
; Compare two NUL terminated ASCII strings for a pattern match.
;
; String to compare must be an exact match to the pattern with
; one exception: a "d" in the pattern will match any hexadecimal
; digit (0 - 9, A - F)
;
; Inputs:
;   MLINEBUF : the string to check against the pattern
;   MCMP_TEXT : the pattern to check
;
; Outputs:
;   C bit set if string matches the pattern, clear otherwise
;   MPARSEDNUM = the value of any hex digits that were matched to the pattern
;
AS_STR_MATCH    .proc
                PHP
                PHD

                setdp <>MONITOR_VARS

                setas
                setxl
                LDY #0

                STZ MPARSEDNUM      ; Set parsed number to 0 in anticipation of 
                STZ MPARSEDNUM+2    ; hex digits in the pattern

match_loop      LDA [MCMP_TEXT],Y   ; Get the pattern character
                BEQ nul_check       ; If at end of pattern, check for end of test string
                CMP #'d'            ; Is it a digit?
                BEQ check_digit     ; Yes: do special check for hex digit

compare         PHA
                LDA [MLINEBUF],Y
                STA MTEMP
                PLA
                
                CMP MTEMP           ; Does it match the character to test?
                BNE return_false    ; No: return fail

next_char       INY                 ; Yes: test the next character
                BRA match_loop

nul_check       LDA [MLINEBUF],Y    ; Check to see that we're at the end of the test string
                BNE return_false    ; If not: return false

return_true     PLD
                PLP                 ; Return true
                SEC
                RTL

return_false    PLD
                PLP                 ; Return false
                CLC
                RTL

                ; Check to see if the test character matches a hex digit
check_digit     setas
                LDA [MLINEBUF],Y
                CMP #'9'+1
                BCS check_AF
                CMP #'0'
                BCS shift_digit     ; character is in [0..9]

check_AF        CMP #'F'+1
                BCS check_lc        ; check lower case
                CMP #'A'
                BCS shift_digit     ; character is in [A..F]

check_lc        CMP #'f'+1
                BCS return_false    ; check lower case
                CMP #'a'
                BCS to_upcase       ; character is in [A..F] 
                BRA return_false    ; No match found... return false

to_upcase       AND #%11011111      ; Convert lower case to upper case

shift_digit     JSL AS_SHIFT_HEX    ; Shift the digit into MPARSEDNUM
                BRA next_char       ; And check the next character
                .pend

;
; Advance MCMP_TEXT pointer to the byte after NUL
;
; Inputs:
;   MCMP_TEXT = pointer to advance to the next byte after a NUL
;
; Registers Changed
;   A, Y, P
;
AS_MCMP_NEXT    .proc
                PHD

                setdp <>MONITOR_VARS

                LDY #0
                setas
loop            LDA [MCMP_TEXT],Y   ; Check to see if we have gotten to the NUL
                BEQ found_nul

                INY
                BRA loop

found_nul       setal
                INY                 ; Got to NUL... point to next byte
                PHY
                PLA                 ; And add that index to MCMP_TEXT pointer
                CLC
                ADC MCMP_TEXT
                STA MCMP_TEXT
                LDA MCMP_TEXT+2
                ADC #0
                STA MCMP_TEXT+2

                PLD
                RTL
                .pend

;
; Find the address of the mnemonic matching the mnemonic field
;
; Inputs:
;   MARG2 = pointer to the mnemonic field (a NUL terminated string)
;
; Outputs:
;   A = pointer to the mnemonic contained in the field ($FFFF if not found)
;
; Registers:
;   A, P
;
AS_FIND_MNEMO   .proc
                PHD

                setdp <>MONITOR_VARS

                setal
                LDA MARG2                   ; Point MLINEBUF to the text
                STA MLINEBUF
                LDA MARG2+2
                STA MLINEBUF+2

                LDA #<>MNEMONICS_TAB        ; Point to the first mnemonic
                STA MCMP_TEXT
                LDA #`MNEMONICS_TAB
                STA MCMP_TEXT+2

match_loop      JSL AS_STR_MATCH            ; Check to see if the text matches the mnemonic
                BCS found_mnemonic          ; If so: return that we found it

                JSL AS_MCMP_NEXT            ; Point to the next mnemonic

                LDA [MCMP_TEXT]             ; Check to see if it's NUL
                BNE match_loop              ; If not, check this next mnemonic

                LDA #$FFFF                  ; Otherwise, return -1
                BRA done

found_mnemonic  LDA MCMP_TEXT               ; Found it: return the address

done            PLD
                RTL
                .pend
;
; Find the addressing mode matching the operand field
;
; Inputs:
;   MARG3 = pointer to the operand field
;
; Outputs:
;   A = the address mode code that matches the operand field ($FF if none)
;
AS_FIND_MODE    .proc
                PHP
                PHD

                setdp <>MONITOR_VARS

                setaxl
                LDA MARG3                   ; Point MLINEBUF to the operand
                STA MLINEBUF
                LDA MARG3+2
                STA MLINEBUF+2

                LDA #<>ADDR_PATTERNS        ; Point to the first address mode pattern to check
                STA MCMP_TEXT
                LDA #`ADDR_PATTERNS
                STA MCMP_TEXT+2

match_loop      JSL AS_STR_MATCH            ; Check to see if the pattern matches the operand
                BCS is_match                ; Yes: Find address mode code

                JSL AS_MCMP_NEXT            ; Point to the address mode

                setal
                CLC                         ; Point to the first byte of the next pattern
                LDA MCMP_TEXT
                ADC #1
                STA MCMP_TEXT
                LDA MCMP_TEXT+2
                ADC #0
                STA MCMP_TEXT+2

                setas
                LDA [MCMP_TEXT]             ; Is the first byte 0?
                BNE match_loop              ; No: check this next pattern

                setal
                LDA #$FFFF                  ; Yes: we didn't find a matching pattern, return -1
                BRA done

is_match        JSL AS_MCMP_NEXT            ; Point to the address mode
                
                setas                       ; We found a match
                LDA [MCMP_TEXT]             ; Get the corresponding address mode code (a byte)
                setal                       ; to return in A
                AND #$00FF

done            PLD
                PLP
                RTL
                .pend

;;
;; Disassembler code
;;

;
; Disassembler theory of operation:
; DS_PR_LINE disassembles a line of machine code at MCURSOR
; For any given opcode XX, it will look up a pointer to the mnemonic in MNEMONIC_TAB
; and the addressing mode code in ADDRESS_TAB. The mnemonic will be printed by
; DS_PR_MNEMONIC, and the operand by DS_PR_OPERAND (which uses the addressing mode
; to determine how to print the operand and how many bytes are in the operand).
;
; DS_PR_LINE will also track the current values of the M and X bits from the status
; register by taking REP and SEP instruction into account. These bits will be used
; to determine operand size for certain immediate addressing cases. This method will
; not be perfect, and the user will be expected to over-ride the values of M and X
; when starting the disassembler.
;

; TODO: provide a means to over-ride the MX bits in MCPUSTAT

;
; Disassembler Testing Notes:
;   30/3/2019 -- PJW -- Verified: single byte instructions, branches, JMP, JML, JSR, and JSL.
;   31/3/2019 -- PJW -- Verified: ADC, SBC, CPx, INx, AND, EOR, ORA, BIT, TRB, TSB
;                       ASL, LSR, ROL, ROR, BRK, COP, MVN, MVP, NOP, PEA, PEI, PER
;                       LDA, LDX, LDY, STA, STX, STY
;
; TODO: REP/SEP and M/X bit interactions
;

;
; Disassemble a block of memeory
;
; Inputs:
;   MARG1 = start address of the block (optional)
;   MARG2 = end address of the block (optional)
;
IMDISASSEMBLE   .proc
                PHP
                PHB
                PHD

                ; Made the direct page coincide with our variables
                setdp <>MONITOR_VARS

                ; Check the number of arguments
                setas
                LDA MARG_LEN
                CMP #2
                BGE set_cursor      ; 2>= arguments? Use them as-is
                
                CMP #1
                BLT no_args         ; No arguments passed? Use defaults

                ; Has a start but no end address
                ; end address := start address + 256
                setal
                CLC
                LDA MARG1
                ADC #MMEMDUMPSIZE
                STA MARG2
                setas
                LDA MARG1+2
                ADC #0
                STA MARG2+2

                ; Set the cursor to the start address
set_cursor      setal
                LDA MARG1
                STA MCURSOR
                setas
                LDA MARG1+2
                STA MCURSOR+2
                BRA dasm_loop

                ; Has neither start nor end address
                ; end address := cursor + 256
no_args         setal
                CLC
                LDA MCURSOR
                ADC #MMEMDUMPSIZE
                STA MARG2
                setas
                LDA MCURSOR+2
                ADC #0
                STA MARG2+2

dasm_loop       JSL DS_PR_LINE

                ; Check to see if we've printed the last byte
                setas
                LDA MCURSOR+2           ; Are the banks the same?
                CMP MARG2+2
                BLT dasm_loop           ; No: continue
                setal
                LDA MCURSOR             ; Are the lower bits the same?
                CMP MARG2
                BLT dasm_loop           ; Nope... keep going

done            CALL PRINTCR

                PLD
                PLB
                PLP
                RTL
                .pend

;
; Print a line of assembly assuming MCURSOR points to the opcode
;
; The disassemble command should call this repeatedly until MCURSOR >= the desired end address
;
DS_PR_LINE      .proc
                PHP
                PHD

                setas               ; Print "A "
                LDA #'A'
                CALL PRINTC
                LDA #' '
                CALL PRINTC

                setdp MCURSOR

                setal               ; Print the address of the line
                LDA MCURSOR
                STA MTEMP
                setas
                LDA MCURSOR+2
                STA MTEMP+2
                JSL M_PR_ADDR

                LDA #' '
                CALL PRINTC

                ; TODO: remove this for the real version
                ; This is a work around for a suspected bug in the emulator
                ; MTEMP = MCURSOR + 1
                setal
                CLC
                LDA MCURSOR
                ADC #1
                STA MTEMP
                setas
                LDA MCURSOR+2
                ADC #0
                STA MTEMP+2

                setas
                setxl
                LDA [MCURSOR]           ; Get the mnemonic
                CMP #$C2                ; Is it REP?
                BNE check_sep           ; No: check to see if it is SEP

                ; Handle the REP instruction
handle_rep      PHA
                LDA [MTEMP]             ; Get the operand
                EOR #$FF                ; Invert the bits
                AND @lMCPUSTAT          ; Mask off the bits in the CPUSTAT
                BRA save_stat

check_sep       CMP #$E2                ; Is it SEP?
                BNE get_op_index        ; No: process the instruction regularly

                ; Handle the SEP instruction
handle_sep      PHA
                LDA [MTEMP]             ; Get the operand
                ORA @lMCPUSTAT          ; Activate the bits in the CPUSTAT
save_stat       STA @lMCPUSTAT          ; And save it back
                PLA

get_op_index    setal
                AND #$00FF
                ASL A
                TAX                     ; Get the index into the mnemonic lookup table

                LDA @lMNEMONIC_TAB,X    ; Get the mnemonic
                TAX
                JSL DS_PR_MNEMONIC      ; And print it

                setas
                LDA [MCURSOR]
                TAX

pr_operand      LDA @lADDRESS_TAB,X     ; Get the addressing mode for the instruction
                JSL M_INC_CURSOR        ; Advance the cursor to the next byte
                JSL DS_PR_OPERAND       ; And print the correct operand

                CALL PRINTCR
                PLD
                PLP
                RTL
                .pend

;
; Print the operand for an instruction
;
; Inputs:
;   MCURSOR = pointer to the operand, assuming there is one
;   A = the addressing mode code (one of the ADDR_ values)
;   Y = mode bit to check for immediate operand length (OP_M_EFFECT for Accumulator, OP_X_EFFECT for X/Y, or none)
;
; On Return:
;   MCURSOR = pointer to the first byte of the next instruction
;
DS_PR_OPERAND   .proc
                PHP

                setas
                PHA             ; Save the address mode so we can get to the M and X flags
                AND #%00111111  ; Filter out the mode flags
                ASL A           ; Compute the index to the table
                setxl
                TAX
                PLA             ; Restore A

                JMP (dispatch,X)
dispatch        .word <>is_dp_ind_x
                .word <>is_dp
                .word <>is_imm
                .word <>is_abs
                .word <>is_dp_ind_y
                .word <>is_dp_x
                .word <>is_abs_y
                .word <>is_abs_x
                .word <>is_accumulator
                .word <>is_stack_r
                .word <>is_dp_long
                .word <>is_abs_long
                .word <>is_stack_r_y
                .word <>is_dp_y_long
                .word <>is_abs_x_long
                .word <>is_dp_ind
                .word <>is_abs_x_id
                .word <>is_dp_y
                .word <>is_pc_rel
                .word <>is_implied
                .word <>is_xyc
                .word <>is_abs_ind
                .word <>is_pc_rel_long
                .word <>is_abs_ind_long

                ; Addressing mode is zero-page-indirect-x
is_dp_ind_x     LDA #'('                ; Print (dd,X)
                CALL PRINTC
                JSL DS_PR_OPERAND1      ; Print dd
                LDA #','
                CALL PRINTC
                LDA #'X'
                CALL PRINTC
                LDA #')'
                CALL PRINTC
                JMP done_1

                ; Addressing mode is zero-page
is_dp           JSL DS_PR_OPERAND1      ; Print dd
                JMP done_1

                ; Addressing mode is immediate
is_imm          setas
                PHA                   
                LDA #'#'
                CALL PRINTC
                PLA

                AND #%11000000          ; Filter so we just look at the mode bits
                CMP #$00                ; Are any set to check?
                BEQ is_imm_short        ; No: treat it as a short always
                LSR A                   ; Move the flag bits right by 2 to match
                LSR A                   ; the positions of the bits in the CPU status register
                AND @lMCPUSTAT          ; Otherwise, filter the mode bit we care about
                BNE is_imm_short        ; If it is set, immediate operation is short

                ; Otherwise, the immediate should be a long
                JSL DS_PR_OPERAND2      ; Print dddd
                JMP done_1

                ; the immediate should be a short
is_imm_short    JSL DS_PR_OPERAND1      ; Print dd
                JMP done_1

                ; Addressing mode is absolute
is_abs          JSL DS_PR_OPERAND2      ; Print dddd
                JMP done_1

                ; Addressing mode is zero-page-indirect-y
is_dp_ind_y     LDA #'('                ; Print (dd),Y
                CALL PRINTC
                JSL DS_PR_OPERAND1      ; Print dd
                LDA #')'
                CALL PRINTC
                LDA #','
                CALL PRINTC
                LDA #'Y'
                CALL PRINTC
                JMP done_1

                ; Addressing mode is zero-page-x
is_dp_x         JSL DS_PR_OPERAND1      ; Print dd,X
                LDA #','
                CALL PRINTC
                LDA #'X'
                CALL PRINTC
                JMP done_1

                ; Addressing mode is zero-page-y
is_dp_y         JSL DS_PR_OPERAND1      ; Print dd,Y
                LDA #','
                CALL PRINTC
                LDA #'Y'
                CALL PRINTC
                JMP done_1

                ; Addressing mode is absolute-y
is_abs_y        JSL DS_PR_OPERAND2      ; Print dddd,Y
                LDA #','
                CALL PRINTC
                LDA #'Y'
                CALL PRINTC
                JMP done_1

                ; Addressing mode is absolute-x
is_abs_x        JSL DS_PR_OPERAND2      ; Print dddd,X
                LDA #','
                CALL PRINTC
                LDA #'X'
                CALL PRINTC
                JMP done_1

                ; Addressing mode is absolute x indirect
is_abs_x_id     LDA #'('
                CALL PRINTC
                JSL DS_PR_OPERAND2      ; Print (dddd,X)
                LDA #','
                CALL PRINTC
                LDA #'X'
                CALL PRINTC
                LDA #')'
                CALL PRINTC
                JMP done_1

is_dp_ind       LDA #'('
                CALL PRINTC
                JSL DS_PR_OPERAND1      ; Print (dd)
                LDA #')'
                CALL PRINTC
                JMP done_1

                ; Addressing mode is accumulator
is_accumulator  LDA #'A'                ; Print A
                CALL PRINTC
                JMP done

                ; Addressing mode is stack relative
is_stack_r      JSL DS_PR_OPERAND1      ; Print dd,S

                LDA #','
                CALL PRINTC
                LDA #'S'
                CALL PRINTC
                JMP done_1

                ; Addressing mode is direct page long
is_dp_long      LDA #'['                ; [dd]
                CALL PRINTC

                JSL DS_PR_OPERAND1      ; Print dd

                LDA #']'
                CALL PRINTC
                JMP done_1

                ; Addressing mode is absolute long
is_abs_long     JSL DS_PR_OPERAND3      ; Print dddddd
                JMP done

                ; Addressing mode is stack relative indirect indexed by Y
is_stack_r_y    LDA #'('                ; (dd,S),Y
                CALL PRINTC

                JSL DS_PR_OPERAND1      ; Print dd

                LDA #','
                CALL PRINTC
                LDA #'S'
                CALL PRINTC
                LDA #')'
                CALL PRINTC
                LDA #','
                CALL PRINTC
                LDA #'Y'
                CALL PRINTC
                JMP done_1

                ; Addressing mode is direct page indirected indexed by Y long
is_dp_y_long    LDA #'['                ; [dd],Y
                CALL PRINTC

                JSL DS_PR_OPERAND1      ; Print dd

                LDA #']'
                CALL PRINTC
                LDA #','
                CALL PRINTC
                LDA #'Y'
                CALL PRINTC
                JMP done_1

is_pc_rel_long  LDY #2
                BRA do_pcrel

is_pc_rel       LDY #1
do_pcrel        JSL DS_PR_PCREL
                JMP done

                ; Addressing mode is implied, there is not operand byte
is_implied      JMP done

                ; Addressing mode is absolute long indexed by X
is_abs_x_long   JSL DS_PR_OPERAND3      ; Print dddddd
                LDA #','
                CALL PRINTC
                LDA #'X'
                CALL PRINTC
                JMP done

                ; Addressing mode with two immediates (used by move instructions)
is_xyc          LDA #'#'
                CALL PRINTC

                PHB                     ; Make sure the databank is pointed to our number
                LDA MCURSOR+2
                PHA
                PLB

                LDX MCURSOR             ; Print dd
                INX
                LDY #1
                JSL PRINTH

                LDA #','
                CALL PRINTC

                LDA #'#'
                CALL PRINTC
                LDX MCURSOR             ; Print dd
                LDY #1
                JSL PRINTH

                PLB                     ; Get our old data bank back

                JSL M_INC_CURSOR
                JMP done_1

is_abs_ind      LDA #'('
                CALL PRINTC
                JSL DS_PR_OPERAND2      ; Print (dddd)
                LDA #')'
                CALL PRINTC
                JMP done_1

is_abs_ind_long LDA #'['
                CALL PRINTC
                JSL DS_PR_OPERAND2      ; Print [dddd]
                LDA #']'
                CALL PRINTC
                JMP done_1

done_1          JSL M_INC_CURSOR    ; Skip over a single byte operand
done            PLP
                RTL
                .pend

;
; Print a single byte operand value
;
; Inputs:
;   MCURSOR = pointer to the single byte operand to print
;
DS_PR_OPERAND1  .proc
                PHP

                setas

                LDA [MCURSOR]
                CALL PRHEXB

                PLP
                RTL
                .pend

;
; Print a two byte operand value
;
; Inputs:
;   MCURSOR = pointer to the two byte operand to print
;
DS_PR_OPERAND2  .proc
                PHP

                setaxl
                LDA [MCURSOR]
                CALL PRHEXW

                JSL M_INC_CURSOR

                PLP
                RTL
                .pend

;
; Print a three byte operand value
;
; Inputs:
;   MCURSOR = pointer to the three byte operand to print
;
DS_PR_OPERAND3  .proc
                PHP
                PHB
                PHD
                setaxl
                PHY

                setdp MCURSOR
                setdbr `MTEMP

                setas
                LDY #0
copy_loop       LDA [MCURSOR]       ; Copy the address pointed to by MCURSOR
                STA MTEMP,Y         ; to MTEMP
                JSL M_INC_CURSOR
                INY
                CPY #3
                BNE copy_loop

                JSL M_PR_ADDR       ; Print the address

                setaxl
                PLY
                PLD
                PLB
                PLP
                RTL
                .pend

;
; Print the mnemonic indicated by X
; All mnemonics are assumed to be 3 characters long
;
DS_PR_MNEMONIC  .proc
                PHP
                PHB
                setas
                setxl
                setdbr `MN_ORA

                .rept 3             ; Print the three characters
                LDA #0,B,X
                CALL PRINTC
                INX
                .next

                LDA #' '            ; Print a space
                CALL PRINTC

                PLB
                PLP
                RTL
                .pend

;
; Print a relative address where the offset is at MCURSOR
;
; Inputs:
;   MCURSOR points to the offset byte(s)
;   Y = number of bytes in the offset
;
DS_PR_PCREL     ;.proc
                PHP
                PHD

                ; Save sign-extended offste to MTEMP
                setdp MCURSOR
                setas

                CPY #2
                BEQ offset_2
                LDA [MCURSOR]
                STA MTEMP
                BMI is_negative
                STZ MTEMP+1
                STZ MTEMP+2
                BRA add_offset
is_negative     LDA #$FF
                STA MTEMP+1
                STA MTEMP+2
                BRA add_offset

offset_2        LDA [MCURSOR]
                STA MTEMP
                JSL M_INC_CURSOR
                LDA [MCURSOR]
                STA MTEMP+1
                BMI is_negative2
                STZ MTEMP+2
                BRA add_offset
is_negative2    LDA #$FF
                STA MTEMP+2

                ; Add the offset to the current address
add_offset      setal
                SEC             ; Add 1 to the offset
                LDA MCURSOR
                ADC MTEMP
                STA MTEMP
                setas
                LDA MCURSOR+2
                ADC MTEMP+2
                STA MTEMP+2

                ; And print the resulting address
                JSL M_PR_ADDR

                JSL M_INC_CURSOR

                PLD
                PLP
                RTL
                ;.pend

;
; Print a 24-bit address in the format "BB:HHLL"
;
; Inputs:
;   MTEMP contains the address to print
; 
M_PR_ADDR       .proc
                PHP
                PHD
                setal
                PHA

                setdp <>MONITOR_VARS

                setas
                LDA MTEMP+2     ; Print the bank byte of the address
                CALL PRHEXB

                setas
                LDA #':'
                CALL PRINTC

                setal
                LDA MTEMP       ; Print the lower 16-bits of the address
                CALL PRHEXW               

                PLA
                PLD
                PLP
                RTL
                .pend

;;
;; Tables to define mnemonics, opcodes, addressing modes, and their relationships
;;
;; Both the assembler and disassembler use these tables to translate between
;; machine code and assembly code.
;;

;
; Mnemonics
;
MNEMONICS_TAB
MN_ORA      #MNEMONIC "ORA"
MN_AND      #MNEMONIC "AND"
MN_EOR      #MNEMONIC "EOR"
MN_ADC      #MNEMONIC "ADC"
MN_STA      #MNEMONIC "STA"
MN_LDA      #MNEMONIC "LDA"
MN_CMP      #MNEMONIC "CMP"
MN_SBC      #MNEMONIC "SBC"
MN_ASL      #MNEMONIC "ASL"
MN_ROL      #MNEMONIC "ROL"
MN_LSR      #MNEMONIC "LSR"
MN_ROR      #MNEMONIC "ROR"
MN_STX      #MNEMONIC "STX"
MN_LDX      #MNEMONIC "LDX"
MN_DEC      #MNEMONIC "DEC"
MN_INC      #MNEMONIC "INC"
MN_BIT      #MNEMONIC "BIT"
MN_JMP      #MNEMONIC "JMP"
MN_STY      #MNEMONIC "STY"
MN_LDY      #MNEMONIC "LDY"
MN_CPY      #MNEMONIC "CPY"
MN_CPX      #MNEMONIC "CPX"

MN_BRK      #MNEMONIC "BRK"
MN_JSR      #MNEMONIC "JSR"
MN_RTI      #MNEMONIC "RTI"
MN_RTS      #MNEMONIC "RTS"
MN_PHP      #MNEMONIC "PHP"
MN_PLP      #MNEMONIC "PLP"
MN_PHA      #MNEMONIC "PHA"
MN_PLA      #MNEMONIC "PLA"
MN_DEY      #MNEMONIC "DEY"
MN_TAY      #MNEMONIC "TAY"
MN_INY      #MNEMONIC "INY"
MN_INX      #MNEMONIC "INX"
MN_CLC      #MNEMONIC "CLC"
MN_SEC      #MNEMONIC "SEC"
MN_CLI      #MNEMONIC "CLI"
MN_SEI      #MNEMONIC "SEI"
MN_TYA      #MNEMONIC "TYA"
MN_CLV      #MNEMONIC "CLV"
MN_CLD      #MNEMONIC "CLD"
MN_SED      #MNEMONIC "SED"
MN_TXA      #MNEMONIC "TXA"
MN_TXS      #MNEMONIC "TXS"
MN_TAX      #MNEMONIC "TAX"
MN_TSX      #MNEMONIC "TSX"
MN_DEX      #MNEMONIC "DEX"
MN_NOP      #MNEMONIC "NOP"

; Branches (follow format xxy10000)
MN_BPL      #MNEMONIC "BPL"
MN_BMI      #MNEMONIC "BMI"
MN_BVC      #MNEMONIC "BVC"
MN_BVS      #MNEMONIC "BVS"
MN_BCC      #MNEMONIC "BCC"
MN_BCS      #MNEMONIC "BCS"
MN_BNE      #MNEMONIC "BNE"
MN_BEQ      #MNEMONIC "BEQ"

; 65C02
MN_TSB      #MNEMONIC "TSB"
MN_TRB      #MNEMONIC "TRB"
MN_STZ      #MNEMONIC "STZ"
MN_BRA      #MNEMONIC "BRA"
MN_PHY      #MNEMONIC "PHY"
MN_PLY      #MNEMONIC "PLY"
MN_PHX      #MNEMONIC "PHX"
MN_PLX      #MNEMONIC "PLX"

; 65816
MN_PHD      #MNEMONIC "PHD"
MN_PLD      #MNEMONIC "PLD"
MN_PHK      #MNEMONIC "PHK"
MN_RTL      #MNEMONIC "RTL"
MN_PHB      #MNEMONIC "PHB"
MN_PLB      #MNEMONIC "PLB"
MN_WAI      #MNEMONIC "WAI"
MN_XBA      #MNEMONIC "XBA"
MN_TCS      #MNEMONIC "TCS"
MN_TSC      #MNEMONIC "TSC"
MN_TCD      #MNEMONIC "TCD"
MN_TDC      #MNEMONIC "TDC"
MN_TXY      #MNEMONIC "TXY"
MN_TYX      #MNEMONIC "TYX"
MN_STP      #MNEMONIC "STP"
MN_XCE      #MNEMONIC "XCE"
MN_COP      #MNEMONIC "COP"
MN_JSL      #MNEMONIC "JSL"
MN_WDM      #MNEMONIC "WDM"
MN_PER      #MNEMONIC "PER"
MN_BRL      #MNEMONIC "BRL"
MN_REP      #MNEMONIC "REP"
MN_SEP      #MNEMONIC "SEP"
MN_MVP      #MNEMONIC "MVP"
MN_MVN      #MNEMONIC "MVN"
MN_PEI      #MNEMONIC "PEI"
MN_PEA      #MNEMONIC "PEA"
MN_JML      #MNEMONIC "JML"
            .byte 0, 0

;
; Map each opcode to its mnemonic
;
MNEMONIC_TAB    .word <>MN_BRK, <>MN_ORA, <>MN_COP, <>MN_ORA, <>MN_TSB, <>MN_ORA, <>MN_ASL, <>MN_ORA    ; 0x
                .word <>MN_PHP, <>MN_ORA, <>MN_ASL, <>MN_PHD, <>MN_TSB, <>MN_ORA, <>MN_ASL, <>MN_ORA

                .word <>MN_BPL, <>MN_ORA, <>MN_ORA, <>MN_ORA, <>MN_TRB, <>MN_ORA, <>MN_ASL, <>MN_ORA    ; 1x
                .word <>MN_CLC, <>MN_ORA, <>MN_INC, <>MN_TCS, <>MN_TRB, <>MN_ORA, <>MN_ASL, <>MN_ORA

                .word <>MN_JSR, <>MN_AND, <>MN_JSL, <>MN_AND, <>MN_BIT, <>MN_AND, <>MN_ROL, <>MN_AND    ; 2x
                .word <>MN_PLP, <>MN_AND, <>MN_ROL, <>MN_PLD, <>MN_BIT, <>MN_AND, <>MN_ROL, <>MN_AND

                .word <>MN_BMI, <>MN_AND, <>MN_AND, <>MN_AND, <>MN_BIT, <>MN_AND, <>MN_ROL, <>MN_AND    ; 3x
                .word <>MN_SEC, <>MN_AND, <>MN_DEC, <>MN_TSC, <>MN_BIT, <>MN_AND, <>MN_ROL, <>MN_AND

                .word <>MN_RTI, <>MN_EOR, <>MN_WDM, <>MN_EOR, <>MN_MVP, <>MN_EOR, <>MN_LSR, <>MN_EOR    ; 4x
                .word <>MN_PHA, <>MN_EOR, <>MN_LSR, <>MN_PHK, <>MN_JMP, <>MN_EOR, <>MN_LSR, <>MN_EOR

                .word <>MN_BVC, <>MN_EOR, <>MN_EOR, <>MN_EOR, <>MN_MVN, <>MN_EOR, <>MN_LSR, <>MN_EOR    ; 5x
                .word <>MN_CLI, <>MN_EOR, <>MN_PHY, <>MN_TCD, <>MN_JML, <>MN_EOR, <>MN_LSR, <>MN_EOR

                .word <>MN_RTS, <>MN_ADC, <>MN_PER, <>MN_ADC, <>MN_STZ, <>MN_ADC, <>MN_ROR, <>MN_ADC    ; 6x
                .word <>MN_PLA, <>MN_ADC, <>MN_ROR, <>MN_RTL, <>MN_JMP, <>MN_ADC, <>MN_ROR, <>MN_ADC

                .word <>MN_BVS, <>MN_ADC, <>MN_ADC, <>MN_ADC, <>MN_STZ, <>MN_ADC, <>MN_ROR, <>MN_ADC    ; 7x
                .word <>MN_SEI, <>MN_ADC, <>MN_PLY, <>MN_TDC, <>MN_JMP, <>MN_ADC, <>MN_ROR, <>MN_ADC

                .word <>MN_BRA, <>MN_STA, <>MN_BRL, <>MN_STA, <>MN_STY, <>MN_STA, <>MN_STX, <>MN_STA    ; 8x
                .word <>MN_DEY, <>MN_BIT, <>MN_TXA, <>MN_PHB, <>MN_STY, <>MN_STA, <>MN_STX, <>MN_STA

                .word <>MN_BCC, <>MN_STA, <>MN_STA, <>MN_STA, <>MN_STY, <>MN_STA, <>MN_STX, <>MN_STA    ; 9x
                .word <>MN_TYA, <>MN_STA, <>MN_TXS, <>MN_TXY, <>MN_STZ, <>MN_STA, <>MN_STZ, <>MN_STA

                .word <>MN_LDY, <>MN_LDA, <>MN_LDX, <>MN_LDA, <>MN_LDY, <>MN_LDA, <>MN_LDX, <>MN_LDA    ; Ax
                .word <>MN_TAY, <>MN_LDA, <>MN_TAX, <>MN_PLB, <>MN_LDY, <>MN_LDA, <>MN_LDX, <>MN_LDA

                .word <>MN_BCS, <>MN_LDA, <>MN_LDA, <>MN_LDA, <>MN_LDY, <>MN_LDA, <>MN_LDX, <>MN_LDA    ; Bx
                .word <>MN_CLV, <>MN_LDA, <>MN_TSX, <>MN_TYX, <>MN_LDY, <>MN_LDA, <>MN_LDX, <>MN_LDA

                .word <>MN_CPY, <>MN_CMP, <>MN_REP, <>MN_CMP, <>MN_CPY, <>MN_CMP, <>MN_DEC, <>MN_CMP    ; Cx
                .word <>MN_INY, <>MN_CMP, <>MN_DEX, <>MN_WAI, <>MN_CPY, <>MN_CMP, <>MN_DEC, <>MN_CMP

                .word <>MN_BNE, <>MN_CMP, <>MN_CMP, <>MN_CMP, <>MN_PEI, <>MN_CMP, <>MN_DEC, <>MN_CMP    ; Dx
                .word <>MN_CLD, <>MN_CMP, <>MN_PHX, <>MN_STP, <>MN_JML, <>MN_CMP, <>MN_DEC, <>MN_CMP

                .word <>MN_CPX, <>MN_SBC, <>MN_SEP, <>MN_SBC, <>MN_CPX, <>MN_SBC, <>MN_INC, <>MN_SBC    ; Ex
                .word <>MN_INX, <>MN_SBC, <>MN_NOP, <>MN_XBA, <>MN_CPX, <>MN_SBC, <>MN_INC, <>MN_SBC

                .word <>MN_BEQ, <>MN_SBC, <>MN_SBC, <>MN_SBC, <>MN_PEA, <>MN_SBC, <>MN_INC, <>MN_SBC    ; Fx
                .word <>MN_SED, <>MN_SBC, <>MN_PLX, <>MN_XCE, <>MN_JSR, <>MN_SBC, <>MN_INC, <>MN_SBC

                .word 0
                
;
; Map each opcode to its addressing mode
;
ADDRESS_TAB     .byte ADDR_IMPLIED, ADDR_DP_IND_X, ADDR_IMM, ADDR_SP_R                  ; 0x
                .byte ADDR_DP, ADDR_DP, ADDR_DP, ADDR_DP_LONG
                .byte ADDR_IMPLIED, ADDR_IMM | OP_M_EFFECT, ADDR_ACC, ADDR_IMPLIED
                .byte ADDR_ABS, ADDR_ABS, ADDR_ABS, ADDR_ABS_LONG

                .byte ADDR_PC_REL, ADDR_DP_IND_Y, ADDR_DP_IND, ADDR_SP_R_Y              ; 1x
                .byte ADDR_DP, ADDR_DP_X, ADDR_DP_X, ADDR_DP_Y_LONG
                .byte ADDR_IMPLIED, ADDR_ABS_Y, ADDR_ACC, ADDR_IMPLIED
                .byte ADDR_ABS, ADDR_ABS_X, ADDR_ABS_X, ADDR_ABS_X_LONG

                .byte ADDR_ABS, ADDR_DP_IND_X, ADDR_ABS_LONG, ADDR_SP_R                 ; 2x
                .byte ADDR_DP, ADDR_DP, ADDR_DP, ADDR_DP_LONG
                .byte ADDR_IMPLIED, ADDR_IMM | OP_M_EFFECT, ADDR_ACC, ADDR_IMPLIED
                .byte ADDR_ABS, ADDR_ABS, ADDR_ABS, ADDR_ABS_LONG

                .byte ADDR_PC_REL, ADDR_DP_IND_Y, ADDR_DP_IND, ADDR_SP_R_Y              ; 3x
                .byte ADDR_DP_X, ADDR_DP_X, ADDR_DP_X, ADDR_DP_Y_LONG
                .byte ADDR_IMPLIED, ADDR_ABS_Y, ADDR_ACC, ADDR_IMPLIED
                .byte ADDR_ABS_X, ADDR_ABS_X, ADDR_ABS_X, ADDR_ABS_X_LONG

                .byte ADDR_IMPLIED, ADDR_DP_IND_X, ADDR_IMPLIED, ADDR_SP_R              ; 4x
                .byte ADDR_XYC, ADDR_DP, ADDR_DP, ADDR_DP_LONG
                .byte ADDR_IMPLIED, ADDR_IMM | OP_M_EFFECT, ADDR_ACC, ADDR_IMPLIED
                .byte ADDR_ABS, ADDR_ABS, ADDR_ABS, ADDR_ABS_LONG

                .byte ADDR_PC_REL, ADDR_DP_IND_Y, ADDR_DP_IND, ADDR_SP_R_Y              ; 5x
                .byte ADDR_XYC, ADDR_DP_X, ADDR_DP_X, ADDR_DP_Y_LONG
                .byte ADDR_IMPLIED, ADDR_ABS_Y, ADDR_IMPLIED, ADDR_IMPLIED
                .byte ADDR_ABS_LONG, ADDR_ABS_X, ADDR_ABS_X, ADDR_ABS_LONG

                .byte ADDR_IMPLIED, ADDR_DP_IND_X, ADDR_PC_REL_LONG, ADDR_SP_R          ; 6x
                .byte ADDR_DP, ADDR_DP, ADDR_DP, ADDR_DP_LONG
                .byte ADDR_IMPLIED, ADDR_IMM | OP_M_EFFECT, ADDR_ACC, ADDR_IMPLIED
                .byte ADDR_ABS_IND, ADDR_ABS, ADDR_ABS, ADDR_ABS_LONG

                .byte ADDR_PC_REL, ADDR_DP_IND_Y, ADDR_DP_IND, ADDR_SP_R_Y              ; 7x
                .byte ADDR_DP_X, ADDR_DP_X, ADDR_DP_X, ADDR_DP_Y_LONG
                .byte ADDR_IMPLIED, ADDR_ABS_Y, ADDR_IMPLIED, ADDR_IMPLIED
                .byte ADDR_ABS_X_ID, ADDR_ABS_X, ADDR_ABS_X, ADDR_ABS_X_LONG

                .byte ADDR_PC_REL, ADDR_DP_IND_X, ADDR_PC_REL_LONG, ADDR_SP_R           ; 8x
                .byte ADDR_DP, ADDR_DP, ADDR_DP, ADDR_DP_LONG
                .byte ADDR_IMPLIED, ADDR_IMM | OP_M_EFFECT, ADDR_IMPLIED, ADDR_IMPLIED
                .byte ADDR_ABS, ADDR_ABS, ADDR_ABS, ADDR_ABS_LONG

                .byte ADDR_PC_REL, ADDR_DP_IND_Y, ADDR_DP_IND, ADDR_SP_R_Y              ; 9x
                .byte ADDR_DP_X, ADDR_DP_X, ADDR_DP_Y, ADDR_DP_Y_LONG
                .byte ADDR_IMPLIED, ADDR_ABS_Y, ADDR_IMPLIED, ADDR_IMPLIED
                .byte ADDR_ABS, ADDR_ABS_X, ADDR_ABS_X, ADDR_ABS_X_LONG

                .byte ADDR_IMM | OP_M_EFFECT, ADDR_DP_IND_X, ADDR_IMM | OP_X_EFFECT, ADDR_SP_R  ; Ax
                .byte ADDR_DP, ADDR_DP, ADDR_DP, ADDR_DP_LONG
                .byte ADDR_IMPLIED, ADDR_IMM | OP_M_EFFECT, ADDR_IMPLIED, ADDR_IMPLIED
                .byte ADDR_ABS, ADDR_ABS, ADDR_ABS, ADDR_ABS_LONG

                .byte ADDR_PC_REL, ADDR_DP_IND_Y, ADDR_DP_IND, ADDR_SP_R_Y              ; Bx
                .byte ADDR_DP_X, ADDR_DP_X, ADDR_DP_Y, ADDR_DP_Y_LONG
                .byte ADDR_IMPLIED, ADDR_ABS_Y, ADDR_IMPLIED, ADDR_IMPLIED
                .byte ADDR_ABS_X, ADDR_ABS_X, ADDR_ABS_Y, ADDR_ABS_X_LONG

                .byte ADDR_IMM | OP_X_EFFECT, ADDR_DP_IND_X, ADDR_IMM, ADDR_SP_R        ; Cx
                .byte ADDR_DP, ADDR_DP, ADDR_DP, ADDR_DP_LONG
                .byte ADDR_IMPLIED, ADDR_IMM | OP_M_EFFECT, ADDR_IMPLIED, ADDR_IMPLIED
                .byte ADDR_ABS, ADDR_ABS, ADDR_ABS, ADDR_ABS_LONG

                .byte ADDR_PC_REL, ADDR_DP_IND_Y, ADDR_DP_IND, ADDR_SP_R_Y              ; Dx
                .byte ADDR_DP, ADDR_DP_X, ADDR_DP_X, ADDR_DP_Y_LONG
                .byte ADDR_IMPLIED, ADDR_ABS_Y, ADDR_IMPLIED, ADDR_IMPLIED
                .byte ADDR_ABS_IND_LONG, ADDR_ABS_X, ADDR_ABS_X, ADDR_ABS_X_LONG

                .byte ADDR_IMM | OP_X_EFFECT, ADDR_DP_IND_X, ADDR_IMM, ADDR_SP_R        ; Ex
                .byte ADDR_DP, ADDR_DP, ADDR_DP, ADDR_DP_IND
                .byte ADDR_IMPLIED, ADDR_IMM | OP_M_EFFECT, ADDR_IMPLIED, ADDR_IMPLIED
                .byte ADDR_ABS, ADDR_ABS, ADDR_ABS, ADDR_ABS_LONG

                .byte ADDR_PC_REL, ADDR_DP_IND_Y, ADDR_DP_IND, ADDR_SP_R_Y              ; Fx
                .byte ADDR_ABS, ADDR_DP_X, ADDR_DP_X, ADDR_DP_Y_LONG
                .byte ADDR_IMPLIED, ADDR_ABS_Y, ADDR_IMPLIED, ADDR_IMPLIED
                .byte ADDR_ABS_X_ID, ADDR_ABS_X, ADDR_ABS_X, ADDR_ABS_X_LONG

; The lengths of the operands in the various addressing modes
ADDR_LENGTH     .byte 1, 1, 1, 2, 1, 1, 2, 2, 0, 1, 1, 3, 1, 1, 3, 1, 2, 1, 1, 0, 2, 2, 2, 2

; Map address mode syntax patterns to address mode code
; NOTE: the order is important. When multiple patterns
; start the same way, list longer patterns first to avoid
; ambiguity.
ADDR_PATTERNS   #DEFMODE "A", ADDR_ACC
                #DEFMODE "dd:dddd,X", ADDR_ABS_X_LONG
                #DEFMODE "dd:dddd", ADDR_ABS_LONG
                #DEFMODE "dddd,X", ADDR_ABS_X
                #DEFMODE "dddd,Y", ADDR_ABS_Y
                #DEFMODE "dddd", ADDR_ABS
                #DEFMODE "dd,X", ADDR_DP_X
                #DEFMODE "dd,Y", ADDR_DP_Y
                #DEFMODE "dd,S", ADDR_SP_R
                #DEFMODE "dd", ADDR_DP
                #DEFMODE "#dddd", ADDR_IMM | OP_M_EFFECT | OP_X_EFFECT
                #DEFMODE "#dd,#dd", ADDR_XYC
                #DEFMODE "#dd", ADDR_IMM
                #DEFMODE "(dd,S),Y", ADDR_SP_R_Y
                #DEFMODE "(dddd,X)", ADDR_ABS_X_ID
                #DEFMODE "(dddd)", ADDR_ABS_X_ID
                #DEFMODE "(dd,X)", ADDR_DP_IND_X
                #DEFMODE "(dd),Y", ADDR_DP_IND_Y
                #DEFMODE "(dd)", ADDR_DP_IND
                #DEFMODE "[dddd]", ADDR_ABS_IND_LONG
                #DEFMODE "[dd],Y", ADDR_DP_Y_LONG
                #DEFMODE "[dd]", ADDR_DP_LONG
                .byte 0, 0

.dpage 0