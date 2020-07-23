;;;
;;; Commands and statements for the FAT file system
;;;
;;; Commands:
;;; LOAD <path> -- load the BASIC file (ASCII text) into memory, replacing th current program
;;; BLOAD <path> [, <address>] -- Load a binary file into memory. If provided, <address> will
;;;     determine where the file loads. However, certain file types will contain their own destination
;;;     address data, and BLOAD will honor that.
;;; BRUN <path> -- loads a binary file into memory and starts executing the code
;;;     starting at the first byte loaded. Note that his only works for executable types. Currently,
;;;     that means only PGX
;;; SAVE <path> -- Save the current BASIC program as an ASCII text file.
;;; BSAVE <path>, <start address>, <end address> -- Save the memory from <start address>
;;;     to <end address> (inclusive) to a file.
;;; DIR -- List the directory (currently only works with the root directory of the SDC)
;;; DEL <path> -- delete a file
;;;

; Directory entry
DIRENTRY                .struct
SHORTNAME               .fill 11        ; $00 - The short name of the file (8 name, 3 extension)
ATTRIBUTE               .byte ?         ; $0B - The attribute bits
IGNORED1                .word ?         ; $0C - Unused (by us) bytes
CREATE_TIME             .word ?         ; $0E - Creation time
CREATE_DATE             .word ?         ; $10 - Creation date
ACCESS_DATE             .word ?         ; $12 - Last access date
CLUSTER_H               .word ?         ; $14 - High word of the first cluster #
MODIFIED_TIME           .word ?         ; $16 - Last modified time
MODIFIED_DATE           .word ?         ; $18 - Last modified date
CLUSTER_L               .word ?         ; $1A - Low word of the first cluster #
SIZE                    .dword ?        ; $1C - The size of the file (in bytes)
                        .ends

; Directory entry attribute flags

DOS_ATTR_RO = $01                       ; File is read-only
DOS_ATTR_HIDDEN = $02                   ; File is hidden
DOS_ATTR_SYSTEM = $04                   ; File is a system file
DOS_ATTR_VOLUME = $08                   ; Entry is the volume label
DOS_ATTR_DIR = $10                      ; Entry is a directory
DOS_ATTR_ARCH = $20                     ; Entry has changed since last backup
DOS_ATTR_LONGNAME = $0F                 ; Entry is the long file name

DOS_DIR_ENT_UNUSED = $E5                ; Marker for an unused directory entry 

; File Descriptor -- Used as parameter for higher level DOS functions
FILEDESC            .struct
STATUS              .byte ?             ; The status flags of the file descriptor (open, closed, error, EOF, etc.)
DEV                 .byte ?             ; The ID of the device holding the file
PATH                .dword ?            ; Pointer to a NULL terminated path string
CLUSTER             .dword ?            ; The current cluster of the file.
FIRST_CLUSTER       .dword ?            ; The ID of the first cluster in the file
BUFFER              .dword ?            ; Pointer to a cluster-sized buffer
FILESIZE            .dword ?            ; The size of the file
CREATE_DATE         .word ?             ; The creation date of the file
CREATE_TIME         .word ?             ; The creation time of the file
MODIFIED_DATE       .word ?             ; The modification date of the file
MODIFIED_TIME       .word ?             ; The modification time of the file
                    .ends

; File descriptor status flags

FD_STAT_READ = $01                      ; The file is readable
FD_STAT_WRITE = $02                     ; The file is writable
FD_STAT_OPEN = $40                      ; The file is open
FD_STAT_ERROR = $60                     ; The file is in an error condition
FD_STAT_EOF = $80                       ; The file cursor is at the end of the file

DIR_TIME        .macro hour, minute, second
                .word \hour << 11 | \minute << 5 | \second
                .endm

DIR_DATE        .macro year, month, day
                .word (\year - 1980) << 9 | \month << 5 | \day 
                .endm

;
; DOS High Memory Variables
;
.section variables
CLUSTER_BUFF    .fill 512           ; A buffer for cluster read/write operations
FD_IN           .dstruct FILEDESC   ; A file descriptor for input operations
.send

;
; Print a FAT file size
;
; Inputs:
;   ARGUMENT1 = the file size to print
;
PR_FILESIZE     .proc
                PHX
                PHD
                PHP

                setdp GLOBAL_VARS

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
                PLD
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
                PHD
                PHP

                setdp GLOBAL_VARS

                setal

                CALL ITOS
                CALL S_PAD2
                LDA STRPTR          ; Copy the pointer to the string to ARGUMENT1
                STA ARGUMENT1
                LDA STRPTR+2
                STA ARGUMENT1+2
                CALL PR_STRING      ; And print it
                
                PLP
                PLD
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
                PHD
                PHP

                setdp GLOBAL_VARS

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
                PLD
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
                PHD
                PHP

                setdp GLOBAL_VARS

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
                PLD
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
                PHD
                PHP

                setdp GLOBAL_VARS

                setal

                ; Print the time

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
                PLD
                RETURN
                .pend

;
; Print out a directory listing
;
CMD_DIR         .proc
                PHD
                PHP
                TRACE "CMD_DIR"

                setaxl
                LDA #0                      ; Zero out the pagination line count
                STA @l LINECOUNT
                STA @l LINECOUNT+2

                setas
                CALL PEEK_TOK               ; Check to see what the next token is
                CMP #0
                BEQ set_null                ; If none provided, set the path to empty

                ; Set up the file descriptor based on the provided string

                CALL EVALEXPR               ; Try to evaluate the file path
                CALL ASS_ARG1_STR           ; Make sure it is a string

                BRA set_fd

set_null        ; Set up the file descriptor for the default directory

                setal
                LDA #0                      ; Set ARGUMENT1 to the NULL string
                STA ARGUMENT1
                STA ARGUMENT1+2
                setas
                LDA #TYPE_STRING
                STA ARGTYPE1
                setal

set_fd          CALL SETFILEDESC            ; Set the file description based on the argument
                JSL FK_DIROPEN              ; Open up the directory
                BCS pr_entry

                CALL SET_DOSSTAT            ; Set DOSSTAT and BIOSSTAT variables
                THROW ERR_DIRECTORY         ; Throw a directory error

pr_entry        setdp SDOS_VARIABLES
                setas
                LDY #DIRENTRY.SHORTNAME     ; Start with the file name
                LDA [DOS_DIR_PTR],Y         ; Get the initial character of the name
                BNE chk_unused
                BRL done                    ; If it's NULL, we're done

chk_unused      CMP #DOS_DIR_ENT_UNUSED     ; Is it the unusued code?
                BNE chk_attributes
                BRL next_entry              ; Yes: go to the next entry

chk_attributes  LDY #DIRENTRY.ATTRIBUTE     
                LDA [DOS_DIR_PTR],Y         ; Get the attribute byte

                BIT #DOS_ATTR_VOLUME        ; Is it a volume?
                BEQ chk_hidden
                BRL pr_volume               ; Print the volume label

chk_hidden      BIT #DOS_ATTR_HIDDEN        ; Is it a hidden file?
                BEQ chk_long
                BRL next_entry              ; Yes: go to the next entry

chk_long        AND #DOS_ATTR_LONGNAME      ; Is it a long file name entry?
                CMP #DOS_ATTR_LONGNAME
                BNE get_short_name
                BRL next_entry              ; Yes: go to the next entry

get_short_name  LDY #DIRENTRY.SHORTNAME     ; Starting with the first character of the file...
pr_name_loop    LDA [DOS_DIR_PTR],Y         ; Get a character of the name
                CMP #CHAR_SP                ; Is it a blank?
                BEQ pr_dot                  ; Yes: end the name and print the dot
                CALL PRINTC                 ; Otherwise: print it.
                INY                         ; Move to the next character
                CPY #DIRENTRY.SHORTNAME+8   ; Are we at the end of the name portion?
                BNE pr_name_loop            ; No: print this new character

pr_dot          LDY #DIRENTRY.SHORTNAME+8
                LDA [DOS_DIR_PTR],Y         ; Get the first characater of the extension
                CMP #CHAR_SP                ; Is it a space
                BEQ pr_tab1                 ; Yes: skip to the next field

                LDA #'.'                    ; Print the dot separator
                CALL PRINTC

                LDY #DIRENTRY.SHORTNAME+8   ; Move to the first of the extension characters
pr_ext_loop     LDA [DOS_DIR_PTR],Y         ; Get a character of the name
                CMP #CHAR_SP                ; Is it a blank?
                BEQ pr_tab1                 ; Yes: print a tab
                JSR PRINTC                  ; Otherwise: print it.
                INY                         ; Move to the next character
                CPY #DIRENTRY.SHORTNAME+11  ; Are we at the end of the extension portion?
                BNE pr_ext_loop             ; No: print this new character

pr_tab1         LDA #CHAR_TAB               ; Print a TAB
                CALL PRINTC

                ; Print type flag

                LDY #DIRENTRY.ATTRIBUTE
                LDA [DOS_DIR_PTR],Y         ; Get the attribute

                BIT #DOS_ATTR_VOLUME        ; Is it a volume?
                BNE end_entry               ; Yes: we're done printing this entry

chk_read        BIT #DOS_ATTR_RO            ; Is it a read-only file?
                BEQ chk_system
                LDA #'R'                    ; Yes: print an R
                CALL PRINTC

chk_system      BIT #DOS_ATTR_SYSTEM        ; Is it System file?
                BEQ chk_directory
                LDA #'S'                    ; Yes: print an S
                CALL PRINTC

chk_directory   BIT #DOS_ATTR_DIR           ; Is it a directory?
                BEQ pr_tab2
                LDA #'D'                    ; Yes: print a D
                CALL PRINTC

pr_tab2         LDA #CHAR_TAB               ; Print a TAB
                CALL PRINTC

                ; Print the file size   
                setal
                LDY #DIRENTRY.SIZE
                LDA [DOS_DIR_PTR],Y         ; Get the file size
                STA @l ARGUMENT1
                INY
                INY
                LDA [DOS_DIR_PTR],Y
                STA @l ARGUMENT1+2

                setas
                LDA #TYPE_INTEGER
                STA @l ARGTYPE1

                CALL PR_FILESIZE            ; ... and print it       

                setas
                LDA #CHAR_TAB               ; Print a TAB
                CALL PRINTC    

                ; Print date-time

pr_date_time    setal
                LDY #DIRENTRY.CREATE_DATE
                LDA [DOS_DIR_PTR],Y         ; Get the creation date
                CALL PR_DATE                ; ... and print it

                setas
                LDA #' '
                CALL PRINTC

                setal
                LDY #DIRENTRY.CREATE_TIME
                LDA [DOS_DIR_PTR],Y         ; Get the creation time
                CALL PR_TIME                ; ... and print it 

end_entry       CALL PRINTCR
next_entry      CALL PAGINATE               ; Pause the listing, if necessary
                JSL FK_DIRNEXT
                BCC done
                BRL pr_entry

done            CALL SET_DOSSTAT            ; Set DOSSTAT and BIOSSTAT variables

                setdp GLOBAL_VARS
                CALL SKIPSTMT
                CALL PRINTCR

                PLP
                PLD
                RETURN

pr_volume       setdp SDOS_VARIABLES

                setas
                AND #DOS_ATTR_LONGNAME      ; Is it a long file name entry?
                CMP #DOS_ATTR_LONGNAME
                BEQ next_entry              ; Yes: skip it
                
pr_lbracket     LDA #'['
                CALL PRINTC

                LDY #DIRENTRY.SHORTNAME     ; Starting with the first character of the file...
pr_vol_loop     LDA [DOS_DIR_PTR],Y         ; Get a character of the name
                CMP #CHAR_SP                ; Is it a blank?
                BEQ pr_rbracket             ; Yes: end the name and print the dot
                CALL PRINTC                 ; Otherwise: print it.
                INY                         ; Move to the next character
                CPY #DIRENTRY.SHORTNAME+8   ; Are we at the end of the name portion?
                BNE pr_vol_loop             ; No: print this new character

pr_rbracket     LDA #']'                    ; Print a close bracket
                CALL PRINTC
                BRA end_entry               ; And try to get the next entry

                .pend

.dpage GLOBAL_VARS

;
; Set up a file descriptor
;
; Inputs:
;   ARGUMENT1 = a string containing the path to use
;
; Outputs:
;   DOS_FD_PTR = pointer to a file descriptor with everything zeroed
;
SETFILEDESC     .proc
                PHD
                PHP

                setdp SDOS_VARIABLES

                setaxl
                LDA #<>FD_IN            ; Point to the file descriptor
                STA DOS_FD_PTR
                LDA #`FD_IN
                STA DOS_FD_PTR+2

                LDY #0                  ; Fille the file descriptor with 0
                setas
                LDA #0
zero_loop       STA [DOS_FD_PTR],Y
                INY
                CPY #SIZE(FILEDESC)
                BNE zero_loop

                setal
                LDA #<>CLUSTER_BUFF     ; Point to the cluster buffer
                STA @l FD_IN.BUFFER
                LDA #`CLUSTER_BUFF
                STA @l FD_IN.BUFFER+2

                LDA @l ARGUMENT1        ; Point the file desriptor to the path
                STA @l FD_IN.PATH
                LDA @l ARGUMENT1+2
                STA @l FD_IN.PATH+2

                PLP
                PLD
                RETURN
                .pend

.dpage GLOBAL_VARS

;
; Load a binary file from the file system into memory
; BLOAD <path> [, <address>]
;
S_BLOAD         .proc
                PHP
                TRACE "S_BLOAD"

                setaxl

                CALL SKIPWS
                CALL EVALEXPR               ; Try to evaluate the file path
                CALL ASS_ARG1_STR           ; Make sure it is a string
                CALL SETFILEDESC            ; Set up a file descriptor
                
                ; Is there a destination address
                setas
                LDA #','
                STA TARGETTOK
                CALL OPT_TOK
                BCS get_dest

                setal
                LDA #$FFFF                  ; Set destination address to something "safe"
                STA @l DOS_DST_PTR
                STA @l DOS_DST_PTR+2
                BRA do_load

get_dest        CALL INCBIP 
                CALL EVALEXPR               ; Yes: Try to get the destination address
                CALL ASS_ARG1_INT

                setal
                LDA ARGUMENT1               ; Set the destination address
                STA @l DOS_DST_PTR
                LDA ARGUMENT1+2
                STA @l DOS_DST_PTR+2

do_load         JSL FK_LOAD                 ; Attempt to load the file
                BCS done

                THROW ERR_LOAD

done            PLP
                RETURN
                .pend

;
; Set the variables "DOSSTAT", "BIOSSTAT"
;
; Inputs:
;   A = value for ERR
;   LINENUM = the value for ERL
;
SET_DOSSTAT     .proc
                PHB
                PHD
                PHP

                setdp GLOBAL_VARS
                setdbr BASIC_BANK

                setas
                LDA @l DOS_STATUS           ; Get the DOS status code
                STA ARGUMENT1
                LDA #0
                STA ARGUMENT1+1
                STA ARGUMENT1+2
                STA ARGUMENT1+3
                LDA #TYPE_INTEGER
                STA ARGTYPE1

                STA TOFINDTYPE              ; Indicate what variable to set (DOSSTAT)
                LDA #`dosstat_name
                STA TOFIND+2
                setal
                LDA #<>dosstat_name
                STA TOFIND

                CALL VAR_SET                ; Set the variable

                setas
                LDA @l BIOS_STATUS          ; Get the BIOS status code
                STA ARGUMENT1
                LDA #0
                STA ARGUMENT1+1
                STA ARGUMENT1+2
                STA ARGUMENT1+3
                LDA #TYPE_INTEGER
                STA ARGTYPE1

                STA TOFINDTYPE              ; Indicate what variable to set (BIOSSTAT)
                LDA #`biosstat_name
                STA TOFIND+2
                setal
                LDA #<>biosstat_name
                STA TOFIND

                CALL VAR_SET                ; Set the variable

                PLP
                PLD
                PLB
                RETURN
dosstat_name    .null "DOSSTAT"
biosstat_name   .null "BIOSSTAT"
                .pend

;
; Load a binary file from the file system into memory and try to execute it
; BRUN <path>
;
CMD_BRUN        .proc
                PHP
                TRACE "S_BRUN"

                setaxl

                CALL SKIPWS
                CALL EVALEXPR               ; Try to evaluate the file path
                CALL ASS_ARG1_STR           ; Make sure it is a string

                LDA ARGUMENT1
                STA @l DOS_RUN_PARAM
                LDA ARGUMENT1+2
                STA @l DOS_RUN_PARAM+2

                LDA #$FFFF
                STA @l DOS_DST_PTR
                STA @l DOS_DST_PTR+2

                JSL FK_RUN                  ; Attempt to run the file
                BCS done                    ; If we got it: try to execute it

                CALL SET_ERRERL             ; Set the ERR and ERL variables based on the return result
                CALL SET_DOSSTAT            ; Set DOSSTAT and BIOSSTAT variables
                THROW ERR_LOAD

done            CALL SET_ERRERL             ; Set the ERR and ERL variables based on the return result
                PLP
                RETURN
                .pend
    
;
; Load a BASIC file from the file system into memory
; LOAD <path>
;
CMD_LOAD        .proc
                PHP
                TRACE "CMD_LOAD"

                setaxl

                CALL SKIPWS
                CALL EVALEXPR               ; Try to evaluate the file path
                CALL ASS_ARG1_STR           ; Make sure it is a string
                CALL SETFILEDESC            ; Set up a file descriptor

                LDA #<>LOADBLOCK
                STA @l DOS_DST_PTR
                LDA #`LOADBLOCK
                STA @l DOS_DST_PTR+2        ; Set the destination address

                CALL CMD_NEW                ; Call NEW to clear the program area

                JSL FK_LOAD                 ; Attempt to load the file
                BCS start_tokenize          ; If we got it: start tokenizing

                CALL SET_DOSSTAT            ; Set DOSSTAT and BIOSSTAT variables
                THROW ERR_LOAD

                ; Put a 0 at the end of the loaded data.

start_tokenize  CALL SET_DOSSTAT            ; Set DOSSTAT and BIOSSTAT variables

                setal
                LDX #FILEDESC.FILESIZE
                CLC                         ; Set MTEMP to point to the byte after the file
                LDA FD_IN,X
                ADC #<>LOADBLOCK
                STA MTEMP
                LDA FD_IN+2,X
                ADC #`LOADBLOCK
                STA MTEMP+2

                setas
                LDA #0
                STA [MTEMP]                 ; Write a NULL right after the file

                setal
                LDA #<>LOADBLOCK            ; Set MCURSOR to the begining of the loaded data
                STA MCURSOR
                LDA #`LOADBLOCK
                STA MCURSOR+2

copy_line       LDX #0
copy_char       setas
                LDA [MCURSOR]
                BEQ clean_up                ; If the character is 0, we're done
                CMP #CHAR_CR                ; If it is new line...
                BEQ do_process              ; ... we want to process the line
                CMP #CHAR_LF                ; If it is a line feed...
                BEQ next_char               ; ... we want to skip it

                STA INPUTBUF,X              ; Otherwise, copy the character to the input buffer
                INX

next_char       setal
                INC MCURSOR                 ; Advance the input cursor
                BNE copy_char
                INC MCURSOR+2
                BRA copy_char

do_process      setas
                LDA #0                      ; Put a 0 at the end of the input buffer
                STA INPUTBUF,X

                CALL PROCESS                ; Process the line.
                
                INC MCURSOR                 ; Try again with the next line
                BNE copy_line
                INC MCURSOR+2
                BRA copy_line

clean_up        CPX #0                      ; Is there data in the INPUTBUF?
                BEQ done                    ; No: just return

                setas
                LDA #0                      ; Make sure there is a trailing NULL
                STA INPUTBUF,X
                CALL PROCESS                ; Process the line

done            PLP
                RETURN
                .pend

;
; BSAVE <path>, <start>, <end>
; Save a block of memory running from <start> through <end> to the file <path>
;
S_BSAVE         .proc
                PHP
                TRACE "S_BSAVE"

                setaxl

                CALL SKIPWS
                CALL EVALEXPR               ; Try to evaluate the file path
                CALL ASS_ARG1_STR           ; Make sure it is a string
                CALL SETFILEDESC            ; Set up a file descriptor

                setas
                LDA #','
                CALL EXPECT_TOK             ; Get the next parameter
                setal
                CALL EVALEXPR               ; Try to evaluate the start address
                CALL ASS_ARG1_INT           ; Make sure it is an integer  

                LDA ARGUMENT1               ; Put that address in DOS_SRC_PTR
                STA @l DOS_SRC_PTR
                LDA ARGUMENT1+2
                STA @l DOS_SRC_PTR+2           

                setas
                LDA #','
                setal
                CALL EXPECT_TOK             ; Get the next parameter
                CALL EVALEXPR               ; Try to evaluate the end address
                CALL ASS_ARG1_INT           ; Make sure it is an integer    

                LDA ARGUMENT1               ; Put that address in DOS_END_PTR
                STA @l DOS_END_PTR
                LDA ARGUMENT1+2
                STA @l DOS_END_PTR+2

                JSL FK_SAVE                 ; Attempt to save the memory to file.
                BCS done

                CALL SET_DOSSTAT            ; Set DOSSTAT and BIOSSTAT variables
                THROW ERR_SAVE              ; Throw an error that we couldn't save

done            CALL SET_DOSSTAT            ; Set DOSSTAT and BIOSSTAT variables

                PLP
                RETURN
                .pend

;
; Copy the string in ARGUMENT1 to DOS_PATH_BUFF
;
COPY2PATHBUF    .proc
                PHX
                PHY
                PHP

                LDX #0
                LDY #0
                setas
loop            LDA [ARGUMENT1],Y           ; Copy the path to the DOS_PATH_BUFF
                STA DOS_PATH_BUFF,X
                BEQ done
                INX
                INY
                BRA loop

done            PLP
                PLY
                PLX
                RETURN
                .pend

;
; SAVE <path>
; Saves the current program as an ASCIIZ file
;
CMD_SAVE        .proc
                PHP
                TRACE "CMD_SAVE"

                setaxl

                CALL SKIPWS
                CALL EVALEXPR               ; Try to evaluate the file path
                CALL ASS_ARG1_STR           ; Make sure it is a string
                CALL SETFILEDESC            ; Set up a file descriptor

                ; Set up the output memory buffer
                LDA #<>LOADBLOCK
                STA OBUFFER
                setas
                LDA #`LOADBLOCK
                STA OBUFFER+2

                LDA #DEV_BUFFER             ; Set up output for the buffer
                STA BCONSOLE

                setal
                LDA #0
                STA OBUFFIDX

                LDA #$FFFF
                STA OBUFFSIZE

                ; List the entire file
                setal
                LDA #0                      ; Set start line number to 0
                STA MARG1
                STA MARG1+2

                LDA #$FFFF                  ; Set end line number to MAXINT
                STA MARG2
                LDA #$7FFF
                STA MARG2+2

                CALL LISTPROG               ; List the file

                ; Close the memory buffer
                setas
                LDA #DEV_SCREEN             ; Restore output to the screen
                STA BCONSOLE

                ; Save the buffer to the block device
                setal
                DEC OBUFFIDX                ; OBUFFIDX points to the next free byte... so pull it in one

                CLC                         ; Set the range of memory to save
                LDA #<>LOADBLOCK
                STA @l DOS_SRC_PTR
                ADC OBUFFIDX
                STA @l DOS_END_PTR
                LDA #`LOADBLOCK
                STA @l DOS_SRC_PTR+2
                ADC #0
                STA @l DOS_END_PTR+2

                ; JSR PRTRACE
                ; BRA do_save
                ; .null "Calling: FK_SAVE", 13

do_save         JSL FK_SAVE                 ; Attempt to save the file
                BCS done
                CALL SET_DOSSTAT            ; Set DOSSTAT and BIOSSTAT variables
                THROW ERR_SAVE              ; Throw an error if there was a problem

done            CALL SET_DOSSTAT            ; Set DOSSTAT and BIOSSTAT variables

                PLP
                RETURN
                .pend

;
; DEL <path>
; Delete a file
;
S_DEL           .proc
                PHP
                TRACE "S_DEL"

                setaxl

                CALL SKIPWS
                CALL EVALEXPR               ; Try to evaluate the file path
                CALL ASS_ARG1_STR           ; Make sure it is a string
                CALL COPY2PATHBUF           ; Copy the file name to the path buffer

path_loaded     JSL FK_DELETE               ; Try to delete the file
                BCS done
                CALL SET_DOSSTAT            ; Set DOSSTAT and BIOSSTAT variables
                THROW ERR_DELETE            ; If error: throw delete error

done            CALL SET_DOSSTAT            ; Set DOSSTAT and BIOSSTAT variables

                PLP
                RETURN
                .pend

;
; Validate that the character in A is valid for a FAT file name
; Also converts the character to upper case.
;
; Inputs:
;   A = the character to check (assumed to be 8-bits)
;
; Outputs:
;   A = the character
;   C set if ok, clear if false
;
VALIDFILECHAR   .proc
                PHX
                PHP

                setas
                CMP #'a'                    ; Is it lower case?
                BLT chk_space
                CMP #'z'+1
                BGE chk_space

                AND #%11011111              ; Yes: convert to upper case
                BRA ret_valid

chk_space       CMP #CHAR_SP            ; Is it a control code?
                BLT is_invalid          ; Yes: it's invalid

                LDX #0                  ; See if it's in the list of invalids
loop            CMP invalid_chars,X
                BEQ is_invalid
                INX
                CPX #15                 ; # of invalid characters
                BNE loop

ret_valid       PLP
                SEC
                PLX
                RTL

is_invalid      PLP
                CLC
                PLX
                RTL

invalid_chars   .text "*+,/:;<=>?\[]|",CHAR_DQUOTE
                .pend

;
; RENAME <path>, <filename>
; Renames a file
;
S_RENAME        .proc
                PHP
                TRACE "S_RENAME"

                setdp GLOBAL_VARS

                setaxl
                CALL EVALEXPR               ; Try to evaluate the file path
                CALL ASS_ARG1_STR           ; Make sure it is a string
                CALL COPY2PATHBUF           ; Copy the file name to the path buffer

                JSL FK_DIRREAD              ; Try to read the file
                BCS get_new_name            ; If ok: get the new name
                CALL SET_DOSSTAT            ; Set DOSSTAT and BIOSSTAT variables
                THROW ERR_FILENOTFOUND      ; Throw a file not found error

get_new_name    setas
                LDA #','
                CALL EXPECT_TOK             ; Get the next parameter
                setal
                CALL EVALEXPR               ; Try to evaluate the new file name
                CALL ASS_ARG1_STR           ; Make sure it is a string

                LDA DOS_DIR_PTR
                STA INDEX
                LDA DOS_DIR_PTR+2
                STA INDEX+2

                setas
                LDX #0
                LDA #CHAR_SP                ; We'll use MLINEBUFF as temporary name storage
blank_loop      STA MLINEBUF,X              ; Fill it with blanks
                INX
                CPX #11
                BNE blank_loop

                LDX #0
                LDY #0
name_loop       LDA [ARGUMENT1],Y           ; Get the character of the new name
                BEQ copy_short_name         ; If end-of-string: copy what we have
                CMP #'.'                    ; Is it a dot?
                BEQ skip_dot                ; Yes: move on to the extension characters

                JSL VALIDFILECHAR           ; Make sure the character is valid and uppercase
                BCS save_nm_char
                THROW ERR_ARGUMENT          ; Otherwise, throw an illegal argument error

save_nm_char    STA MLINEBUF,X              ; Otherwise: copy it
                INY
                INX
                CPY #8
                BNE name_loop
                BRA do_ext

skip_dot        INY

do_ext          LDX #8
ext_loop        LDA [ARGUMENT1],Y           ; Get the character of the new extension
                BEQ copy_short_name         ; If end-of-string: copy what we have

                JSL VALIDFILECHAR           ; Make sure the character is valid and uppercase
                BCS save_ext_char
                CALL SET_DOSSTAT            ; Set DOSSTAT and BIOSSTAT variables
                THROW ERR_ARGUMENT          ; Otherwise, throw an illegal argument error

save_ext_char   STA MLINEBUF,X              ; Otherwise: copy it
                INY
                INX
                CPY #11
                BNE ext_loop

copy_short_name LDX #0                      ; Copy the short name we built to the directory entry
                LDY #DIRENTRY.SHORTNAME
copy_loop       LDA MLINEBUF,X
                STA [INDEX],Y
                INX
                INY
                CPY #11
                BNE copy_loop

                JSL FK_DIRWRITE             ; Write the directory entry back
                BCS done
                CALL SET_DOSSTAT            ; Set DOSSTAT and BIOSSTAT variables
                THROW ERR_DIRNOTWRITE       ; Throw an error

done            CALL SET_DOSSTAT            ; Set DOSSTAT and BIOSSTAT variables

                PLP
                RETURN
                .pend

;
; COPY <source path>, <destination path>
; Copies a file
;
S_COPY          .proc
                PHP
                TRACE "S_COPY"

                setdp GLOBAL_VARS

                setaxl
                CALL EVALEXPR               ; Try to evaluate the source file path
                CALL ASS_ARG1_STR           ; Make sure it is a string
                
                LDA ARGUMENT1               ; Set the source path
                STA @l DOS_STR1_PTR
                LDA ARGUMENT1+2
                STA @l DOS_STR1_PTR+2

                setas
                LDA #','
                CALL EXPECT_TOK             ; Get the next parameter
                setal
                CALL EVALEXPR               ; Try to evaluate the new file name
                CALL ASS_ARG1_STR           ; Make sure it is a string

                LDA ARGUMENT1               ; Set the source path
                STA @l DOS_STR2_PTR
                LDA ARGUMENT1+2
                STA @l DOS_STR2_PTR+2

                JSL FK_COPY                 ; Attempt to copy the file
                BCS done

                THROW ERR_NOTCOPIED        ; If failed: throw a file copy error

done            PLP
                RETURN
                .pend
