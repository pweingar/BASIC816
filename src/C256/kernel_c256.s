;;;
;;; Kernel Jump Table for C256 Foenix
;;;

FK_GETCHW           = $00104c ; Get a character from the input channel. Waits until data received. A=0 and Carry=1 if no data is wating
FK_PUTC             = $001018 ; Print a character to the currently selected channel
FK_PUTS             = $00101C ; Print a string to the currently selected channel
FK_LOCATE           = $001084 ; Reposition the cursor to row Y column X
FK_IPRINTH          = $001078 ; Print a HEX string