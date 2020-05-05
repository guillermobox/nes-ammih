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

PPU_BUF_LO   = $0015
PPU_BUF_HI   = $0016
PPU_BUF_VAL  = $0017
STAGE_ADDR   = $0019
PPUMASK_BUF  = $0021
A_CHARACTER_MOVED = $0000

P1_COOR      = $0200
P2_COOR      = $0201
P1_NEXT_COOR = $0202
P2_NEXT_COOR = $0203
STEPS_TAKEN  = $0204
STAGE_EXIT_1 = $0205
STAGE_EXIT_2 = $0206
STAGE_STEPS  = $0207
FRAME = $0100

INPUT        = $0300
PRESSED      = $0301
BULK_UPDATE  = $0302
ACTIVE_STAGE = $0303
GAME_STATE   = $0306
BULK_LOAD    = $0307

PPU_ENCODED     = $0400
PPU_ENCODED_LEN = $04FF

ATT_MIRROR   = $06C0
OAMADDR      = $0700

GameStateLoading     = $00
GameStatePlaying     = $01
GameStateVictory     = $02
GameStateEndScreen   = $03
GameStateIdle        = $04
GameStateFailure     = $05
GameStateTitleScreen = $06

DPAD_MASK       = DPAD_UP | DPAD_DOWN | DPAD_LEFT | DPAD_RIGHT
DPAD_UP         = %00001000
DPAD_DOWN       = %00000100
DPAD_LEFT       = %00000010
DPAD_RIGHT      = %00000001
DPAD_START      = %00010000

.include "chr.s"

.segment "CODE"
nmi:
	inc FRAME

	lda BULK_LOAD
	beq :+
		jsr enterBulkLoadRoutine
		rti
	:

	jsr doConsumePPUEncoded
	; enqueue DMA transfer to OAM
	lda #>OAMADDR
	sta OAM_DMA

	; ppu critical phase finished
	jsr doProcessInput
	jsr doTriggerAudio
	jsr updatePlayerSprites
	jsr updateHUD
	jsr updateGameState

	rti

enterBulkLoadRoutine:
	; disable nmi and rendering
	lda #%00100000
	sta PPUCONTROL
	lda #%00000000
	sta PPUMASK
	lda #%00001110
	sta PPUMASK_BUF

; dispatch the proper long-run task
	lda GAME_STATE
	cmp #GameStateTitleScreen
	bne :+
		jsr bulkLoadTitleScreen
		jmp @dispatchDone
	:
	cmp #GameStateLoading
	bne :+
		jsr bulkLoadStage
		jmp @dispatchDone
	:
	cmp #GameStateEndScreen
	bne :+
		jsr bulkLoadEndScreen
		jmp @dispatchDone
	:
	brk ; should never reach here
@dispatchDone:

	; wait for next frame before re-enabling rendering
	: bit PPUSTATUS
	bpl :-

	; enable nmi and rendering
	lda #%10100000
	sta PPUCONTROL
	lda PPUMASK_BUF
	sta PPUMASK

	; reset PPU ADDR to origin
	lda #$20
	sta PPUADDR
	lda #$00
	sta PPUADDR

	; bulk load finished
	lda #0
	sta BULK_LOAD

	rts

bulkLoadEndScreen:
	jsr doShowEndScreen
	lda #GameStateIdle
	sta GAME_STATE
	rts


bulkLoadTitleScreen:
	jsr clearField
	lda #<msg
	sta $00
	lda #>msg
	sta $01
	jsr doEnqueueTextMessage
	lda #<msg_title
	sta $00
	lda #>msg_title
	sta $01
	jsr doEnqueueTextMessage
	lda #<msg_title2
	sta $00
	lda #>msg_title2
	sta $01
	jsr doEnqueueTextMessage
	lda #<msg_start
	sta $00
	lda #>msg_start
	sta $01
	jsr doEnqueueTextMessage
	rts
	
bulkLoadStage:
	jsr doLoadStage
	jsr updatePlayerSprites
	lda STAGE_STEPS
	sta STEPS_TAKEN

	; enqueue DMA transfer to OAM
	lda #>OAMADDR
	sta OAM_DMA
	lda #GameStatePlaying
	sta GAME_STATE
	lda #%00011110
	sta PPUMASK_BUF
	rts


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
	lda GAME_STATE
	cmp #GameStatePlaying
	beq :+
	rts
	:

	jsr updateBattery
	rts

updateBattery:

	ldx PPU_ENCODED_LEN
	lda #$08
	sta PPU_ENCODED,x
	inx
; input tile coordinates: x = 2 y = 2
; PPU nametable address: 0x2042
	lda #$20
	sta PPU_ENCODED,x
	inx
	lda #$42
	sta PPU_ENCODED,x
	inx
	ldy #$00
@next_battery_tile:
	lda #METATILE_BATTERYFULL
	cpy STEPS_TAKEN
	bmi :+
	lda #METATILE_SOLID
	:
	sta PPU_ENCODED,x
	inx
	iny
	cpy #$08
	bne @next_battery_tile
	stx PPU_ENCODED_LEN

	ldx #$02
	ldy #$02

	lda #$23
	sta $00
	txa
	lsr
	lsr
	sta $01
	tya
	asl
	and #%00111000
	ora #$c0
	ora $01
	sta $01

; ATT_MIRROR   = $06C0
	ldx PPU_ENCODED_LEN
	lda #$03
	tay
	sta PPU_ENCODED,x
	inx
	lda $00
	sta PPU_ENCODED,x
	inx
	lda $01
	sta PPU_ENCODED,x
	inx
@next_attribute_tile:
	lda #$50
	sta PPU_ENCODED,x
	inx
	dey
	bne @next_attribute_tile
	stx PPU_ENCODED_LEN
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
	beq :+
	rts
:

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
	lda STEPS_TAKEN
	bne :+
	jmp @died_return
:
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
	jsr initializeAttributeTable
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

	lda #<msg_start
	sta $00
	lda #>msg_start
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
	beq @dispatchInput
	rts
@dispatchInput:

	lda #1
	sta PRESSED
	; we dispatch depending on the game state
	lda GAME_STATE
	jsr dispatchEngine
	.addr doNothing
	.addr handleInputPlaying
	.addr handleInputVictory
	.addr doNothing
	.addr handleInputEndScreen
	.addr handleInputFailure
	.addr handleInputTitleScreen

doNothing:
	brk
	rts

; find in A the index of the addr to dispatch
; the addresses follow the jsr call to this routine
; control will be returned to the upper frame, so
; do not call this from the bottom of the stack
dispatchEngine:
	asl

	tsx

	sec
	inx
	adc $0100,x
	sta $00

	lda #$00
	inx
	adc $0100,x
	sta $01

	txs

	ldy #$00
	lda ($00),y
	sta $02
	iny
	lda ($00),y
	sta $03
	jmp ($0002)

handleInputEndScreen:
	lda INPUT
	and #DPAD_START
	beq @return
		lda #$00
		sta ACTIVE_STAGE
		lda #$01
		sta BULK_LOAD
		lda #GameStateTitleScreen
		sta GAME_STATE
@return:
	rts

handleInputTitleScreen:
	lda INPUT
	and #DPAD_START
	beq @return
		lda #$00
		sta ACTIVE_STAGE
		lda #1
		sta BULK_LOAD
		lda #GameStateLoading
		sta GAME_STATE
@return:
	rts

handleInputFailure:
	lda INPUT
	and #DPAD_START
	beq @return
		lda #1
		sta BULK_LOAD
		lda #GameStateLoading
		sta GAME_STATE
@return:
	rts

handleInputVictory:
	lda INPUT
	and #DPAD_START
	beq @return
		inc ACTIVE_STAGE
		lda ACTIVE_STAGE
		cmp numberOfStages
		bne @toNextStage
		lda #GameStateEndScreen
		sta GAME_STATE
		lda #1
		sta BULK_LOAD
		rts
		@toNextStage:
		lda #GameStateLoading
		sta GAME_STATE
		lda #1
		sta BULK_LOAD
@return:
	rts

handleInputPlaying:
	lda INPUT
	and #DPAD_MASK
	bne :+
	rts
	:
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
	dec STEPS_TAKEN
@nobodymoved:
	rts

doTriggerAudio:
	rts

; show metasprite at coordinates, use 'x' to pick what OAMADDR to use
; sprite is found at $00
; logical coordinates at $01 (single byte coordinate)
; palette at $02
writeMetasprite:
	clc
	lda $01
	and #$F0
	adc #$FD
	sta OAMADDR,x
	inx
	lda $00
	sta OAMADDR,x
	inx
	lda $02
	sta OAMADDR,x
	inx
	lda $01
	and #$0F
	asl
	asl
	asl
	asl
	sta OAMADDR,x
	inx

	lda $01
	and #$F0
	adc #$FD
	sta OAMADDR,x
	inx
	inc $00
	inc $00
	lda $00
	sta OAMADDR,x
	inx
	lda $02
	sta OAMADDR,x
	lda $01
	and #$0F
	asl
	asl
	asl
	asl
	clc
	adc #8
	inx
	sta OAMADDR,x

	inx
	rts

; form the actual player position, update the sprites to be in the corresponding
; location in the screen
updatePlayerSprites:
	ldx #$00

	lda #METATILE_ROBOT
	sta $00
	lda P1_COOR
	sta $01
	lda #$00
	sta $02
	jsr writeMetasprite

	lda #METATILE_ROBOT
	sta $00
	lda P2_COOR
	sta $01
	lda #$01
	sta $02
	jsr writeMetasprite
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

:	bit PPUSTATUS
	bpl :-

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

:	bit PPUSTATUS
	bpl :-

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

	; we kickstart the game loading the title screen
	lda #GameStateTitleScreen
	sta GAME_STATE
	lda #1
	sta BULK_LOAD
	lda #0
	sta ACTIVE_STAGE

@BusyLoop: jmp @BusyLoop

.include "text.s"
.include "stages.s"
.include "initialize.s"

.segment "VECTORS"
	.addr nmi
	.addr reset
	.addr nmi
