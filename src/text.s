; receive in Y the message index to enqueue
doEnqueueMessage:
	lda MESSAGES_TABLE,y
	sta $00
	lda MESSAGES_TABLE + 1,y
	sta $01

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

.include "assets/messages.s"