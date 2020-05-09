CYCLE_LENGTH = $0040
CYCLE_COUNTER = $0041
CYCLE_ADDR = $0042
CYCLE_MAX_X = $0043
CYCLE_COMPONENTS = $0044 ; and following

; initialize everything such that the selected palette swap can be used
; load the addr of the palette swap definition in $00,$01
loadPaletteSwap:
	ldy #0
	sty CYCLE_LENGTH
	sty CYCLE_COUNTER

	lda ($00),y
	lsr
	lsr
	lsr
	sta CYCLE_ADDR

	lda ($00),y
	and #$07
	asl
	sta $02
	inc $02 ; $02 contains the maximum value for y in this scan

	lda #0
	ldx #0
@loop:
	iny
	cpy $02
	beq @finished
	; process the length of the step
	clc

	lda CYCLE_LENGTH
	sta CYCLE_COMPONENTS,x
	inx

	lda ($00),y
	adc CYCLE_LENGTH
	sta CYCLE_LENGTH
	iny
	; process the color of the step
	lda ($00),y
	sta CYCLE_COMPONENTS,x
	inx
	jmp @loop
@finished:
	stx CYCLE_MAX_X
	rts

; execute a cycle with the registered palette swap
doCyclePalette:
	lda #$3f
	sta PPUADDR
	lda CYCLE_ADDR
	sta PPUADDR
	inc CYCLE_COUNTER
	lda CYCLE_COUNTER
	cmp CYCLE_LENGTH
	bne :+
		lda #0
		sta CYCLE_COUNTER
	:
	ldx #0

@nextCycleComponent:
	cpx CYCLE_MAX_X
	beq @done
	cmp CYCLE_COMPONENTS,x
	bne :+
		inx
		lda CYCLE_COMPONENTS,x
		sta PPUDATA
		rts
	:
	inx
	inx
	jmp @nextCycleComponent
@done:
	rts

pswp_blinking:
; Palette swap for energy (blinking green)
; first the control byte
; aaaaabbb where
;   A palette index (will be $3f00 + A)
;   B number of steps
	.byte %00101010
; now B steps, with the len and color
	.byte 30, $19
	.byte 30, $1A
