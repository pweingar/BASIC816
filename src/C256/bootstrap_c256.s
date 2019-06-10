;;;
;;; Code to bootstrap the interpreter on the C256 Foenix
;;;

; Override RESET vector to point to the start of BASIC

.section vectors
RESTART     .word <>START
.send