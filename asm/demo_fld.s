; Beam Racer * https://beamracer.net
; Video and Display List coprocessor board for the Commodore 64
; Copyright (C)2019-2020 Mad Hackers Lab
;
; https://github.com/madhackerslab/beamracer-examples
;
; An FLD routine that inserts varying numbers of empty
; rasterlines between text lines.

QUICK_EXIT = 0  ; set to 1 if you want to bail out from the FLD-ing part of the
                ; display list as soon as possible.

CTRL1  = $d011
RASTER = $d012
CTRL2  = $d016
EC     = $d020
B0C    = $d021

        .include "vlib/vasyl.s"
        .macpack cbm

        jsr knock_knock
        jsr fill_screen
        jsr copy_and_activate_dlist

        sei
        lda 56334
        and #$fe
        sta 56334

        lda #$ff
        sta $3fff       ; make empty lines visible
        lda #0
        sta VREG_STEP1  ; not really imporant, but let's be tidy

next_frame:
        lda #32
wait_for_raster:
        cmp RASTER
        bne wait_for_raster
        bit CTRL1
        bmi wait_for_raster

        lda #1          ; CPU rastertime marker
        sta EC

        ldx #0
next_block:
        ; ctrset_pointers tables hold LO and HI bytes of pointers to
        ; locations in the display list that correspond to loop counters controlling
        ; the number of blank raster lines between subsequent character lines.
        ; We modify these counters based on a sinus sequence to get a nice bouncy feel.
        lda ctrset_pointers_lo,x
        sta VREG_ADR1
        lda ctrset_pointers_hi,x
        sta VREG_ADR1+1

        txa
        adc frame_ctr
        tay
        lda sinus,y
        sta VREG_PORT1

        inx
        cpx #FLD_BLOCKS
        bne next_block
       
        ldy frame_ctr
        iny
        cpy #sinus_end - sinus
        bne no_sinus_end
        ldy #0
no_sinus_end:
        sty frame_ctr
 
        lda #0
        sta EC
        jmp next_frame

; Fill the screen so that it is easier to see what's going on.
fill_screen:
        lda #$13
        jsr $ab47   ; print "HOME" code to set $d1 pointer to the first line

        lda reps
        sta rep_cntr

        ldy #0
@restart_text:
        ldx #0
        dec rep_cntr
        beq @end
@next_letter:
        lda text,x
        beq @restart_text
        sta ($d1),y
        inx
        iny
        bne @next_letter
        inc $d2
        bne @next_letter
@end:


        .include "vlib/vlib.s"


FLD_BLOCKS = 21

dlist:
        MOV     $11,$1b ; Reset y-scroll position at the start of a frame.
        MOV     $20,0
        WAIT    50, 0   ; Wait for the line preceding the first badline.

.if QUICK_EXIT = 1
        MOV     VREG_DLIST2L, <(dl_finish - dlist)
        MOV     VREG_DLIST2H, >(dl_finish - dlist)
.endif

        .repeat FLD_BLOCKS,I
        .ident  (.concat ("ctrset_ptr", .string(I))):
        SETA    0       ; Argument of SETA determines how many rasterlines are inserted
                        ; before the next text line.
        MOV     $20,2   ; Just a visual marker
        .ident  (.concat ("dl_loop", .string(I))):
        BADLINE 2       ; Push the badline away

.if QUICK_EXIT = 1
        SKIP            ; Activate SKIP modifier for the next WAIT
        WAIT    251,0   ; Are we past the 250th line?
        BRA     2       ; If not, skip the next instruction (two bytes).
        MOV     VREG_DL2STROBE, 0   ; Jump to the final instructions of the display list.
                                    ; We're not using BRA, because the destination could
                                    ; be more than 128 bytes away (i.e out of range).
.endif

        DELAYV  1
        DECA
        BRA    .ident(.concat ("dl_loop", .string(I)))

        MOV     $20,10
        BADLINE 0
        DELAYV  7
        .endrep
dl_finish:
        MOV     $20,0   ; end marker
        END
dlend:

ctrset_pointers_lo:
        .repeat FLD_BLOCKS,I
        .lobytes .ident(.concat("ctrset_ptr", .string(I))) - dlist + 1 ; +1 for address of the operand
        .endrep

ctrset_pointers_hi:
        .repeat FLD_BLOCKS,I
        .hibytes .ident(.concat("ctrset_ptr", .string(I))) - dlist + 1 ; +1 for address of the operand
        .endrep

frame_ctr:
        .byte 0
reps:   .byte 1000 / (text_end - text)
rep_cntr: .byte 0
text:   scrcode " beamracer fld * "
text_end:
        .byte 0
sinus:
    .byte 4,4,5,6,6,7,7,7,7,7,7,7,6,6,5,4
    .byte 4,3,2,1,1,0,0,0,0,0,0,0,1,1,2,3
sinus_end:
    .byte 4,4,5,6,6,7,7,7,7,7,7,7,6,6,5,4
    .byte 4,3,2,1,1,0,0,0,0,0,0,0,1,1,2,3
    .byte 4,4,5,6,6,7,7,7,7,7,7,7,6,6,5,4
    .byte 4,3,2,1,1,0,0,0,0,0,0,0,1,1,2,3

