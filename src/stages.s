EMPTY     = METATILE_SOLID
BORDER_UP = METATILE_BOX
BORDER_DN = METATILE_BOX + 1
BORDER_LE = METATILE_BOX + 2
BORDER_RI = METATILE_BOX + 3
BORDER_DL = METATILE_BOX + 4
BORDER_UL = METATILE_BOX + 5
BORDER_DR = METATILE_BOX + 6
BORDER_UR = METATILE_BOX + 7

tileCombinationTable:
	.byte BORDER_UP,BORDER_DN,BORDER_UL,BORDER_UR
	.byte BORDER_UP,BORDER_DN,BORDER_DL,BORDER_DR
	.byte BORDER_UL,BORDER_DL,BORDER_LE,BORDER_RI
	.byte BORDER_UR,BORDER_DR,BORDER_LE,BORDER_RI

; in A the coordinates of the metatile
writePaletteAtMetatile:
	tax
	lsr
	lsr
	and #%00111000
	sta $00
	txa
	lsr
	and #%00000111
	ora $00
	ora #$C0
	sta $00

	; read the palette value
	lda #$23
	sta PPUADDR
	lda $00
	sta PPUADDR
	lda PPUDATA
	lda PPUDATA
	sta $01

	; calculate the mask (at $02)
	lda #$03
	sta $02
	lda #$01
	sta $03

	txa
	lsr
	lsr
	lsr
	lsr
	and #%01
	beq :+
		asl $02
		asl $02
		asl $02
		asl $02
		asl $03
		asl $03
		asl $03
		asl $03
:
	txa
	and #$01
	beq :+
		asl $02
		asl $02
		asl $03
		asl $03
:
	lda $02
	eor #$FF
	sta $02
	lda $01
	and $02
	ora $03
	sta $01
	lda #$23
	sta PPUADDR
	lda $00
	sta PPUADDR
	lda $01
	sta PPUDATA
	rts


readTile:
	jsr convertTilePPU
	lda $02
	sta PPUADDR
	lda $03
	sta PPUADDR
	lda PPUDATA
	lda PPUDATA
	sta $04
	rts

; combine tiles at $04 (already set) and $05 (new tile)
; and write the result at $05
combineTile:
	lda $04
	; if this is outside, it can be safely written
	cmp #METATILE_SOLID
	bne :+
		rts
	:
	; if this is not a border, do not write in there
	cmp #METATILE_BOX
	beq @yes
	cmp #METATILE_BOX + 1
	beq @yes
	cmp #METATILE_BOX + 2
	beq @yes
	cmp #METATILE_BOX + 3
	beq @yes
	cmp #METATILE_BOX + 4
	beq @yes
	cmp #METATILE_BOX + 5
	beq @yes
	cmp #METATILE_BOX + 6
	beq @yes
	cmp #METATILE_BOX + 7
	beq @yes
	sta $05
	rts
@yes:
	; if the new tile is a corner, ignore it, it's low precedence
	lda $05
	sec
	sbc #METATILE_BOX
	cmp #$04
	bmi :+
		lda $04
		sta $05
		rts
	:
	; if the old tile is a corner, overwrite it
	lda $04
	sec
	sbc #METATILE_BOX
	cmp #$04
	bmi :+
		rts
	:
	; otherwise, use the tile combination table
	lda $05
	sec
	sbc #METATILE_BOX
	asl
	asl
	tax

	lda $04
	sec
	sbc #METATILE_BOX

	tay
	iny
	dex
:
	inx
	dey
	bne :-


	lda tileCombinationTable,x
	sta $05
	rts


; write a box around a particular logical coordinate, set at y=$00 and x=$01
WriteSingleBox:
	; after writing the tile, get the logical coordinates and convert them
	; to the tile coordinates (2xlogical)
	asl $00
	asl $01

	dec $00
	dec $01

	jsr readTile
	lda #BORDER_DR
	sta $05
	jsr combineTile
	lda $05
	lda $02
	sta PPUADDR
	lda $03
	sta PPUADDR
	lda $05
	sta PPUDATA

	inc $01
	jsr readTile
	lda #BORDER_UP
	sta $05
	jsr combineTile
	lda $05
	lda $02
	sta PPUADDR
	lda $03
	sta PPUADDR
	lda $05
	sta PPUDATA

	inc $01
	jsr readTile
	lda #BORDER_UP
	sta $05
	jsr combineTile
	lda $05
	lda $02
	sta PPUADDR
	lda $03
	sta PPUADDR
	lda $05
	sta PPUDATA

	inc $01
	jsr readTile
	lda #BORDER_DL
	sta $05
	jsr combineTile
	lda $05
	lda $02
	sta PPUADDR
	lda $03
	sta PPUADDR
	lda $05
	sta PPUDATA

	inc $00
	jsr readTile
	lda #BORDER_RI
	sta $05
	jsr combineTile
	lda $05
	lda $02
	sta PPUADDR
	lda $03
	sta PPUADDR
	lda $05
	sta PPUDATA

	inc $00
	jsr readTile
	lda #BORDER_RI
	sta $05
	jsr combineTile
	lda $05
	lda $02
	sta PPUADDR
	lda $03
	sta PPUADDR
	lda $05
	sta PPUDATA

	inc $00
	jsr readTile
	lda #BORDER_UL
	sta $05
	jsr combineTile
	lda $05
	lda $02
	sta PPUADDR
	lda $03
	sta PPUADDR
	lda $05
	sta PPUDATA

	dec $01
	jsr readTile
	lda #BORDER_DN
	sta $05
	jsr combineTile
	lda $05
	lda $02
	sta PPUADDR
	lda $03
	sta PPUADDR
	lda $05
	sta PPUDATA

	dec $01
	jsr readTile
	lda #BORDER_DN
	sta $05
	jsr combineTile
	lda $05
	lda $02
	sta PPUADDR
	lda $03
	sta PPUADDR
	lda $05
	sta PPUDATA

	dec $01
	jsr readTile
	lda #BORDER_UR
	sta $05
	jsr combineTile
	lda $05
	lda $02
	sta PPUADDR
	lda $03
	sta PPUADDR
	lda $05
	sta PPUDATA

	dec $00
	jsr readTile
	lda #BORDER_LE
	sta $05
	jsr combineTile
	lda $05
	lda $02
	sta PPUADDR
	lda $03
	sta PPUADDR
	lda $05
	sta PPUDATA

	dec $00
	jsr readTile
	lda #BORDER_LE
	sta $05
	jsr combineTile
	lda $05
	lda $02
	sta PPUADDR
	lda $03
	sta PPUADDR
	lda $05
	sta PPUDATA

	rts

; CONVERT FROM TILE COORDINATES TO PPU COORDINATES
; get y and x tile coorinates from $00 and $01
; save the result in $02 (high) and $03 (low)
convertTilePPU:
	lda $00
	lsr
	lsr
	lsr
	ora #$20
	sta $02

	lda $01
	sta $03
	lda $00
	and #$07
	asl
	asl
	asl
	asl
	asl
	ora $03
	sta $03
	rts

; this is not used right now but will be soon
writeFloor:
	ldy #$0e + 1
@nextRow:
	dey
	ldx #$0f + 1
@nextTile:
	dex
	tya
	lsr
	lsr
	ora #$20
	sta PPU_BUF_HI

	txa
	asl
	sta PPU_BUF_LO
	tya
	and #$03
	asl
	asl
	asl
	asl
	asl
	asl
	ora PPU_BUF_LO
	sta PPU_BUF_LO
	lda #METATILE_FLOOR
	sta PPU_BUF_VAL

	jsr writeMetatile
	cpx #$00
	bne @nextTile
	cpy #$02
	bne @nextRow

	rts

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

	; CONSUME THE BACKGROUND TILES
	ldy #$0
	lda (STAGE_ADDR),y
	tax
:
	jsr consumeMapCoordinates

	lda (STAGE_ADDR),y
	and #$0F
	sta $01
	lda (STAGE_ADDR),y
	lsr
	lsr
	lsr
	lsr
	sta $00

	txa
	pha
	tya
	pha

	jsr WriteSingleBox

	pla
	tay
	pla
	tax

	dex
	bne :-

	; CONSUME THE BACKGROUND TILES
	ldy #$0
	lda (STAGE_ADDR),y
	tax
:
	jsr consumeMapCoordinates
	lda #METATILE_SOLID
	sta PPU_BUF_VAL
	jsr writeBackgroundBlock
	dex
	bne :-


	; CONSUME THE DEATH TILES
	iny
	lda (STAGE_ADDR),y
	beq @noDeadTiles
	tax

:
	jsr consumeMapCoordinates
	lda #METATILE_DEADLYGROUND
	sta PPU_BUF_VAL
	jsr writeMetatile
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
	jsr consumeMapCoordinates
	lda (STAGE_ADDR),y
	sta STAGE_EXIT_1
	jsr writePaletteAtMetatile
	lda #METATILE_TERMINAL
	sta PPU_BUF_VAL
	jsr writeMetatile

	jsr consumeMapCoordinates
	lda (STAGE_ADDR),y
	sta STAGE_EXIT_2
	jsr writePaletteAtMetatile
	lda #METATILE_TERMINAL
	sta PPU_BUF_VAL
	jsr writeMetatile

	; CONSUME THE STEPS
	iny
	lda (STAGE_ADDR),y
	sta STAGE_STEPS

	ldy #MSG_UI_ENERGY
	jsr doEnqueueMessage

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

.include "assets/stages.s"