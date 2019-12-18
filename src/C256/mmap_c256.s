;;;
;;; Block assignment for C256 Foenix
;;;

.include "page_00_inc.s"

; Section of memory used to handle the RESET and start BASIC
* = $002000
.dsection bootblock

; Section of memory for global (direct page) variables
* = $000800
.dsection globals
.cerror * > $8FF, "Too many direct page variables"

; Section for global variables that don't need to reside in direct page memory
* = $17D000
.dsection variables
.cerror * > $17DFFF, "Too many system variables"

; Section of memory for the BASIC interpreter's code
* = $170000
.dsection code

; Section of memory for all constant data
* = $17E000
.dsection data
.cerror * > $19FFFF, "Too many string constants"

; A block of memory for the virtul file system (jetison this when there is a real one)
* = VFS
.dsection vfs_block

; Section of memory for the restart vector
; TODO: this will need to be removed once C256 is out of the prototype stage
* = $00FFFC
.dsection vectors

;;;
;;; Definitions for special areas
;;;

.include "vicky_def.s"

BASIC_BANK = $00            ; Memory bank for default purposes
CODE_BANK = $17             ; Memory bank for the BASIC816 code

ARRIDXBUF = $004D00         ; The array index buffer used for array references
TEMPBUF = $004E00           ; Temporary buffer for string processing, etc.
INPUTBUF = $004F00          ; Starting address of the line input buffer (one page)
RETURN_BOT = $005000        ; Starting address of the return stack
RETURN_TOP = $005FFF        ; Ending address of the return stack
ARGUMENT_BOT = $006000      ; Starting address of the argument stack
ARGUMENT_TOP = $006FFF      ; Ending address of the argument stack
OPERATOR_BOT = $007000      ; Starting address of the operator stack
OPERATOR_TOP = $007FFF      ; Ending address of the operator stack
HEAP_TOP = $15FFFF          ; Starting point of the heap
BASIC_BOT = $010000         ; Starting point for BASIC programs
VRAM = $B00000              ; Start of video RAM
VFS = $160000               ; Start of the "virtual file system"
LOADBLOCK = $020000         ; File loading will start here