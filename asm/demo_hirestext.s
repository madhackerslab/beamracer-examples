; BeamRacer * https://beamracer.net
; Video and Display List coprocessor board for the Commodore 64
; Copyright (C)2019-2020 Mad Hackers Lab
;
; https://github.com/madhackerslab/beamracer-examples
;
; HiRes screen text output and scrolling in two versions.
;
; First version uses CPU to draw characters and scroll the screen.
; The second one relies on hardware acceleration for both of those things.

CTRL1  = $d011
RASTER = $d012
CTRL2  = $d016
EC     = $d020
B0C    = $d021

scrpos = $fb
FONT_ROM  = $d800   ; We want second part of character ROM (lowercase).
FONT_COPY = $0900   ; Address in VASYL memory.
SCREEN    = $1000   ; Address in VASYL memory.

        .macpack cbm

        .include "vlib/vasyl.s"
        jsr knock_knock

        jsr copy_and_activate_dlist
        jsr copy_fonts
        jsr init_rnd
loop:
        ; Pick random X position for the text.
        lda $d41b
        and #15
        sta posx
        lda #192
        sta posy

        lda #<string
        ldx #>string

        ldy mode
        bne mode_fast

        jsr drawstring_soft
        jsr scroll_soft
        jmp check_key
mode_fast:
        jsr drawstring_hard
        jsr scroll_hard
check_key:
        jsr $ffe4   ; Check if key pressed.
        beq loop

        lda mode    ; Change mode if so.
        eor #255
        sta mode

        jmp loop

        .include "vlib/vlib.s"

posx:   .res 1
posy:   .res 1
mode:   .byte 0

drawstring_soft:
        sta tmp_ptr2
        stx tmp_ptr2 + 1
        lda VREG_CONTROL
        ora #(1 << CONTROL_PORT_READ_ENABLE_BIT)
        sta VREG_CONTROL
        lda #40         ; How many bytes in a screen line.
        sta VREG_STEP1
        lda #<-128      ; How many bytes between character's lines in copied font data.
        sta VREG_STEP0
        lda posx        ; Calculate the location of the first byte to draw.
        ldy posy
        clc
        adc lineptr_lo,y
        sta scrpos
        lda #0
        adc lineptr_hi,y
        sta scrpos+1

        ldy #0
@next_char:
        lda (tmp_ptr2),y    ; Grab the next character.
        beq @end            ; Bail-out if string's end found.
        sta VREG_ADR0       ; Thanks to how font data is placed in VASYL memory,
        lda #>FONT_COPY     ; finding the starting byte of any character is
        sta VREG_ADR0+1     ; simple and fast.

        lda scrpos
        sta VREG_ADR1
        lda scrpos + 1
        sta VREG_ADR1 + 1

        .repeat 8       ; Unroll the loop for eight bytes of a character.
        lda VREG_PORT0
        sta VREG_PORT1
        .endrep

        iny
@nocarry:
        inc scrpos
        bne @next_char
        inc scrpos + 1

        jmp @next_char
        
@end:
        rts


drawstring_hard:
        sta tmp_ptr2
        stx tmp_ptr2 + 1
        lda VREG_CONTROL
        ora #CONTROL_PORT_MODE_COPY ; Activate hardware copying.
        sta VREG_CONTROL
        lda #40         ; How many bytes in a screen line.
        sta VREG_STEP1
        lda #<-128      ; How many bytes between character's lines in copied font data.
        sta VREG_STEP0
        lda posx        ; Calculate the location of the first byte to draw.
        ldy posy
        clc
        adc lineptr_lo,y
        sta scrpos
        lda #0
        adc lineptr_hi,y
        sta scrpos+1

        ldy #0
        ldx #8
@next_char:
        lda (tmp_ptr2),y    ; Grab the next character.
        beq @end            ; Bail-out if string's end found.
        sta VREG_ADR0       ; Thanks to how font data are placed in VASYL memory,
        lda #>FONT_COPY     ; finding the starting byte of any character is
        sta VREG_ADR0+1     ; simple and fast.

        lda scrpos
        sta VREG_ADR1
        lda scrpos + 1
        sta VREG_ADR1 + 1

        stx VREG_REP1       ; Kick-off hardware copy of 8 bytes.
                            ; At least 8 cycles must pass from this moment
                            ; until the next access to ADR registers, because
                            ; we're not otherwise checking if copy hardware is
                            ; done.
        iny
@nocarry:
        inc scrpos
        bne @next_char
        inc scrpos + 1

        jmp @next_char
@end:
        rts


scroll_soft:
        lda VREG_CONTROL
        ora #(1 << CONTROL_PORT_READ_ENABLE_BIT)
        sta VREG_CONTROL

        lda lineptr_lo
        sta VREG_ADR1
        lda lineptr_hi
        sta VREG_ADR1 + 1
        lda lineptr_lo + 8  ; We scroll eight lines up.
        sta VREG_ADR0
        lda lineptr_hi + 8
        sta VREG_ADR0 + 1

        lda #1
        sta VREG_STEP0
        sta VREG_STEP1

UNROLL_FACTOR = 16
        ldy #30     ; 30 pages = 7680 bytes = 24 lines * 40 rows * 8 bytes
@outer_loop:
        ldx #256 / UNROLL_FACTOR
@scroll_loop:
        .repeat UNROLL_FACTOR
        lda VREG_PORT0
        sta VREG_PORT1
        .endrep
        dex
        bne @scroll_loop
        dey
        bne @outer_loop

        ; Now clear the bottommost line of 8 * 40 = 320 bytes.
        lda lineptr_lo + 192
        sta VREG_ADR1
        lda lineptr_hi + 192
        sta VREG_ADR1 + 1

        ldx #(8*40-256) / UNROLL_FACTOR
        ldy #1
        lda #0
@clean_loop:
        .repeat UNROLL_FACTOR
        sta VREG_PORT1
        .endrep
        dex
        bne @clean_loop
        ldx #256 / UNROLL_FACTOR
        dey
        bpl @clean_loop

        rts


scroll_hard:
        lda VREG_CONTROL
        ora #CONTROL_PORT_MODE_COPY
        sta VREG_CONTROL

        lda lineptr_lo
        sta VREG_ADR1
        lda lineptr_hi
        sta VREG_ADR1 + 1
        lda lineptr_lo + 8  ; We scroll eight lines up.
        sta VREG_ADR0
        lda lineptr_hi + 8
        sta VREG_ADR0 + 1

        lda #1
        sta VREG_STEP0
        sta VREG_STEP1

        ldy #30     ; 30 pages = 7680 bytes = 24 lines * 40 rows * 8 bytes
@outer_loop:
        lda VREG_REP1   ; Make sure the previous hardware copy is complete.
        bne @outer_loop
        sta VREG_REP1   ; Kick-off a 256-byte copy.
        dey
        bne @outer_loop
@bltwait:
        lda VREG_REP1   ; Wait for the final page to finish copying.
        bne @bltwait

        lda VREG_CONTROL
        and #~(CONTROL_PORT_MODE_MASK)+256
        sta VREG_CONTROL

        ; Clear bottommost text line.
        lda lineptr_lo + 192
        sta VREG_ADR1
        lda lineptr_hi + 192
        sta VREG_ADR1 + 1

        ldx #(8*40-256) - 1
        lda #0
        sta VREG_PORT1
        stx VREG_REP1   ; 64 bytes.
@bltwait2:
        lda VREG_REP1
        bne @bltwait2
        sta VREG_REP1   ; 256 bytes.

@bltwait3:
        lda VREG_REP1
        bne @bltwait3

        rts


; Font data is copied from ROM to VASYL memory at the start,
; so that it can be located and accessed faster. We use the opportunity
; to rearrange font bitmap placement - rather than follow ROM's ordering, which
; puts eight bytes of a character in consecutive locations, we separate them
; by 128 bytes. This way, letter "A" can start at location 1, letter "b" at 2,
; and so on, sparing us the need to compute (or look up) their addresses - character's
; code is also the low byte of its address (and high bytes are all identical).
;
; The only problem with this trick is that automatic post-increment/decrement supported
; by VASYL ports ranges from -128 to 127. Not a problem - we just use a negative
; step of -128, placing font bitmaps upside-down in memory (they don't really care).
copy_fonts:
        sei
        lda #<FONT_ROM
        sta tmp_ptr
        lda #>FONT_ROM
        sta tmp_ptr + 1

        lda #<-128        ; ca65 requires this notation to accept a negative byte.
        sta VREG_STEP0

        ldx #0
@next_char:
        stx VREG_ADR0
        lda #>FONT_COPY
        sta VREG_ADR0 + 1

        ldy #0
@character_loop:
        ; bring up character ROM at $d000
        lda 1
        and #(~4)+256
        sta 1
        lda (tmp_ptr),y
        pha
        ; bring back IO at $d000
        lda 1
        ora #4
        sta 1
        pla
        sta VREG_PORT0
        iny
        cpy #8
        bne @character_loop

        lda tmp_ptr
        clc
        adc #8
        sta tmp_ptr
        bcc @no_carry
        inc tmp_ptr + 1
@no_carry:

        inx
        cpx #128        ; We just need 128 characters.
        bne @next_char

        cli
        rts

; Initialize SID so that we can use it to obtain random numbers quickly.
init_rnd:
        lda #$ff
        sta $d40e
        sta $d40f
        lda #$80
        sta $d412
        rts

string:
        scrcode  "BeamRacer Hires TextOut()"
        .byte 0

; Lo- and hi-bytes of pointers to lines' starting addresses.
lineptr_lo:
        .repeat 200,L
        .lobytes SCREEN+L*40
        .endrep
lineptr_hi:
        .repeat 200,L
        .hibytes SCREEN+L*40
        .endrep

        .segment "VASYL"
dl_start:
        WAIT 51,0
        MOV  VREG_PBS_BASEL, <SCREEN
        MOV  VREG_PBS_BASEH, >SCREEN
        MOV  VREG_PBS_PADDINGL, 0
        MOV  VREG_PBS_PADDINGH, 0
        MOV  VREG_PBS_STEPL, 1
        MOV  VREG_PBS_STEPH, 0
        MOV  VREG_PBS_CONTROL, (1 << PBS_CONTROL_ACTIVE_BIT)

        WAIT 251,0

        MOV  $40, 0           ; Turn off the PBS.

        END



