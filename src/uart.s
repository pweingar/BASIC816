;;;
;;; Low-level serial I/O routines
;;;

;;;
;;; UART routines
;;;
;;; UART_SELECT : Call with A = COM# to make that UART the active port for subsequent calls
;;; UART_INIT : Initialize the selected UART with some basic, standard settings
;;; UART_SETBPS : Set the transfer rate for the selected UART. A = the desired rate (e.g. UART_9600)
;;; UART_SETLCR : Set parity, stop bit, and data length parameters. A = the flags to set (see LCR_ constants)
;;; UART_HASBYT : Check to see if the receive FIFO has any data. Carry is set, if so.
;;; UART_GETC : Get a byte from the selected UART into A. Block if nothing ready.
;;; UART_PUTC : Send a byte in A to the selected UART. Block until the transmit FIFO has room.
;;; UART_PUTS : Send a nul terminated string to the UART. X = pointer to the string, B = data bank of the string.
;;;

; UARTs
UART1_BASE = $AF13F8        ; Base address for UART 1 (COM1)
UART2_BASE = $AF12F8        ; Base address for UART 2 (COM2)

; Register Offsets
UART_TRHB = $00             ; Transmit/Receive Hold Buffer
UART_DLL = UART_TRHB        ; Divisor Latch Low Byte
UART_DLH = $01              ; Divisor Latch High Byte
UART_IER = UART_DLH         ; Interupt Enable Register
UART_FCR = $02              ; FIFO Control Register
UART_IIR = UART_FCR         ; Interupt Indentification Register
UART_LCR = $03              ; Line Control Register
UART_MCR = $04              ; Modem Control REgister
UART_LSR = $05              ; Line Status Register
UART_MSR = $06              ; Modem Status Register
UART_SR = $07               ; Scratch Register

; Interupt Enable Flags
UINT_LOW_POWER = $20        ; Enable Low Power Mode (16750)
UINT_SLEEP_MODE = $10       ; Enable Sleep Mode (16750)
UINT_MODEM_STATUS = $08     ; Enable Modem Status Interrupt
UINT_LINE_STATUS = $04      ; Enable Receiver Line Status Interupt
UINT_THR_EMPTY = $02        ; Enable Transmit Holding Register Empty interrupt
UINT_DATA_AVAIL = $01       ; Enable Recieve Data Available interupt   

; Interrupt Identification Register Codes
IIR_FIFO_ENABLED = $80      ; FIFO is enabled
IIR_FIFO_NONFUNC = $40      ; FIFO is not functioning
IIR_FIFO_64BYTE = $20       ; 64 byte FIFO enabled (16750)
IIR_MODEM_STATUS = $00      ; Modem Status Interrupt
IIR_THR_EMPTY = $02         ; Transmit Holding Register Empty Interrupt
IIR_DATA_AVAIL = $04        ; Data Available Interrupt
IIR_LINE_STATUS = $06       ; Line Status Interrupt
IIR_TIMEOUT = $0C           ; Time-out Interrupt (16550 and later)
IIR_INTERRUPT_PENDING = $01 ; Interrupt Pending Flag

; Line Control Register Codes
LCR_DLB = $80               ; Divisor Latch Access Bit
LCR_SBE = $60               ; Set Break Enable

LCR_PARITY_NONE = $00       ; Parity: None
LCR_PARITY_ODD = $08        ; Parity: Odd
LCR_PARITY_EVEN = $18       ; Parity: Even
LCR_PARITY_MARK = $28       ; Parity: Mark
LCR_PARITY_SPACE = $38      ; Parity: Space

LCR_STOPBIT_1 = $00         ; One Stop Bit
LCR_STOPBIT_2 = $04         ; 1.5 or 2 Stop Bits

LCR_DATABITS_5 = $00        ; Data Bits: 5
LCR_DATABITS_6 = $01        ; Data Bits: 6
LCR_DATABITS_7 = $02        ; Data Bits: 7
LCR_DATABITS_8 = $03        ; Data Bits: 8

LSR_ERR_RECIEVE = $80       ; Error in Received FIFO
LSR_XMIT_DONE = $40         ; All data has been transmitted
LSR_XMIT_EMPTY = $20        ; Empty transmit holding register
LSR_BREAK_INT = $10         ; Break interrupt
LSR_ERR_FRAME = $08         ; Framing error
LSR_ERR_PARITY = $04        ; Parity error
LSR_ERR_OVERRUN = $02       ; Overrun error
LSR_DATA_AVAIL = $01        ; Data is ready in the receive buffer

UART_300 = 384              ; Code for 300 bps
UART_1200 = 96              ; Code for 1200 bps
UART_2400 = 48              ; Code for 2400 bps
UART_4800 = 24              ; Code for 4800 bps
UART_9600 = 12              ; Code for 9600 bps
UART_19200 = 6              ; Code for 19200 bps
UART_38400 = 3              ; Code for 28400 bps
UART_57600 = 2              ; Code for 57600 bps
UART_115200 = 1             ; Code for 115200 bps

.section globals
CURRUART    .long ?         ; Long pointer to the current UART
.send

;
; Select a UART to use. Set the CURRUART pointer to that port's base address.
;
; Inputs:
;   A = the UART number (1 or 2)
;
; Returns:
;   CURRUART = the base address of the selected UART
;
UART_SELECT .proc
            PHP
    
            setal
            CMP #2
            BEQ is_COM2

            setal
            LDA #<>UART1_BASE
            BRA setaddr

is_COM2     setal
            LDA #<>UART2_BASE
setaddr     STA @lCURRUART
            setas
            LDA #`UART1_BASE
            STA @lCURRUART+2

            PLP
            RTL
            .pend

;
; Set the transfer rate for the UART
;
; Inputs:
;   A = the transfer rate code
;
UART_SETBPS .proc
            PHP
            PHD

            setdp GLOBAL_VARS

            setaxl
            PHA

            setas
            LDY #UART_LCR       ; Enable divisor latch
            LDA [CURRUART],Y  
            ORA #LCR_DLB
            STA [CURRUART],Y

            setal
            PLA
            LDY #UART_DLL
            STA [CURRUART],Y    ; Save the divisor to the UART

            setas
            LDY #UART_LCR       ; Disable divisor latch
            LDA [CURRUART],Y  
            EOR #LCR_DLB
            STA [CURRUART],Y 

            PLD
            PLP
            RTL          
            .pend

;
; Set the line control register
;
; Input:
;   X = the port number to set (1 or 2)
;   A = the line control flags (parity, stop bit, data length)
UART_SETLCR .proc
            PHP
            PHD

            setdp GLOBAL_VARS

            setas
            setxl
            AND #$7F            ; We don't want to alter divisor latch
            LDY #UART_LCR
            STA [CURRUART],Y

            PLD
            PLP
            RTL
            .pend

;
; Initialize the serial port to a default state:
;   115200, 1 stop bit, no parity, 8 data bits
;
UART_INIT   .proc
            PHP
            PHD
            setaxl

            setdp GLOBAL_VARS

            ; Set speed to 115200 bps
            LDA #UART_115200
            JSL UART_SETBPS

            ; Set: no parity, 1 stop bit, 8 data bits
            setas
            LDA #LCR_PARITY_NONE | LCR_STOPBIT_1 | LCR_DATABITS_8
            JSL UART_SETLCR

            ; Enable FIFOs, set for 56 byte tigger level
            LDA #%11100001
            LDY #UART_FCR
            STA [CURRUART],Y

            PLD
            PLP
            RTL
            .pend

;
; Check to see if a character is waiting on the receive FIFO.
;
; Outputs:
;   C is set if a character is available
;
UART_HASBYT .proc
            PHP
            PHD

            setaxl
            setdp GLOBAL_VARS

            setas                  
            LDY #UART_LSR           ; Check the receive FIFO
wait_putc   LDA [CURRUART],Y
            AND #LSR_DATA_AVAIL
            BNE ret_true            ; If flag is set, return true

ret_false   PLD                     ; Return false
            PLP
            CLC
            RTL

ret_true    PLD                     ; Return true
            PLP
            SEC
            RTL
            .pend

;
; Get a character from the selected UART's receive FIFO.
; Block if nothing is ready.
;
; Outputs:
;   A = the character read
;
UART_GETC   .proc
            PHP
            PHD

            setaxl
            setdp GLOBAL_VARS

            setas                  
            LDY #UART_LSR           ; Check the receive FIFO
wait_getc   LDA [CURRUART],Y
            AND #LSR_DATA_AVAIL
            BEQ wait_getc           ; If the flag is clear, wait

            LDY #UART_TRHB          ; Get the byte from the receive FIFO
            LDA [CURRUART],Y

            PLD
            PLP
            RTL
            .pend

;
; Send a byte to the UART
;
; Inputs:
;   A = the character to print
;   X = the port to use
;
UART_PUTC   .proc
            PHP
            PHD

            setaxl
            setdp GLOBAL_VARS

            setas
            PHA                     ; Wait for the transmit FIFO to free up
            LDY #UART_LSR
wait_putc   LDA [CURRUART],Y
            AND #LSR_XMIT_EMPTY
            BEQ wait_putc
            PLA

            LDY #UART_TRHB
            STA [CURRUART],Y

            PLD
            PLP
            RTL
            .pend

;
; Send a nul-terminated string to the selected UART
;
; Inputs:
;   B = the data bank for the string
;   X = the pointer to the string
;
UART_PUTS   .proc
            PHP

            setas
put_loop    LDA #0,B,X
            BEQ done
            JSL UART_PUTC
            INX
            BRA put_loop

done        PLP
            RTL
            .pend
