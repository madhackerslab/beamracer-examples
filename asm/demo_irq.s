; Simple example demonstrating how to simultaneously handle
; VIC and VASYL interrupts.
;
; The display list raises VASYL IRQ 9 times, once every 16 lines.
; Once VASYL IRQ starts, it requests VIC IRQ to happen in 8 lines.

CTRL1  = $d011
RASTER = $d012
CTRL2  = $d016
EC     = $d020
B0C    = $d021

        .include "vlib/vasyl.s"

        jsr knock_knock
        sei
        jsr copy_dlist

        ; turn off CIA interrupts
        lda #%01111111
        sta $dc0d
        sta $dd0d
        lda $dc0d
        lda $dd0d

        ; ROMs off
        lda #$35
        sta $01

        ; set IRQ handler
        lda #<irq_vec
        sta $fffe
        lda #>irq_vec
        sta $ffff

        cli

        ; activate the display list
        lda #0
        sta VREG_DLIST
        sta VREG_DLIST+1
        ldx #(1 << CONTROL_DLIST_ON_BIT)
        stx VREG_CONTROL

        ; go round and round
infloop:
        jmp infloop


irq_vec:
        ; earliest IRQ time marker possible
        sta $d020
        
        pha
        txa
        pha
        tya
        pha

        ; recognize IRQ source
        lda $d019
        and #%00010000
        bne vasyl_irq
        lda $d019
        and #%00000001
        bne vic_irq

        ; something else than VIC or VASYL??
        lda #14
        sta $d020
        lda #$ff
        sta $d019
end_irq:
        pla
        tay
        pla
        tax
        pla
        rti

vic_irq:
        ; change color to light green...
        lda #13
        sta $d020
        ; ...acknowledge VIC-II IRQ...
        ; NOTE: do not use ASL or DEC here!
        lda #%00000001
        sta $d019
        ; ...that's it
        jmp end_irq

vasyl_irq:
        ; Mark with successive colors...
        lda counter
        sta $d020

        ; request VIC interrupt 8 rasterlines from here
        lda $d012
        clc
        adc #8
        sta $d012

        ; zero the MSB of rasterline
        lda #$1b
        sta $d011

        ; handle the counter
        inc counter
        lda counter
        cmp #10
        bne no_wrap
        lda #1
        sta counter
no_wrap:
        ; acknowledge VASYL IRQ
        lda #%00010000
        sta $d019
        ; finish
        jmp end_irq

counter:
        .byte 1


        .include "vlib/vlib.s"

dlist:
dl_start:
        MOV     $d01a, %00010001    ; enable VASYL and VIC interrupts
        WAIT    30, 0
        SETA    8
repeat:
        DELAYV  16
        IRQ
        DECA
        BRA     repeat

        DELAYV  16
        MOV     $20, 0
        END
dlend:
