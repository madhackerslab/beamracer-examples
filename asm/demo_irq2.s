; BeamRacer * https://beamracer.net
; Video and Display List coprocessor board for the Commodore 64
; Copyright (C)2019-2020 Mad Hackers Lab
;
; https://github.com/madhackerslab/beamracer-examples
;
; Example demonstrating how to use VASYL interrupts to synchronize
; CPU with the display. Needs only 24 CPU cycles.

CTRL1  = $d011
RASTER = $d012
CTRL2  = $d016
EC     = $d020
B0C    = $d021

        .include "vlib/vasyl.s"

        jsr knock_knock
        sei
        jsr copy_dlist

        ; Turn off CIA interrupts.
        lda #%01111111
        sta $dc0d
        sta $dd0d
        lda $dc0d
        lda $dd0d

        ; ROMs off.
        lda #$35
        sta $01

        ; Set IRQ handler.
        lda #<irq_vec
        sta $fffe
        lda #>irq_vec
        sta $ffff

        cli

        ; Activate the display list.
        lda #0
        sta VREG_DLIST
        sta VREG_DLIST+1
        ldx #(1 << CONTROL_DLIST_ON_BIT)
        stx VREG_CONTROL

        ; Go round and round. Ensure that the IRQ-entry jitter is large.
        lda #2
infloop:
        ldx #0      ; 2 cycles
        ldy 255     ; 3 cycles
        ldy 256     ; 4 cycles
        inc 251     ; 5 cycles
        inc 251,x   ; 6 cycles
        inc 256,x   ; 7 cycles
loop:
        dey         ; Introduce some variance to our timing, so that
        bpl loop    ; we don't get locked on some repetitive pattern.
        
        jmp infloop


irq_vec:
        pha
        ; Acknowledge VASYL IRQ.
        lda #%00010000
        sta $d019   ; <-- This is the synchronization point.
                    ; IRQ jitter is 7 cycles (8, if "illegal" opcodes are used).
                    ; The 4th cycle of this STA instruction, which
                    ; is when the write access takes place, is timed to occur either
                    ; during the sequence of 7 VASYL MOV instructions, or immediately
                    ; after it. In the latter case, it will continue executing normally.
                    ; In the former, the CPU will be recorded and stopped until the
                    ; 7 MOVs are done, and then one extra cycle (right after the MOVs)
                    ; will be used to replay CPU write access.
                    ; In both cases the CPU write to VIC occurs immediately after the MOVs,
                    ; and then CPU continues from the next instruction.
                    ; Given that MOVs are obviously display-synchronized, from this point
                    ; on so is the CPU.

        sty $d020   ; Just an early visual indicator of stability - a flashing line segment.

        ; Save XY if needed.
        txa
        pha
        tya
        pha

        ldx #30
colorloop:
        stx $d020
        dex
        bpl colorloop

        ; Restore XY
        pla
        tay
        pla
        tax

        pla
        sta $d020   ; End-of-interrupt visual marker.
        rti


        .include "vlib/vlib.s"

        .segment "VASYL"
dl_start:
        MOV     $d01a, %00010000    ; Enable VASYL interrupts.
        WAIT    44, 12
        MOV     $d020, 1            ; Just a visual marker.
        IRQ
        DELAYH  16

        .repeat 7, C
        MOV     $d020, C    ; Any VIC-II write. Could go to an unused color register
        .endrep             ; or even to $d019.

        END

