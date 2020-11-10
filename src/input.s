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
	.addr handleInputPlaying
	.addr handleInputVictory
	.addr handleInputEndScreen
	.addr handleInputFailure
	.addr handleInputTitleScreen

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
		lda #GameStatePlaying
		sta GAME_STATE
@return:
	rts

handleInputFailure:
	lda INPUT
	and #DPAD_START
	beq @return
		lda #1
		sta BULK_LOAD
		lda #GameStatePlaying
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
		lda #GameStatePlaying
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

