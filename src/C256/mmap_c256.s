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

INPUTBUF = $004F00          ; Starting address of the line input buffer (one page)
RETURN_BOT = $005000        ; Starting address of the return stack
RETURN_TOP = $005FFF        ; Ending address of the return stack
ARGUMENT_BOT = $006000      ; Starting address of the argument stack
ARGUMENT_TOP = $006FFF      ; Ending address of the argument stack
OPERATOR_BOT = $007000      ; Starting address of the operator stack
OPERATOR_TOP = $007FFF      ; Ending address of the operator stack
STACK_BEGIN = $008000       ; 32512 Bytes The default beginning of stack space
STACK_END = $00FEFF         ; 0 Byte  End of stack space. Everything below this is I/O space
HEAP_TOP = $17FFFF          ; Starting point of the heap
BASIC_BOT = $010000         ; Starting point for BASIC programs

SCREENBEGIN      = $00000C ;3 Bytes Start of screen in video RAM. This is the upper-left corrner of the current video page being written to. This may not be what's being displayed by VICKY. Update this if you change VICKY's display page.
CURSORPOS        = $000017 ;3 Bytes The next character written to the screen will be written in this location.
CURSORX          = $00001A ;2 Bytes This is where the blinking cursor sits. Do not edit this direectly. Call LOCATE to update the location and handle moving the cursor correctly.
CURSORY          = $00001C ;2 Bytes This is where the blinking cursor sits. Do not edit this direectly. Call LOCATE to update the location and handle moving the cursor correctly.
COLS_VISIBLE     = $00000F ;2 Bytes Columns visible per screen line. A virtual line can be longer than displayed, up to COLS_PER_LINE long. Default = 80
COLS_PER_LINE    = $000011 ;2 Bytes Columns in memory per screen line. A virtual line can be this long. Default=128
LINES_VISIBLE    = $000013 ;2 Bytes The number of rows visible on the screen. Default=25
LINES_MAX        = $000015 ;2 Bytes The number of rows in memory for the screen. Default=64
CURCOLOR         = $00001E ;2 Bytes Color of next character to be printed to the screen.

CS_TEXT_MEM_PTR  = $AFA000
CS_COLOR_MEM_PTR = $AFC000

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
