;;;
;;; Code to manage user variables
;;;

.section globals
VARIABLES       .long ?         ; Pointer to the most recently allocated variable
TOFIND          .long ?         ; Pointer to the variable name to find
TOFINDTYPE      .byte ?         ; The type to find
.send

BINDING         .struct
TYPE            .fill 1                 ; The type of the data stored in the variable
NAME            .fill VAR_NAME_SIZE     ; The name of the variable
VALUE           .fill 4                 ; The data stored in the variable
NEXT            .fill 3                 ; The pointer to the next allocated variable of this type
                .ends

;
; Initialize the variable table to empty
;
INITVARS        .proc
                PHP

                setdp <>GLOBAL_VARS
                setal
                STZ VARIABLES
                STZ TOFIND
                setas
                STZ VARIABLES+2
                STZ TOFIND+2
                STZ TOFINDTYPE

                PLP
                RETURN
                .pend

;
; Check if the byte in A is a valid character for a variable name
;
; Inputs:
;   A = byte to test (assumed to be in 8-bit mode)
;
; Outputs:
;   C is set if the character is valid for a variable name, clear otherwise
;
ISVARCHAR       .proc
                CMP #'_'            ; Check if it's an underscore
                BEQ return_true     ; Yes: return true

                CMP #'9'+1          ; Check if its in [0-9]
                BGE else1           ; No: check something else
                CMP #'0'
                BGE return_true     ; Yes: return true

else1           CMP #'Z'+1          ; Check if its in [A-Z]
                BGE not_upper       ; No: check lower case
                CMP #'A'
                BGE return_true     ; Yes: return true

not_upper       CMP #'z'+1          ; Check if its in [a-z]
                BGE return_false    ; No: return false
                CMP #'a'
                BGE return_true     ; Yes: return true

return_false    CLC
                RETURN

return_true     SEC
                RETURN
                .pend


;
; Compare the name in a variable block with a name to find
;
; Inputs:
;   SCRATCH = pointer to the name of a bound variable (MSB terminated)
;   TOFIND = pointer to the name to find (terminated by a non-alphanumeric)
;
; Outputs:
;   C is set if the names match, clear otherwise
VARNAMECMP      .proc
                PHP
                TRACE_L "VARNAMECMP", SCRATCH
                TRACE_L "SEEKING: ", TOFIND

                setas
                setxl
                LDY #0

cmp_loop        LDA [SCRATCH],Y         ; Check the character in the variable name
                BEQ is_end
                CMP [TOFIND],Y          ; Compare the character to the one TOFIND
                BNE return_false        ; Not equal? Then this is not a match

                INY
                CPY #VAR_NAME_SIZE
                BNE cmp_loop

is_end          LDA [TOFIND],Y          ; Check the character in the name to find
                CALL TOUPPERA
                CALL ISVARCHAR          ; Is it a variable name character?
                BCS return_false        ; YES: we do not have a match

return_true     TRACE "VARNAMECMP: TRUE"
                PLP
                SEC
                RETURN

return_false    TRACE "VARNAMECMP: FALSE"
                PLP
                CLC
                RETURN
                .pend

;
; For lookup and setting, variable names will be assumed to be of the following form:
; 1. Starts with an alphabetic character [a-zA-Z]
; 2. All following characters are in the set [0-9a-zA-Z_]
; 3. Last character designates the type:
;       $ for strings
;       % for integers
;       nothing for floats
;
; Finally, for the purposes of matching the variable name, the type of the variable
; will be considered part of the name. So A$ is not the same name as A or A%.
;

;
; Find the record for a variable with a given name and type
;
; Inputs:
;   TOFINDTYPE = type of the variable
;   TOFIND = pointer to the name to find
;
; Outputs:
;   INDEX = pointer to the variable record
;   C = set if variable was found, clear if not found
;
VAR_FIND        .proc
                PHP
                TRACE "VAR_FIND"

                setas
                setxl

                ; Convert TOFIND to upper case in a temporary buffer
                LDY #0
                LDX #0
upper_loop      LDA [TOFIND],Y          ; Get a character
                BEQ done_upper
                CALL TOUPPERA           ; Make sure it's upper case
                STA @lTEMPBUF,X         ; And save it to the temp
                INY
                INX
                BRA upper_loop          ; Go back for another

done_upper      LDA #0
                STA @lTEMPBUF,X         ; NULL terminate the temporary string

                setal
                LDA #<>TEMPBUF          ; Make the temporary string the string
                STA TOFIND              ; the variable name to find
                setas
                LDA #`TEMPBUF
                STA TOFIND+2

                ; INDEX := VARIABLES
                ; return false if VARIABLES == 0
                setal
                LDA VARIABLES           ; Point INDEX to the first variable to check
                STA INDEX
                BNE set_index_h         ; If the low word is not 0, copy the high byte
                setas                   ; Otherwise, check to see if the high byte is 0
                LDA VARIABLES+2
                BEQ not_found           ; If it is, we have no variables yet.
set_index_h     setas
                LDA VARIABLES+2
                STA INDEX+2

                ; Check the binding indicated by INDEX
check_binding   LDA TOFINDTYPE
                LDY #BINDING.TYPE       ; Get the type of the variable
                CMP [INDEX],Y
                BNE check_next          ; If it's not a match, check the next binding

                ; Check that the names match.
                ; The recorded variable name will be NULL terminated
                ; The one to search for will be terminated by anything outside [0-9a-zA-Z_]

                setal                   ; Set SCRATCH to the pointer of the variable name
                CLC
                LDA INDEX
                ADC #BINDING.NAME
                STA SCRATCH
                setas
                LDA INDEX+2
                ADC #0
                STA SCRATCH+2

                CALL VARNAMECMP         ; Compare the name at SCRATCH to the one at TOFIND
                BCS found               ; If they match, return that we've found the variable

                ; Current variable is not a match... try the next one
check_next      LDY #BINDING.NEXT       ; SCRATCH := [INDEX].NEXT
                setal
                LDA [INDEX],Y
                STA SCRATCH
                INY
                INY
                setas
                LDA [INDEX],Y
                STA SCRATCH+2

                BNE set_index           ; If SCRATCH == 0, the variable wasn't found
                setal
                LDA SCRATCH
                BEQ not_found

set_index       setal                   ; Otherwise, set INDEX := SCRATCH
                LDA SCRATCH
                STA INDEX
                setas
                LDA SCRATCH+2
                STA INDEX+2
                BRA check_binding       ; And check this next variable for a match

not_found       PLP
                CLC
                RETURN

found           PLP
                SEC
                RETURN
                .pend

;
; Set ARGUMENT1 to the value of the given variable
;
; Inputs:
;   TOFINDTYPE = type of the variable
;   TOFIND = pointer to the name to find
;
; Outputs:
;   ARGUMENT1 = value of the variable
;   ARGTYPE1 = type of the variable
;
; If variable not found, throw ERR_NOTFOUND
;
VAR_REF         .proc
                PHP
                TRACE "VAR_REF"
                CALL VAR_FIND
                BCS found

                THROW ERR_NOTFOUND

found           TRACE_L "VAR_REF: FOUND",INDEX
                setaxl
                LDY #BINDING.VALUE
                LDA [INDEX],Y
                STA ARGUMENT1
                INY
                INY
                LDA [INDEX],Y
                STA ARGUMENT1+2

                setas
                LDY #BINDING.TYPE
                LDA [INDEX],Y
                STA ARGTYPE1

done            PLP
                RETURN
                .pend

;
; Create a new variable and bind a value to it
; This can shadow a previous binding.
;
; Inputs:
;   TOFIND = pointer to the name of the variable to create
;   TOFINDTYPE = the type of the variable to create
;   ARGUMENT1 = the value to assign
;
; If ARGTYPE1 <> TOFINDTYPE, throw ERR_TYPE
;
VAR_CREATE      .proc
                PHP
                TRACE "VAR_CREATE"

                setas
                LDA ARGTYPE1        ; Validate that our types match
                CMP TOFINDTYPE
                BEQ can_create

                THROW ERR_TYPE

can_create      setas
                setxl
                LDX #size(BINDING)  ; Get space for the binding
                LDA #TYPE_BINDING   ; And the type
                CALL ALLOC

                setaxl              ; Point INDEX to the NAME field of the variable
                CLC
                LDA CURRBLOCK
                ADC #BINDING.NAME
                STA INDEX
                setas
                LDA CURRBLOCK+2
                ADC #0
                STA INDEX+2

                LDY #0              ; Ensure that the name field is blank
                LDA #0
blank_loop      STA [INDEX],Y
                INY
                CPY #VAR_NAME_SIZE
                BNE blank_loop

                LDY #0
name_loop       LDA [TOFIND],Y      ; Copy TOFIND to the NAME field
                BEQ set_type
                CALL TOUPPERA
                CALL ISVARCHAR
                BCC set_type
                STA [INDEX],Y

                INY
                CPY #VAR_NAME_SIZE
                BNE name_loop

set_type        LDY #BINDING.TYPE   ; Set the type of the variable
                LDA ARGTYPE1
                STA [CURRBLOCK],Y

                setal
                LDY #BINDING.VALUE  ; Copy the value to the variable
                LDA ARGUMENT1
                STA [CURRBLOCK],Y
                LDA ARGUMENT1+2
                INY
                INY
                STA [CURRBLOCK],Y

                LDA VARIABLES       ; Point NEXT to the current top of variables
                LDY #BINDING.NEXT
                STA [CURRBLOCK],Y
                INY
                INY
                setas
                LDA VARIABLES+2
                STA [CURRBLOCK],Y

                setal               ; Point VARIABLES to the new variable
                LDA CURRBLOCK
                STA VARIABLES
                setas
                LDA CURRBLOCK+2
                STA VARIABLES+2

                PLP
                RETURN
                .pend

;
; Set the value of a variable to the contents of ARGUMENT1.
; If the variable already has a value, this will replace the old value.
; If the variable is not assigned, it will be allocated and assigned a value.
;
; Inputs:
;   ARGUMENT1 = value to set
;   ARGTYPE1 = type of the variable
;   TOFINDTYPE = the type of the variable to create
;   TOFIND = pointer to the name to find
;
VAR_SET         .proc
                PHP
                TRACE "VAR_SET"

                setaxl
                LDA VARIABLES          ; If VARIABLES = 0, use VAR_CREATE
                BNE use_find
                setas
                LDA VARIABLES+2
                BEQ use_create

use_find        CALL VAR_FIND
                BCS found

use_create      CALL VAR_CREATE
                BRA done

found           setaxl
                LDY #BINDING.VALUE
                LDA ARGUMENT1
                STA [INDEX],Y
                INY
                INY
                LDA ARGUMENT1+2
                STA [INDEX],Y

done            PLP
                RETURN
                .pend

;
; Scan the current location in the BASIC program for a variable name
;
; Inputs:
;   BIP = the pointer to the current program
;
; Outputs:
;   C is set if a name was found, clear otherwise
;   TOFIND = pointer to the variable name
;   TOFINDTYPE = the type of the variable name
;
VAR_FINDNAME    .proc
                PHP
                TRACE "VAR_FINDNAME"

                CALL SKIPWS         ; Skip over any whitespace

                setas
                LDA [BIP]           ; Get the first character
                CALL ISALPHA        ; Check if it's ok as an initial character
                BCC not_found

                setal               ; Point TOFIND to the variable name
                LDA BIP
                STA TOFIND
                setas
                LDA BIP+2
                STA TOFIND+2

                ; Scan to the end of the name to look for the type symbol
loop            CALL INCBIP         ; Point to the next character
                LDA [BIP]
                BEQ is_float        ; If it's EOL, the variable is a float

                CMP #'$'            ; If it's $, the variable is a string
                BEQ is_string

                CMP #'%'            ; If it's %, the variable is an integer
                BEQ is_integer

                CALL ISVARCHAR      ; Is the character still suitable for variables
                BCS loop            ; Check the next one

is_float        ; LDA #TYPE_FLOAT     ; Otherwise it's a float
                LDA #TYPE_INTEGER   ; TODO: Remove this when floats are implemented
                BRA set_type

is_integer      CALL INCBIP         ; Skip over the type symbol
                LDA #TYPE_INTEGER
                BRA set_type

is_string       CALL INCBIP         ; Skip over the type symbol
                LDA #TYPE_STRING
set_type        STA TOFINDTYPE              
                PLP
                SEC
                RETURN

not_found       PLP
                CLC
                RETURN
                .pend