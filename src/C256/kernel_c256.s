;;;
;;; Kernel Jump Table for C256 Foenix
;;;

FK_GETCHW           = $38104c ; Get a character from the input channel. Waits until data received. A=0 and Carry=1 if no data is wating
FK_PUTC             = $381018 ; Print a character to the currently selected channel
FK_PUTS             = $38101C ; Print a string to the currently selected channel
FK_LOCATE           = $381084 ; Reposition the cursor to row Y column X
FK_IPRINTH          = $381078 ; Print a HEX string
FK_SETOUT           = $38103c ; Select an output channel

FK_OPEN             = $3810F0 ; open a file for reading/writing/creating
FK_CREATE           = $3810F4 ; create a new file
FK_CLOSE            = $3810F8 ; close a file (make sure last cluster is written)
FK_WRITE            = $3810FC ; write the current cluster to the file
FK_READ             = $381100 ; read the next cluster from the file
FK_DELETE           = $381104 ; delete a file / directory
FK_DIROPEN          = $381108 ; open a directory and seek the first directory entry
FK_DIRNEXT          = $38110C ; seek to the next directory of an open directory
FK_DIRREAD          = $381110 ; Read the directory entry for the specified file
FK_DIRWRITE         = $381114 ; Write any changes in the current directory cluster back to the drive
FK_LOAD             = $381118 ; load a binary file into memory, supports multiple file formats
FK_SAVE             = $38111C ; Save memory to a binary file

;;;
;;; Kernel Constants
;;;

CHAN_CONSOLE = 0
CHAN_COM1 = 1
CHAN_COM2 = 2
