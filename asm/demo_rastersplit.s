; BeamRacer * https://beamracer.net
; Video and Display List coprocessor board for the Commodore 64
; Copyright (C)2019-2020 Mad Hackers Lab
;
; https://github.com/madhackerslab/beamracer-examples
;
; More advanced implementation of rasterbars that relies on
; VASYL programming to divide work between main CPU and VASYL,
; thus achieving much better performance.
;
; Basically identical to demo_rasterbars.s sans the extra
; code to handle right-hand side bar splits.
;
; Since VASYL code makes active use of both ports, it is critical
; that the CPU accesses to port 0 do not overlap with VASYL's. Here it is
; achieved by performing CPU's work in rasterlines 0 to 10. At that time VASYL
; is doing nothing but WAIT-ing.

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
        lda #0
wait_for_raster:
        cmp RASTER
        bne wait_for_raster
        bit CTRL1
        bmi wait_for_raster

        ; Every frame, we calculate buffer addresses where to put the rasterbar.
        ; This kind of calculations is best made with the CPU.
        lda #<(line_ptrs - dl_start)
        sta VREG_ADR0
        lda #>(line_ptrs - dl_start)
        sta VREG_ADR0 + 1
        lda #1
        sta VREG_STEP0

        ldx #BAR_COUNT - 1
next_rasterbar:
        stx $d020
        lda #0
        sta adr0_high

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
        lda adr0_high
        adc #>(linecolors - dl_start)
        sta VREG_PORT0
        
        dex
        bpl next_rasterbar
        
 
        inc sinptr1
        lda sinptr2
        clc
        adc #3
        sta sinptr2

        lda #0
        sta $d020
 
        jmp next_frame

multable:
        .repeat BAR_COUNT, LINE
        .byte LINE * 8  ; visual offset between bars
        .endrep


        .include "vlib/vlib.s"

dlist:
dl_start:
        WAIT    14, 0      ; Wait for an off-screen location in both PAL and NTSC.

        ; In the first stage we are rendering the bars into a "linecolor" buffer
        ; that holds colors of individual rasterlines.

        ; Set up PORT0 to read from line_ptr table that contains CPU-computed
        ; addresses of lines to put bars at in the current frame.
        ; We will walk the table backwards starting from the end, so that the
        ; bars are drawn in the proper order.
        MOV     VREG_ADR0,   <(line_ptrs_end - 1 - dl_start)
        MOV     VREG_ADR0+1, >(line_ptrs_end - 1 - dl_start)
        MOV     VREG_STEP0, -1

        ; Loop as many times as there are bars.
        SETA    BAR_COUNT - 1
        MOV     VREG_STEP1, 1
bar_loop:
        ; Initialize PORT1 pointer based on successive values from "line_ptrs" table.
        XFER    VREG_ADR1+1, (0)    ; hi-byte first - remember we're reading backwards.
        XFER    VREG_ADR1, (0)

        ; Now write the rasterbar colors to location set above.
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
        ; finally putting the bars on screen. Then we wait till the middle of
        ; a rasterbar and change color again, this time walking the "line-color"
        ; buffer from the end.

        WAIT    FIRST_LINE, 0   ; Starting line for rasterbar display.

        ; PORT1 walks "line-color" buffer beginning-to-end.
        MOV     VREG_ADR1,   <(linecolors - dl_start)
        MOV     VREG_ADR1+1, >(linecolors - dl_start)
        MOV     VREG_STEP1, 1
        ; PORT0 walks it end-to-beginning.
        MOV     VREG_ADR0,   <(linecolors_end - 1 - dl_start)
        MOV     VREG_ADR0+1, >(linecolors_end - 1- dl_start)
        MOV     VREG_STEP0, -1

        SETA    LINE_COUNT - 1
line_loop:
        ; Left-hand bars.
        MOV     VREG_STEP1, 0
        XFER    $20, (1)

        ; Right-hand bars.
        MASKV   0           ; Mask out vertical position bits.
        WAIT    0, 35       ; Wait for cycle 35th.

        MOV     VREG_STEP0, 0
        XFER    $20, (0)

        ; Check if we have passed vertical midpoint of the screen.
        ; If so, we can start clearing line-color table. Why here? Consider
        ; which buffer locations of [A,B,C,D] buffer are needed to draw lines
        ; 1, 2, 3 and 4. 3 is the first line where both locations are accessed
        ; for the last time in a frame.
        ;
        ;   L      R
        ;   ========
        ; 1|A      D
        ; 2|B      C
        ;   --------
        ; 3|C      B
        ; 4|D      A

        SKIP    ; SKIP modifier for the WAIT in the next line.
        WAIT    FIRST_LINE + LINE_COUNT / 2, 0
        BRA     skip       ; still upper half
        MOV     VREG_PORT0, 0   ; clear color
        MOV     VREG_PORT1, 0   ; clear color
skip:
        DELAYV  1   ; Wait until next line starts. Do it early, because
                    ; in badlines there is not much cycle budget left.
                    
        ; Advance counters by reading from ports with appropriate step.
        MOV     VREG_STEP0, -1  ; Going backwards.
        XFER    VREG_STEP0, (0) ; We need a register to store the readout into.
                                ; STEP0 will be reset anyway, so it's ok to trash it.
                                ; We could also read into some unused color register,
                                ; if STEP0 had to be preserved.

        MOV     VREG_STEP1, 1   ; Going forwards.
        XFER    VREG_STEP1, (1) ; As above, but with STEP1.

        DECA
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
linecolors_end:
dlend:


sinus:
    .include "sinus_ntsc2.inc"
sinus_end:
    .include "sinus_ntsc2.inc"
