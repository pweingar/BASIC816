;;;
;;; C256 Math Coprocessor Utilities
;;;

;
; Divide the unsigned integer value in A by the value in X
;
; Inputs:
;   A = the numerator
;   X = the divisor
;
; Outputs:
;   A = the quotient
;   X = the remainder

UINT_DIV_A_X        .proc
                    PHP

                    setal
                    STA @l UNSIGNED_DIV_NUM_LO
                    TXA
                    STA @l UNSIGNED_DIV_DEM_LO

                    LDA @l UNSIGNED_DIV_REM_LO
                    TAX
                    LDA @l UNSIGNED_DIV_QUO_LO

                    PLP
                    RETURN
                    .pend

;
; Divide the signed integer value in A by the value in X
;
; Inputs:
;   A = the numerator
;   X = the divisor
;
; Outputs:
;   A = the quotient
;   X = the remainder

INT_DIV_A_X         .proc
                    PHP

                    setal
                    STA @l SIGNED_DIV_NUM_LO
                    TXA
                    STA @l SIGNED_DIV_DEM_LO

                    LDA @l SIGNED_DIV_REM_LO
                    TAX
                    LDA @l SIGNED_DIV_QUO_LO

                    PLP
                    RETURN
                    .pend