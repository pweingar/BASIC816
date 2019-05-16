;;;
;;; Block assignment for C64 with SuperCPU
;;;

; Section of memory for the BASIC interpreter's code
* = $0801
.dsection code
.cerror * > $2000, "CODE section too small"

; Section of memory for all constant data
* = $2000
.dsection data

; Section of memory for global (direct page) variables
* = $0002
.dsection globals
.cerror * > $00FF, "Too many global variables"

;;;
;;; Definitions for special areas
;;;

BASIC_BANK = $00            ; Program Bank for BASIC816 code

ARGUMENT_BOT = $00C000      ; Starting address of the argument stack
ARGUMENT_TOP = $00C0FF      ; Ending address of the argument stack
OPERATOR_BOT = $00C100      ; Starting address of the operator stack
OPERATOR_TOP = $00C1FF      ; Ending address of the operator stack
