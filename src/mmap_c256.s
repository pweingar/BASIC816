;;;
;;; Block assignment for C256 Foenix
;;;

; Section of memory for the BASIC interpreter's code
* = $002000
.dsection code

; Section of memory for all constant data
* = $001000
.dsection data
.cerror * > $001FFFF, "Too many string constants"

; Section of memory for global (direct page) variables
* = $000210
.dsection globals
.cerror * > $2FF, "Too many global variables"

; Section of memory for the restart vector
; TODO: this will need to be removed once C256 is out of the prototype stage
* = $00FFFC
.dsection vectors

;;;
;;; Definitions for special areas
;;;

BASIC_BANK = $00            ; Program Bank for BASIC816 code

ARGUMENT_BOT = $006000      ; Starting address of the argument stack
ARGUMENT_TOP = $006FFF      ; Ending address of the argument stack
OPERATOR_BOT = $007000      ; Starting address of the operator stack
OPERATOR_TOP = $007FFF      ; Ending address of the operator stack
RETURN_BOT = $005000        ; Starting address of the return stack
RETURN_TOP = $005FFF        ; Ending address of the return stack

HEAP_TOP = $17FFFF          ; Starting point of the heap
BASIC_BOT = $010000         ; Starting point for BASIC programs

;;;
;;; Math co-processor
;;;

M1_OPERAND_A     = $000108 ;2 Bytes Operand A (ie: A x B)
M1_OPERAND_B     = $00010A ;2 Bytes Operand B (ie: A x B)
M1_RESULT        = $00010C ;4 Bytes Result of A x B

DIVIDER_1        = $000110 ;0 Byte  Signed divider
D1_OPERAND_A     = $000110 ;2 Bytes Divider 1 denominator ex: B in  A/B
D1_OPERAND_B     = $000112 ;2 Bytes Divider 1 numerator ex A in A/B
D1_RESULT        = $000114 ;2 Bytes Signed quotient result of A/B ex: 7/2 = 3 r 1
D1_REMAINDER     = $000116 ;2 Bytes Signed remainder of A/B ex: 1 in 7/2=3 r 1
