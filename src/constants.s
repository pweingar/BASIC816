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

CHAR_CTRL_C = $03       ; CTRL-C: used as a program interrupt key
CHAR_BELL = $07         ; Ring the console bell
CHAR_BS = $08           ; Backspace
CHAR_TAB = $09          ; TAB
CHAR_LF = $0A           ; Linefeed
CHAR_CR = $0D           ; Carriage Return
CHAR_INS = $0F          ; Insert
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

TYPE_INTEGER = 0        ; 32-bit integer
TYPE_FLOAT = 1          ; Single-precision floating point
TYPE_STRING = 2         ; ASCII string
TYPE_ARR_INTEGER = $80  ; Array of 32-bit integers
TYPE_ARR_FLOAT = $81    ; Array of 32-bit floats
TYPE_ARR_STRING = $82   ; Array of strings
TYPE_BINDING = $7F      ; A variable name binding
TYPE_NAV = $FF          ; Not-A-Value

;
; Errors
;

ERR_OK = 0              ; No error
ERR_BREAK = 1           ; The user pressed an interrupt key
ERR_SYNTAX = 2          ; A syntax error was found on the current line
ERR_MEMORY = 3          ; Out of memory
ERR_TYPE = 4            ; Type mismatch error
ERR_NOTFOUND = 5        ; Variable not found error
ERR_NOLINE = 6          ; Line number not found
ERR_STACKUNDER = 7      ; Stack underflow error
ERR_STACKOVER = 8       ; Stack overflow error
ERR_RANGE = 9           ; Out-of-range error
ERR_ARGUMENT = 10       ; Bad argument error
ERR_NOFILE = 11         ; File not found error
ERR_NAN = 12            ; Floating point math resulted in something that is not a number
ERR_OVERFLOW = 13       ; Math operation overflowed
ERR_UNDERFLOW = 14      ; Math operation underflowed
ERR_DIV0 = 15           ; Math operation involved a division by zero
ERR_DIRECTORY = 16      ; Error reading the directory
ERR_LOAD = 17           ; Could not load file
ERR_SAVE = 18           ; Could not save a file
ERR_DELETE = 19         ; Could not delete a file