;;;
;;; Code to bootstrap the interpreter on the C64
;;;

            ; Insert BASIC stub for C64 testing
            .word ss, 10
            .null $9e, format("%d", START)
ss          .word 0