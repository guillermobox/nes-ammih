
doLoadStage:
	jsr clearField

	; get the stage address
	lda ACTIVE_STAGE
	asl
	tax
	lda stagesLookUpTable,x
	sta STAGE_ADDR
	inx
	lda stagesLookUpTable,x
	sta STAGE_ADDR+1

	ldy #$0
	lda (STAGE_ADDR),y
	tax
@nextField:
	jsr consumeMapCoordinates

	lda #BLOCK_SPRITE_F1
	sta PPU_BUF_VAL
	jsr writeBackgroundBlock

	dex
	bne @nextField

	iny
	lda (STAGE_ADDR),y
	sta P1_COOR
	iny
	lda (STAGE_ADDR),y
	sta P2_COOR

	lda #BLOCK_SPRITE_F2
	sta PPU_BUF_VAL
	jsr consumeMapCoordinates
	jsr writeBackgroundBlock
	jsr consumeMapCoordinates
	jsr writeBackgroundBlock

	rts

consumeMapCoordinates:
; for the y coordinate
	iny
	lda (STAGE_ADDR),y
	lsr
	lsr
	lsr
	lsr
	lsr
	lsr
	ora #$20
	sta PPU_BUF_HI

; for the x coordinate
	lda (STAGE_ADDR),y
	lsr
	lsr
	lsr
	lsr
	and #$03
	asl
	asl
	asl
	asl
	asl
	asl
	sta 0
	lda (STAGE_ADDR),y
	and #$0F
	asl
	ora 0
	sta PPU_BUF_LO
	rts

writeBackgroundBlock:
	lda PPU_BUF_HI
	sta PPUADDR
	lda PPU_BUF_LO
	sta PPUADDR
	lda PPU_BUF_VAL
	sta PPUDATA
	sta PPUDATA
	clc
	lda PPU_BUF_LO
	adc #$20
	lda #$00
	adc PPU_BUF_HI
	sta PPUADDR
	lda PPU_BUF_LO
	adc #$20
	sta PPUADDR
	lda PPU_BUF_VAL
	sta PPUDATA
	sta PPUDATA
	rts

; Read on A the cell coordinates, return on A the cell type
stageTileType:
	sta $31
	lda ACTIVE_STAGE
	asl
	tax
	lda stagesLookUpTable,x
	sta STAGE_ADDR
	inx
	lda stagesLookUpTable,x
	sta STAGE_ADDR+1

	ldy #$00
	lda (STAGE_ADDR),y
	tax
@next_tile:
	iny
	lda (STAGE_ADDR),y
	cmp $31
	beq @found_tile
	dex
	bne @next_tile
	lda #$00
	rts
@found_tile:
	; the tile might be a exit tile
	; maybe there are still tiles to process
	ldy #$00
	lda (STAGE_ADDR),y
	tay
	iny
	iny
	iny
	lda (STAGE_ADDR),y
	cmp $31
	beq @found_exit_tile
	iny
	lda (STAGE_ADDR),y
	cmp $31
	beq @found_exit_tile

	lda #$01
	rts
@found_exit_tile:
	lda #$02
	rts

stagesLookUpTable:
	.addr map1
	.addr map2
	.addr map3

numberOfStages:
	.byte $03

map1:
; Encoded first map of the game, for testing purposes
; First, the coordinates of the "walkable area"
; How many, then y and x compressed in a single byte
.byte $05
.byte $44
.byte $45
.byte $74
.byte $75
.byte $76
; Second, the start locations for the characters
.byte $44
.byte $74
; Last, the exit locations
.byte $45
.byte $76
map2:
; Encoded second map that requires a little more thinking
.byte $07
.byte $45
.byte $55
.byte $65
.byte $48
.byte $58
.byte $68
.byte $69
; Second, the start locations for the characters
.byte $45, $48
.byte $55, $68
map3:
; Encoded third map that requires a little more thinking
.byte $12
.byte $44
.byte $45
.byte $46
.byte $47
.byte $54
.byte $55
.byte $56
.byte $57
.byte $65
.byte $66
.byte $67
.byte $5a
.byte $5b
.byte $5c
.byte $6a
.byte $6b
.byte $6c
.byte $7a
; Second, the start locations for the characters
.byte $56, $7a
.byte $56, $6c

