;;;
;;; Custom Functions for the C256 Foenix
;;;

;
; Write the BCD number in A as a string to [STRPTR],Y
;
BCD2STR     .proc
            PHP
            setas

            STA SAVE_A
            LSR A 
            LSR A 
            LSR A 
            LSR A 
            AND #$0F
            CLC
            ADC #'0'
            STA [STRPTR],Y
            INY

            LDA SAVE_A
            AND #$0F
            CLC
            ADC #'0'
            STA [STRPTR],Y
            INY

            PLP
            RETURN            
            .pend

;
; Get the current date from the RTC
; "DD/MM/YY" = GETDATE$(0)
;
F_GETDATE   .proc
            FN_START "F_GETDATE"
            PHP

            CALL EVALEXPR           ; Evaluate the argument, but we don't care what it is

            setas
            setxl

            LDA @lRTC_CTRL          ; Pause updates to the clock registers
            ORA #%00001000
            STA @lRTC_CTRL

            CALL TEMPSTRING         ; Get the temporary string
            LDY #0

            LDA @lRTC_DAY           ; Write the day of the month
            CALL BCD2STR   

            LDA #'/'                ; Write the separator
            STA [STRPTR],Y
            INY

            LDA @lRTC_MONTH         ; Write the month
            CALL BCD2STR          

            LDA #'/'                ; Write the separator
            STA [STRPTR],Y
            INY

            LDA @lRTC_CENTURY       ; Write the year
            CALL BCD2STR
            LDA @lRTC_YEAR          ; Write the year
            CALL BCD2STR

            LDA #0                  ; NULL terminate the string
            STA [STRPTR],Y

            LDA @lRTC_CTRL          ; Re-enable updates to the clock registers
            AND #%11110111
            STA @lRTC_CTRL

            setal                   ; Copy the date string to the heap
            LDA STRPTR
            STA ARGUMENT1
            LDA STRPTR+2
            STA ARGUMENT1+2
            setas
            LDA #TYPE_STRING
            STA ARGTYPE1

            PLP
            FN_END
            RETURN
            .pend

;
; Get the current time from the RTC
; "HH:MM:SS" = GETTIME$(0)
;
F_GETTIME   .proc
            FN_START "F_GETTIME"
            PHP

            CALL EVALEXPR           ; Evaluate the argument, but we don't care what it is

            setas
            setxl

            LDA @lRTC_CTRL          ; Pause updates to the clock registers
            ORA #%00001000
            STA @lRTC_CTRL

            CALL TEMPSTRING         ; Get the temporary string
            LDY #0

            LDA @lRTC_HRS           ; Write the hour
            AND #$7F                ; Trim out the AM/PM indicator
            CALL BCD2STR   

            LDA #':'                ; Write the separator
            STA [STRPTR],Y
            INY

            LDA @lRTC_MIN           ; Write the minute
            CALL BCD2STR          

            LDA #':'                ; Write the separator
            STA [STRPTR],Y
            INY

            LDA @lRTC_SEC           ; Write the second
            CALL BCD2STR

            LDA #0                  ; NULL terminate the string
            STA [STRPTR],Y

            LDA @lRTC_CTRL          ; Re-enable updates to the clock registers
            AND #%11110111
            STA @lRTC_CTRL

            setal                   ; Copy the date string to the heap
            LDA STRPTR
            STA ARGUMENT1
            LDA STRPTR+2
            STA ARGUMENT1+2
            setas
            LDA #TYPE_STRING
            STA ARGTYPE1

            PLP
            FN_END
            RETURN
            .pend

;
; Return a random floating point number
;
FN_RND      .proc
            FN_START "FN_RND"
            PHP

            CALL EVALEXPR               ; Evaluate the argument, but we don't care what it is

            setas
            LDA #TYPE_FLOAT             ; We'll return a floating point number
            STA ARGTYPE1

            LDA #FP_CTRL0_CONV_0 | FP_CTRL0_CONV_1
            STA @l FP_MATH_CTRL0        ; Expect fixed point numbers

            LDA #FP_OUT_DIV             ; Set us to do a division
            STA @l FP_MATH_CTRL1

            setaxl
            LDA @l GABE_RNG_DAT_LO      ; Get a random 16-bits
            STA @l FP_MATH_INPUT0_LL    ; Send them to the FP unit
            LDA @l GABE_RNG_DAT_LO      ; Get another random 16-bits
            AND #$7FFF                  ; Make sure it's positive
            STA @l FP_MATH_INPUT0_LL+2  ; Send them to the FP unit

            LDA #$FFFF                  ; Get the maximum value
            STA @l FP_MATH_INPUT1_LL    ; Send it to the FP unit
            LDA #$7FFF
            STA @l FP_MATH_INPUT1_LL+2

            NOP
            NOP
            NOP

            LDA @l FP_MATH_OUTPUT_FP_LL     ; Get the normalized result
            STA ARGUMENT1
            LDA @l FP_MATH_OUTPUT_FP_LL+2
            STA ARGUMENT1+2

            PLP
            FN_END
            RETURN
            .pend