;;;
;;; Top Level Unit Test for BASIC816
;;;

; Get the unit test framework
.include "unittests.s"
; .include "evaltests.s"
; .include "heaptests.s"
; .include "stringtests.s"
; .include "floattests.s"
.include "tokentests.s"
; .include "interptests.s"
;.include "cmdtests.s"
.include "statementtests.s"
;.include "variabletests.s"
.include "functests.s"
.include "optests.s"
;.include "arraytests.s"

.section globals
TST_TEMP1       .dword ?
TST_TEMP2       .dword ?
TST_TEMP3       .dword ?
.send

TMP_BUFF_ORG = $014000
TMP_BUFF_SIZ = $100

TST_BASIC       .proc
                CALL UT_MSGCOLOR
                TRACE "TST_BASIC"
                ; CALL TST_HEAP
                ; CALL TST_EVAL
                ; CALL TST_STRINGS
                ; CALL TST_FLOATS
                ; CALL TST_VARIABLES
                CALL TST_TOKENS
                ; CALL TST_INTERP
                ; CALL TST_CMD
                CALL TST_OPS
                CALL TST_STMNTS
                CALL TST_FUNCS
                ; CALL TST_ARRAY

                UT_PASSED "TST_BASIC"
                RETURN
                .pend
