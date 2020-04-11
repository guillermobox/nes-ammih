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

beep         = $0004
P1_COOR_X    = $0200
P1_COOR_Y    = $0201
P2_COOR_X    = $0202
P2_COOR_Y    = $0203

INPUT        = $0300
oamaddr      = $0700


BLOCK_SPRITE_BG = $24

.segment "CODE"
nmi:
	lda #$1e
	sta PPUMASK

	; write title of the game
	lda #$20
	sta PPUADDR
	lda #$24
	sta PPUADDR

	ldx #$00
nextletter:
	lda msg,x
	beq textdone
	sta PPUDATA
	inx
	jmp nextletter
textdone:

	; enqueue DMA transfer to OAM
	lda #>oamaddr
	sta OAM_DMA

	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR

	; ppu critical phase finished
	jsr doProcessInput
	jsr doTriggerAudio

	rti

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

	rts

doTriggerAudio:
	lda beep
	beq @finished
	lda #<179
	sta $4002
	lda #>179
	and #$07
	ora #%10100000
	sta $4003
	lda #%10011111
	sta $4000
@finished:
	lda #0
	sta beep
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

	lda #1
	sta beep

	; activate NMI and large sprites
	lda PPUCONTROL
	ora #%10100000
	sta PPUCONTROL
BusyLoop:
	jmp BusyLoop

msg:
; Encoded string produced by encode.c
; The string: "a match made in heaven"
.byte $0a,$24,$16,$0a,$1d,$0c,$11,$24,$16,$0a,$0d,$0e,$24,$12,$17,$24,$11,$0e,$0a,$1f,$0e,$17,$00


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
	sta oamaddr,x ; y position
	inx
	lda #BLOCK_SPRITE_BG
	sta oamaddr,x ; sprite index
	inx
	lda #0
	sta oamaddr,x ; palette
	inx
	sta oamaddr,x ; x position
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
	.byte $21,$30,$3f,$3f ; background 0
	.byte $3f,$3f,$3f,$3f ; background 1
	.byte $3f,$3f,$3f,$3f ; background 2
	.byte $3f,$3f,$3f,$3f ; background 3
	.byte $3f,$16,$37,$07 ; sprite 0
	.byte $3f,$19,$37,$07 ; sprite 1
	.byte $3f,$3f,$3f,$3f ; sprite 2
	.byte $3f,$3f,$3f,$3f ; sprite 3

.segment "VECTORS"
	.addr nmi
	.addr reset
	.addr nmi
