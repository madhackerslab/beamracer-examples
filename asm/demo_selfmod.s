; Beam Racer * https://beamracer.net
; Video and Display List coprocessor board for the Commodore 64
; Copyright (C)2019-2020 Mad Hackers Lab
;
; https://github.com/madhackerslab/beamracer-examples
;
; An example of self-modifying display list. CPU is only used to initialize
; things, everything else is done by VASYL. White stripe in the bottom part
; of the screen is rastertime that VASYL needs to copy the rasterbar data.

        .include "vlib/vasyl.s"

        jsr knock_knock
        jsr copy_and_activate_dlist
        rts

        .include "vlib/vlib.s"

dlist:
dl_start:
        ; Use seq table data to set border and paper colors every two lines.
        MOV    VREG_ADR0, <(seq - dl_start)
        MOV    (VREG_ADR0+1), >(seq - dl_start)
        SETA   (seq_end - seq) - 1
        WAIT   45,0
loop:
        DELAYV 2
        MOV    VREG_STEP0,0 ; Do not autoincrement the address during the next
        XFER   $d020, (0)   ; operation, so that we can use the same value twice: here...
        MOV    VREG_STEP0,1
        XFER   $d021, (0)   ; ...and here.
        DECA
        BRA    loop

        MOV    $d020,0

        ; Now that the visual part is done, let's prepare the color sequence
        ; for the next frame by rotating the entire 96-byte buffer:
        ; 1. Copy the first byte to the location immediately following the buffer.
        MOV    $d021,1  ; visual marker
        MOV    VREG_ADR0, <(seq - dl_start)
        MOV    (VREG_ADR0+1), >(seq - dl_start)
        MOV    VREG_ADR1, <(seq_end - dl_start)
        MOV    (VREG_ADR1+1), >(seq_end - dl_start)
        MOV    VREG_STEP1,1
        XFER   VREG_PORT1, (0)

        ; 2. Copy locations 1-96 to locations 0-95. Note that it also pulls the
        ;    byte we copied in step 1. into the buffer.
        MOV    VREG_ADR1, <(seq - dl_start)
        MOV    (VREG_ADR1+1), >(seq - dl_start)

        SETA   (seq_end - seq) - 1
loop2:
        XFER   VREG_PORT1, (0)
        DECA
        BRA    loop2
        MOV    $d021,6
dl_last:
        END

        ; Some hopefully pleasant color sequences.
seq:
        .byte 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
        .repeat 8
        .byte 1,0
        .endrep
        .repeat 8
        .byte 2,6
        .endrep
        .byte 0, 6, 2, 4, 5, 15, 7, 1
        .byte 1, 7, 15, 5, 4, 2, 6, 0
        .byte 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15
        .byte $0, $9, $2, $4, $c, $3, $d, $1
        .byte $1, $d, $3, $c, $4, $2, $9, $0
seq_end:
        .byte 0

dlend:
