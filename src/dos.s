;;;
;;; Disk Operating System Commands and support routines
;;;

;
; Offsets and constants for directory entries
;

DOS_BLOCK_SIZE = 512        ; Size of a block transfered from DOS
DIR_ENTRY_SIZE = $20        ; Size of a FAT32 directory entry

DIR_FILENAME = $00          ; Offset to the short file name (8 bytes)
DIR_FILEEXT = $08           ; Offset to the file extension (3 bytes)
DIR_FILEATTR = $0B          ; Offset to the file attributes (1 byte)
DIR_CLUSTER_H = $14         ; Offset to the high word of the starting cluster number (2 bytes)
DIR_MOD_TIME = $16          ; Offset to the last modified time (2 bytes)
DIR_MOD_DATE = $18          ; Offset to the last modified date (2 bytes)
DIR_CLUSTER_L = $1A         ; Offset to the low word of the starting cluster number (2 bytes)
DIR_FILE_SIZE = $1C         ; Offset to the file size in bytes (4 bytes)

; Special initial bytes for the file name
DIR_FILE_EOD = $00          ; Filename initial character: end of directory table
DIR_FILE_DEL = $E5          ; Filename initial character: entry was erased

; File attribute flags
DIR_ATTR_RO = $01           ; File attribute read-only
DIR_ATTR_HIDE = $02         ; File attribute hidden
DIR_ATTR_SYS = $04          ; File attribute system file
DIR_ATTR_VOL = $08          ; File attribute volume name
DIR_ATTR_DIR = $10          ; File attribute subdirectory
DIR_ATTR_ARC = $20          ; File attribute archive needed
DIR_ADDR_DEV = $40          ; File attribute character device

DIR_TIME        .macro hour, minute, second
                .word \hour << 11 | \minute << 5 | \second
                .endm

DIR_DATE        .macro year, month, day
                .word (\year - 1980) << 9 | \month << 5 | \day 
                .endm

;
; Load a file directly into memory from storage
;
; Inputs:
;   MARG1 = pointer to the path to load
;   MARG2 = destination address
;
DOS_RAWLOAD     .proc
                PHP
                PHB

                setxl
                setas
                LDA MARG1+2             ; Set B to the path's bank
                PHA
                PLB
                LDX MARG1               ; Set X to the path's address

                setal
                LDA #0                  ; TODO: set the access to READ

                CALL FD_OPEN
                BCC err_open
                STA MTEMP               ; Save file descriptor to MTEMP

loop            setas
                LDA MARG2+2             ; Set B to the destination bank
                PHA
                PLB
                LDX MARG2               ; Set X to the destination address
                LDY #DOS_BLOCK_SIZE     ; Set the size to read

                setal
                LDA MTEMP               ; Set the file handle to read

                CALL FD_READ            ; Try to read a block
                BCC err_read            ; Handle any read error

                CMP #0                  ; Did we read anything?
                BEQ close_fd            ; No: we're finished

                CLC                     ; Advance the destination address by the amount read
                ADC MARG2
                STA MARG2
                LDA MARG2+2
                ADC #0
                STA MARG2+2

                BRA loop                ; And try again

close_fd        LDA MTEMP               ; Set the file handle to close
                CALL FD_CLOSE           ; And attempt to close it
                BCC err_close           ; Handle any error on closing

                PLB
                PLP
                RETURN

err_open        PLB
                THROW ERR_OPEN

err_close       PLB
                THROW ERR_CLOSE

err_read        PLB
                THROW ERR_READ
                .pend

;
; Save a file directly frpm memory to storage
;
; Inputs:
;   MARG1 = pointer to the path to load
;   MARG2 = address of first byte to write
;   MARG3 = address of last byte to write
;
; Affects:
;   MARG4 = amount to write on any particular cycle
;
DOS_RAWSAVE     .proc
                PHP
                PHB

                setxl
                setas
                LDA MARG1+2             ; Set B to the path's bank
                PHA
                PLB
                LDX MARG1               ; Set X to the path's address

                setal
                LDA #0                  ; TODO: set the access to WRITE

                CALL FD_OPEN
                BCC err_open
                STA MTEMP               ; Save file descriptor to MTEMP

                LDA #0
                STA MARG4+2

loop            SEC
                LDA MARG3               ; compute END - START
                SBC MARG2
                AND #$01FF              ; Make sure it is in [0, 511]
                STA MARG4               ; put it in MARG4

                LDA MARG4               ; If count is 0, we're finished
                BEQ close_fd

                setas
                LDA MARG2+2             ; Set B to the source bank
                PHA
                PLB
                LDX MARG2               ; Set X to the source address
                LDY MARG4               ; Set the size to write

                setal
                LDA MTEMP               ; Set the file handle to write

                CALL FD_WRITE           ; Try to read a block
                BCC err_read            ; Handle any read error

                CMP #0                  ; Did we read anything?
                BEQ close_fd            ; No: we're finished

                CLC                     ; Advance the destination address by the amount read
                ADC MARG2
                STA MARG2
                LDA MARG2+2
                ADC #0
                STA MARG2+2

                BRA loop                ; And try again

close_fd        LDA MTEMP               ; Set the file handle to close
                CALL FD_CLOSE           ; And attempt to close it
                BCC err_close           ; Handle any error on closing

                PLB
                PLP
                RETURN

err_open        PLB
                THROW ERR_OPEN

err_close       PLB
                THROW ERR_CLOSE

err_read        PLB
                THROW ERR_READ

                PLB
                PLP
                RETURN
                .pend

;
; Print a FAT file size
;
; Inputs:
;   ARGUMENT1 = the file size to print
;
PR_FILESIZE     .proc
                PHX
                PHP

                setaxl
                LDA ARGUMENT1+2
                BIT #$FFF0              ; Check to see if the amount is in MB range
                BNE pr_mb               ; If so, print it in MBs

                BIT #$000F              ; Check to see if the amount is in KB range
                BNE pr_kb
                LDA ARGUMENT1
                BIT #$FC00
                BNE pr_kb               ; If so, print it in KBs

pr_regular      CALL PR_INTEGER         ; Print the number raw (for numbers < 1,024 bytes)
                BRA done

pr_kb           LDX #10                 ; Shift so the amount in KB is in ARGUMENT1
kb_shift        LSR ARGUMENT1+2
                ROR ARGUMENT1
                DEX
                BNE kb_shift

                CALL PR_INTEGER         ; Print the number in KB (for numbers < 1,024 KB)
                setas
                LDA #'K'
                CALL PRINTC
                setal
                BRA done

pr_mb           LDX #20                 ; Shift so the amount in MB is in ARGUMENT1
mb_shift        LSR ARGUMENT1+2
                ROR ARGUMENT1
                DEX
                BNE mb_shift

                CALL PR_INTEGER         ; Print the number in MB (for all other numbers)
                setas
                LDA #'M'
                CALL PRINTC
                setal

done            PLP
                PLX
                RETURN
                .pend

;
; Print a two-digit padded number
;
; Inputs:
;   ARGUMENT1 = the number to print
;
PR_INTPAD2      .proc
                PHP
                setal

                CALL ITOS
                CALL S_PAD2
                LDA STRPTR          ; Copy the pointer to the string to ARGUMENT1
                STA ARGUMENT1
                LDA STRPTR+2
                STA ARGUMENT1+2
                CALL PR_STRING      ; And print it
                
                PLP
                RETURN
                .pend

;
; Pad a temporary numerical string with a leading 0
; If a string is two characters with a leading blank, change the blank to a 0
; If the string is three characters with a leading blank, delete the blank
;
; Input:
;   STRPTR = string to modify
;
S_PAD2          .proc
                PHY
                PHP

                setas
                LDA [STRPTR]
                CMP #CHAR_SP
                BNE done

                LDY #2
                LDA [STRPTR],Y
                BNE shift

                LDA #'0'            ; It's two characters with a leading blank
                STA [STRPTR]        ; Replace it with a 0
                BRA done

shift           LDY #1
                LDA [STRPTR],Y
                STA [STRPTR]

                setal
                INC STRPTR          ; Trim the leading space
                BNE done
                INC STRPTR+2

done            PLP
                PLY
                RETURN
                .pend

;
; Print a date, given the FAT date format
;
; Output in format YYYY-MM-DD
;
; Inputs:
;   A = the date code (YYYYYYYYMMMMDDDDD, where year is since 1980)
;
PR_DATE         .proc
                PHP

                setal

                ; Print the year

                STA @lCPUA
                LDX #9                  ; Extract the year code
pr_hour_loop    LSR A
                DEX
                BNE pr_hour_loop

                CLC
                ADC #1980
                STA ARGUMENT1
                STZ ARGUMENT1+2
                setas
                LDA #TYPE_INTEGER
                STA ARGTYPE1
                setal

                CALL PR_INTEGER

                LDA #'-'
                CALL PRINTC             ; Print a separator

                setal
                LDA @lCPUA

                LDX #5                  ; Extract the minute
pr_min_loop     LSR A
                DEX
                BNE pr_min_loop
                AND #$000F

                STA ARGUMENT1
                STZ ARGUMENT1+2
                setas
                LDA #TYPE_INTEGER
                STA ARGTYPE1
                setal

                CALL PR_INTPAD2

                LDA #'-'
                CALL PRINTC             ; Print a separator                

                setal
                LDA @lCPUA              ; Extract the second code
                AND #$001F

                STA ARGUMENT1
                STZ ARGUMENT1+2
                setas
                LDA #TYPE_INTEGER
                STA ARGTYPE1
                setal

                CALL PR_INTPAD2

                PLP
                RETURN
                .pend

;
; Print a time, given the FAT time format
;
; Output in format HH:MM
;
; Inputs:
;   A = the date code (YYYYYYYYMMMMDDDDD, where year is since 1980)
;
PR_TIME         .proc
                PHP

                setal

                ; Print the year

                STA @lCPUA
                LDX #11                  ; Extract the hour
pr_year_loop    LSR A
                DEX
                BNE pr_year_loop

                STA ARGUMENT1
                STZ ARGUMENT1+2
                setas
                LDA #TYPE_INTEGER
                STA ARGTYPE1
                setal

                CALL PR_INTEGER

                LDA #':'
                CALL PRINTC             ; Print a separator

                setal
                LDA @lCPUA

                LDX #5                  ; Extract the month code
pr_month_loop   LSR A
                DEX
                BNE pr_month_loop
                AND #$000F

                STA ARGUMENT1
                STZ ARGUMENT1+2
                setas
                LDA #TYPE_INTEGER
                STA ARGTYPE1
                setal

                CALL PR_INTPAD2

                LDA #':'
                CALL PRINTC             ; Print a separator                

                setal
                LDA @lCPUA              ; Extract the day code
                AND #$001F

                STA ARGUMENT1
                STZ ARGUMENT1+2
                setas
                LDA #TYPE_INTEGER
                STA ARGTYPE1
                setal

                CALL PR_INTPAD2

                PLP
                RETURN
                .pend

;
; Command to print the directory
;
; DIR <path>
;
CMD_DIR         .proc
                PHY
                PHP
                TRACE "CMD_DIR"

                setas
                STZ LINECOUNT           ; Clear the pagination line counter

                setaxl
                CALL DIR_OPEN

                LDA #CHAR_CR
                CALL PRINTC

                CLC
                LDA MCURSOR             ; Save the end of the block to MTEMP
                ADC #<>DOS_BLOCK_SIZE
                STA MTEMP
                LDA MCURSOR+2
                ADC #`DOS_BLOCK_SIZE
                STA MTEMP+2

loop            CALL DIR_PRENTRY
                BCC pr_cr               ; If at the end of the directory, wrap up

                CALL PAGINATE           ; If we're not done, check to see if we've printed a full page

                LDA MCURSOR             ; If we're not finished with the block...
                CMP MTEMP   
                BNE loop                ; Keep printing entries
                LDA MCURSOR+2
                CMP MTEMP+2
                BNE loop

                CALL DIR_NEXT_BLOCK     ; Get the next directory block
                BCS loop                ; If we got something, start over with this block

pr_cr           LDA #CHAR_CR
                CALL PRINTC

done            PLP
                PLY
                RETURN
                .pend

;
; Open a directory for listing, and load the first block
;
; Inputs:
;   the path to the directory (or maybe the file descriptor)
;
; Outputs:
;   MCURSOR = pointer to the first entry in the loaded block
;
DIR_OPEN        .proc
                PHP
                TRACE "DIR_OPEN"

                ; TODO: actually load the first block
                
                setal
                LDA #<>DIR_SAMPLE
                STA MCURSOR
                LDA #`DIR_SAMPLE
                STA MCURSOR+2

                PLP
                RETURN
                .pend

;
; Read the next block of the directory from the file system
;
; Inputs:
;   It's a mystery!... something to point to the directory and track how to load it.
;
; Outputs:
;   C is set if loaded successfully, clear if we're done.
;
DIR_NEXT_BLOCK  .proc
                PHP
                TRACE "DIR_NEXT_BLOCK"

ret_false       PLP
                CLC
                RETURN
                .pend

;
; Print the current directory entry and move to the next entry
;
; Inputs:
;   MCURSOR = pointer to the beginning of the entry
;
; Outputs:
;   C is set if the directory is not finished, clear otherwise
;
DIR_PRENTRY     .proc
                PHY
                PHP
                TRACE "DIR_PRENTRY"

                setas

                ; Check that we should print the entry

                LDY #0
                LDA [MCURSOR],Y     
                BNE chk_del         ; If the first character is 0, finish listing the directory

                PLP                 ; Return false
                CLC
                PLY
                RETURN

chk_del         CMP #DIR_FILE_DEL   ; Is the entry deleted?
                BNE chk_hide        ; No: check if the entry is hidden
                BRL done            ; Yes: skip the entry... don't print anything

chk_hide        LDY #DIR_FILEATTR
                LDA [MCURSOR],Y     ; Get the attributes
                BIT #DIR_ATTR_HIDE  ; Is it hidden
                BEQ start_pr_name   ; No: go to print the name
                BRL done            ; Yes: just skip the entry

                ; Print the 8 character file name

start_pr_name   LDY #0
pr_name         LDA [MCURSOR],Y     ; Get the character
                BEQ pr_dot          ; If blank, just print the dot
                CALL PRINTC         ; Print the 8 character file name
                INY
                CPY #DIR_FILEEXT    ; End of the name?
                BNE pr_name         ; No: keep printing characters

pr_dot          LDY #DIR_FILEEXT    ; Check the first character of the extension
                LDA [MCURSOR],Y
                BEQ pr_tab1         ; If it's NULL, skip printing the dot
                CMP #CHAR_SP        ; Also if it's a space
                BEQ pr_tab1         ; If it's NULL, skip printing the dot

                LDA #'.'            ; Print a dot
                CALL PRINTC

                ; Print the 3 character file extension

pr_ext          LDA [MCURSOR],Y     ; Print the 3 character file extension
                BEQ pr_tab1         ; If blank, just go to process the attributes
                CALL PRINTC
                INY
                CPY #DIR_FILEATTR
                BNE pr_ext

pr_tab1         LDA #CHAR_TAB       ; Print a TAB
                CALL PRINTC

                ; Print the attributes field

                LDY #DIR_FILEATTR
                LDA [MCURSOR],Y     ; Get the attribute
                BIT #DIR_ATTR_DIR   ; Is it a directory?
                BEQ chk_sys         ; No: skip and check the system flag

                LDA #'D'            ; Yes: print a D
                CALL PRINTC
                LDA [MCURSOR],Y     ; Get the attribute

chk_sys         BIT #DIR_ATTR_SYS   ; Is it a system file?
                BEQ chk_ro

                LDA #'S'            ; Yes: print a S
                CALL PRINTC
                LDA [MCURSOR],Y     ; Get the attribute

chk_ro          BIT #DIR_ATTR_RO    ; Check if it's read-only
                BEQ pr_tab2

                LDA #'R'            ; Yes: Print an R
                CALL PRINTC
                LDA [MCURSOR],Y     ; Get the attribute

pr_tab2         BIT #DIR_ATTR_DIR   ; Check again if it's a directory
                BNE pr_cr           ; If so: don't print size and date

                LDA #CHAR_TAB       ; Print a tab before the size
                CALL PRINTC

                ; Print the size
                setas
                LDA #TYPE_INTEGER
                STA ARGUMENT1
                setal
                LDY #DIR_FILE_SIZE
                LDA [MCURSOR],Y
                STA ARGUMENT1
                INY
                INY
                LDA [MCURSOR],Y
                STA ARGUMENT1+2
                CALL PR_FILESIZE

                LDA #CHAR_TAB       ; Print a tab before the time/date
                CALL PRINTC

                ; Print the date
                LDY #DIR_MOD_DATE
                LDA [MCURSOR],Y
                CALL PR_DATE

                ; Print the time
                LDY #DIR_MOD_TIME
                LDA [MCURSOR],Y
                CALL PR_TIME

pr_cr           setas
                LDA #CHAR_CR        ; Print a new line at the end of the entry
                CALL PRINTC

done            CLC                 ; Advance MCURSOR to the next entry (might be outside the block)
                LDA MCURSOR
                ADC #DIR_ENTRY_SIZE
                STA MCURSOR
                LDA MCURSOR+2
                ADC #0
                STA MCURSOR+2

                PLP
                SEC
                PLY
                RETURN
                .pend

.align $100
DIR_SAMPLE      .text "FILE0001"
                .text "TXT"
                .byte 0             ; Attributes
                .fill 8, 0          ; Reserved
                .word 0             ; Block High
                DIR_TIME 10,20,30   ; Modification time
                DIR_DATE 2020,02,03 ; Modification date
                .word 0             ; Block Low
                .dword 123          ; File size

DIR_SAMPLE2     .text "FILE0002"
                .text "BAT"
                .byte DIR_ATTR_RO   ; Attributes
                .fill 8, 0          ; Reserved
                .word 0             ; Block High
                DIR_TIME 11,21,31   ; Modification time
                DIR_DATE 2020,02,14 ; Modification date
                .word 0             ; Block Low
                .dword 456 * 1024   ; File size

                .text "SYSTEM  "
                .byte 0, 0, 0
                .byte DIR_ATTR_DIR  ; Attributes
                .fill 8, 0          ; Reserved
                .word 0             ; Block High
                DIR_TIME 11,21,31   ; Modification time
                DIR_DATE 2020,02,04 ; Modification date
                .word 0             ; Block Low
                .dword 0            ; File size

                .text "BOOT", 0, 0, 0, 0
                .text "FNX"
                .byte 0                     ; Attributes
                .fill 8, 0                  ; Reserved
                .word 0                     ; Block High
                DIR_TIME 11,21,31           ; Modification time
                DIR_DATE 2020,02,14         ; Modification date
                .word 0                     ; Block Low
                .dword 789 * 1024 * 1024    ; File size

                .fill $20, 0        ; Blank entry to end the directory
