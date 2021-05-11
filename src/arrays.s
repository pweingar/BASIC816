;;;
;;; Implement arrays
;;;
;;;
;;; Memory format
;;;
;;; +---+-----+-----+-----+-----+-----+-----+-----+-----+
;;; | n | d_0 | d_1 | ... | d_n | v_0 | v_1 | ... | v_x |
;;; +---+-----+-----+-----+-----+-----+-----+-----+-----+
;;;
;;; n = number of dimensions (1 byte)
;;; d_i = the size of the ith dimension (1 byte)
;;; v_j = the jth value (4 bytes)
;;;

;
; Macro to push the array index buffer to the stack
;
; After this operation, the byte at the top of the stack will be the
; number of indexes pushed. The words on the stack after that will be
; the indexes themselves.
;
; Affects:
;   A, X, width of registers
;
PHARRIDX        .macro
                setas
                LDA @lARRIDXBUF
                setaxl
                AND #$00FF
                ASL A
                TAX                 ; And put the highest index in X

loop            LDA @lARRIDXBUF+1,X ; The the Xth index
                PHA                 ; Save it to the stack
                DEX                 ; Go to the previous index
                DEX
                BPL loop            ; Keep looping until we roll over

                setas
                LDA @lARRIDXBUF     ; Get the size
                PHA                 ; And save it to the stack               
                .endm

;
; Macro to pull the array index buffer from the stack.
;
; The byte at the top of the stack should contain the number of indexes to pull
; The words on the stack after that will be the indexes to pull.
;
; Affects:
;   A, X, Y, width of registers
;   Contents of ARRIDXBUF
;
PLARRIDX        .macro
                setas
                PLA                 ; Pull the size from the stack
                STA @lARRIDXBUF     ; And restore it to the array index buffer

                setaxl
                AND #$00FF
                TAY                 ; Put the count in Y
                LDX #0              ; We'll start with the zero index

loop            PLA                 ; Get the next index
                STA @lARRIDXBUF+1,X ; Save it to the array index buffer
                INX                 ; Move to the next index
                INX
                DEY
                BNE loop            ; And keep looping until we are done
                .endm

;
; Allocate an array
;
; Inputs:
;   TOFINDTYPE = the type of the array contents
;   ARRIDXBUF = list of dimension sizes with n at ARRIDXBUF+0, d_0 at ARRIDXBUF + 1, d_1 at at ARRIDXBUF + 3, and so on
;
; Outputs:
;   CURRBLOCK = the array allocated
;
ARR_ALLOC       .proc
                PHP
                TRACE "ARR_ALLOC"               

                CALL HEAP_GETHED

                ; Compute the size of the block needed
                setal
                LDA #1                      ; ARGUMENT1 := 1
                STA ARGUMENT1
                LDA #0
                STA ARGUMENT1+2

                setas
                LDA @lARRIDXBUF
                setal
                AND #$00FF
                STA MCOUNT                  ; Save it to MCOUNT for later
                TAY                         ; Y := number of dimensions

                LDX #1                      ; X := index to size 0                    
size_loop       setal
                LDA @lARRIDXBUF,X           ; ARGUMENT2 := Ith dimension
                STA ARGUMENT2
                LDA #0
                STA ARGUMENT2+2
                setas
                LDA #TYPE_INTEGER
                STA ARGTYPE2
                setal

                CALL OP_MULTIPLY            ; ARGUMENT1 := ARGUMENT1 * Ith dimension

                INX
                INX
                DEY
                BNE size_loop               ; If there are more dimensions, take the next one

                setal
                LDA #ARGUMENT_SIZE-1        ; Size of a data item (don't include the type code)
                STA ARGUMENT2
                LDA #0
                STA ARGUMENT2+2

                CALL OP_MULTIPLY            ; ARGUMENT1 := size of the data area of the array

                setas
                LDA @lARRIDXBUF             ; SCRATCH := N * 2
                STA SCRATCH
                LDA #0
                STA SCRATCH+1
                setal
                ASL SCRATCH

                SEC                         ; ARGUMENT1 := size of the complete block
                LDA ARGUMENT1
                ADC SCRATCH                 ; Size of data area + N*2 + 1 (in carry)
                STA ARGUMENT1
                LDA ARGUMENT1+2
                ADC #0
                STA ARGUMENT1+2
                BNE too_big                 ; size > 16-bit? Yes: throw an error        

                ; Allocate the block
                setas
                LDA TOFINDTYPE              ; Get the type
                ORA #$80                    ; Flip the flag to make it an array of that type
                LDX ARGUMENT1               ; Get the computed size
                CALL ALLOC                  ; Allocate the array

                TRACE "-ALLOC"

                ; Copy the dimensions to the block

                setas
                LDA @lARRIDXBUF
                STA [CURRBLOCK]             ; Write the number of dimensions to the array's preamble

                LDY #1
                LDX #0
copy_loop       setas
                LDA @lARRIDXBUF+1,X         ; ARGUMENT2 := Ith dimension
                STA [CURRBLOCK],Y           ; And write the dimension to the array's preamble
                CPX MCOUNT                  ; Have we written the last byte?
                BEQ null_array              ; Yes: clear the array

                INX                         ; No: move to the next byte
                INY
                BRA copy_loop

too_big         THROW ERR_RANGE             ; Size is too big

null_array      setas
                SEC                         ; INDEX := pointer to first value
                LDA CURRBLOCK
                ADC [CURRBLOCK]
                STA INDEX
                LDA CURRBLOCK+1
                ADC #0
                STA INDEX+1
                LDA CURRBLOCK+2
                ADC #0
                STA INDEX+2
                STZ INDEX+3

                setal
                LDY #HEAPOBJ.END            ; SCRATCH := pointer the the first byte after the array
                LDA [CURRHEADER],Y
                STA SCRATCH
                setas
                INY
                INY
                LDA [CURRHEADER],Y
                STA SCRATCH+2
                STZ SCRATCH+3

clr_loop        setas
                LDA #0
                STA [INDEX]                 ; Clear the byte

                setal
                CLC                         ; Increment INDEX
                LDA INDEX
                ADC #1
                STA INDEX
                LDA INDEX+2
                ADC #0
                STA INDEX+2

                CMP SCRATCH+2               ; INDEX == SCRATCH?
                BNE clr_loop                ; No: write to this next byte
                LDA INDEX
                CMP SCRATCH
                BNE clr_loop

done            TRACE "/ARR_ALLOC"
                PLP
                RETURN
                .pend

;
; Get a pointer to the specified value of in an array
;
; Inputs:
;   CURRBLOCK = pointer to the array to access
;   ARRIDXBUF = list of dimension sizes with n at ARRIDXBUF+0, d_0 at ARRIDXBUF + 1, d_1 at at ARRIDXBUF + 3, and so on
;
; Outputs:
;   INDEX = pointer to the value in the array
;
ARR_CELL        .proc
                PHP
                TRACE "ARR_CELL"

                ; GOAL: INDEX := Sum(I_j * D_j) for j = 0 to N - 1

                setal
                STZ INDEX               ; INDEX := 0
                STZ INDEX+2

                setas
                LDA @l ARRIDXBUF        ; MCOUNT := N (number of dimensions)
                STA MCOUNT
                STZ MCOUNT+1

                LDX #1                  ; X := index to dimension 0

                setas
                LDA [CURRBLOCK]         ; Make sure the dimensions of the array
                CMP MCOUNT              ; ... match those requested
                BEQ dims_match          ; Yes: the dimensions match

                LDX MCOUNT
                BRK

arg_err         THROW ERR_ARGUMENT      ; Throw an argument error

dims_match      CMP #1                  ; Check to see if this array is one dimensional
                BEQ add_last            ; If so, just add the index of the cell to INDEX

                ; FOR j := 0 TO N - 1

                LDY #1                  
index_loop      setas

                LDA @lARRIDXBUF,X       ; ARGUMENT1 := I_j
                STA ARGUMENT1
                STZ ARGUMENT1+1
                STZ ARGUMENT1+2
                STZ ARGUMENT1+3

                LDA [CURRBLOCK],Y       ; ARGUMENT2 := D_j
                STA ARGUMENT2
                STZ ARGUMENT2+1
                STZ ARGUMENT2+2
                STZ ARGUMENT2+3

                ; Check that the index is within bounds
                LDA ARGUMENT1
                CMP ARGUMENT2           ; Is I_j >= D_j
                BGE range_err           ; Yes: throw an out-of-range error

                CALL OP_MULTIPLY        ; ARGUMENT1 := ARGUMENT1 * ARGUMENT2

                setal
                CLC                     ; INDEX := INDEX + ARGUMENT1
                LDA INDEX
                ADC ARGUMENT1
                STA INDEX
                LDA INDEX+2
                ADC ARGUMENT1+2
                STA INDEX+2

                INX
                INX
                INY

                CPY MCOUNT              ; Are we on the last index?
                BNE index_loop          ; No: move to the next index and try again

add_last        setas                   ; Yes: just add its index to the total

                CLC
                LDA @lARRIDXBUF,X       ; INDEX := INDEX + I_(n-1)
                STA MCOUNT+1
                ADC INDEX
                STA INDEX
                LDA INDEX+1
                ADC #0
                STA INDEX+1
                setal
                LDA INDEX+2
                ADC #0
                STA INDEX+2

                ; GOAL: ARGUMENT1 := INDEX * CELLSIZE

                setal
                ASL INDEX               ; INDEX := INDEX * 4 (size of a value)
                ROL INDEX+2
                ASL INDEX
                ROL INDEX+2

                setas                   ; Add N + 1 to INDEX to skip over the preamble
                SEC
                LDA INDEX
                ADC MCOUNT
                STA INDEX
                LDA INDEX+1
                ADC #0
                STA INDEX+1
                setal
                LDA INDEX+2
                ADC #0
                STA INDEX+2

                CLC                     ; INDEX := INDEX + CURRBLOCK (point to the address desired)
                LDA INDEX
                ADC CURRBLOCK
                STA INDEX
                setas
                LDA INDEX+2
                ADC CURRBLOCK+2
                STA INDEX+2

                PLP
                RETURN
range_err       THROW ERR_RANGE         ; Throw an exception for index out-of-range
                .pend

;
; Set the value of a cell in an array
;
; array(i_0, i_1, ... i_n) := v
;
; Inputs:
;   ARGUMENT1 = value to assign
;   CURRBLOCK = pointer to the array to access
;   ARRIDXBUF = list of dimension sizes with n at ARRIDXBUF+0, d_0 at ARRIDXBUF + 1, d_1 at at ARRIDXBUF + 3, and so on
;
ARR_SET         .proc
                PHP
                TRACE "ARR_SET"

                CALL HEAP_GETHED    ; Set CURRHEADER for this CURRBLOCK

                setas
                LDY #HEAPOBJ.TYPE   ; Get the type of the array
                LDA [CURRHEADER],Y
                AND #$7F            ; Mask off the ARRAY OF bit

                CMP #TYPE_STRING    ; Is it a string array?
                BNE chk_integer
                CALL ASS_ARG1_STR   ; Yes: make sure the value is a string
                BRA save_type

chk_integer     CMP #TYPE_INTEGER   ; Is it an integer array?
                BNE chk_float
                CALL ASS_ARG1_INT   ; Yes: make sure the value is an integer (cast if needed)
                BRA save_type

chk_float       CMP #TYPE_FLOAT     ; Is it an float array?
                BNE type_mismatch   ; No: throw a type mismatch error... something strange...
                CALL ASS_ARG1_FLOAT ; Yes: make sure the value is a float (cast if needed)

save_type       LDA ARGTYPE1        ; Save the type
                PHA

                setal
                LDA ARGUMENT1+2     ; Save ARGUMENT1
                PHA
                LDA ARGUMENT1
                PHA

                CALL ARR_CELL       ; INDEX := pointer to the cell desired

                PLA                 ; Restore ARGUMENT1
                STA ARGUMENT1
                PLA
                STA ARGUMENT1+2

                setas
                PLA
                STA ARGTYPE1

                setal
                LDA ARGUMENT1       ; Set the value in the cell
                STA [INDEX]
                LDY #2
                LDA ARGUMENT1+2
                STA [INDEX],Y

                PLP
                RETURN
type_mismatch   THROW ERR_TYPE      ; Throw a type mismatch error
                .pend

;
; Gets the value of a cell in an array
;
; array(i_0, i_1, ... i_n)
;
; Inputs:
;   CURRBLOCK = pointer to the array to access
;   ARRIDXBUF = list of dimension sizes with n at ARRIDXBUF+0, d_0 at ARRIDXBUF + 1, d_1 at at ARRIDXBUF + 3, and so on 
;
; Outputs:
;   ARGUMENT1 = the value of array(i_0, i_1, ... i_n)
;
ARR_REF         .proc
                PHP
                TRACE "ARR_REF"

                CALL HEAP_GETHED    ; Set CURRHEADER for this CURRBLOCK

                PEA #0              ; Make room on the stack that ARR_CELL expects
                PEA #0
                setas
                PHA

                CALL ARR_CELL       ; INDEX := pointer to the cell desired

                setas               ; Clean up the stack
                PLA
                setal
                PLA
                PLA

                setal
                LDA [INDEX]         ; Get the value in the cell
                STA ARGUMENT1
                LDY #2
                LDA [INDEX],Y
                STA ARGUMENT1+2

                setas
                LDY #HEAPOBJ.TYPE   ; Get the type of the array
                LDA [CURRHEADER],Y
                AND #$7F            ; Mask off the ARRAY OF bit
                STA ARGTYPE1        ; Set the type of the return value

                CALL STR_NORMAL     ; Hack! If it's a string, make sure we don't return NULL

                PLP
                RETURN
                .pend
