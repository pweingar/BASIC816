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

;
; Set up global memory labels and variables
;

.section data
DATA_BLOCK = *
.send

.section globals
GLOBAL_VARS = *
BIP         .dword ?    ; Pointer to the current byte in the current BASIC program
INDEX       .dword ?    ; A temporary pointer
SCRATCH     .dword ?    ; A temporary scratch variable
STRPTR      .long ?     ; A temporary pointer for strings
CURLINE     .dword ?    ; Pointer to the current input line needing tokenization
CURTOKLEN   .byte ?     ; Length of the text of the current token
ARGUMENTSP  .word ?     ; Pointer to the top of the argument stack
OPERATORSP  .word ?     ; Pointer to the top of the operator stack
ARGUMENT1   .dword ?    ; Argument 1 for expression calculations
ARGTYPE1    .byte ?     ; Type code for argument 1 (integer, float, string)
ARGUMENT2   .dword ?    ; Argument 2 for expression calculations
ARGTYPE2    .byte ?     ; Type code for argument 2 (integer, float, string)
JMP16PTR    .word ?     ; Pointer for 16-bit indirect jumps (within BASIC816's code base)
GOSUBDEPTH  .word ?     ; Number of GOSUBs on the stack
RETURNSP    .word ?     ; Pointer to the top of the return stack
NESTING     .byte ?     ; Counter of the depth of lexical nesting for FOR/NEXT, DO/LOOP
TARGETTOK   .byte ?     ; When searching for a token, TARGETTOK is the token to find
.send