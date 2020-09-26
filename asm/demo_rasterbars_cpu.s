; BeamRacer * https://beamracer.net
; Video and Display List coprocessor board for the Commodore 64
; Copyright (C)2019-2020 Mad Hackers Lab
;
; https://github.com/madhackerslab/beamracer-examples
;
; Naive rasterbars

BAR_COUNT = 10

CTRL1  = $d011
RASTER = $d012
CTRL2  = $d016
EC     = $d020
B0C    = $d021

        .include "vlib/vasyl.s"

        jsr knock_knock

        sei
        lda 56334
        and #$fe
        sta 56334

        lda #0
        sta VREG_CONTROL

        jsr create_dl

next_frame:
        lda #245
wait_for_raster:
        cmp RASTER
        bne wait_for_raster

; Mark starting rasterline
        lda #7
        sta EC

        jsr clear_bars

        ldx #0
next_rasterbar:
; Calculate offset in the sine table.
        lda #0
        sta adr0_high
        txa
        clc
        adc sinptr1
        tay
        lda sinus,y
        pha

        txa
        clc
        adc sinptr2
        tay
        clc
        pla
        adc sinus,y

; Multiply by four, since each line in the display list is
; four bytes long.
        asl
        rol adr0_high
        asl
        rol adr0_high

; Add byte offset of MOV's argument in a line.
        clc
        adc #3
        sta VREG_ADR0
        bcc no_adr0_ovf
        inc adr0_high
no_adr0_ovf:
        lda adr0_high
        sta VREG_ADR0 + 1
        
        ldy #4
        sty VREG_STEP0

        ldy #15
copy_bar:
        lda colorbar,y
        sta VREG_PORT0
        dey
        bpl copy_bar

        txa
        clc
        adc #8
        tax
        cpx #BAR_COUNT * 8
        bne next_rasterbar
        
 
        inc sinptr1
        lda sinptr2
        clc
        adc #3
        sta sinptr2
 
        lda #1
        sta EC
        sta EC
        sta EC
        sta EC
        lda #0
        sta EC
        jmp next_frame

sinptr1:
        .byte 0
sinptr2:
        .byte 0
adr0_high:
        .byte 0

; Set argument of all MOV $D020,X instructions to 0,
; thus removing the rasterbars from the screen.
clear_bars:
        ldx #3
        stx VREG_ADR0
        ldx #0
        stx VREG_ADR0 + 1
        ldx #4
        stx VREG_STEP0

UNROLL_FACTOR = 8
; The clearing loop is unrolled by 8 for speed.
        ldy #(266-20) / UNROLL_FACTOR
        lda #0
clear_loop:
        .repeat UNROLL_FACTOR
        sta VREG_PORT0
        .endrep
        dey
        bne clear_loop
        rts
        

create_dl:
; Prepare display list composed of repeated
;
; WAIT rasterline,0
; MOV         $20,0
;
; followed by 
;
; END
;
; rasterline ranges from 20 to 256+5=261.
;
; Instruction format of WAIT V,H is
; first byte:   0H5H4H3H2H1H0V8
; second byte: V7V6V5V4V3V2V1V0
; which explains bit manipulation below.

        ldx #0
        stx counter
        stx counter + 1
; Initialize PORT0 to point to the beginning of VASYL memory
; and to increase by one with each byte written.
        stx VREG_ADR0
        stx VREG_ADR0 + 1
        ldx #1
        stx VREG_STEP0
        
        ldy #20
next_rasterline:
        ldx #0 << 1
        tya
        iny
        bne no_ctr_ovf
        inc counter + 1
no_ctr_ovf:
        lda counter + 1
        beq no_ctr_ovf2
        cpy #6
        beq dl_complete
        inx
no_ctr_ovf2:
        tya
        ; WAIT rasterline, 0
        stx VREG_PORT0
        sta VREG_PORT0

        ; MOV $d020, 0
        lda #$c0 + $20
        sta VREG_PORT0
        lda #0
        sta VREG_PORT0

        jmp next_rasterline

dl_complete:
        ; END
        lda #$7f
        sta VREG_PORT0
        lda #$ff
        sta VREG_PORT0

        ; start using the new Display List
        lda #0
        sta VREG_DLIST
        sta VREG_DLIST + 1
        lda #1 << CONTROL_DLIST_ON_BIT
        sta VREG_CONTROL

        rts

        .include "vlib/vlib.s"

counter:
        .word 0

colorbar:
        .byte $0, $9, $2, $4, $c, $3, $d, $1
        .byte $1, $d, $3, $c, $4, $2, $9, $0

sinus:
    .include "sinus_ntsc.inc"
sinus_end:
    
