; BeamRacer * https://beamracer.net
; Video and Display List coprocessor board for the Commodore 64
; Copyright (C)2019-2020 Mad Hackers Lab
;
; https://github.com/madhackerslab/beamracer-examples
;
; Example demonstrating how to use VASYL interrupts to cycle-synchronize
; CPU with the display. Needs only 55 CPU cycles.

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
        ; Earliest IRQ time marker possible.
        ; At this point the jitter is equal to 7 cycles.
        sta $d020

        inc $ffff   ; Switch IRQ vector to 2nd stage handler.

        pha
        ; Acknowledge VASYL IRQ.
        lda #%00010000
        sta $d019

        cli         ; The second IRQ triggered by VASYL occurs somewhere here.
        .repeat 10
        nop
        .endrep

        ; CPU nevers gets to here.

        ; Space-filler ensuring that stage2 starts exactly 256 bytes
        ; after irq_vec, and we can switch between them by increasing and
        ; decreasing the high-byte of IRQ vector.
        .res 256-(*-irq_vec), 0

stage2:
        ; Acknowledge VASYL IRQ.
        ; At this point the jitter is equal to 1 cycle.
        lda #%00010000
        sta $d019   ; <-- This is the critical point. Either this write to VIC
                    ; occurs one cycle after VASYL's, or it happens concurrently
                    ; and VASYL stops the CPU for one cycle to replay it. In both
                    ; cases CPU's write is executed exactly on cycle after VASYL's.
                    ; And now, since VASYL is display-synchronized, so is the CPU.

        sta $d020   ; Just  a visual marker.

        ; Save XY if needed.
        txa
        pha
        tya
        pha

        inc $d020
        inc $d020
        inc $d020
        inc $d020
        inc $d020

        ; Restore XY
        pla
        tay
        pla
        tax

        ; Remove PC and P stored by the 2nd IRQ.
        pla
        pla
        pla

        pla
        dec $ffff   ; Switch IRQ vector to 1nd stage handler.
        sta $d020   ; End-of-interrupt visual marker.
        rti


        .include "vlib/vlib.s"

        .segment "VASYL"
dl_start:
        MOV     $d01a, %00010000    ; Enable VASYL interrupts.
        WAIT    44, 0
        MOV     $d020, 1            ; Just a visual marker.
        IRQ
        DELAYH  38
        IRQ
        DELAYH  13
        MOV     $d019, %00010000    ; Synchronization point. Could be any write to VIC.
                                    ; Let's do the same thing that the CPU is doing.

        END

