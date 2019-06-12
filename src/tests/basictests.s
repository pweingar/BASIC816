;;;
;;; Top Level Unit Test for BASIC816
;;;

; Get the unit test framework
.include "unittests.s"
.include "evaltests.s"
.include "heaptests.s"
.include "stringtests.s"
.include "interptests.s"
.include "cmdtests.s"
.include "variabletests.s"

TST_BASIC       .proc
                CALL TST_EVAL
                CALL TST_HEAP
                CALL TST_STRINGS
                CALL TST_VARIABLES
                CALL TST_INTERP
                CALL TST_CMD

                UT_LOG "TST_BASIC: PASSED"
                RETURN
                .pend
