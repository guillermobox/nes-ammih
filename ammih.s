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
A_CHARACTER_MOVED = $0000

P1_COOR      = $0200
P2_COOR      = $0201
P1_NEXT_COOR = $0202
P2_NEXT_COOR = $0203
STEPS_TAKEN  = $0204

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
GameStateEndScreen = $03
GameStateIdle = $04
GameStateFailure = $05

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

	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR

	; ppu critical phase finished
	jsr doProcessInput
	jsr doTriggerAudio
	jsr updatePlayerSprites
	jsr updateGameState
	jsr updateHUD

	lda GAME_STATE
	cmp #GameStateLoading
	bne @stageIsAlreadyLoaded
	; disable rendering
	ldx #0
	stx PPUMASK
	; disable nmi
	lda #%00100000
	sta PPUCONTROL
	; load the stage
	jsr doLoadStage
	lda #$00
	sta STEPS_TAKEN
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

	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR
@stageIsAlreadyLoaded:

	lda GAME_STATE
	cmp #GameStateEndScreen
	bne @notInEndScreen
	; disable rendering
	ldx #0
	stx PPUMASK
	; disable nmi
	lda #%00100000
	sta PPUCONTROL
	; load the stage
	jsr doShowEndScreen
	lda #GameStateIdle
	sta GAME_STATE
	; wait for the next blank
	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR
:
	bit PPUSTATUS
	bpl :-
	; enable rendering
	lda #$0e
	sta PPUMASK
	; enable nmi
	lda #%10100000
	sta PPUCONTROL

	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR
@notInEndScreen:

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

updateHUD:
	lda #$20
	sta $00
	lda #$8D
	sta $01
	lda STEPS_TAKEN
	sta $02
	jsr enqueueNumber
	rts

; consume the address from 00 (high) 01 (low) and the value from 02
enqueueNumber:
	ldx PPU_ENCODED_LEN
	lda #$02
	sta PPU_ENCODED,x
	inx
	lda $00
	sta PPU_ENCODED,x
	inx
	lda $01
	sta PPU_ENCODED,x
	inx

	lda $02
	lsr
	lsr
	lsr
	lsr
	sta PPU_ENCODED,x
	inx

	lda $02
	and #$0f
	sta PPU_ENCODED,x
	inx

	stx PPU_ENCODED_LEN
	rts

; uses zero page $00, $01
updateGameState:
	lda GAME_STATE
	cmp #GameStatePlaying
	bne @return

	lda P1_COOR
	jsr stageTileType
	sta $00
	lda P2_COOR
	jsr stageTileType
	sta $01

	; if any of them died, we died
	lda $00
	cmp #$04
	beq @died_return
	lda $01
	cmp #$04
	beq @died_return
	; if any of them did not win, we return
	lda $00
	cmp #$02
	bne @return
	lda $01
	cmp #$02
	bne @return
	; otherwise, we win
	jmp @victory_return

@return:
	rts
@died_return:
	lda #GameStateFailure
	sta GAME_STATE
	lda #<ohman
	sta $00
	lda #>ohman
	sta $01
	jsr doEnqueueTextMessage
	lda #<msg_try_again
	sta $00
	lda #>msg_try_again
	sta $01
	jsr doEnqueueTextMessage
	rts
@victory_return:
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
	rts

clearField:
	jsr initializeNametables
	lda #<msg
	sta $00
	lda #>msg
	sta $01
	jsr doEnqueueTextMessage
	rts

doShowEndScreen:
	jsr clearField

	lda #<congrats1
	sta $00
	lda #>congrats1
	sta $01
	jsr doEnqueueTextMessage

	lda #<congrats2
	sta $00
	lda #>congrats2
	sta $01
	jsr doEnqueueTextMessage

	lda #<congrats3
	sta $00
	lda #>congrats3
	sta $01
	jsr doEnqueueTextMessage

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
	cmp #GameStateFailure
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
	lda GAME_STATE
	cmp #GameStateEndScreen
	beq @notstart
	lda INPUT
	and #CTRL_START
	beq @notstart
		; go to next stage then
		lda GAME_STATE
		cmp #GameStateFailure
		beq @toNextStage
		inc ACTIVE_STAGE
		lda ACTIVE_STAGE
		cmp numberOfStages
		bne @toNextStage
		lda #GameStateEndScreen
		sta GAME_STATE
		rts
		@toNextStage:
		lda #GameStateLoading
		sta GAME_STATE

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

	lda #$00
	sta A_CHARACTER_MOVED
	lda P1_NEXT_COOR
	jsr stageTileType
	beq :+ ; a tileType 0 is not walkable
		lda P1_NEXT_COOR
		sta P1_COOR
		inc A_CHARACTER_MOVED
	:
	lda P2_NEXT_COOR
	jsr stageTileType
	beq :+ ; a tileType 0 is not walkable
		lda P2_NEXT_COOR
		sta P2_COOR
		inc A_CHARACTER_MOVED
	:

	ldx A_CHARACTER_MOVED
	beq @nobodymoved
	; BCD increment the variable steps taken
	inc STEPS_TAKEN
	lda STEPS_TAKEN
	and #$0f
	cmp #$0a
	bmi :+
		inc STEPS_TAKEN
		inc STEPS_TAKEN
		inc STEPS_TAKEN
		inc STEPS_TAKEN
		inc STEPS_TAKEN
		inc STEPS_TAKEN
	:
@nobodymoved:
	rts

doTriggerAudio:
	rts

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

.include "text.s"
.include "stages.s"
.include "initialize.s"

.segment "VECTORS"
	.addr nmi
	.addr reset
	.addr nmi
