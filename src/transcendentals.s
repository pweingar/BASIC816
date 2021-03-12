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

;;; "quick" scaling function: as long as ARGUMENT1 < ARGUMENT2, place
;;; ARGUMENT1 in FP input 0 of fp copro, read out result, store back
;;; in ARGUMENT1. Return the number of times through the loop in X.
;;; Assumes that ARGUMENT2 has already been copied to fp input 1 of
;;; the float coprocessor, and that the float coprocessor has been
;;; setup for the appropriate operation.
;;; Also assumes that both A and index registers are setup for 16-bit
;;; operation.
Q_FP_SCALE      .proc
                .al
                .xl
                LDX #0
loop            LDA ARGUMENT1
                CMP ARGUMENT2
                LDA ARGUMENT1+2
                SBC ARGUMENT2+2
                BMI done
                LDA ARGUMENT1
                STA @l FP_MATH_INPUT0_LL
                LDA ARGUMENT1+2
                STA @l FP_MATH_INPUT0_HL
                NOP
                NOP
                NOP
                LDA @l FP_MATH_OUTPUT_FP_LL
                STA ARGUMENT1
                LDA @l FP_MATH_OUTPUT_FP_HL
                STA ARGUMENT1+2
                INX
                BRA loop
done
                RETURN
                .pend

Q_FP_SCALE_TAU  .proc
                setas
                LDA ARGUMENT1+3
                BPL notneg
                AND #$7F
                STA ARGUMENT1+3
                LDA #1
                PHA
                BRA compute
notneg          LDA #0
                PHA
compute         LDA #FP_ADD_IN0_MUX0 | FP_ADD_IN1_MUX1
                STA @l FP_MATH_CTRL0
                LDA #FP_OUT_ADD
                STA @l FP_MATH_CTRL1
                setaxl
                LDA @l twopi001
                STA @l FP_MATH_INPUT1_LL
                LDA @l twopi001+2
                STA @l FP_MATH_INPUT1_HL
                CALL Q_FP_SCALE
                setas
                PLA
                setal
                BEQ done
                LDA ARGUMENT1
                STA @l FP_MATH_INPUT1_LL
                LDA ARGUMENT1+2
                STA @l FP_MATH_INPUT1_HL
                NOP
                NOP
                NOP
                LDA @l FP_MATH_OUTPUT_FP_LL
                STA ARGUMENT1
                LDA @l FP_MATH_OUTPUT_FP_HL
                AND #$7fff
                STA ARGUMENT1+2
done
                RETURN
                .pend

Q_FP_NORM_ANGLE .proc
                .al
                .xl
                LDX #0
                LDA ARGUMENT1
                CMP @l onepi
                LDA ARGUMENT1+2
                SBC @l onepi+2
                BPL ltonepi
        ;; between pi and 2*pi. At this point, ARGUMENT2 should already
        ;; be 2*pi, and the fp copro should be set up to subtract
        ;; input 1 (ARGUMENT2) from input 0, but we need to copy
        ;; ARGUMENT1 into input 0
                LDA ARGUMENT1
                STA @l FP_MATH_INPUT0_LL
                LDA ARGUMENT1+2
                STA @l FP_MATH_INPUT0_HL
                NOP
                NOP
                NOP
                LDA @l FP_MATH_OUTPUT_FP_LL
                STA ARGUMENT1
                LDA @l FP_MATH_OUTPUT_FP_HL
                ORA #$8000
                STA ARGUMENT1+2
                SEC
ltonepi         TXA
                ROL
                TAX
                LDA ARGUMENT1
                CMP @l halfpi
                LDA ARGUMENT1+2
                SBC @l halfpi+2
                BPL lthalfpi
                LDA @l onepi
                STA @l FP_MATH_INPUT0_LL
                LDA @l onepi+2
                STA @l FP_MATH_INPUT0_HL
                LDA ARGUMENT1
                STA @l FP_MATH_INPUT1_LL
                LDA ARGUMENT1+2
                STA @l FP_MATH_INPUT1_HL
                NOP
                NOP
                NOP
                LDA @l FP_MATH_OUTPUT_FP_LL
                STA ARGUMENT1
                LDA @l FP_MATH_OUTPUT_FP_HL
                STA ARGUMENT1+2
                SEC
lthalfpi        TXA
                ROL
                TAX
                LDA ARGUMENT1
                CMP @l quarterpi
                LDA ARGUMENT1+2
                CMP @l quarterpi+2
                BPL ltquarterpi
                LDA @l halfpi
                STA @l FP_MATH_INPUT0_LL
                LDA @l halfpi+2
                STA @l FP_MATH_INPUT0_HL
                LDA ARGUMENT1
                STA @l FP_MATH_INPUT1_LL
                LDA ARGUMENT1+2
                STA @l FP_MATH_INPUT1_HL
                NOP
                NOP
                NOP
                LDA @l FP_MATH_OUTPUT_FP_LL
                STA ARGUMENT1
                LDA @l FP_MATH_OUTPUT_FP_HL
                STA ARGUMENT1+2
                SEC
ltquarterpi     TXA
                ROL
                TAX
                RETURN
                .pend

FP_SCALE        .proc
                PHP
                setaxl
                PHA
                PHX
                CALL Q_FP_SCALE_TAU
                PLX
                PLY
                PLP
                RETURN
                .pend

;;; "quick" cosine computation, assuming that the argument is in the
;;; range [0, pi/4].
Q_FP_COS        .proc
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

;;; "quick" sine computation, assuming that the argument is in the
;;; range [0, pi/4]
Q_FP_SIN        .proc
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

;;; "quick" tangent computation, assuming that the argument is in the
;;; range [0, pi/4].
Q_FP_TAN        .proc
                PHP
                setaxl
                PHA
                LDA ARGUMENT1
                STA SCRATCH
                LDA ARGUMENT1+2
                STA SCRATCH+2
                CALL Q_FP_COS
                LDA ARGUMENT1
                PHA
                LDA ARGUMENT1+2
                PHA
                LDA SCRATCH
                STA ARGUMENT1
                LDA SCRATCH+2
                STA ARGUMENT1+2
                CALL Q_FP_SIN
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

Q_FP_LN         .proc
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

FP_SIN          .proc
                PHP
                setaxl
                PHA
                PHX
                CALL Q_FP_SCALE_TAU
                CALL Q_FP_NORM_ANGLE
                BRA DONE
                TXA
                AND #1
                BNE do_cos
                CALL Q_FP_SIN
                BRA maybe_neg
do_cos          CALL Q_FP_COS
maybe_neg       TXA
                AND #4
                BEQ done
                setas
                LDA ARGUMENT1+3
                ORA #$80
                STA ARGUMENT1+3
                setal
done            PLX
                PLA
                PLP
                RETURN
                .pend

FP_COS          .proc
                PHP
                setaxl
                PHA
                PHX
                CALL Q_FP_SCALE_TAU
                CALL Q_FP_NORM_ANGLE
                TXA
                AND #2
                BNE do_sin
                CALL Q_FP_COS
                BRA maybe_neg
do_sin          CALL Q_FP_SIN
maybe_neg       TXA
                AND #2
                BEQ done
                setas
                LDA ARGUMENT1+3
                ORA #$80
                STA ARGUMENT1+3
                setal
done            PLX
                PLA
                PLP
                RETURN
                .pend

FP_TAN          .proc
                PHP
                setaxl
                PHA
                PHX
                CALL Q_FP_SCALE_TAU
                CALL Q_FP_TAN
                PLX
                PLA
                PLP
                RETURN
                .pend

FP_LN           .proc
                CALL Q_FP_LN
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
onepi           .dword $40490FDB
halfpi          .dword $3FC90FDB
quarterpi       .dword $3F490FDB
