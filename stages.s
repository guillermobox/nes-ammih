Metatile_Ground = $29

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

	; CONSUME THE BACKGROUND TILES
	lda (STAGE_ADDR),y
	tax
	
:
	jsr consumeMapCoordinates
	lda #Metatile_Ground
	sta PPU_BUF_VAL
	jsr writeMetatile
	dex
	bne :-

	; CONSUME THE DEATH TILES
	iny
	lda (STAGE_ADDR),y
	beq @noDeadTiles
	tax

:
	jsr consumeMapCoordinates
	lda #BLOCK_SPRITE_F3
	sta PPU_BUF_VAL
	jsr writeBackgroundBlock
	dex
	bne :-
@noDeadTiles:

	; CONSUME THE CHARACTERS STARTING POSITIONS
	iny
	lda (STAGE_ADDR),y
	sta P1_COOR
	iny
	lda (STAGE_ADDR),y
	sta P2_COOR

	; CONSUME THE CHARACTERS WINNING POSITIONS
	lda #BLOCK_SPRITE_F2
	sta PPU_BUF_VAL

	jsr consumeMapCoordinates
	lda (STAGE_ADDR),y
	sta STAGE_EXIT_1
	lda #$40
	sta PPU_BUF_VAL
	jsr writeMetatile

	jsr consumeMapCoordinates
	lda (STAGE_ADDR),y
	sta STAGE_EXIT_2
	lda #$40
	sta PPU_BUF_VAL
	jsr writeMetatile

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

writeMetatile:
	lda PPU_BUF_HI
	sta PPUADDR
	lda PPU_BUF_LO
	sta PPUADDR
	lda PPU_BUF_VAL
	inc PPU_BUF_VAL
	sta PPUDATA
	lda PPU_BUF_VAL
	inc PPU_BUF_VAL
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
	inc PPU_BUF_VAL
	sta PPUDATA
	lda PPU_BUF_VAL
	inc PPU_BUF_VAL
	sta PPUDATA
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
; uses zero page $31, fix that
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

	; test for killing tiles
	lda (STAGE_ADDR),y ; read the length
	tax
	; consume "x" bytes
	beq @noDeath
:
	iny
	lda (STAGE_ADDR),y
	cmp $31
	beq @found_death_tile
	dex
	bne :-
@noDeath:

	iny

	; skip character starting positions
	iny
	iny

	; test for exit tiles
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
@found_death_tile:
	lda #$04
	rts

stagesLookUpTable:
	.addr map1
	.addr map2
	.addr map3
	.addr map4

numberOfStages:
	.byte $04

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
; Now the coordinates of the "dead area"
; How many, then y and x compressed in a single byte
.byte $00
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
; Now the coordinates of the "dead area"
; How many, then y and x compressed in a single byte
.byte $00
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
; Now the coordinates of the "dead area"
; How many, then y and x compressed in a single byte
.byte $00
; Second, the start locations for the characters
.byte $56, $7a
.byte $56, $6c
map4:
; How many, then y and x compressed in a single byte
.byte 15
.byte $44
.byte $45
.byte $53
.byte $54
.byte $55
.byte $63
.byte $64
.byte $65
.byte $48
.byte $58
.byte $59
.byte $68
.byte $69
.byte $78
.byte $79
; Now the coordinates of the "dead area"
; How many, then y and x compressed in a single byte
.byte $04
.byte $45
.byte $55
.byte $65
.byte $68
; Second, the start locations for the characters
.byte $44
.byte $48
; Last, the exit locations
.byte $63
.byte $78


