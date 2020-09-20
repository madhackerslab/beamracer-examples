; BeamRacer * https://beamracer.net
; Video and Display List coprocessor board for the Commodore 64
; Copyright (C)2019-2020 Mad Hackers Lab
;
; https://github.com/madhackerslab/beamracer-examples
;
; Use bitmap sequencer to display the same logo three times, each different.

FIRST_LINE = 51

CTRL1  = $d011
RASTER = $d012
CTRL2  = $d016
EC     = $d020
B0C    = $d021

        .include "vlib/vasyl.s"

        jsr knock_knock
        jsr copy_and_activate_dlist

        rts

        
       .include "vlib/vlib.s"


dlist:
dl_start:
        WAIT    FIRST_LINE, 0

        ; First logo:
        ; - position on the left side of the screen,
        MOV     VREG_PBS_CYCLE_START, 15
        MOV     VREG_PBS_CYCLE_STOP, MHL_logo_width_bytes + 15
        ; - fetch bytes from successive memory addresses,
        MOV     VREG_PBS_STEPL, 1
        MOV     VREG_PBS_STEPH, 0
        ; - when end-of-line reached, continue to the next byte (no padding),
        MOV     VREG_PBS_PADDINGL, 0
        MOV     VREG_PBS_PADDINGH, 0
        ; - apart from turning on the sequencer, we also request mirroring,
        ;   because the logo is in .xbm format, which for some reason stores pixels
        ;   in a byte using right-to-left order,
        MOV     VREG_PBS_CONTROL, 1 << PBS_CONTROL_ACTIVE_BIT | PBS_CONTROL_SWIZZLE_MIRROR
        ; - finally set the starting address of the logo: its top-left byte.
        ; It's important that the address is set at the very end - otherwise it could
        ; be affected by not-yet-ready values of other sequencer registers.
        MOV     VREG_PBS_BASEL, <(mhl_logo - dl_start)
        MOV     VREG_PBS_BASEH, >(mhl_logo - dl_start)
        MOV     $21, 0

        DELAYV  MHL_logo_height ; Wait until the entire logo has been drawn.

        ; Second logo - mirrored sidewise:
        ; - position on the right side of the screen
        MOV     VREG_PBS_CYCLE_START, (40 - MHL_logo_width_bytes) + 15
        MOV     VREG_PBS_CYCLE_STOP, 40 + 15
        ; - fetch bytes in reverse order,
        MOV     VREG_PBS_STEPL, <-1
        MOV     VREG_PBS_STEPH, >-1
        ; - since now we're starting with the last byte of a line and moving towards
        ;   the first, once we get there, we need to jump forward to the last byte of
        ;   the next line - i.e. two lines worth of bytes,
        MOV     VREG_PBS_PADDINGL, < (MHL_logo_width_bytes * 2)
        MOV     VREG_PBS_PADDINGH, > (MHL_logo_width_bytes * 2)
        ; - now the ordering of pixels in a byte matches the display order, so it's
        ;   enough to just turn on the sequencer.
        MOV     VREG_PBS_CONTROL, 1 << PBS_CONTROL_ACTIVE_BIT
        ; - start fetching from the last byte of the logo's first line.
        MOV     VREG_PBS_BASEL, <(mhl_logo - dl_start + MHL_logo_width_bytes - 1)
        MOV     VREG_PBS_BASEH, >(mhl_logo - dl_start + MHL_logo_width_bytes - 1)
        MOV     $21, 4

        DELAYV  MHL_logo_height ; Wait until the entire logo has been drawn.

        ; Third logo - mirrored upside-down:
        ; - centered horizontally on the screen,
        MOV     VREG_PBS_CYCLE_START, (40 - MHL_logo_width_bytes) / 2 + 15
        MOV     VREG_PBS_CYCLE_STOP, (40 - MHL_logo_width_bytes) / 2 + 15 + MHL_logo_width_bytes
        ; - fetch bytes from successive memory addresses...
        MOV     VREG_PBS_STEPL, 1
        MOV     VREG_PBS_STEPH, 0
        ; - ...but once you get to the end of line, jump two lines earlier in memory,
        MOV     VREG_PBS_PADDINGL, < -(MHL_logo_width_bytes * 2)
        MOV     VREG_PBS_PADDINGH, > -(MHL_logo_width_bytes * 2)
        ; - reverse pixel ordering in a byte again,
        MOV     VREG_PBS_CONTROL, 1 << PBS_CONTROL_ACTIVE_BIT | PBS_CONTROL_SWIZZLE_MIRROR
        ; - start from the first byte of the logo's last line.
        MOV     VREG_PBS_BASEL, <(mhl_logo - dl_start + MHL_logo_width_bytes * (MHL_logo_height - 1))
        MOV     VREG_PBS_BASEH, >(mhl_logo - dl_start + MHL_logo_width_bytes * (MHL_logo_height - 1))
        MOV     $21, 8

        DELAYV  MHL_logo_height ; Wait until the entire logo has been drawn.
        
        MOV     $21, 6
        MOV     VREG_PBS_CONTROL, 0           ; turn off the sequencer

        END
mhl_logo:
        .include "mhl.xbm"
dlend:
