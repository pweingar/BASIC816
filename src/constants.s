;;;
;;; Constant Definitions
;;;

;
; Possible target systems
;

SYSTEM_C256 = 2         ; C256 Foenix
SYSTEM_C64 = 1          ; Commodore 64 with SuperCPU

;
; Characters
;

CHAR_BELL = $07         ; Ring the console bell
CHAR_BS = $08           ; Backspace
CHAR_TAB = $09          ; TAB
CHAR_LF = $0A           ; Linefeed
CHAR_CR = $0D           ; Carriage Return
CHAR_ESC = $1B          ; Escape
CHAR_DQUOTE = $22       ; Double quote
CHAR_SP = $20           ; Space
CHAR_DEL = $7F          ; Delete

;
; Miscellaneous constants
;

ARGUMENT_SIZE = 5       ; Number of bytes in an argument
VAR_NAME_SIZE = 8       ; Maximum number of characters in a variable name

;
; Type Codes
;

TYPE_INTEGER = 0        ; 16-bit integer
TYPE_FLOAT = 1          ; Single-precision floating point
TYPE_STRING = 2         ; ASCII string
TYPE_BINDING = $80      ; A varaible name binding
TYPE_NAV = $FF          ; Not-A-Value

;
; Errors
;

ERR_OK = 0              ; No error
ERR_SYNTAX = 1          ; A syntax error was found on the current line
ERR_MEMORY = 2          ; Out of memory
ERR_TYPE = 3            ; Type mismatch error
ERR_NOTFOUND = 4        ; Variable not found error
ERR_NOLINE = 5          ; Line number not found
ERR_STACKUNDER = 6      ; Stack underflow error
ERR_STACKOVER = 7       ; Stack overflow error