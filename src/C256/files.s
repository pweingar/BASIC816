;;;
;;; C256 specific code for managing files.
;;;

;;
;; A record for a date
;;
FS_DATE     .struct
YEAR        .word ?
MONTH       .byte ?
DAY         .byte ?
            .ends

;;
;; A record of information about a file
;;
FS_FILEREC      .struct
NAME            .fill 8             ; The 8-character name of the file
EXTENSION       .fill 3             ; The 3 character extenion of the file
ATTRIBUTES      .byte ?             ; A byte containing attribute bits about the file
SIZE            .dword ?            ; The size of the file in bytes
HANDLE          .dword ?            ; A "magic" number reprenenting a pointer or handle to the file (not to be used by caller)
NEXT            .dword ?            ; A "magic" number pointing to the next file record (not to be used by caller)
                .ends

.section variables
FS_PATH         .fill 256           ; The path to a file for any file I/O requests
FS_FILE         .dstruct FS_FILEREC ; A record of file information
.send

;
; Request the first file in a directory
;
; Input:
;   FS_PATH contains the path requested
;
; Returns:
;   FS_FILE contains the record about the first file in the directory
;
FS_DIRFIRST     .proc
                PHP
                setdp GLOBAL_VARS
                setxl
                setas

                ; This dummy routine just ignores the path

                LDX #0
copy_loop       LDA @lVFS,X                 ; Copy the first file record
                STA @lFS_FILE,X
                INX
                CPX #24                     ; Length of FS_FILEREC
                BNE copy_loop

                PLP
                RETURN
                .pend

;
; Request the next file in a directory
;
; Input:
;   FS_FILE contains the reference to the current file from the directory
;
; Returns:
;   FS_FILE contains the record about the first file in the directory
;   C set, if we found a file entry, clear if we're done
;
FS_DIRNEXT      .proc
                PHP
                setdp GLOBAL_VARS

                setaxl
                LDX #FS_FILEREC.NEXT        ; Copy the internal NEXT pointer to INDEX
                LDA @lVFS,X
                STA INDEX
                INX
                INX
                LDA @lVFS,X
                STA INDEX+2

                LDA INDEX                   ; Check to see if there is anything there
                BNE copy_next
                LDA INDEX+2
                BNE copy_next

ret_false       PLP                         ; No: return FALSE (carry clear)
                CLC
                RETURN

copy_next       setas
                LDX #0
                LDY #0
copy_loop       LDA [INDEX],Y               ; Copy the next file record to the FS_FILE record
                STA @lFS_FILE,X
                INX
                INY
                CPX #24                     ; Length of FS_FILEREC
                BNE copy_loop

ret_true        PLP                         ; And return TRUE (carry set)
                SEC
                RETURN
                .pend

;
; Find the file record for the file that matches the given path
;
; Inputs:
;   FS_PATH = the path to the file desired
;
; Outputs:
;   FS_FILEREC = the record of the file found
;   C is set, if the file is found, clear otherwise
;
FS_FINDFILE     .proc
                PHP
                PHB

                setdbr `FS_PATH

                ; TODO: support nested directories

                CALL FS_DIRFIRST        ; Get the first directory entry

check_names     setas
                LDY #0
                LDX #FS_FILEREC.NAME
chk_name_loop   LDA FS_FILE,X           ; Get the character in the record
                BEQ check_dot           ; If it's 0, check for a dot in the search path
                CMP FS_PATH,Y           ; Compare it to the source name
                BNE not_matched         ; If not equal, try the next entry

                INX
                INY
                CPX #8                  ; Have we checked the last character of the name?
                BNE chk_name_loop       ; No: check the next character in the name

check_ext       INY                     ; Skip over the dot
check_ext2      LDX #FS_FILEREC.EXTENSION
chk_ext_loop    LDA FS_FILE,X           ; Get the extension character in the file record
                BEQ check_done          ; If NUL, check that the path has a NULL too
                CMP FS_PATH,Y           ; Compare it to the source extension
                BNE not_matched         ; If not equal, try the next entry

                INX
                INY
                CPX #3                  ; Have we checked the last character of the extension?
                BNE chk_ext_loop        ; No: keep checking

ret_true        PLB
                PLP                     ; Return true
                SEC
                RETURN

check_done      LDA FS_PATH,Y           ; Check the character in the path
                BEQ ret_true            ; Is it NUL (end of path?): Yes: we have a matching record
                BRA not_matched         ; No: try the next record

check_dot       LDA FS_PATH,Y           ; Is the current character in the path a dot?
                CMP #'.'
                BEQ check_ext           ; Yes: we have a match so far, check the extension

not_matched     CALL FS_DIRNEXT         ; Try to get the next entry
                BCS check_names         ; If found, check it

ret_false       PLB
                PLP
                CLC
                RETURN
                .pend

.databank 0

;
; Load a file into memory
;
; Input:
;   FS_PATH contains the path requested
;   MARG2 = the destination address for the load
;
; Outputs:
;   C is set if successful, clear otherwise
FS_LOAD         .proc
                PHP
                setdp GLOBAL_VARS

                setaxl
                CALL FS_FINDFILE        ; Try to find the file
                BCC ret_false           ; If failure: return false

                LDX #FS_FILEREC.HANDLE
                LDA FS_FILE,X
                STA INDEX
                LDA FS_FILE+2,X
                STA INDEX+2

                setas
copy_loop       LDA [INDEX]             ; Get the current byte of the file
                STA [MARG2]             ; Store it at the destination
                BEQ ret_true            ; If it's 0 (END-OF-FILE): return

                setal
                INC INDEX               ; Point to the next source byte
                BNE inc_MARG2
                INC INDEX+2

inc_MARG2       INC MARG2               ; Point to the next destination address
                BNE copy_loop
                INC MARG2+2
                BRA copy_loop

ret_true        PLP                     ; Return success
                SEC
                RETURN

ret_false       PLP                     ; Return failure
                CLC
                RETURN
                .pend

;
; Save the contents of memory to a file
;
; Inputs:
;   FS_PATH = the full name of the file to create
;   MARG2 = the starting address of the memory to save
;   MARG3 = the number of bytes to write
;
FS_SAVE         .proc
                PHP
                setdp GLOBAL_VARS
                PLP
                RETURN
                .pend

.section vfs_block
                ; Sample Hello, World program
HELLO_RECORD    .text "hello", 0, 0, 0
                .text "bas"
                .byte 0
                .dword HELLO_END - HELLO_START
                .dword HELLO_START
                .dword BYE_RECORD
HELLO_START     .text "10 PRINT ",CHAR_DQUOTE,"Hello, world!",CHAR_DQUOTE,13
                .text "20 GOTO 10",13
                .text "30 END",13
HELLO_END       .byte 0

                ; Sample Goodbye, World program
BYE_RECORD      .text "goodbye", 0
                .text "bas"
                .byte 0
                .dword BYE_END - BYE_START
                .dword BYE_START
                .dword 0
BYE_START       .text "10 PRINT ",CHAR_DQUOTE,"Goodbye, cruel world!",CHAR_DQUOTE,13
                .text "20 GOTO 10",13
                .text "30 END",13
BYE_END         .byte 0
.send
