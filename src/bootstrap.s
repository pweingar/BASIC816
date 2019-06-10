;;;
;;; Code to bootstrap the interpreter
;;;
;;; This code is system dependent
;;;

.if SYSTEM == SYSTEM_C64
    .include "CBM/bootstrap_CBM.s"
.elsif SYSTEM == SYSTEM_C256
    .include "C256/bootstrap_c256.s"
.endif