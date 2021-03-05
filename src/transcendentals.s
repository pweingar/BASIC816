;
; POLY_HR - Horner's rule
;
; On entry: as, xl
; X points to coefficient table of 5 values
; ARGUMENT1 contains a floating-point argument (which may be x,
;   or x*x, depending on the actual function being approximated.)
; Leaves the value in ARGUMENT1
POLY_HR         .proc
                PHY
                setas
                ;; Set up adder for input from input muxes and ADD operation.
                ;; Set the muxes to take fp input.
                LDA #FP_MATH_CTRL0_ADD | FP_ADD_IN0_MUX0 | FP_ADD_IN1_MUX1
                STA @l FP_MATH_CTRL0
                setal
                ;; Get first coefficient (highest-ordered, as they are stored
                ;; in reverse order)
                LDA 0,X
                STA @l FP_MATH_INPUT0_LL
                LDA 2,X
                STA @l FP_MATH_INPUT0_HL
                LDY #4          ; 5 coefficients.
loop            INX
                INX
                INX
                INX
                setas
                LDA #FP_OUT_MULT
                STA @l FP_MATH_CTRL1
                setal
                LDA @l ARGUMENT1
                STA @l FP_MATH_INPUT1_LL
                LDA @l ARGUMENT1+2
                STA @l FP_MATH_INPUT1_HL
                NOP
                NOP
                NOP
                LDA @l FP_MATH_OUTPUT_FP_LL
                PHA
                LDA @l FP_MATH_OUTPUT_FP_HL
                STA FP_MATH_INPUT0_HL
                PLA
                STA @l FP_MATH_INPUT0_LL
                setas
                LDA #FP_OUT_ADD
                STA @l FP_MATH_CTRL1
                setal
                LDA 0,X
                STA @l FP_MATH_INPUT1_LL
                LDA 2,X
                STA @l FP_MATH_INPUT1_HL
                NOP
                NOP
                NOP
                DEY
                BEQ done
                LDA @l FP_MATH_OUTPUT_FP_LL
                STA @l FP_MATH_INPUT0_LL
                LDA @l FP_MATH_OUTPUT_FP_HL
                STA @l FP_MATH_INPUT0_HL
                BRL loop
done            LDA @l FP_MATH_OUTPUT_FP_LL
                STA @l ARGUMENT1
                LDA @l FP_MATH_OUTPUT_FP_HL
                STA @l ARGUMENT1+2
                PLY
                RTS
                .pend

Q_SQ            .proc
                setas
                LDA #0
                STA @l FP_MATH_CTRL0
                LDA #FP_OUT_MULT
                STA @l FP_MATH_CTRL1
                setal
                LDA ARGUMENT1
                STA @l FP_MATH_INPUT0_LL
                STA @l FP_MATH_INPUT1_LL
                LDA @l ARGUMENT1+2
                STA @l FP_MATH_INPUT0_HL
                STA @l FP_MATH_INPUT1_HL
                NOP
                NOP
                NOP
                LDA @l FP_MATH_OUTPUT_FP_LL
                STA ARGUMENT1
                LDA @l FP_MATH_OUTPUT_FP_HL
                STA ARGUMENT1+2
                RTS
                .pend

FP_COS          .proc
                PHP
                setaxl
                PHA
                PHX
                CALL Q_SQ
                PHB
                setas
                LDA #`cos_coeff
                PHA
                PLB
                setal
                LDX #<>cos_coeff
                CALL POLY_HR
                LDA #TYPE_FLOAT
                STA @l ARGTYPE1
                PLB
                PLX
                PLA
                PLP
                RETURN
                .pend

FP_SIN          .proc
                PHP
                setaxl
                PHA
                PHX
                LDA ARGUMENT1
                STA ARGUMENT2
                LDA ARGUMENT1+2
                STA ARGUMENT2+2
                CALL Q_SQ
                PHB
                setas
                LDA #`sin_coeff
                PHA
                PLB
                setal
                LDX #<>sin_coeff
                CALL POLY_HR
                PLB
                CALL OP_FP_MUL
                PLX
                PLA
                PLP
                RETURN
                .pend

FP_TAN          .proc
                PHP
                setaxl
                PHA
                LDA ARGUMENT1
                STA SCRATCH
                LDA ARGUMENT1+2
                STA SCRATCH+2
                CALL FP_COS
                LDA ARGUMENT1
                PHA
                LDA ARGUMENT1+2
                PHA
                LDA SCRATCH
                STA ARGUMENT1
                LDA SCRATCH+2
                STA ARGUMENT1+2
                CALL FP_SIN
                PLA
                STA ARGUMENT2+2
                PLA
                STA ARGUMENT2
                CALL OP_FP_DIV
                setal
                PLA
                PLP
                RETURN
                .pend

FP_LN           .proc
                PHP
                setaxl
                PHA
                PHX
                setas
                LDA #FP_ADD_IN0_MUX0 | FP_ADD_IN1_MUX1
                STA @l FP_MATH_CTRL0
                LDA #FP_OUT_ADD
                STA @l FP_MATH_CTRL1
                setal
                LDA ARGUMENT1
                STA @l FP_MATH_INPUT0_LL
                LDA ARGUMENT1+2
                STA @l FP_MATH_INPUT0_HL
                LDA @l fp_one
                STA @l FP_MATH_INPUT1_LL
                LDA @l fp_one+2
                STA @l FP_MATH_INPUT1_HL
                NOP
                NOP
                NOP
                LDA @l FP_MATH_OUTPUT_FP_LL
                STA SCRATCH
                LDA @l FP_MATH_OUTPUT_FP_HL
                STA SCRATCH+2
                setas
                LDA #FP_MATH_CTRL0_ADD | FP_ADD_IN0_MUX0 | FP_ADD_IN1_MUX1
                STA @l FP_MATH_CTRL0
                setal
                NOP
                NOP
                NOP
                LDA @l FP_MATH_OUTPUT_FP_LL
                STA SCRATCH2
                LDA @l FP_MATH_OUTPUT_FP_HL
                STA SCRATCH2+2
                setas
                LDA #FP_OUT_DIV
                STA @l FP_MATH_CTRL1
                setal
                LDA SCRATCH
                STA @l FP_MATH_INPUT0_LL
                LDA SCRATCH+2
                STA @l FP_MATH_INPUT0_HL
                LDA SCRATCH2
                STA @l FP_MATH_INPUT1_LL
                LDA SCRATCH2+2
                STA @l FP_MATH_INPUT1_HL
                NOP
                NOP
                NOP
                LDA @l FP_MATH_OUTPUT_FP_LL
                STA ARGUMENT1
                LDA @l FP_MATH_OUTPUT_FP_HL
                STA ARGUMENT1+2
                ;; send MUX0 to both adder inputs
                setas
                LDA #FP_MATH_CTRL0_ADD | FP_ADD_IN0_MUX0 | FP_ADD_IN1_MUX0
                STA @l FP_MATH_CTRL0
                LDA #FP_OUT_ADD
                STA @l FP_MATH_CTRL1
                setal
                LDA ARGUMENT1
                STA @l FP_MATH_INPUT0_LL
                LDA ARGUMENT1+2
                STA @l FP_MATH_INPUT0_HL
                NOP
                NOP
                NOP
                LDA @l FP_MATH_OUTPUT_FP_LL
                STA ARGUMENT2
                LDA @l FP_MATH_OUTPUT_FP_HL
                STA ARGUMENT2+2
                CALL Q_SQ
                PHB
                setas
                LDA #`ln_coeff
                PHA
                PLB
                setal
                LDX #<>ln_coeff
                CALL POLY_HR
                LDA #TYPE_FLOAT
                STA @l ARGTYPE1
                STA @l ARGTYPE1
                CALL OP_FP_MUL
                PLB
                PLX
                PLA
                PLP
                RETURN
                .pend

cos_coeff
                .dword $37D00D01
                .dword $BAB60B61
                .dword $3D2AAAAB
                .dword $BF000000
                .dword $3F800000

sin_coeff
                .dword $3638EF1D
                .dword $B9500D01
                .dword $3C088889
                .dword $BE2AAAAB
                .dword $3F800000

ln_coeff        .dword $3DE38E39
                .dword $3E124925
                .dword $3E4CCCCD
                .dword $3EAAAAAB
fp_one          .dword $3F800000

eexp64          .dword $6DA12CC1
eexp16          .dword $4B07975F
eexp04          .dword $425A6481
eexp01          .dword $402DF854

twopi100        .dword $441D1463
twopi010        .dword $427B53D1
twopi001        .dword $40C90FDB
