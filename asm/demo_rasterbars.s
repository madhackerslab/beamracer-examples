; Beam Racer * https://beamracer.net
; Video and Display List coprocessor board for the Commodore 64
; Copyright (C)2019-2020 Mad Hackers Lab
;
; https://github.com/madhackerslab/beamracer-examples
;
; More advanced implementation of rasterbars that relies on
; VASYL self-programming to divide work between main CPU and VASYL,
; thus achieving much better performance - total CPU time used is
; approx. 10 rasterlines per frame.

BAR_COUNT  = 10
LINE_COUNT = 234
FIRST_LINE = 30

CTRL1  = $d011
RASTER = $d012
CTRL2  = $d016
EC     = $d020
B0C    = $d021
adr0_low = 200
adr0_high = 201
sinptr1 = 202
sinptr2 = 203

        .include "vlib/vasyl.s"

        jsr knock_knock

        sei
        lda 56334
        and #$fe
        sta 56334

        lda #0
        sta sinptr1
        sta sinptr2

        jsr copy_and_activate_dlist
 
next_frame:
        lda #100
wait_for_raster:
        cmp RASTER
        bne wait_for_raster

        ; Every frame, we calculate line addresses where to put the rasterbars.
        ; This kind of calculations is best done by the CPU.
        lda #<(line_ptrs - dl_start)
        sta VREG_ADR0
        lda #>(line_ptrs - dl_start)
        sta VREG_ADR0 + 1
        lda #1
        sta VREG_STEP0

        ldx #BAR_COUNT - 1
next_rasterbar:
        stx B0C

        ; The position corresponds to sin(8a+t)+sin(8a+3t),
        ; where "a" is rasterbar # and "t" is frame #.
        lda multable,x
        clc
        adc sinptr1
        tay
        lda sinus,y
        sta partial_sum + 1

        lda multable,x
        clc
        adc sinptr2
        tay
        clc
partial_sum: lda #0 ; self modifying code
        adc sinus,y

        ; Finally add the address of "linecolors" buffer where colors need to be
        ; put and store resulting address in the line_ptrs table.
        clc
        adc #<(linecolors - dl_start)
        sta VREG_PORT0
        lda #0
        adc #>(linecolors - dl_start)
        sta VREG_PORT0
        
        dex
        bpl next_rasterbar
        
 
        inc sinptr1
        lda sinptr2
        clc
        adc #3
        sta sinptr2

        lda #6
        sta B0C
 
        jmp next_frame

multable:
        .repeat BAR_COUNT, LINE
        .byte LINE * 8  ; Visual offset between bars.
        .endrep


        .include "vlib/vlib.s"

dlist:
dl_start:
        WAIT    14, 0   ; Wait for an off-screen location in both PAL and NTSC.

        ; In the first stage we are rendering the bars into a "linecolor" buffer
        ; that holds colors of individual rasterlines.

        ; Set up PORT0 to read from line_ptr table that contains CPU-computed
        ; addresses of lines to put bars at in the current frame.
        ; We will walk the table backwards starting from the end, so that the
        ; bars are drawn in the proper order.
        MOV     VREG_ADR0,   <(line_ptrs_end - 1 - dl_start)
        MOV     VREG_ADR0+1, >(line_ptrs_end - 1 - dl_start)
        MOV     VREG_STEP0, -1
        MOV     VREG_STEP1, 1

        ; Loop as many times as there are bars.
        SETA    BAR_COUNT - 1
bar_loop:
        ; Initialize PORT1 pointer based on successive values from "line_ptrs" table.
        XFER    VREG_ADR1+1, (0)    ; hi-byte first - remember we're reading backwards.
        XFER    VREG_ADR1, (0)

        ; Now write the rasterbar colors to the location set above.
        MOV     VREG_PORT1, 0
        MOV     VREG_PORT1, 9
        MOV     VREG_PORT1, 2
        MOV     VREG_PORT1, 4
        MOV     VREG_PORT1, 12
        MOV     VREG_PORT1, 3
        MOV     VREG_PORT1, 13
        MOV     VREG_PORT1, 1
        MOV     VREG_PORT1, 1
        MOV     VREG_PORT1, 13
        MOV     VREG_PORT1, 3
        MOV     VREG_PORT1, 12
        MOV     VREG_PORT1, 4
        MOV     VREG_PORT1, 2
        MOV     VREG_PORT1, 9
        MOV     VREG_PORT1, 0

        DECA            ; Iterate for all rasterbars.
        BRA     bar_loop

        ; Everything above was just a preparation. Now we repeatedly wait for
        ; the beginning of a line and then change the background color,
        ; showing "linecolors" buffer on screen.

        WAIT    FIRST_LINE, 0   ; Starting line for rasterbar display.

        MOV     VREG_ADR1,   <(linecolors - dl_start)
        MOV     VREG_ADR1+1, >(linecolors - dl_start)

        SETA    LINE_COUNT - 1
line_loop:
        ; We want to access each buffer location twice in quick succession:
        ; 1. To read it.
        ; 2. To clear it.
        MOV     VREG_STEP1, 0   ; That's why we first set the step to 0, so that
        XFER    $20, (1)        ; this read access does not advance port pointer.
        MOV     VREG_STEP1, 1   ; Now we set it 1, so the pointer is increased
        MOV     VREG_PORT1, 0   ; _after_ write access in this line.

        DELAYV  1               ; Wait until next line begins.

        DECA                    ; Iterate for all lines.
        BRA     line_loop

dl_end_opcode:
        END

line_ptrs:
        .repeat BAR_COUNT
        .word $ff00     ; Initial line pointers aim at a safe, distant location.
        .endrep
line_ptrs_end:
linecolors:
        .res LINE_COUNT, 0
dlend:
        

sinus:
    .include "sinus_ntsc2.inc"
sinus_end:
