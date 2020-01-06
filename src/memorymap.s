;;;
;;; Layout the memory map of the BASIC interpreter
;;;

;
; Define the memory blocks
;

.if SYSTEM == SYSTEM_C64
.include "CBM/mmap_cbm.s"
.elsif SYSTEM == SYSTEM_C256
.include "C256/mmap_c256.s"
.endif

VBRK = $00FFE6          ; Vector for the native-mode BRK vector 

;
; Set up global memory labels and variables
;

.section data
DATA_BLOCK = *
.send

.section globals
GLOBAL_VARS = *
BIP         .dword ?    ; Pointer to the current byte in the current BASIC program
BIPPREV     .dword ?    ; Pointer to the previous bytein the current BASIC program
INDEX       .dword ?    ; A temporary pointer
SCRATCH     .dword ?    ; A temporary scratch variable
SCRATCH2    .dword ?    ; A temporary scratch variable
STRPTR      .dword ?    ; A temporary pointer for strings
CURLINE     .dword ?    ; Pointer to the current input line needing tokenization
CURTOKLEN   .byte ?     ; Length of the text of the current token
ARGUMENTSP  .word ?     ; Pointer to the top of the argument stack
OPERATORSP  .word ?     ; Pointer to the top of the operator stack
ARGUMENT1   .dword ?    ; Argument 1 for expression calculations
ARGTYPE1    .byte ?     ; Type code for argument 1 (integer, float, string)
SIGN1       .byte ?     ; Temporary sign marker for argument 1
ARGUMENT2   .dword ?    ; Argument 2 for expression calculations
ARGTYPE2    .byte ?     ; Type code for argument 2 (integer, float, string)
SIGN2       .byte ?     ; Temporary sign marker for argument 1
JMP16PTR    .word ?     ; Pointer for 16-bit indirect jumps (within BASIC816's code base)
GOSUBDEPTH  .word ?     ; Number of GOSUBs on the stack
RETURNSP    .word ?     ; Pointer to the top of the return stack
SKIPNEST    .byte ?     ; Flag to indicate if token seeking should respect nesting (MSB set if so)
NESTING     .byte ?     ; Counter of the depth of lexical nesting for FOR/NEXT, DO/LOOP
TARGETTOK   .byte ?     ; When searching for a token, TARGETTOK is the token to find
DATABIP     .dword ?    ; Pointer to the next data element for READ statements
DATALINE    .dword ?    ; Pointer to the current line for a DATA statement
SAVEBIP     .dword ?    ; Spot to save BIP temporarily
SAVELINE    .dword ?    ; Spot to save CURLINE temporarily

MONITOR_VARS = *
MCMDADDR    .long ?     ;3 Bytes Address of the current line of text being processed by the command parser. Can be in display memory or a variable in memory. MONITOR will parse up to MTEXTLEN characters or to a null character.
MCMP_TEXT   .long ?     ;3 Bytes Address of symbol being evaluated for COMPARE routine
MCMP_LEN    .word ?     ;2 Bytes Length of symbol being evaluated for COMPARE routine
MCMD        .long ?     ;3 Bytes Address of the current command/function string
MCMD_LEN    .word ?     ;2 Bytes Length of the current command/function string
MARG1       .dword ?    ;4 Bytes First command argument. May be data or address, depending on command
MARG2       .dword ?    ;4 Bytes First command argument. May be data or address, depending on command. Data is 32-bit number. Address is 24-bit address and 8-bit length.
MARG3       .dword ?    ;4 Bytes First command argument. May be data or address, depending on command. Data is 32-bit number. Address is 24-bit address and 8-bit length.
MARG4       .dword ?    ;4 Bytes First command argument. May be data or address, depending on command. Data is 32-bit number. Address is 24-bit address and 8-bit length.
MARG5       .dword ?    ;4 Bytes First command argument. May be data or address, depending on command. Data is 32-bit number. Address is 24-bit address and 8-bit length.
MARG6       .dword ?    ;4 Bytes First command argument. May be data or address, depending on command. Data is 32-bit number. Address is 24-bit address and 8-bit length.
MARG7       .dword ?    ;4 Bytes First command argument. May be data or address, depending on command. Data is 32-bit number. Address is 24-bit address and 8-bit length.
MARG8       .dword ?    ;4 Bytes First command argument. May be data or address, depending on command. Data is 32-bit number. Address is 24-bit address and 8-bit length.
MARG9       .dword ?    ;4 Bytes First command argument.
MARG_LEN    .byte ?     ;1 Byte count of the number of arguments passed
MCURSOR     .dword ?    ;4 Bytes Pointer to the current memory location for disassembly, memory dump, etc.
MLINEBUF    .fill 17    ;17 Byte buffer for dumping memory (TODO: could be moved to a general string scratch area)
MCOUNT      .long ?     ;2 Byte counter
MTEMP       .dword ?    ;4 Bytes of temporary space
MCPUSTAT    .byte ?     ;1 Byte to represent what the disassembler thinks the processor MX bits are
MADDR_MODE  .byte ?     ;1 Byte address mode found by the assembler
MPARSEDNUM  .dword ?    ;4 Bytes to store a parsed number
MMNEMONIC   .word ?     ;2 Byte address of mnemonic found by the assembler
MTEMPPTR    .dword ?    ;4 Byte temporary pointer
MJUMPINST   .byte ?     ;1 Byte JSL opcode
MJUMPADDR   .long ?     ;3 Byte address for JSL 
.send

MANTISSA1 = ARGUMENT1
EXPONENT1 = ARGUMENT1+3
