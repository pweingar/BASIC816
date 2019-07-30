;;;
;;; Custom statements for the C256
;;;

; BLOAD path,destination
; BSAVE path,source
; LOAD path
; SAVE path

; SETLUTCOLOR lut,index,red,green,blue,alpha

;
; Set the time on the real time clock
; SETTIME hour,minute,second
;
S_SETTIME       .proc
                PHP
                TRACE "S_SETTIME"

                setas

                CALL EVALEXPR           ; Get the hour number
                CALL ASS_ARG1_BYTE      ; Make sure it's a byte
                CALL DIVINT10           ; Separate both digits
                LDA ARGUMENT1           ; Take the tens digit
                ASL A                   ; Shift it 4 bits
                ASL A
                ASL A
                ASL A
                ORA ARGUMENT2           ; And add in the ones digit
                STA SCRATCH

                LDA #','
                CALL EXPECT_TOK

                CALL EVALEXPR           ; Get the minute number
                CALL ASS_ARG1_BYTE      ; Make sure it's a byte
                CALL DIVINT10           ; Separate both digits
                LDA ARGUMENT1           ; Take the tens digit
                ASL A                   ; Shift it 4 bits
                ASL A
                ASL A
                ASL A
                ORA ARGUMENT2           ; And add in the ones digit
                STA SCRATCH+1

                LDA #','
                CALL EXPECT_TOK

                CALL EVALEXPR           ; Get the second number
                CALL ASS_ARG1_BYTE      ; Make sure it's a byte
                CALL DIVINT10           ; Separate both digits
                LDA ARGUMENT1           ; Take the tens digit
                ASL A                   ; Shift it 4 bits
                ASL A
                ASL A
                ASL A
                ORA ARGUMENT2           ; And add in the ones digit
                STA SCRATCH+2

                LDA @lRTC_CTRL          ; Pause updates to the clock registers
                ORA #%00001000
                STA @lRTC_CTRL

                LDA SCRATCH             ; Save the hour...
                STA @lRTC_HRS

                LDA SCRATCH+1           ; Minutes...
                STA @lRTC_MIN

                LDA SCRATCH+2           ; And seconds to the RTC
                STA @lRTC_SEC

                LDA @lRTC_CTRL          ; Re-enable updates to the clock registers
                AND #%11110111
                STA @lRTC_CTRL

                PLP
                RETURN
                .pend

;
; Set the date on the real time clock
; SETDATE day,month,year
;
S_SETDATE       .proc
                PHP
                TRACE "S_SETDATE"

                setas

                CALL EVALEXPR           ; Get the day number
                CALL ASS_ARG1_BYTE      ; Make sure it's a byte
                CALL DIVINT10           ; Separate both digits
                LDA ARGUMENT1           ; Take the tens digit
                ASL A                   ; Shift it 4 bits
                ASL A
                ASL A
                ASL A
                ORA ARGUMENT2           ; And add in the ones digit
                STA SCRATCH

                LDA #','
                CALL EXPECT_TOK

                CALL EVALEXPR           ; Get the month number
                CALL ASS_ARG1_BYTE      ; Make sure it's a byte
                CALL DIVINT10           ; Separate both digits
                LDA ARGUMENT1           ; Take the tens digit
                ASL A                   ; Shift it 4 bits
                ASL A
                ASL A
                ASL A
                ORA ARGUMENT2           ; And add in the ones digit
                STA SCRATCH+1

                LDA #','
                CALL EXPECT_TOK

                CALL EVALEXPR           ; Get the year number
                CALL ASS_ARG1_BYTE      ; Make sure it's a byte
                CALL DIVINT10           ; Separate both digits
                LDA ARGUMENT1           ; Take the tens digit
                ASL A                   ; Shift it 4 bits
                ASL A
                ASL A
                ASL A
                ORA ARGUMENT2           ; And add in the ones digit
                STA SCRATCH+2

                LDA @lRTC_CTRL          ; Pause updates to the clock registers
                ORA #%00001000
                STA @lRTC_CTRL

                LDA SCRATCH             ; Save the day...
                STA @lRTC_DAY

                LDA SCRATCH+1           ; Month...
                STA @lRTC_MONTH

                LDA SCRATCH+2           ; And year to the RTC
                STA @lRTC_YEAR

                LDA @lRTC_CTRL          ; Re-enable updates to the clock registers
                AND #%11110111
                STA @lRTC_CTRL

                PLP
                RETURN
                .pend


;
; Set the text foreground color
; SETFGCOLOR index
;
; Inputs:
;   ARGUMENT1 = the index of the foreground color
;
S_SETFGCOLOR    .proc
                PHP
                TRACE "S_SETFGCOLOR"

                ; TODO: convert float arguments to integer

                CALL EVALEXPR       ; Get the red component
                CALL ASS_ARG1_BYTE  ; Assert that the result is a byte value

                setas
                LDA ARGUMENT1       ; Covert the color number to the right position
                AND #$0F
                .rept 4
                ASL A
                .next

                STA SCRATCH
                LDA @lCURCOLOR      ; Mask off the old foreground color
                AND #$0F
                ORA SCRATCH            ; And add in the new one
                STA @lCURCOLOR

                PLP
                RETURN
                .pend

;
; Set the text background color
; SETBGCOLOR index
;
; Inputs:
;   ARGUMENT1 = the index of the background color
;
S_SETBGCOLOR    .proc
                PHP
                TRACE "S_SETBGCOLOR"

                ; TODO: convert float arguments to integer

                CALL EVALEXPR       ; Get the red component
                CALL ASS_ARG1_BYTE  ; Assert that the result is a byte value

                setas
                LDA ARGUMENT1       ; Make sure the index is just 4 bits
                AND #$0F

                STA SCRATCH
                LDA @lCURCOLOR      ; Mask off the old background color
                AND #$F0
                ORA SCRATCH            ; And add in the new one
                STA @lCURCOLOR

                PLP
                RETURN
                .pend

; Set the border color give red, green, and blue components
; SETBRDCOLOR red, green, blue
S_SETBRDCOLOR   .proc
                PHP
                TRACE "S_SETBRDCOLOR"

                ; TODO: convert float arguments to integer

                CALL EVALEXPR       ; Get the red component
                CALL ASS_ARG1_BYTE  ; Assert that the result is a byte value

                setas
                LDA ARGUMENT1       ; Save the red component to the stack
                PHA

                LDA #','
                CALL EXPECT_TOK     ; Try to find the comma

                CALL EVALEXPR       ; Get the green component
                CALL ASS_ARG1_BYTE  ; Assert that the result is a byte value

                LDA ARGUMENT1       ; Save the green component to the stack
                PHA

                LDA #','
                CALL EXPECT_TOK     ; Try to find the comma

                CALL EVALEXPR       ; Get the blue component
                CALL ASS_ARG1_BYTE  ; Assert that the result is a byte value

                LDA ARGUMENT1
                STA @lBORDER_COLOR_B    ; Set the border color
                PLA
                STA @lBORDER_COLOR_G
                PLA
                STA @lBORDER_COLOR_R            

                PLP
                RETURN
                .pend
