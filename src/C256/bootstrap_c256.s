;;;
;;; Code to bootstrap the interpreter on the C256 Foenix
;;;

; Override RESET vector to point to the start of BASIC

.section bootblock
COLDSTART   JML START
.send

.section vectors
RESTART     .word <>COLDSTART
.send