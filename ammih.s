PPUCONTROL   = $2000
PPUMASK      = $2001
PPUSTATUS    = $2002
PPUADDR      = $2006
PPUDATA      = $2007
APU_ADDR     = $4000
APU_WA1      = $4000
APU_WA2      = $4004
APU_TRI      = $4008
APU_NOI      = $400C
APU_DMC      = $4010
APU_STATUS   = $4015
APU_FRAME    = $4017
INPUT_CTRL_1 = $4016
INPUT_CTRL_2 = $4017
OAM_DMA      = $4014

PPU_BUF_LO   = $0005
PPU_BUF_HI   = $0006
PPU_BUF_VAL  = $0007
STAGE_ADDR   = $0009

P1_COOR      = $0200
P2_COOR      = $0201
P1_NEXT_COOR = $0202
P2_NEXT_COOR = $0203

INPUT        = $0300
PRESSED      = $0301
BULK_UPDATE  = $0302
ACTIVE_STAGE = $0303
GAME_STATE   = $0306


PPU_ENCODED     = $0400
PPU_ENCODED_LEN = $04FF

OAMADDR      = $0700

BLOCK_SPRITE_BG = $24
BLOCK_SPRITE_F1 = $26
BLOCK_SPRITE_F2 = $27
BLOCK_SPRITE_F3 = $28

GameStateLoading = $00
GameStatePlaying = $01
GameStateVictory = $02

DPAD_MASK       = DPAD_UP | DPAD_DOWN | DPAD_LEFT | DPAD_RIGHT
DPAD_UP         = %00001000
DPAD_DOWN       = %00000100
DPAD_LEFT       = %00000010
DPAD_RIGHT      = %00000001
CTRL_START      = %00010000

.segment "CODE"
nmi:
	jsr doConsumePPUEncoded

	; enqueue DMA transfer to OAM
	lda #>OAMADDR
	sta OAM_DMA

	; ppu critical phase finished
	jsr doProcessInput
	jsr doTriggerAudio
	jsr updatePlayerSprites
	jsr updateGameState

	lda GAME_STATE
	bne @stageIsAlreadyLoaded
	; disable rendering
	ldx #0
	stx PPUMASK
	; disable nmi
	lda #%00100000
	sta PPUCONTROL
	; load the stage
	jsr doLoadStage
	; wait for the next blank
	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR
@vblankwait:
	bit PPUSTATUS
	bpl @vblankwait
	; enable rendering
	lda #$1e
	sta PPUMASK
	; enable nmi
	lda #%10100000
	sta PPUCONTROL
	lda #GameStatePlaying
	sta GAME_STATE
@stageIsAlreadyLoaded:

	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR

	rti

; PPU encoded instructions are, per byte:
;   - number of characters (N)
;   - ppuaddress: high, low
;   - N bytes
doConsumePPUEncoded:
	ldx #$0
@nextrow:
	cpx PPU_ENCODED_LEN
	beq @done
	ldy PPU_ENCODED,x
	inx
	lda PPU_ENCODED,x
	sta PPUADDR
	inx
	lda PPU_ENCODED,x
	sta PPUADDR
	@nextletter:
	    inx
	    lda PPU_ENCODED,x
	    sta PPUDATA
	    dey
	bne @nextletter
	inx
	jmp @nextrow
@done:
	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR
	sta PPU_ENCODED
	sta PPU_ENCODED_LEN
	rts

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

updateGameState:
	lda GAME_STATE
	cmp #GameStatePlaying
	beq :+
		rts
	:

	; get the stage address
	lda ACTIVE_STAGE
	asl
	tax
	lda stagesLookUpTable,x
	sta STAGE_ADDR
	inx
	lda stagesLookUpTable,x
	sta STAGE_ADDR+1

	; if both characters are in exit cells, you win
	ldy #$00
	lda (STAGE_ADDR),y
	tay
	iny
	; now map1,x points to the character start location
	iny
	iny
	; now map1,x points to the exit cell
	; y contains the ammount of characters in output cells
	ldx #$0
	lda (STAGE_ADDR),y
	cmp P1_COOR
	bne :+
		inx
	:
	cmp P2_COOR
	bne :+
		inx
	:
	iny
	lda (STAGE_ADDR),y
	cmp P1_COOR
	bne :+
		inx
	:
	cmp P2_COOR
	bne :+
		inx
	:
	cpx #$02
	bne :+
		lda #GameStateVictory
		sta GAME_STATE
		lda #<welldone
		sta $00
		lda #>welldone
		sta $01
		jsr doEnqueueTextMessage
		lda #<msg_press_start
		sta $00
		lda #>msg_press_start
		sta $01
		jsr doEnqueueTextMessage
	:
	rts

clearField:
	jsr initializeNametables
	lda #<msg
	sta $00
	lda #>msg
	sta $01
	jsr doEnqueueTextMessage
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

doProcessInput:
	lda #$00
	sta INPUT

	lda #$01
	sta INPUT_CTRL_1
	lda #$00
	sta INPUT_CTRL_1

	ldx #$08
@nextInput:
	lda INPUT_CTRL_1
	lsr a
	rol INPUT
	dex
	bne @nextInput

	lda INPUT
	bne @newInput
	lda #0
	sta PRESSED
	rts
@newInput:

	lda PRESSED
	beq @moveCharacter
	rts
@moveCharacter:
	; we dispatch difference things depending on the game state
	lda GAME_STATE
	cmp #GameStatePlaying
	bne :+
	jsr doMaybeMoveCharacters
	jmp @done
:
	cmp #GameStateVictory
	bne :+
	jsr doMaybeMenu
	jmp @done
:
@done:
	lda #1
	sta PRESSED
@finishedInput:
	rts

doMaybeMenu:
	lda INPUT
	and #CTRL_START
	beq @notstart
		; go to next stage then
		lda #GameStateLoading
		sta GAME_STATE
		inc ACTIVE_STAGE

@notstart:
	rts

doMaybeMoveCharacters:
	; calculate destination coordinates
	lda P1_COOR
	sta P1_NEXT_COOR
	lda P2_COOR
	sta P2_NEXT_COOR

	lda INPUT
	and #DPAD_LEFT
	beq @notleft
	dec P1_NEXT_COOR
	dec P2_NEXT_COOR
	jmp @calculated
@notleft:
	lda INPUT
	and #DPAD_RIGHT
	beq @notright
	inc P1_NEXT_COOR
	inc P2_NEXT_COOR
	jmp @calculated
@notright:
	lda INPUT
	and #DPAD_UP
	beq @notup

	clc
	lda P1_COOR
	adc #$f0
	and #$f0
	sta 0
	lda P1_COOR
	and #$0f
	ora 0
	sta P1_NEXT_COOR

	clc
	lda P2_COOR
	adc #$f0
	and #$f0
	sta 0
	lda P2_COOR
	and #$0f
	ora 0
	sta P2_NEXT_COOR

	jmp @calculated
@notup:
	lda INPUT
	and #DPAD_DOWN
	beq @notdown

	clc
	lda P1_COOR
	adc #$10
	and #$f0
	sta 0
	lda P1_COOR
	and #$0f
	ora 0
	sta P1_NEXT_COOR

	clc
	lda P2_COOR
	adc #$10
	and #$f0
	sta 0
	lda P2_COOR
	and #$0f
	ora 0
	sta P2_NEXT_COOR

	jmp @calculated
@notdown:
@calculated:
	; now that I have the possible new coordinates,
	; move the characters if they can

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
@nextBackgroundTile:
	iny
	lda (STAGE_ADDR),y
	cmp P1_NEXT_COOR
	bne @player1CannotMoveThere
	lda P1_NEXT_COOR
	sta P1_COOR
	lda (STAGE_ADDR),y
@player1CannotMoveThere:
	cmp P2_NEXT_COOR
	bne @player2CannotMoveThere
	lda P2_NEXT_COOR
	sta P2_COOR
@player2CannotMoveThere:
	dex
	bne @nextBackgroundTile

	rts

doTriggerAudio:
	rts

reset:
	; reset cpu state to a well known state
	sei             ; ignore IRQs
	cld             ; disable decimal mode
	ldx #$ff
	txs             ; Set up stack
	inx             ; now X = 0
	stx APU_DMC     ; disable DMC IRQs
	lda PPUSTATUS   ; clear the status by reading it
	stx PPUCONTROL  ; disable NMI
	stx PPUMASK     ; disable rendering

	; The vblank flag is in an unknown state after reset,
	; so it is cleared here to make sure that @vblankwait1
	; does not exit immediately.
	bit PPUSTATUS

@vblankwait1:
	bit PPUSTATUS
	bpl @vblankwait1

	txa
@clrmem:
	sta $000,x
	sta $100,x
	sta $200,x
	sta $300,x
	sta $400,x
	sta $500,x
	sta $600,x
	sta $700,x
	inx
	bne @clrmem

@vblankwait2:
	bit PPUSTATUS
	bpl @vblankwait2

	jsr initializeNametables
	jsr initializeApu
	jsr initializePalette
	jsr initializeAttributeTable
	jsr initializeDmaTable
	jsr updatePlayerSprites

	; activate NMI and large sprites
	lda PPUCONTROL
	ora #%10100000
	sta PPUCONTROL

	lda #GameStateLoading
	sta GAME_STATE
	lda #0
	sta ACTIVE_STAGE
BusyLoop:
	jmp BusyLoop

msg:
.byte $20,$44
; Encoded string produced by encode.c
; The string: "a match made in heaven"
.byte $0a,$24,$16,$0a,$1d,$0c,$11,$24,$16,$0a,$0d,$0e,$24,$12,$17,$24,$11,$0e,$0a,$1f,$0e,$17,$00

welldone:
.byte $23,$2b
; Encoded string produced by encode.c
; The string: "well done"
.byte $20,$0e,$15,$15,$24,$0d,$18,$17,$0e,$00

msg_press_start:
.byte $23,$64
; Encoded string produced by encode.c
; The string: "press start to continue"
.byte $19,$1b,$0e,$1c,$1c,$24,$1c,$1d,$0a,$1b,$1d,$24,$1d,$18,$24,$0c,$18,$17,$1d,$12,$17,$1e,$0e,$00

stagesLookUpTable:
	.addr map1
	.addr map2
map1:
; Encoded first map of the game, for testing purposes
; First, the coordinates of the "walkable area"
; How many, then y and x compressed in a single byte
.byte $05
.byte $45
.byte $55
.byte $48
.byte $58
.byte $68
; Second, the start locations for the characters
.byte $45
.byte $48
; Last, the exit locations
.byte $55
.byte $68
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

updatePlayerSprites:
	clc
	lda P1_COOR
	and #$f0
	adc #$Fd
	sta OAMADDR
	lda P1_COOR
	and #$0F
	asl
	asl
	asl
	asl
	sta OAMADDR+3
	lda #$30
	sta OAMADDR+1

	lda P1_COOR
	and #$f0
	adc #$Fd
	sta OAMADDR+4
	lda P1_COOR
	and #$0F
	asl
	asl
	asl
	asl
	clc
	adc #8
	sta OAMADDR+3+4
	lda #$32
	sta OAMADDR+1+4

	lda P2_COOR
	and #$f0
	adc #$FD
	sta OAMADDR+8
	lda #$01
	sta OAMADDR+2+8
	lda P2_COOR
	and #$0f
	asl
	asl
	asl
	asl
	sta OAMADDR+3+8
	lda #$30
	sta OAMADDR+1+8

	lda P2_COOR
	and #$f0
	adc #$fd
	sta OAMADDR+4+8
	lda #$01
	sta OAMADDR+4+2+8
	lda P2_COOR
	and #$0f
	asl
	asl
	asl
	asl
	clc
	adc #8
	sta OAMADDR+3+4+8
	lda #$32
	sta OAMADDR+1+4+8
	rts

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

.segment "VECTORS"
	.addr nmi
	.addr reset
	.addr nmi
