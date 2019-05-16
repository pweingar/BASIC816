;;;
;;; Kernel Jump Table for C256 Foenix
;;;

BOOT             = $190000 ; Cold boot routine
RESTORE          = $190004 ; Warm boot routine
BREAK            = $190008 ; End program and return to command prompt
READY            = $19000C ; Print prompt and wait for keyboard input
SCINIT           = $190010 ;
IOINIT           = $190014 ;
PUTC             = $190018 ; Print a character to the currently selected channel
PUTS             = $19001C ; Print a string to the currently selected channel
PUTB             = $190020 ; Output a byte to the currently selected channel
PUTBLOCK         = $190024 ; Ouput a binary block to the currently selected channel
SETLFS           = $190028 ; Obsolete (done in OPEN)
SETNAM           = $19002C ; Obsolete (done in OPEN)
OPEN             = $190030 ; Open a channel for reading and/or writing. Use SETLFS and SETNAM to set the channels and filename first.
CLOSE            = $190034 ; Close a channel
SETIN            = $190038 ; Set the current input channel
SETOUT           = $19003C ; Set the current output channel
GETB             = $190040 ; Get a byte from input channel. Return 0 if no input. Carry is set if no input.
GETBLOCK         = $190044 ; Get a X byes from input channel. If Carry is set, wait. If Carry is clear, do not wait.
GETCH            = $190048 ; Get a character from the input channel. A=0 and Carry=1 if no data is wating
GETCHW           = $19004C ; Get a character from the input channel. Waits until data received. A=0 and Carry=1 if no data is wating
GETCHE           = $190050 ; Get a character from the input channel and echo to the screen. Wait if data is not ready.
GETS             = $190054 ; Get a string from the input channel. NULL terminates
GETLINE          = $190058 ; Get a line of text from input channel. CR or NULL terminates.
GETFIELD         = $19005C ; Get a field from the input channel. Value in A, CR, or NULL terminates
TRIM             = $190060 ; Removes spaces at beginning and end of string.
PRINTC           = $190064 ; Print character to screen. Handles terminal commands
PRINTS           = $190068 ; Print string to screen. Handles terminal commands
PRINTCR          = $19006C ; Print Carriage Return
PRINTF           = $190070 ; Print a float value
PRINTI           = $190074 ; Prints integer value in TEMP
PRINTH           = $190078 ; Print Hex value in DP variable
PRINTAI          = $19007C ; Prints integer value in A
PRINTAH          = $190080 ; Prints hex value in A. Printed value is 2 wide if M flag is 1, 4 wide if M=0
LOCATE           = $190084 ;
PUSHKEY          = $190088 ;
PUSHKEYS         = $19008C ;
CSRRIGHT         = $190090 ;
CSRLEFT          = $190094 ;
CSRUP            = $190098 ;
CSRDOWN          = $19009C ;
CSRHOME          = $1900A0 ;
SCROLLUP         = $1900A4 ; Scroll the screen up one line. Creates an empty line at the bottom.
SCRREADLINE      = $1900A8 ; Loads the MCMDADDR/BCMDADDR variable with the address of the current line on the screen. This is called when the RETURN key is pressed and is the first step in processing an immediate mode command.
SCRGETWORD       = $1900AC ; Read a current word on the screen. A word ends with a space, punctuation (except _), or any control character (value < 32). Loads the address into CMPTEXT_VAL and length into CMPTEXT_LEN variables.
CLRSCREEN        = $1900B0 ; Clear the screen
INITCHLUT        = $1900B4 ; Init character look-up table
INITSUPERIO      = $1900B8 ; Init Super-IO chip
INITKEYBOARD     = $1900BC ; Init keyboard
INITRTC          = $1900C0 ; Init Real-Time Clock
INITCURSOR       = $1900C4 ; Init the Cursors registers
INITFONTSET      = $1900C8 ; Init the Internal FONT Memory
INITGAMMATABLE   = $1900CC ; Init the RGB GAMMA Look Up Table
INITALLLUT       = $1900D0 ; Init the Graphic Engine (Bitmap/Tile/Sprites) LUT
INITVKYTXTMODE   = $1900D4 ; Init the Text Mode @ Reset Time
INITVKYGRPMODE   = $1900D8 ; Init the Basic Registers for the Graphic Mode