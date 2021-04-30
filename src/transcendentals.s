;;; Transcendentals for the C256Foenix, using the floating-point
;;; coprocessor.
;;;
;;; Conventions:
;;; - Functions that are named Q_something do little or no error
;;; checking or setup. It is up to the caller to ensure these
;;; functions are called with sensible parameter values.
;;; - Parameters are passed in ARGUMENT1 (and possibly ARGUMENT2). It
;;; is up to the caller to ensure that the parameters have been
;;; converted into the right type.

;;;
;;; Q_POLY_HR - Horner's rule
;;;
;;; On entry: as, xl
;;; Y contains the number of coefficients
;;; X points to coefficient table of <Y> values. These are stored in the
;;; reverse order.
;;; ARGUMENT1 contains a floating-point argument (which may be x,
;;; or x*x, depending on the actual function being approximated.)
;;; Leaves the value in ARGUMENT1
Q_POLY_HR       .proc
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
                DEY             ; (Y-1) more coefficients.
loop            INX             ; point to the next coefficient
                INX
                INX
                INX
;;; Multiply by x
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
;;; Retrieve product and store it back into input0. Note that all
;;; bytes of the output must be retrieved before we change the input.
                LDA @l FP_MATH_OUTPUT_FP_LL
                PHA
                LDA @l FP_MATH_OUTPUT_FP_HL
                STA FP_MATH_INPUT0_HL
                PLA
                STA @l FP_MATH_INPUT0_LL
;;; Get next coefficient and add it to partial result
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
;;; Get result of addition and send it back to input0. As before, note
;;; that all bytes of the output must be retrieved before we change
;;; the input.
                LDA @l FP_MATH_OUTPUT_FP_LL
                PHA
                LDA @l FP_MATH_OUTPUT_FP_HL
                STA @l FP_MATH_INPUT0_HL
                PLA
                STA @l FP_MATH_INPUT0_LL
                BRA loop
done            LDA @l FP_MATH_OUTPUT_FP_LL
                STA @l ARGUMENT1
                LDA @l FP_MATH_OUTPUT_FP_HL
                STA @l ARGUMENT1+2
                RTS
                .pend

;;; Q_SQ - "Quick" squaring function.
;;; ARGUMENT1 contains a floating-point argument.
;;; Leaves the value in ARGUMENT1
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

;;; Q_INV - "Quick" inverse.
;;; ARGUMENT1 contains a floating-point argument.
;;; Leaves the value in ARGUMENT1
Q_INV           .proc
                setas
                LDA #0
                STA @l FP_MATH_CTRL0
                LDA #FP_OUT_DIV
                STA @l FP_MATH_CTRL1
                setal
                LDA ARGUMENT1
                STA @l FP_MATH_INPUT1_LL
                LDA @l ARGUMENT1+2
                STA @l FP_MATH_INPUT1_HL
                LDA @l fp_one
                STA @l FP_MATH_INPUT0_LL
                LDA @l fp_one+2
                STA @l FP_MATH_INPUT0_HL
                NOP
                NOP
                NOP
                LDA @l FP_MATH_OUTPUT_FP_LL
                STA ARGUMENT1
                LDA @l FP_MATH_OUTPUT_FP_HL
                STA ARGUMENT1+2
                RTS
                .pend

;;; Q_FP_SCALE - "quick" scaling function:
;;;
;;; As long as ARGUMENT1 < ARGUMENT2, place ARGUMENT1 in FP input 0 of
;;; fp copro, read out result, store back in ARGUMENT1. Return the
;;; number of times through the loop in X.
;;;
;;; Assumes that ARGUMENT2 has already been copied to fp input 1 of
;;; the float coprocessor, and that the float coprocessor has been
;;; setup for the appropriate operation.
;;;
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
                BCC done
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

;;; Q_QP_SCALE_TAU: scale ARGUMENT1 to [0, 2pi]
;;; - if ARGUMENT1 is negative, use the absolue value and subtract the
;;; result from 2pi at the end.
;;; - implemented as a loop that repeatedly subtracts 2pi until the
;;; result is less than 2pi.
;;; Note: this is not fast or accurate when the argument is large. It
;;; could be made slightly more accurate and faster by runing several
;;; loops using (e.g.) 1000*2pi, 100*2pi, 10*2pi and 2pi. It would
;;; still lose accuracy, and maybe we shouldn't encourage people to
;;; try to run sin(31415.927)...
Q_FP_SCALE_TAU  .proc
                ;; check if ARGUMENT1 is negative
                setas
                LDA ARGUMENT1+3
                BPL notneg
                ;; Yes; flip sign bit...
                AND #$7F
                STA ARGUMENT1+3
                ;; and push 1 to indicate that the original value was
                ;; negative
                LDA #1
                PHA
                BRA compute
notneg          LDA #0          ; not negative, so push 0.
                PHA
                ;; set up fp copro to subtract input1 from input0
compute         LDA #FP_ADD_IN0_MUX0 | FP_ADD_IN1_MUX1
                STA @l FP_MATH_CTRL0
                LDA #FP_OUT_ADD
                STA @l FP_MATH_CTRL1
                setaxl
                ;; write 2pi to input1, and to ARGUMENT2.
                LDA @l twopi
                STA ARGUMENT2
                STA @l FP_MATH_INPUT1_LL
                LDA @l twopi+2
                STA ARGUMENT2+2
                STA @l FP_MATH_INPUT1_HL
                ;; make Q_FP_SCALE do the actual work.
                CALL Q_FP_SCALE
                setas
                ;; Get the argument-was-negative flag from stack.
                PLA
                setal
                BEQ done
                ;; the argument was negative, so we compute (2pi-x) by
                ;; subtracting 2i from x, then negating the result.
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
                ;; flip sign bit before saving top 16 bits of result.
                AND #$7fff
                STA ARGUMENT1+2
done
                RETURN
                .pend

;;; Q_FP_NORM_ANGLE - normalize angle.
;;; - if angle is greater than pi, subtract it from 2pi and record the
;;; fact in flag bit 2.
;;; - if angle is greater than pi/2, subtract it from pi and record
;;; the fact in flag bit 1.
;;; - if angle is greater than pi/4, subtract it from pi and record
;;; the fact in flag bit 0.
;;; At the end, the angle will be in the range [0,pi/4), and the flags
;;; will indicate
;;; 0: the "opposite" function must be called (is, sin() for cos(),
;;; and vice versa).
;;; 1: the parameter has been reflected around pi/2, so the value for
;;; cos() must be negated.
;;; 2: the parameter has been reflected around pi, so the value for
;;; sin() must be negated.
;;; Note that the order of the constants twopi, onepi, halfpi and
;;; quarterpi (at the end of this file) is important, and allows us to
;;; use a simple loop instead of a long, linear sequence of operations.
Q_FP_NORM_ANGLE .proc
                .al
                .xl
                PHY
                LDX #0
                LDY #0
                ;; 32-bit comparison, using CMP and SBC. Using CMP for
                ;; the first subtraction means that we do not have to
                ;; initialize the carry bit.
loop            LDA ARGUMENT1
                CMP @l onepi,x
                LDA ARGUMENT1+2
                SBC @l onepi+2,x
                BCC less
                LDA @l twopi,x
                STA @l FP_MATH_INPUT0_LL
                LDA @l twopi+2,x
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
                SEC             ; set carry to indicate a reflection
less            TYA             ; carry already cleared if we branched
                                ; from the comparison.
                ROL             ; shift carry into flags...
                TAY             ; and store back into y
                INX             ; next set of values
                INX
                INX
                INX
                CPX #12         ; check if we have already looked at 3
                                ; sets of values (or 12 bytes).
                BNE loop
                TYA             ; copy Y to X, as that's what we have
                                ; said that we want to return the
                                ; value in.
                TAX
                PLY
                RETURN
                .pend

;;; FP_SCALE: body of BASIC function "SCALETAU". Will be removed at
;;; some point, but has been useful for testing.
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
;;; Implemented via Horner's rule, using even powers of x... so we
;;; start by computing x^2, so that we can drop computing 0.0 * odd
;;; powers of x.
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
                PHY
                LDY #5
                CALL Q_POLY_HR
                PLY
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
;;; Implemented via Horner's rule, using even powers of x... so we
;;; start by computing x^2, so that we can drop computing 0.0 * odd
;;; powers of x. At the end, we multiply the result by x, since sine
;;; actually has a Taylor expansion that uses odd powers of x.
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
                PHY
                LDY #5
                CALL Q_POLY_HR
                PLY
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
                PHX
                LDA ARGUMENT1
                STA ARGUMENT2
                LDA ARGUMENT1+2
                STA ARGUMENT2+2
                CALL Q_SQ
                PHB
                setas
                LDA #`tan_coeff
                PHA
                PLB
                setal
                LDX #<>tan_coeff
                PHY
                LDY #5
                CALL Q_POLY_HR
                PLY
                PLB
                CALL OP_FP_MUL
                PLX
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
                ;; send MUX0 to both adder inputs (slightly cheaper
                ;; way of multiplying by two).
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
                PHY
                LDY #8
                CALL Q_POLY_HR
                PLY
                LDA #TYPE_FLOAT
                STA @l ARGTYPE1
                STA @l ARGTYPE2
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
                PHX
                TXA
                AND #1
                BNE do_cos
                CALL Q_FP_SIN
                BRA maybe_neg
do_cos          CALL Q_FP_COS
maybe_neg       PLX
                TXA
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
                PHX
                TXA
                AND #1
                BNE do_sin
                CALL Q_FP_COS
                BRA maybe_neg
do_sin          CALL Q_FP_SIN
maybe_neg       PLX
                TXA
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
                CALL Q_FP_NORM_ANGLE
                CALL Q_FP_TAN
                ;; Compute 1/tan() if argument was reflected about pi/4
                TXA
                AND #1
                BEQ no_inv
                CALL Q_INV
no_inv          TXA
                ;; Check if flag bit 2 and 1 are different; if so, we
                ;; need to negate the result. The check is done by
                ;; shifting the flags down two positions, leaving bit2
                ;; as bit 0 and bit 1 in carry. Then, add #0 with
                ;; carry. If bit 0 of the result is 1, then bit 2 and
                ;; 1 were different.
                setas
                LSR
                LSR
                ADC #0
                AND #1
                BEQ no_neg
                LDA ARGUMENT1+3
                ORA #$80
                STA ARGUMENT1+3
no_neg          setal
                PLX
                PLA
                PLP
                RETURN
                .pend

FP_LN           .proc
                PHP
                setaxl
                PHA
                PHX
                PHY
                LDA ARGUMENT1+2
                BPL arg_ok
                THROW ERR_DOMAIN
arg_ok          setaxl
                LDA ARGUMENT1
                CMP @l fp_one
                LDA ARGUMENT1+2
                CMP @l fp_one+2
                BCS gtone
                CALL Q_INV
                CLC
gtone           LDA #0
                TAY
                ROL             ; Rotate Carry into A; 0 means negate
                                ; final result.
                PHA
                setas
                LDA #0
                STA @l FP_MATH_CTRL0
                LDA #FP_OUT_DIV
                STA @l FP_MATH_CTRL1
                setal

                ;; Reduce argument by e^64
                LDA @l eexp64
                STA ARGUMENT2
                STA @l FP_MATH_INPUT1_LL
                LDA @l eexp64+2
                STA ARGUMENT2+2
                STA @l FP_MATH_INPUT1_HL

                CALL Q_FP_SCALE

                TXA
                BEQ chk16
                ASL             ; multiply counter by 64
                ASL
                ASL
                ASL
                ASL
                ASL
                TAY

                ;; Reduce argument by e^16
chk16           LDA @l eexp16
                STA ARGUMENT2
                STA @l FP_MATH_INPUT1_LL
                LDA @l eexp16+2
                STA ARGUMENT2+2
                STA @l FP_MATH_INPUT1_HL
                CALL Q_FP_SCALE

                TXA
                BEQ chk04
                ASL             ; multiply counter by 16
                ASL
                ASL
                ASL
                STA ARGUMENT2   ; and add into total
                CLC
                TYA
                ADC ARGUMENT2
                TAY

                ;; Reduce argument by e^4
chk04           LDA @l eexp04
                STA ARGUMENT2
                STA @l FP_MATH_INPUT1_LL
                LDA @l eexp04+2
                STA ARGUMENT2+2
                STA @l FP_MATH_INPUT1_HL
                CALL Q_FP_SCALE

                TXA
                BEQ chk01
                ASL             ;multiply counter by 4
                ASL
                STA ARGUMENT2   ;and add to total
                CLC
                TYA
                ADC ARGUMENT2
                TAY

                ;; reduce argument by e
chk01           LDA @l eexp01
                STA ARGUMENT2
                STA @l FP_MATH_INPUT1_LL
                LDA @l eexp01+2
                STA ARGUMENT2+2
                STA @l FP_MATH_INPUT1_HL
                CALL Q_FP_SCALE

                STX ARGUMENT2   ; add counter to total
                CLC
                TYA
                ADC ARGUMENT2
                TAY

                CALL Q_FP_LN

                ;; Move result of ln of reduced value to argument2
                LDA ARGUMENT1
                STA ARGUMENT2
                LDA ARGUMENT1+2
                STA ARGUMENT2+2
                ;; Convert integer part of ln to argument 1
                TYA
                STA ARGUMENT1
                STZ ARGUMENT1+2
                ;; ... and convert to float
                CALL ITOF
                ;; ... and add the integer and float parts
                CALL OP_FP_ADD
                ;; Check if we need to negate (i.e, original argument
                ;; was < 1.0)
                PLA
                BNE done
                LDA ARGUMENT1+2
                ORA #$8000
                STA ARGUMENT1+2
done            PLY
                PLX
                PLA
                PLP
                RETURN
                .pend

FP_ASIN         .proc
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
                LDA #`asin_coeff
                PHA
                PLB
                setal
                LDX #<>asin_coeff
                LDY #5
                CALL Q_POLY_HR
                PLB
                CALL OP_FP_MUL
                PLX
                PLA
                PLP
                RETURN
                .pend

FP_ACOS         .proc
                PHP
                setaxl
                PHA
                PHX
                CALL FP_ASIN
                LDA @l halfpi
                STA ARGUMENT2
                LDA @l halfpi+2
                STA ARGUMENT2+2
                CALL OP_FP_SUB
                LDA ARGUMENT1+2
                EOR #$8000
                STA ARGUMENT1+2
                PLX
                PLA
                PLP
                RETURN
                .pend
        
FP_ATAN         .proc
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
                LDA #`atan_coeff
                PHA
                PLB
                setal
                LDX #<>atan_coeff
                LDY #5
                CALL Q_POLY_HR
                PLB
                CALL OP_FP_MUL
                PLX
                PLA
                PLP
                RETURN
                .pend

Q_FP_POW_INT    .proc
                MOVE_D ARGUMENT2,ARGUMENT1
                MOVE_D ARGUMENT1,@l fp_one
loop            TXA
                BEQ done
                LSR
                TAX
                BCC next
                CALL OP_FP_MUL
next            PUSH_D ARGUMENT1
                MOVE_D ARGUMENT1,ARGUMENT2
                CALL Q_SQ
                MOVE_D ARGUMENT2,ARGUMENT1
                PULL_D ARGUMENT1
                BRA loop
done            RETURN
                .pend

Q_FP_EXP        .proc
                PHP
                setaxl
                PHA
                PHX
                PHB
                setas
                LDA #`exp_coeff
                PHA
                PLB
                setal
                LDX #<>exp_coeff
                PHY
                LDY #10
                CALL Q_POLY_HR
                PLY
                PLB
                PLX
                PLA
                PLP
                RETURN
                .pend

FP_EXP          .proc
                PHP
                setaxl
                PHA
                PHX
                PHY
                LDA ARGUMENT1   ; special case for x==0
                ORA ARGUMENT1+2
                BNE notzero
                MOVE_D ARGUMENT1,@l fp_one
                BRA done
notzero         LDA ARGUMENT1+2 ; check if negative
                AND #$8000
                TAY             ; Y != 0 -> arg was negative
                BEQ notneg
                LDA ARGUMENT1+2 ; negate x
                AND #$7FFF
                STA ARGUMENT1+2
notneg          PUSH_D ARGUMENT1 ;at this point, x>0
                CALL ASS_ARG1_INT
                LDX ARGUMENT1              ; INT(x) now in ARGUMENT1; low 16 bits into X
                CALL ASS_ARG1_FLOAT        ; and convert to FP again
                MOVE_D ARGUMENT2,ARGUMENT1 ; Copy int part to ARGUMENT2
                PULL_D ARGUMENT1           ; get original value of x...
                CALL OP_FP_SUB             ; and subtract integer part...
                CALL Q_FP_EXP              ; compute EXP(fractional part)
                PUSH_D ARGUMENT1
                MOVE_D ARGUMENT1,@leexp01
                CALL Q_FP_POW_INT
                PULL_D ARGUMENT2
                CALL OP_FP_MUL
                TYA
                BEQ done
                CALL Q_INV
done            PLY
                PLX
                PLA
                PLP
                RETURN
                .pend

FP_SQR          .proc
                PHP
                setaxl
                PHA
                LDA ARGUMENT1+2
                BPL arg_ok
                THROW ERR_DOMAIN
arg_ok          setaxl
                ORA ARGUMENT1
                BEQ done
                ;; LDA ARGUMENT1+2
                ;; LSR
                ;; STA ARGUMENT2+2
                ;; LDA ARGUMENT1
                ;; ROR
                ;; STA ARGUMENT2
                MOVE_D ARGUMENT2,@l fp_two
                setas
                LDA #TYPE_FLOAT
                STA ARGTYPE2
                setal
                PUSH_D ARGUMENT1
loop            CALL OP_FP_DIV
                LDA ARGUMENT1+2
                CMP ARGUMENT2+2
                BNE more
                LDA ARGUMENT1
                EOR ARGUMENT2
                AND #$FFF8
                BEQ exitloop
more            CALL OP_FP_ADD
                MOVE_D ARGUMENT2,@l fp_two
                CALL OP_FP_DIV
                MOVE_D ARGUMENT2,ARGUMENT1
                PULL_D ARGUMENT1
                PUSH_D ARGUMENT1
                BRA loop
exitloop        PULL_D ARGUMENT2 ; discard
done            PLA
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

tan_coeff
                .dword $3CB327A4
                .dword $3D5D0DD1
                .dword $3E088889
                .dword $3EAAAAAB
                .dword $3F800000

ln_coeff
                .dword $3D888889
                .dword $3D9D89D9
                .dword $3DBA2E8C
                .dword $3DE38E39
                .dword $3E124925
                .dword $3E4CCCCD
                .dword $3EAAAAAB
fp_one          .dword $3F800000
fp_two          .dword $40000000

asin_coeff
                .dword $3CF8E38E
                .dword $3D36DB6E
                .dword $3D99999A
                .dword $3E2AAAAB
                .dword $3F800000

atan_coeff
                .dword $3DE38E39
                .dword $BE124925
                .dword $3E4CCCCD
                .dword $BEAAAAAB
                .dword $3F800000

exp_coeff
        .dword $3638EF1D
        .dword $37D00D01
        .dword $39500D01
        .dword $3AB60B61
        .dword $3C088889
        .dword $3D2AAAAB
        .dword $3E2AAAAB
        .dword $3F000000
        .dword $3F800000
        .dword $3F800000


eexp64          .dword $6DA12CC1
eexp16          .dword $4B07975F
eexp04          .dword $425A6481
eexp01          .dword $402DF854

twopi           .dword $40C90FDB
onepi           .dword $40490FDB
halfpi          .dword $3FC90FDB
quarterpi       .dword $3F490FDB
