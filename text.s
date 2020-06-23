; locate the address of the text message at 00 (high) 01 (low)
doEnqueueTextMessage:
	ldy #$00
	ldx PPU_ENCODED_LEN
	inx
	lda ($00),y
@next:	sta PPU_ENCODED,x
	iny
	inx
	lda ($00),y
	cmp #$ff
	bne @next
	stx 1
	dey
	dey
	sty 0
	ldx PPU_ENCODED_LEN
	lda 0
	sta PPU_ENCODED,x
	lda 1
	sta PPU_ENCODED_LEN
	rts

; input tile coordinates: x = 2 y = 2
; PPU nametable address: 0x2042
msg_battery:
.byte $20, $62
; Encoded string produced by encode.c
; The string: "steps"
.byte $1c,$1d,$0e,$19,$1c,$ff

msg_title:
.byte $21,$c8
; Encoded string produced by encode.c
; The string: "homebrew for nes"
.byte $11,$18,$16,$0e,$0b,$1b,$0e,$20,$24,$0f,$18,$1b,$24,$17,$0e,$1c,$ff

msg_title2:
.byte $22,$06
; Encoded string produced by encode.c
; The string: "still in development"
.byte $1c,$1d,$12,$15,$15,$24,$12,$17,$24,$0d,$0e,$1f,$0e,$15,$18,$19,$16,$0e,$17,$1d,$ff

msg_start:
.byte $23, $2b
; Encoded string produced by encode.c
; The string: "press start"
.byte $19,$1b,$0e,$1c,$1c,$24,$1c,$1d,$0a,$1b,$1d,$ff

msg:
.byte $20,$85
; Encoded string produced by encode.c
; The string: "a match made in heaven"
.byte $0a,$24,$16,$0a,$1d,$0c,$11,$24,$16,$0a,$0d,$0e,$24,$12,$17,$24,$11,$0e,$0a,$1f,$0e,$17,$ff

ohman:
.byte $23,$29
; Encoded string produced by encode.c
; The string: "oh man you died"
.byte $18,$11,$24,$16,$0a,$17,$24,$22,$18,$1e,$24,$0d,$12,$0e,$0d,$ff

welldone:
.byte $23,$29
; Encoded string produced by encode.c
; The string: "solution found"
.byte $1c,$18,$15,$1e,$1d,$12,$18,$17,$24,$0f,$18,$1e,$17,$0d,$ff

msg_try_again:
.byte $23,$64
; Encoded string produced by encode.c
; The string: "press start to try again"
.byte $19,$1b,$0e,$1c,$1c,$24,$1c,$1d,$0a,$1b,$1d,$24,$1d,$18,$24,$1d,$1b,$22,$24,$0a,$10,$0a,$12,$17,$ff

msg_press_start:
.byte $23,$61
; Encoded string produced by encode.c
; The string: "write down the number of steps"
.byte $20,$1b,$12,$1d,$0e,$24,$0d,$18,$20,$17,$24,$1d,$11,$0e,$24,$17,$1e,$16,$0b,$0e,$1b,$24,$18,$0f,$24,$1c,$1d,$0e,$19,$1c,$ff

congrats1:
.byte $21,$63
; Encoded string produced by encode.c
; The string: "congratulations you did it"
.byte $0c,$18,$17,$10,$1b,$0a,$1d,$1e,$15,$0a,$1d,$12,$18,$17,$1c,$24,$22,$18,$1e,$24,$0d,$12,$0d,$24,$12,$1d,$ff

congrats2:
.byte $22,$09
; Encoded string produced by encode.c
; The string: "ask guillermo"
.byte $0a,$1c,$14,$24,$10,$1e,$12,$15,$15,$0e,$1b,$16,$18,$ff

congrats3:
.byte $22,$48
; Encoded string produced by encode.c
; The string: "for more levels"
.byte $0f,$18,$1b,$24,$16,$18,$1b,$0e,$24,$15,$0e,$1f,$0e,$15,$1c,$ff

