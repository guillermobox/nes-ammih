; A nametable has 30 rows of 32 sprites each
clearNametable:
	lda #BLOCK_SPRITE_BG
	ldy #$1e
@row:
	ldx #$20
@back:
	sta PPUDATA
	dex
	bne @back
	dey
	bne @row
	rts

initializeNametables:
	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR
	jsr clearNametable

	lda #$28
	sta PPUADDR
	lda #$00
	sta PPUADDR
	jsr clearNametable

	rts

initializeApu:
	ldy #$13
@loop:  lda audioregs,y
	sta APU_ADDR,y
	dey
	bpl @loop
	lda #$0f
	sta APU_STATUS
	lda #$40
	sta APU_FRAME
	rts

audioregs:
        .byte $30,$08,$00,$00
        .byte $30,$08,$00,$00
        .byte $80,$00,$00,$00
        .byte $30,$00,$00,$00
        .byte $00,$00,$00,$00

initializeDmaTable:
	ldx #0
@next_sprite:
	lda #0
	sta OAMADDR,x ; y position
	inx
	lda #BLOCK_SPRITE_BG
	sta OAMADDR,x ; sprite index
	inx
	lda #0
	sta OAMADDR,x ; palette
	inx
	sta OAMADDR,x ; x position
	inx
	bne @next_sprite
	rts

initializeAttributeTable:
	lda #$23
	sta PPUADDR
	lda #$c0
	sta PPUADDR
	lda #$00
	ldx #$40
@nextAttributeByte:
	sta PPUDATA
	dex
	bne @nextAttributeByte
	rts

initializePalette:
	lda #$3f
	sta PPUADDR
	lda #$00
	sta PPUADDR
	ldx #0
@nextPaletteEntry:
	lda defaultPalette,x
	sta PPUDATA
	inx
	cpx #$20
	bne @nextPaletteEntry
	rts

defaultPalette:
	; the background values for sprites
	; have priority because of mirroring
	.byte $21,$30,$27,$3f ; background 0
	.byte $3f,$3f,$3f,$3f ; background 1
	.byte $3f,$3f,$3f,$3f ; background 2
	.byte $3f,$3f,$3f,$3f ; background 3
	.byte $21,$16,$37,$07 ; sprite 0
	.byte $3f,$19,$37,$07 ; sprite 1
	.byte $3f,$3f,$3f,$3f ; sprite 2
	.byte $3f,$3f,$3f,$3f ; sprite 3

