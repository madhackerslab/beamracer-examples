; Beam Racer * https://beamracer.net
; Video and Display List coprocessor board for the Commodore 64
; Copyright (C)2019-2020 Mad Hackers Lab
;
; https://github.com/madhackerslab/beamracer-examples
;
; FLI using a Display List.
;
; Thanks to Carrion/Bonzai for the permission to use his artwork.


CTRL1  = $d011
RASTER = $d012
CTRL2  = $d016
EC     = $d020
B0C    = $d021
VIC_BANK = $4000
dst_ptr = $fc

        .include "vlib/vasyl.s"

        jsr knock_knock
        sei
        lda 56334
        and #$fe
        sta 56334

        jsr copy_to_screen
        jsr copy_and_activate_dlist

        lda $dd00   ; VIC bank $8000-$BFFF
        and #$fc
        ora #$02
        sta $dd00

        lda #0
        sta B0C
        sta EC
busyloop:
        jmp busyloop


; Copy FLI data to the right places
copy_to_screen:
        lda #<(fli_bitmap + $1F00)
        sta tmp_ptr
        lda #>(fli_bitmap + $1F00)
        sta tmp_ptr + 1
        lda #<(VIC_BANK + $3F00)
        sta dst_ptr
        lda #>(VIC_BANK + $3F00)
        sta dst_ptr + 1
        ldx #4*8
        ldy #0
copy_bmp_loop:
        lda (tmp_ptr),y
        sta (dst_ptr),y
        dey
        bne copy_bmp_loop
        dec tmp_ptr + 1
        dec dst_ptr + 1
        dex
        bne copy_bmp_loop

        lda #<fli_screens
        sta tmp_ptr
        lda #>fli_screens
        sta tmp_ptr + 1
        lda #<VIC_BANK
        sta dst_ptr
        lda #>VIC_BANK
        sta dst_ptr + 1
        ldx #4*8
        ldy #0
copy_scr_loop:
        lda (tmp_ptr),y
        sta (dst_ptr),y
        dey
        bne copy_scr_loop
        inc tmp_ptr + 1
        inc dst_ptr + 1
        dex
        bne copy_scr_loop

copy_loop:
        lda fli_color,x
        sta $D800,x
        lda fli_color+$100,x
        sta $D900,x
        lda fli_color+$200,x
        sta $DA00,x
        lda fli_color+$300,x
        sta $DB00,x
        dex
        bne copy_loop

        rts

        .include "vlib/vlib.s"


dlist:
dl_start:
        MOV    $16, $18 ; multicolor
        MOV    $11, $3a ; bitmap mode
        WAIT   49, 0

        SETB   24   ; 25 character lines (counting from 0)
        MOV    VREG_STEP1,1
blockloop:
        MOV    VREG_ADR1, <(mem_ptrs - dl_start)
        MOV    (VREG_ADR1+1), >(mem_ptrs - dl_start)
        SETA   7
lineloop:
        DELAYV 1    ; wait for the beginning of the next rasterline
        DELAYH 12   ; and then for 12 more cycles
        XFER   $d018, (1)  ; update video matrix address
        BADLINE 0   ; force badline now

        DECA
        BRA    lineloop

        DECB
        BRA    blockloop

        END
mem_ptrs:   ; video matrix addresses for successive rasterlines
        .repeat 8, I
        .byte   (I << 4) | $08
        .endrep
dlend:

fli_data:
    .incbin "image.fli"
fli_color = fli_data + 256 + 2
fli_screens = fli_color + 1024
fli_bitmap = fli_screens + 8192

