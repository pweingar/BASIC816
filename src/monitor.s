.cpu "65816"

;Cmd   Command      Params
;A     ASSEMBLE     [Start] [Assembly code]
;C     COMPARE      Start1 Start2 [Len (1 if blank)]
;D     DISASSEMBLE  Start [End]
;F     FILL         Start End Byte
;G     GO           [Address]
;J                  [Address]
;H     HUNT (find)  Start End Byte [Byte]...
;L     LOAD         "File" [Device] [Start]
;M     MEMORY       [Start] [End]
;R     REGISTERS    Register [Value]  (A 1234, F 00100011)
;;                  PC A X Y SP DBR DP NVMXDIZC
;S     SAVE         "File" Device Start End
;T     TRANSFER     Start End Destination
;V     VERIFY       "File" [Device] [Start]
;X     EXIT
;>     MODIFY       Start Byte [Byte]...
;@     DOS          [Command] Returns drive status if no params.
;?     HELP         Display a short help screen

;Monitor.asm
;Jump Table
;* = $195000
;MSTATUS         JML IMSTATUS
MRETURN         JML IMRETURN
MPARSE          JML IMPARSE
MPARSE1         JML IMPARSE1
MEXECUTE        JML IMEXECUTE
MASSEMBLE       JML IMASSEMBLE
MRMODIFY        JML IMRMODIFY
MCOMPARE        JML IMCOMPARE
MDISASSEMBLE    JML IMDISASSEMBLE
MFILL           JML IMFILL

MGO             JML IMGO
MJUMP           JML IMJUMP
MHUNT           JML IMHUNT
MLOAD           JML IMLOAD
MMEMORY         JML IMMEMORY
MREGISTERS      JML IMREGISTERS
MSAVE           JML IMSAVE
MTRANSFER       JML IMTRANSFER
MVERIFY         JML IMVERIFY
MEXIT           JML IMEXIT
MMODIFY         JML IMMODIFY
MDOS            JML IMDOS

;
; IMONITOR
; monitor entry point. This initializes the monitor
; and prints the prompt.
; Make sure 16 bit mode is turned on
;
IMONITOR        CLC                 ; clear the carry flag
                XCE                 ; move carry to emulation flags

                setal
                LDA #STACK_END      ; Reset the stack
                TAS

                CLI                 ; Re-enable interrupts

                JML IMREADY

;
; IMREADY
; Print the status prompt, then wait for input
;
IMREADY         .proc
                setaxl
                JSL IMREGISTERS

ready_loop      CALL READLINE       ; Read characters until the user presses RETURN
                CALL SCRCOPYLINE    ; Copy the line the cursor is on to the INPUTBUF

                PHB
                setas
                LDA #`INPUTBUF
                PHA
                PLB
                LDX #<>INPUTBUF
                CALL TOUPPER
                PLB

                JSL MPARSE          ; Parse the command
                JSL MEXECUTE        ; And execute the parsed command

                BRA ready_loop
                .pend

;
; IMHELP
; Prints the help message
;
IMHELP          .proc
                PHP
                PHB

                setas
                LDA #`help_text
                PHA
                PLB

                setxl
                LDX #<>help_text
                CALL PRINTS

                PLB
                PLP
                RTL

help_text       .text "A <start> <assembly>",CHAR_CR
                .text "  Assemble a program",CHAR_CR,CHAR_CR

                .text "C <start1> <start2> [len (1 if blank)]",CHAR_CR
                .text "  Compare to sections of memory",CHAR_CR,CHAR_CR

                .text "D <start> [end]",CHAR_CR
                .text "  Disassemble a program",CHAR_CR,CHAR_CR

                .text "F <start> <end> <byte>",CHAR_CR
                .text "  Fill a block of memory with a byte",CHAR_CR,CHAR_CR

                .text "G [address]",CHAR_CR
                .text "  Start execution at a location",CHAR_CR,CHAR_CR

                .text "J [address] - Jump to a location in memory",CHAR_CR
                .text "  Jump to a location in memory",CHAR_CR,CHAR_CR

                .text "H <start> <end> <byte> [byte]..",CHAR_CR
                .text "  Hunt for values in memory",CHAR_CR,CHAR_CR

                ;.text "L     LOAD         ",CHAR_DQUOTE,"File",CHAR_DQUOTE," [Device] [Start]",CHAR_CR

                .text "M <start> [end]",CHAR_CR
                .text "  Dump the value in memory",CHAR_CR,CHAR_CR

                .text "R - Display the values of the registers",CHAR_CR,CHAR_CR

                .text "; <PC> <A> <X> <Y> <SP> <DBR> <DP> <NVMXDIZC>",CHAR_CR
                .text "  Change the contents of the registers",CHAR_CR,CHAR_CR

                ;.text "S     SAVE         ",CHAR_DQUOTE,"File",CHAR_DQUOTE," Device Start End",CHAR_CR

                .text "T <start> <end> <destination>",CHAR_CR
                .text "  Transfer (copy) data within memory",CHAR_CR,CHAR_CR

                ;.text "V     VERIFY       ",CHAR_DQUOTE,"File",CHAR_DQUOTE," [Device] [Start]",CHAR_CR

                .text "W <byte>",CHAR_CR
                .text "  Set the register width flags for the disassembler",CHAR_CR,CHAR_CR

                .text "X - Return to BASIC",CHAR_CR,CHAR_CR

                .text "> <start> <byte> [byte]...",CHAR_CR
                .text "  Edit data in memory",CHAR_CR,CHAR_CR

                .null "? - Display a short help screen",CHAR_CR,CHAR_CR
                .pend

;
; IMWIDTH
; Sets the width bits for the disassembler
;
; Arguments:
;   MARG1 = the value of the "status" register used to set the default widths
;
IMWIDTH         .proc
                PHP

                setdp <>MONITOR_VARS

                setas
                LDA MARG1
                STA MCPUSTAT

                PLP
                RTL
                .pend
;
; IMREGISTERS
; Prints the regsiter status
; Reads the saved register values at CPU_REGISTERS
;
; PC     A    X    Y    SP   DBR DP   NVMXDIZC
; 000000 0000 0000 0000 0000 00  0000 00000000
;
; Arguments: none
; Modifies: A,X,Y
IMREGISTERS     ; Print the MONITOR prompt (registers header)
                setdbr `mregisters_msg
                LDX #<>mregisters_msg
                CALL PRINTS

                setas
                LDA #';'
                CALL PRINTC

                LDA #' '
                CALL PRINTC

                setaxl
                setdbr $0
                ; print Program Counter
                LDY #3
                LDX #CPUPC+2
                CALL PRINTH

                ; print A register
                setal
                LDA #' '
                CALL PRINTC
                LDA @lCPUA
                CALL PRHEXW

                ; print X register
                LDA #' '
                CALL PRINTC
                LDA @lCPUX
                CALL PRHEXW

                ; print Y register
                LDA #' '
                CALL PRINTC
                LDA @lCPUY
                CALL PRHEXW

                ; print Stack Pointer
                LDA #' '
                CALL PRINTC
                LDA @lCPUSTACK
                CALL PRHEXW

                ; print DBR
                LDA #' '
                CALL PRINTC
                LDA @lCPUDBR
                CALL PRHEXB

                ; print Direct Page
                LDA #' '
                CALL PRINTC
                CALL PRINTC
                LDA @lCPUDP
                CALL PRHEXW

                ; print Flags
                LDA #' '
                CALL PRINTC
                PHP
                setas
                LDA CPUFLAGS
                JSL MPRINTB
                PLP

                CALL PRINTCR
                CALL PRINTCR
                RTL

;
; Fill memory with specified value. Start and end must be in the same bank.
;
; Command: F
;
; Inputs:
;   MARG1 = Destination start address (3 bytes)
;   MARG2 = Destination end address (inclusive, 3 bytes)
;   MARG3 = Byte to store (3 bytes)
;
; Registers:
;   A: undefined
;
; Author:
;   PJW
;
IMFILL          .proc
                PHP                 ; Save the caller's context
                PHD

                ; Made the direct page coincide with our variables
                setdp <>MONITOR_VARS

do_copy         setas               ; Write the fill byte to the current destination
                LDA MARG3
                STA [MARG1]

                setas               ; Start address [23..16] == End address[23..16]?
                LDA MARG1+2
                CMP MARG2+2
                BNE go_next         ; No: we haven't reached end address yet
                setal               ; Yes: check [15..0]
                LDA MARG1
                CMP MARG2           ; Are they equal?
                BNE go_next         ; No: we haven't reached end address yet

                CALL PRINTCR

                PLD                 ; Restore the caller's context
                PLP
                RTL 

go_next         setal               ; Point to the next destination address
                CLC
                LDA MARG1
                ADC #1
                STA MARG1
                setas
                LDA MARG1+1
                ADC #0
                STA MARG1+1
                BRA do_copy

                .dpage 0
                .pend

;
; Transfer (copy) data in memory
;
; Command: T
;
; Inputs
;   MARG1 = Source starting address (3 bytes)
;   MARG2 = Source ending address (inclusive, 3 bytes)
;   MARG3 = Destination start address (3 bytes)
;
; Registers:
;   A, X, Y: undefined
;
; Author:
;   PJW
;
IMTRANSFER      .proc
                PHP
                PHD

                ; Made the direct page coincide with our variables
                setdp <>MONITOR_VARS

                ; Check the direction of the copy...
                ; Is MARG1 < MARG3?
                setas               ; Check the bank byte first
                LDA MARG1+2
                CMP MARG3+2
                BLT copy_up         ; If MARG1 < MARG3, we are copying up
                setal               ; Check the lower word next
                LDA MARG1
                CMP MARG3
                BLT copy_up         ; If MARG1 < MARG3, we are copying up

                ; MARG1 > MARG3, so we are copying down
                ; Bytes should be copies from the start of the block, rather than the end
copy_byte_down  setas
                LDA [MARG1]         ; Copy the byte
                STA [MARG3]

                LDA MARG1+2         ; Are the source's current and end bank bytes equal?
                CMP MARG2+2
                BNE inc_pointers    ; No: we're not done yet
                setal
                LDA MARG1           ; Are the rest of the bits equal?
                CMP MARG2
                BNE inc_pointers    ; No: we're not done yet
                JMP done            ; Yes: we've copied the last byte, exit

inc_pointers    setal               ; Increment the current source pointer (MARG1)
                CLC
                LDA MARG1
                ADC #1
                STA MARG1
                setas
                LDA MARG1+1
                ADC #0
                STA MARG1+1

                setal               ; Increment the current destination pointer (MARG3)
                CLC
                LDA MARG3
                ADC #1
                STA MARG3
                setas
                LDA MARG3+1
                ADC #0
                STA MARG3+1
                BRA copy_byte_down  ; And copy that next byte over

copy_up         ; MARG1 < MARG3, so we are copying up
                ; Bytes should be copies from the end of the block, rather than the start

                ; Move the destination pointer up to where its end byte should be
                setal               ; MARG4 := MARG2 - MARG1
                SEC
                LDA MARG2
                SBC MARG1
                STA MARG4
                setas
                LDA MARG2+2
                SBC MARG1+2
                STA MARG4+2

                setal               ; MARG3 += MARG4
                CLC
                LDA MARG4
                ADC MARG3
                STA MARG3
                setas
                LDA MARG4+2
                ADC MARG3+2
                STA MARG3+2

copy_byte_up    setas               ; Copy the byte over
                LDA [MARG2]
                STA [MARG3]

                LDA MARG2+2         ; Are the source's current and start bank bytes equal?
                CMP MARG1+2
                BNE dec_pointers    ; No: we're not done yet
                setal
                LDA MARG2           ; Are the rest of the bits equal?
                CMP MARG1
                BNE dec_pointers    ; No: we're not done yet
                BRA done            ; Yes: we've copied the last byte, exit

dec_pointers    setal               ; Decrement the current source pointer (MARG2)
                SEC
                LDA MARG2
                SBC #1
                STA MARG2
                setas
                LDA MARG2+1
                SBC #0
                STA MARG2+1

                setal
                SEC                 ; Decrement the current destination pointer (MARG3)
                LDA MARG3
                SBC #1
                STA MARG3
                setas
                LDA MARG3+1
                SBC #0
                STA MARG3+1
                BRA copy_byte_up    ; And copy that next byte

done            CALL PRINTCR

                PLD
                PLP
                RTL 
                .dpage 0
                .pend 

;
; Check to see if the character in A is a printable ASCII character
; Return with carry set if it is printable, clear otherwise.
;
; NOTE: this routine assumes a Latin1 character set.
;
; Author:
;   PJW
;
IS_PRINTABLE    .proc
                PHP

                setas
                CMP #33
                BLT not_printable   ; 0 .. 31 are not printable

                CMP #127
                BLT printable       ; 32 .. 126 are printable

                CMP #160
                BLT not_printable   ; 127 .. 159 are not printable (assuming Latin-1)

printable       PLP
                SEC
                RTL

not_printable   PLP
                CLC
                RTL
                .pend

MMEMDUMPSIZE = 256  ; Default number of bytes to dump
MMEMROWSIZE = 8    ; Number of bytes to dump per-row

;
; View memory
;
; Inputs:
;   MARG1 = Start address (optional: default is MCURSOR)
;   MARG2 = End address (optional: default is 256
;
; Command: M
;
; Registers:
;   A, X, Y: undefined
;
; Author:
;   PJW
;
IMMEMORY        .proc
                PHP
                PHB
                PHD

                ; Made the direct page coincide with our variables
                setdp <>MONITOR_VARS

                setas

                LDA #0              ; Clear the pagination line counter
                STA @lLINECOUNT


                LDA MARG_LEN        ; Check the number of arguments
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
                BRA dump_line

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
  
                ; Start the processing to dump the current line to the screen
dump_line       setas

                ; Copy an ASCII version of the line of memory into the line buffer
                LDY #0

                setal                   ; Set pointer to the same as CURSOR
                LDA MCURSOR             ; NOTE: the use of MARG4 here is a temporary
                STA MARG4               ; hack. the copy_loop instruction does not
                setas                   ; Seem to work with indexed-indirect-Y addressing
                LDA MCURSOR+2
                STA MARG4+2
                setas

copy_loop       LDA [MARG4]             ; TODO: Should be LDA [MCURSOR],Y, which doesn't seem to be working
                JSL IS_PRINTABLE        ; Is it printable?
                BCS buffer_char         ; Yes: go ahead and add it to the line buffer
                LDA #'?'                ; No: replace it with dot
buffer_char     STA #MLINEBUF,B,Y

                setal                   ; Increment pointer, part of the hack
                CLC
                LDA MARG4
                ADC #1
                STA MARG4
                setas
                LDA MARG4+2
                ADC #0
                STA MARG4+2

                INY
                CPY #MMEMROWSIZE
                BLT copy_loop
                LDA #0
                STA #MLINEBUF,B,Y

                ; Start printing out a line to the screen
                LDA #'>'
                CALL PRINTC
                LDA #' '
                CALL PRINTC

                ; Print the address
                setas
                LDA MCURSOR+2
                CALL PRHEXB

                LDA #':'                ; then a colon
                CALL PRINTC

                setal
                LDA MCURSOR
                CALL PRHEXW

                ; Set the counter for the number of bytes per row
                setal
                LDA #MMEMROWSIZE
                STA MCOUNT

prhex_loop      setas
                LDA #' '
                CALL PRINTC

                LDA [MCURSOR]
                CALL PRHEXB

                JSL M_INC_CURSOR        ; Point MCURSOR to the next byte

                ; Check to see if we need a new line
check_line      setas
                DEC MCOUNT              ; Count down the number of bytes on the row
                BNE prhex_loop          ; If we're not at zero, keep looping over the bytes

                ; We've reached the end of the line                
                LDA #' '
                CALL PRINTC
                LDA #' '
                CALL PRINTC

                ; Print the ASCII represnetation
                setdbr `MLINEBUF
                LDX #MLINEBUF
                CALL PRINTS

                CALL PRINTCR            ; new line
                CALL PAGINATE           ; Pause if we've printed out a page of lines

                ; Check to see if we've printed the last byte
                LDA MCURSOR+2           ; Are the banks the same?
                CMP MARG2+2
                BLT continue            ; No: continue
                setal
                LDA MCURSOR             ; Are the lower bits the same?
                CMP MARG2
                BLT continue            ; Nope... keep going

done            CALL PRINTCR

                PLD
                PLB
                PLP
                RTL

continue        JMP dump_line
                .dpage 0
                .pend

;
; Copy bytes from the arguments list to MLINEBUF
;
; Inputs:
;   A = number of arguments to copy
;   X = address of starting argument to copy
;   Y = address of destination
;
M_COPY_ARGB     .proc
                PHP

                STA MTEMP

                setas
loop            LDA #0,B,X
                STA #0,B,Y      ; Copy the byte
                
                LDA MTEMP       ; Check the count of characters remaining
                BEQ done        ; If it's 0, we're done

                INY             ; Point to the next destination byte

                INX             ; Point to the next source byte (skip three bytes)
                INX
                INX
                INX

                DEC MTEMP       ; Count down and see if we're done
                BRA loop

done            PLP
                RTL
                .pend

;
;>     MODIFY       Start Byte [Byte]...
;
; Inputs:
;   MARG1 = address to update
;   MARG2..MARG9 = bytes to write
;
; Author:
;   PJW
;
IMMODIFY        .proc
                PHP
                PHD
                PHB

                setdp <>MONITOR_VARS
                setdbr 0

                setaxl
                LDA MARG1           ; Set MCURSOR to MARG1
                STA MCURSOR
                LDA MARG1+2
                STA MCURSOR+2

                setas              
                LDA MARG_LEN        ; Set MCOUNT to the number of bytes in the pattern
                DEC A               ; (MARG_LEN - 1)
                STA MCOUNT

                LDX #<>MARG2        ; Copy MCOUNT bytes from MARG2..MARG9
                LDY #<>MLINEBUF     ; to MLINEBUF
                JSL M_COPY_ARGB

                LDY #0
loop            LDA MLINEBUF,Y      ; Copy the byte from the buffer
                STA [MCURSOR]       ; To the address indicated by MCURSOR

                JSL M_INC_CURSOR    ; Advance the cursor
                INY                 ; Go to the next buffered byte
                CPY MCOUNT          ; Did we just write the last one?
                BNE loop            ; No: continue writing

                PLB
                PLD
                PLP
                RTL
                .pend

;
; Find a value in memory
;
; Inputs:
;   MARG1 = starting address to scan
;   MARG2 = ending address to scan
;   MARG3 .. MARG9 = bytes to find (one byte per argument)
;   MARG_LEN = numbe of arguments passed (number of bytes to find + 2)
;
; Author:
;   PJW
;
IMHUNT          .proc
                PHP
                PHD
                PHB

                setdp <>MONITOR_VARS
                setdbr 0

                setas          
                setxl     
                LDA MARG_LEN        ; Set MCOUNT to the number of bytes in the pattern
                DEC A               ; (MARG_LEN - 2)
                DEC A
                STA MCOUNT

                LDX #<>MARG3
                LDY #<>MLINEBUF
                JSL M_COPY_ARGB

                setal
                LDA MARG1           ; Copy starting address to MCURSOR
                STA MCURSOR
                LDA MARG1+2
                STA MCURSOR+2

outer_loop      setal
                LDA MCURSOR+2      ; If MCURSOR < MARG2, we're not done yet
                CMP MARG2+2
                BNE not_done
                LDA MCURSOR
                CMP MARG2
                BEQ done            ; MCURSOR = MARG2: we're done

not_done        setas
                LDY #0

cmp_loop        LDA [MCURSOR],Y     ; Get the byte from the memory to check
                CMP MLINEBUF,Y      ; Compare it against our pattern
                BNE advance         ; If not equal, we need to move on
                INY                 ; Otherwise do we have more bytes to check?
                CPY MCOUNT
                BNE cmp_loop        ; No: check more

                setal               ; Yes: we have a match!
                LDA MCURSOR         ; Print the address
                STA MTEMP
                LDA MCURSOR+2
                STA MTEMP+2
                JSL M_PR_ADDR

                setas               ; Print a space
                LDA #' '
                CALL PRINTC

advance         JSL M_INC_CURSOR    ; Move MCURSOR forward by one
                BRA outer_loop      ; And try to compare that to the pattern                

done            CALL PRINTCR
                PLB
                PLD
                PLP
                RTL
                .pend

;
; Execute from specified address
;
; Inputs:
;   MARG1 = address (optional)
;
; Author:
;   PJW
;
IMJUMP          setdp MONITOR_VARS

                setas
                LDA MARG_LEN        ; Check to see if an argument was provided
                BEQ MJUMPRESTORE    ; If not, just restore the registers

                setaxl
                LDA MARG1           ; Otherwise, replace PC and K
                STA @lCPUPC         ; With the value of the first argument
                LDA MARG1+2
                STA @lCPUPBR

MJUMPRESTORE    LDA @lCPUX          ; Restore X and Y
                TAX
                LDA @lCPUY
                TAY

                LDA @lCPUSTACK      ; Restore the stack pointer
                TCS

                LDA @lCPUDP         ; Restore the direct page register
                TCD

                setas               ; Push the return address to return to the monitor
                LDA #`MJUMPSTART
                PHA
                LDA #>MJUMPSTART
                PHA
                LDA #<MJUMPSTART
                PHA
                JMP MGOSTACK        ; And push remaining registers and restart execution

MJUMPSTART      NOP                 ; RTL increments PC pulled from stack, NOP leaves space for that
                JML MONITOR

;
; Execute from specified address
;
; Inputs:
;   MARG1 = address (optional)
;
; Author:
;   PJW
;
IMGO            setdp MONITOR_VARS

                setas
                LDA MARG_LEN        ; Check to see if an argument was provided
                BEQ MJUMPRESTORE    ; If not, just restore the registers

                setaxl
                LDA MARG1           ; Otherwise, replace PC and K
                STA @lCPUPC         ; With the value of the first argument
                LDA MARG1+2
                STA @lCPUPBR

MGORESTORE      LDA @lCPUX          ; Restore X and Y
                TAX
                LDA @lCPUY
                TAY

                LDA @lCPUSTACK      ; Restore the stack pointer
                TCS

                LDA @lCPUDP         ; Restore the direct page register
                TCD

MGOSTACK        setas
                LDA @lCPUDBR        ; Restore the data bank register
                PHA
                PLB

                LDA #$5C            ; Save the JSL opcode
                STA @lMJUMPINST
                LDA @lCPUPBR        ; Write PBR
                STA @lMJUMPADDR+2
                LDA @lCPUPC+1       ; Write PCH
                STA @lMJUMPADDR+1
                LDA @lCPUPC         ; Write PCL
                STA @lMJUMPADDR
                LDA @lCPUFLAGS      ; Push processor status
                PHA

                setal
                LDA @lCPUA          ; Restore A
                PLP                 ; And the status register

                JML MJUMPINST       ; And jump to the target address

;
;C     COMPARE      Start1 Start2 [Len (1 if blank)]
;
; Inputs:
;   MARG1 = Starting Address 1
;   MARG2 = Starting Address 2
;   MARG3 = Number of bytes to compare (default: 1)
;
; Author:
;   PJW
;
IMCOMPARE       .proc
                PHP
                PHD
                PHB

                setdbr `MERRARGS
                setdp MONITOR_VARS

                setxl
                setas
                LDA MARG_LEN                ; Check the number of arguments provided
                CMP #2
                BEQ default_len             ; If 2: set MCOUNT to default of 1
                CMP #3
                BNE bad_arguments           ; Otherwise, if not 3: print an error

                setal
                LDA MARG3                   ; If 3: set MCOUNT to MARG3
                STA MCOUNT
                BRA compare

default_len     setal
                LDA #1                      ; No length was provided, set MCOUNT to 1
                STA MCOUNT
                BRA compare

bad_arguments   LDX #<>MERRARGS             ; The wrong number of arguments was provided
                CALL PRINTS                 ; Print an error
                BRA done

compare         LDA MARG1                   ; Set MTEMP to MARG1
                STA MTEMP
                LDA MARG1+2
                STA MTEMP+2

                LDY #0
loop            setas
                LDA [MTEMP]                 ; Compare the byte at MTEMP
                CMP [MARG2],Y               ; To the Yth byte from MARG2
                BEQ continue                ; If they're the same, keep going

mismatch        JSL M_PR_ADDR               ; If they're different, print MTEMP
                LDA #' '
                CALL PRINTC

continue        setal
                CLC                         ; Either way, increment MTEMP
                LDA MTEMP
                ADC #1
                STA MTEMP
                LDA MTEMP+2
                ADC #0
                STA MTEMP+2

                INY                         ; Increment Y
                CPY MCOUNT                  ; Try again unless we've checked MCOUNT bytes
                BNE loop

                CALL PRINTCR           

done            CALL PRINTCR

                PLB
                PLD
                PLP
                RTL
                .pend

;
; Registers -- modify registers (showing registers is done by MSTATUS)
; This should be called in response to the ';' command
;
;   PC     A    X    Y    SP   DBR DP   NVMXDIZC
; ; 000000 0000 0000 0000 0000 00  0000 00000000
;
; Inputs:
;   MARG1 = PC
;   MARG2 = A
;   MARG3 = X
;   MARG4 = Y
;   MARG5 = SP
;   MARG6 = DBR
;   MARG7 = DP
;   MARG8 = Flags (parsed from binary)
;
; Author:
;   PJW
;
IMRMODIFY       .proc
                PHP
                PHD
                PHB

                setdbr 0
                setdp MONITOR_VARS

                setas
                LDA MARG_LEN        ; Check the number of arguments
                BEQ done            ; 0? Just quit

                LDX MARG1           ; Set the PC and PBR
                STX #CPUPC,B
                LDX MARG1+2
                STX #CPUPBR,B

                CMP #1              ; Check the number of arguments
                BEQ done            ; 1? Just quit

                LDX MARG2           ; Set A
                STX #CPUA,B

                CMP #2              ; Check the number of arguments
                BEQ done            ; 2? Just quit

                LDX MARG3           ; Set X
                STX #CPUX,B

                CMP #3              ; Check the number of arguments
                BEQ done            ; 3? Just quit

                LDX MARG4           ; Set Y
                STX #CPUY,B

                CMP #4              ; Check the number of arguments
                BEQ done            ; 4? Just quit

                LDX MARG5           ; Set SP
                STX #CPUSTACK,B

                CMP #5              ; Check the number of arguments
                BEQ done            ; 5? Just quit

                setxs
                LDX MARG6           ; Set DBR
                STX #CPUDBR,B

                CMP #6              ; Check the number of arguments
                BEQ done            ; 6? Just quit

                setxl
                LDX MARG7           ; Set DP
                STX #CPUDP,B

                CMP #7              ; Check the number of arguments
                BEQ done            ; 7? Just quit

                setxs
                LDX MARG8           ; Set flags
                STX #CPUFLAGS,B   

done            PLB
                PLD
                PLP
                RTL
                .pend

;
; Execute the current command line (requires MCMD and MARG1-MARG8 to be populated)
;
; Inputs:
;   MCMD = the command (single letter) to execute
;   MARG1..MARG9 = the arguments provided to the command
;   MARG_LEN = the number of arguments passed
;
IMEXECUTE       .proc
                PHP
                PHD
                PHB

                setdp <>MONITOR_VARS

                setas
                setxl
                LDX #0
loop            LDA @lMCOMMANDS,X
                BEQ done
                CMP [MCMD]
                BEQ found

                INX
                BRA loop
                
found           setal
                TXA
                ASL A
                TAX

                LDA dispatch,X
                STA @lJMP16PTR
                JSL MDOCMD

done            PLB
                PLD
                PLP
                RTL

dispatch        .word <>MASSEMBLE
                .word <>MCOMPARE
                .word <>MDISASSEMBLE
                .word <>MFILL
                .word <>MGO
                .word <>MJUMP
                .word <>MHUNT
                .word <>MLOAD
                .word <>MMEMORY
                .word <>MREGISTERS
                .word <>MRMODIFY
                .word <>MSAVE
                .word <>MTRANSFER
                .word <>MVERIFY
                .word <>IMWIDTH
                .word <>MEXIT
                .word <>MMODIFY
                .word <>IMHELP
                .pend

;
; Call the command through indirection
;
MDOCMD          .proc
                JMP (JMP16PTR)
                .pend

.include "assembler.s"

;
; Utility subroutines
;

;
; Increment the monitor's memory cursor
;
M_INC_CURSOR    .proc
                PHP
                setal
                PHA

                CLC
                LDA MCURSOR
                ADC #1
                STA MCURSOR
                setas
                LDA MCURSOR+2
                ADC #0
                STA MCURSOR+2

                setal
                PLA
                PLP
                RTL
                .pend

;
; Given a NUL terminated ASCII string, convert all lower-case letters to upper case
;
; Inputs:
;   X = pointer to the NUL terminated ASCII string
;   DBR = bank containing the string
;
M_TO_UPPER      .proc
                PHP
                setxl
                PHX

                setas
loop            LDA #0,B,X
                BEQ done

                CMP #'z'+1
                BCS try_next
                CMP #'a'
                BCC try_next

                AND #%11011111
                STA #0,B,X

try_next        INX
                BRA loop

done            PLX
                PLP
                RTL
                .pend

;
; Print a byte as a string of binary digits
;
; Inputs:
;   A = the byte to print 
;
MPRINTB         .proc
                PHP
                setxl
                setas
                PHX

                ; M is clear, so accumulator is short and we shift 8 bits
                LDX #8          ; Set number of bits to print to 8

loop            ASL A           ; Shift MSB to C
                BCS is_one

                ; MSB was 0, to print a '0'
                PHA             ; Save value to print
                LDA #'0'        ; Print '0'
                CALL PRINTC
                BRA continue

is_one          PHA             ; Save value to print
                LDA #'1'        ; Print '1'
                CALL PRINTC
                
continue        PLA
                DEX             ; Count down the bits to shift
                BNE loop        ; And try the next one if there is one

                PLX             ; Otherwise, return
                PLP
                RTL
                .pend

;
; Skip whitespace on monitor command parsing
;
; Inputs:
;   INPUTBUF - buffer containing the input text
;   X = index of the current character in the input buffer
;
; Affects:
;   A width
;
MSKIPWS         .proc
                setdp <>MONITOR_VARS

                setas
loop            LDA [MCURSOR]       ; Check the current character
                BEQ done            ; If NULL, we're done
                CMP #' '            ; Is it a space?
                BNE done            ; No: we're done

                JSL M_INC_CURSOR    ; Yes, try the next one
                BRA loop

done            RTL
                .pend

;
; Skip to the next whitespace or NULL on monitor command parsing
;
; Inputs:
;   INPUTBUF - buffer containing the input text
;   X = index of the current character in the input buffer
;
; Affects:
;   A width
;
MSKIP2WS        .proc
                setdp <>MONITOR_VARS

                setas
loop            LDA [MCURSOR]       ; Check the current character
                BEQ done            ; If NULL, we're done
                CMP #' '            ; Is it a space?
                BEQ done            ; No: we're done

                JSL M_INC_CURSOR    ; Yes, try the next one
                BRA loop

done            RTL
                .pend

;
; Attempt to parse an argument
;
; Inputs:
;   MCURSOR = pointer to the current argument value to parse
;   MARG_LEN = the number of arguments parsed so far
;
; Outputs:
;   MPARSEDNUM = the value parsed
;   MARG_LEN = the number of arguments parsed so far (should be +1)
;   MCURSOR = pointer to the character right after the argument
;
; TODO:
;   Add support for flags, radix-2 arguments, and strings
;
MPARSEARG       .proc
                setdp <>MONITOR_VARS

                setas
                STZ MTEMP                       ; Use MTEMP as a flag for having processed digits

                setal
                STZ MPARSEDNUM                  ; Clear the parsed number
                STZ MPARSEDNUM+2

pa_loop         setas
                LDA [MCURSOR]                   ; Get the current character
                CMP #":"
                BEQ pa_next_char                ; Ignore any colons
                CALL ISHEX                      ; Check to see if it's hexadecimal
                BCC finished_arg                ; No? We're done with this argument

                JSL AS_SHIFT_HEX                ; Yes: shift it onto MPARSEDNUM

                LDA #1                          ; Flag that we've processed a character
                STA MTEMP

pa_next_char    JSL M_INC_CURSOR                ; And try the next character
                BRA pa_loop

                ; MPARSEDNUM should now contain the value of the argument

finished_arg    LDA MTEMP                       ; Check to see if we've processed any characters
                BEQ done                        ; No: we're done

                LDA MARG_LEN                    ; Get the argument count
                setal
                AND #$00FF
                ASL A                           ; multiply it by forfour
                ASL A
                TAX                             ; ... to get the index to the argument

                LDA MPARSEDNUM                  ; Copy the value to the argument slot
                STA MARG1,X
                LDA MPARSEDNUM+2
                STA MARG1+2,X

                setas
                INC MARG_LEN                    ; And bump up the argument count

done            RTL
                .pend

;
; Parse all arguments (up to 9)
;
MPARSEALLARG    .proc
                setas
                STZ MARG_LEN                    ; Set the arg count to 0

parse_arg       JSL MSKIPWS                     ; Otherwise, skip white space
                LDA [MCURSOR]                   ; Check the current character
                BEQ done                        ; If it is NULL, we're done

                JSL MPARSEARG                   ; Attempt to parse the argument
                LDA MARG_LEN                    ; Check how many arguments we've processed
                CMP #9
                BGE done                        ; If >=9, then we're done

                LDA [MCURSOR]                   ; Check the current character
                BEQ done                        ; If EOL: we're done
                CMP #' '
                BEQ parse_arg                   ; If space: try to process another argument
                CALL ISHEX
                BCS parse_arg                   ; If hex digit: try to process another argument

done            RTL
                .pend

;
; Parse the current command line  
;
; Inputs:
;   INPUTBUF - contains the null-terminated line input by the user
;
IMPARSE         .proc
                PHP
                PHD

                setdp MONITOR_VARS

                ; Initialize the command parameters
                setxl
                setas
                LDX #MARG_LEN - MONITOR_VARS    ; Clear the monitor command line parameters
clear_command   STZ MONITOR_VARS,X
                DEX
                BNE clear_command

                LDA #`INPUTBUF                  ; Point the command parser to the input buffer
                STA MCMDADDR+2
                STA MCURSOR+2                   ; And point MCURSOR there too
                setal
                LDA #<>INPUTBUF
                STA MCMDADDR
                STA MCURSOR

                ; Parse the command
                setas
                JSL MSKIPWS                     ; Skip to the first letter of the command
                CMP #0                          ; Is the current character a NULL?
                BEQ done                        ; Yes: there's no command here

                setal                           ; Otherwise, save position for command
                LDA MCURSOR
                STA MCMD
                setas
                LDA MCURSOR+2
                STA MCMD+2

                LDX #1
cmd_loop        JSL M_INC_CURSOR                ; Move to the next character
                LDA [MCURSOR]                   ; What is that character?
                BNE cmd_space                   ; If not NULL: check for a space
no_arguments    STX MCMD_LEN                    ; If NULL: Save the length of the command  
                STZ MARG_LEN                    ; ... And the fact there are no arguments
                BRA done                        ; ... And return

cmd_space       CMP #' '                        ; Is it a space?
                BEQ found_cmd                   ; Yes: save the length

                INX                             ; No: go to the next character
                BRA cmd_loop

found_cmd       STX MCMD_LEN                    ; Save the length of the command
                LDA #0
                STA [MCURSOR]                   ; Write a NULL to the end of the command
                JSL M_INC_CURSOR                ; And skip to the next character

                LDA [MCMD]                      ; Check the command
                CMP #'A'
                BEQ parse_asm                   ; If 'A', parse the line for the assemble command

                JSL MPARSEALLARG

done            PLD
                PLP
                RTL

                ; Parse the arguments for assemble
parse_asm       JSL MSKIPWS                     ; Skip to the first letter of the address
                LDA [MCURSOR]
                BEQ done                        ; Exit if we got the end-of-line

                JSL MPARSEARG                   ; Parse the first argument as the target address

                JSL MSKIPWS                     ; Skip to the first letter of the mnemonic
                LDA [MCURSOR]
                BEQ done                        ; Exit if we got the end-of-line                

                setal
                LDA MCURSOR                     ; Save pointer to the start of the mnemonic
                STA MARG2
                setas
                LDA MCURSOR+2
                STA MARG2+2

asm_find_sp     JSL M_INC_CURSOR                ; Find the space at the end of the mnemonic
                LDA [MCURSOR]
                BEQ asm_no_operand              ; If EOL: we have an instruction but no operand
                CMP #' '
                BNE asm_find_sp
                LDA #0
                STA [MCURSOR]                   ; Null terminate the mnemonic

                INC MARG_LEN                    ; Count the mnemonic as an argument

                JSL M_INC_CURSOR
                JSL MSKIPWS                     ; Skip to the addressing mode
                LDA [MCURSOR]
                BEQ done                        ; If EOL: we're done

                setal
                LDA MCURSOR                     ; Set the pointer to the addressing mode
                STA MARG3
                setas
                LDA MCURSOR+2
                STA MARG3+2

                INC MARG_LEN                    ; And count it as the second argument

                BRA done                        ; and return

asm_no_operand  INC MARG_LEN                    ; Increment the argument count
                BRA done                        ; And quit
                .pend

;
; Exit monitor and return to BASIC command prompt
;
IMEXIT          JML INTERACT

;
; Unimplemented monitor routines
;

IMRETURN        RTL ; Handle RETURN key (ie: execute command)
IMPARSE1        BRK ; Parse one word on the current command line
IMASSEMBLEA     BRK ; Assemble a line of text.
IMLOAD          BRK ; Load data from disk. Device=1 (internal floppy) Start=Address in file
IMSAVE          BRK ; Save memory to disk
IMVERIFY        BRK ; Verify memory and file on disk

IMDOS           BRK ; Execute DOS command

;
; MMESSAGES
; MONITOR messages and responses.
MMESSAGES
MERRARGS        .null "Bad arguments",CHAR_CR

mregisters_msg  .null $0D,"  PC     A    X    Y    SP   DBR DP   NVMXDIZC",CHAR_CR
MCOMMANDS       .null "ACDFGJHLMR;STVWX>?"
