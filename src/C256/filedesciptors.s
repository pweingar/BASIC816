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
; File descriptor offsets
;

FD_SIZE = 32                ; Size allocated for file descriptors (32 bytes)
FD_DEVICE = $00             ; Offset to the device code (1 byte)
FD_ATTR = $01               ; Offset to the attribute for the file descriptor (1 byte)
FD_PATH = $02               ; Offset to the pointer to the path string (4 bytes)
FD_NEXT_BLK = $06           ; Offset to the number of the next block for reading (4 bytes)
FD_FILE_SIZE = $0A          ; Offset to the size of the file in bytes (4 bytes)
FD_CURSOR = $0E             ; Offset to the current position in the file (4 byte)

FD_ATTR_R = $01             ; FD Attribute: system can read from the file
FD_ATTR_W = $02             ; FD Attribute: system can write to the file
FD_ATTR_EOF = $04           ; FD Attribute: end of file has been reached (for read)
FD_ATTR_BLOCK = $08         ; FD Attribute: device is block based
FD_ATTR_OPEN = $80          ; FD Attribute: file is open for reading/writing

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
;   File Descriptor to open
;   Device to open
;   path to the file to read/write
;   code for read or write
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
FD_CLOSE        .proc
                PHP
                PLP
                RETURN
                .pend

;
; Fetch the next block from a block type device
;
; This does nothing for for character based devices or when we have read the last block already
;
; Inputs:
;   A = the number of the file descriptor
;
FD_FILL_BLK     .proc
                PHP
                PLP
                RETURN
                .pend

;
; Read the entire block from the file descriptor to an arbitrary address in memory
;
; Inputs:
;   A = the file descriptor to read
;   MARG1 = the destination address
;
FD_READ_BLK     .proc
                PHA
                PHX
                PHY
                PHP
                PHB

                setaxl
                LDX #9
mult_loop       ASL A               ; Convert FD number to block offset
                DEX
                BNE mult_loop
                
                CLC                 ; Compute the starting address
                ADC #<>FILE_BLOCKS
                TAX                 ; And set as the source

                LDY MARG1           ; Set the destination address

                setas
                LDA #$54            ; MVN
                STA MTEMP
                LDA #`FILE_BLOCKS   ; Source bank: `FILE_BLOCKS
                STA MTEMP+1
                LDA MARG1+2         ; Destination bank: from MARG1
                STA MTEMP+2

                LDA #$6B            ; RTL
                STA MTEMP+3

                setal
                LDA #FD_BLOCK_SIZE  ; Set the size to the block size

                JSL MTEMP           ; Call the MVN subroutine we just created

                PLB
                PLP
                PLY
                PLX
                PLA
                RETURN
                .pend

;
; Write the current block to the block device
;
; This does nothing for a character based device
;
; Inputs
;   A = The file descriptor to write
;
FD_FLUSH_BLK    .proc
                PHP
                PLP
                RETURN
                .pend

;
; Write the entire block to the file descriptor from an arbitrary address in memory
;
; Inputs:
;   A = the file descriptor to write
;   MARG1 = the source address
;
FD_WRITE_BLK    .proc
                PHA
                PHX
                PHY
                PHP
                PHB

                setaxl
                LDX #9
mult_loop       ASL A               ; Convert FD number to block offset
                DEX
                BNE mult_loop
                
                CLC                 ; Compute the starting address
                ADC #<>FILE_BLOCKS
                TAY                 ; And set as the destination

                LDX MARG1           ; Set the source address

                setas
                LDA #$54            ; MVN
                STA MTEMP+1
                LDA MARG1+2         ; Source bank: from MARG1
                STA MTEMP
                LDA #`FILE_BLOCKS   ; Destination bank: `FILE_BLOCKS
                STA MTEMP+2

                LDA #$6B            ; RTL
                STA MTEMP+3

                setal
                LDA #FD_BLOCK_SIZE  ; Set the size to the block size

                JSL MTEMP           ; Call the MVN subroutine we just created

                PLB
                PLP
                PLY
                PLX
                PLA
                RETURN
                .pend

;
; Read a character from the file descriptor
;
; For character devices, just read the character
; For block devices, manage reading in blocks as needed.
;
; Inputs:
;   A = The file descriptor to read
;
; Outputs:
;   A = The character read (0 if EOF)
;
FD_RD_CHAR      .proc
                PHP
                PLP
                RETURN
                .pend

;
; Write a charactger to the file descriptor
;
; For character devices, just write to the device
; For block devices, manage writing to the current block and
; writing blocks to the device as needed.
;
; Inputs:
;   The character to write
;   The file descriptor
;
FD_WR_CHAR      .proc
                PHP
                PLP
                RETURN
                .pend
