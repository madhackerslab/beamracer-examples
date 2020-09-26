; BeamRacer * https://beamracer.net
; Video and Display List coprocessor board for the Commodore 64
; Copyright (C)2019-2020 Mad Hackers Lab
;
; https://github.com/madhackerslab/beamracer-examples
;
; Just load and activate a display list that changes background color
; at the right moments.

        .include "vlib/vasyl.s"

        jsr knock_knock

        lda 53265
        sta preserve_ctrl1
        lda $d020
        sta preserve_ec
        lda #0      ; turn off VIC-II display fetches
        sta 53265   ; so that badlines do not interfere

        jsr copy_and_activate_dlist
loop:
        jsr $ffe4   ; check if key pressed
        beq loop

        lda #0      ; turn off the display list
        sta VREG_CONTROL
        lda preserve_ctrl1
        sta 53265
        lda preserve_ec
        sta $d020
        rts

        .include "vlib/vlib.s"
        
dlist:
        .segment "VASYL"

        .include "logo_dlist.inc"
dlend:

preserve_ctrl1:
        .res 1
preserve_ec:
        .res 1
