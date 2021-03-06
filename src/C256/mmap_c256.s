;;;
;;; Block assignment for C256 Foenix
;;;

SYS_C256_FMX = 1        ; System SKU for C256 Foenix FMX
SYS_C256_USER = 2       ; System SKU for C256 Foenix User

.include "page_00_inc.s"
.include "int_math_defs.s"

; Section of memory used to handle the RESET and start BASIC
* = $002000
.dsection bootblock

; Section of memory for global (direct page) variables
* = $000800
.dsection globals
.cerror * > $8FF, "Too many direct page variables"

; Section of memory for the BASIC interpreter's code
.if C256_SKU == SYS_C256_FMX
* = $3A0000
.elsif C256_SKU == SYS_C256_USER
* = $1A0000
.else
.error "Undefined C256_SKU"
.endif
.dsection code

; Section of memory for all constant data
.if C256_SKU == SYS_C256_FMX
* = $3AD000
.else
* = $1AD000
.endif
.dsection data
.cerror * > $3AEFFF, "Too many string constants"

; Section for global variables that don't need to reside in direct page memory
.if C256_SKU == SYS_C256_FMX
* = $3AF000
.else
* = $1AF000
.endif
.dsection variables
.cerror * > $3AFFFF, "Too many system variables"

; Section of memory for the restart vector
; TODO: this will need to be removed once C256 is out of the prototype stage
* = $00FFFC
.dsection vectors

;;;
;;; Definitions for special areas
;;;

.include "vicky_def.s"

BASIC_BANK = $00            ; Memory bank for default purposes

; Bank 0 memory spaces

IOBUF = $004C00             ; A buffer for I/O operations
ARRIDXBUF = $004D00         ; The array index buffer used for array references
TEMPBUF = $004E00           ; Temporary buffer for string processing, etc.
INPUTBUF = $004F00          ; Starting address of the line input buffer (one page)
RETURN_BOT = $005000        ; Starting address of the return stack
RETURN_TOP = $005FFF        ; Ending address of the return stack
ARGUMENT_BOT = $006000      ; Starting address of the argument stack
ARGUMENT_TOP = $006FFF      ; Ending address of the argument stack
OPERATOR_BOT = $007000      ; Starting address of the operator stack
OPERATOR_TOP = $007FFF      ; Ending address of the operator stack

; Non Bank 0 memory spaces

VRAM = $B00000              ; Start of video RAM
LOADBLOCK = $010000         ; File loading will start here
BASIC_BOT := $360000         ; Starting point for BASIC programs
HEAP_TOP := $37FFFF          ; Starting point of the heap

.if C256_SKU == SYS_C256_USER
BASIC_BOT := $160000         ; Starting point for BASIC programs
HEAP_TOP := $17FFFF          ; Starting point of the heap
.endif