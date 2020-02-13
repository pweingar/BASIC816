;;;
;;; File Descriptors -- This is the low level access to the OS/BIOS/Kernel file systems
;;;
;;; This file wraps around the C256 kernel
;;;
;;; Paths for block devices
;;; @dev:dir1/dir2/.../filename.ext
;;;
;;; dev = F for floppy
;;;       S for SD card
;;;       H0 for hard drive partion 0
;;;       H1 for hard drive partion 1, ...
;;;
;;; @F:HELLO.TXT
;;; @S:/SYSTEM/FLASH.FNX
;;; @H0:/AUTORUN.BAS
;;;

FD_BLOCK_SIZE = 512

;
; File descriptors
;

S_FILEDESC      .struct
DEVICE          .byte ?     ; Device number (0 = screen/keyboard, 1 = COM1, etc. )
FLAGS           .byte ?     ; 
BUFFADDR        .long ?     ; Pointer to the buffer for this file descriptor (if relevant)
PATH            .long ?     ; Pointer to the path for the file (if relevant)
CURRENTBLOCK    .dword ?    ; The current block being read
CURSOR          .dword ?    ; The file pointer (number of the byte to be read)
                            ; BBBBBBBB BBBBBBBB BBBBBBBc cccccccc
                            ; where B = the block index, and c = the index to the byte within the current block
                .send

FD_FLG_OPEN = $80           ; The file descriptor is open
FD_FLG_READ = $01           ; The file descriptor may be read
FD_FLG_WRITE = $02          ; The file descriptor may be written
FD_FLG_BUFFERED = $04       ; The file descriptor is buffered
FD_FLG_FILE = $06           ; THe file descriptor has a path

;
; File descriptor storage
;

.segment variables
.align 256
FILE_DESCS      .fill 256               ; Block of memory to hold the file descriptors (should yield 8 FDs)
FILE_BLOCKS     .fill 8 * FD_BLOCK_SIZE ; R/W buffers, one per file descriptor
.send

;
; Open a file descriptor
;
; When reading from a block type devices, fill the FD's buffer with the first block
;
; Inputs:
;   A = mode (e.g. read, write)
;   B:X = ASCII-Z string containing the path to the file to open
;
; Returns:
;   A = file descriptor ID (error code on error)
;   C is set on success, clear on error
;
FD_OPEN         .proc
                PHP
                PLP
                RETURN
                .pend

;
; Close a file descriptor
;
; For block devices, if the file is open for 
;
; Inputs:
;   A = The file descriptor to close
;
; Returns:
;   A = error code (if there was an error)
;   C is set on success, clear on error
;
FD_CLOSE        .proc
                PHP
                PLP
                RETURN
                .pend

;
; Read a block of data from a file descriptor
;
; Inputs:
;   A = the file handle to read from
;   B:X = the address to write to
;   Y = the number of bytes to read
;
; Returns:
;   A = number of bytes read on success, error code on failure
;   C is set on success, clear on error
;
FD_READ         .proc
                PHP
                PLP
                RETURN
                .pend

;
; Write a block of data to a file descriptor
;
; Inputs:
;   A = the file handle to write to
;   B:X = the address to read the data from
;   Y = the number of bytes to write
;
; Returns:
;   A = error code (if there was an error)
;   C is set on success, clear on error
;
FD_WRITE        .proc
                PHP
                PLP
                RETURN
                .pend
                