initializeAudioEngine:
    lda #0
    sta AUDIO_PATTERN_COUNTER
    sta AUDIO_NOTE_SQUARE_IDX
    sta AUDIO_NOTE_TRIANG_IDX
    lda #<Song_1_Square_Pattern_1
    sta MUSIC_SQUARE_PATTERN
    lda #>Song_1_Square_Pattern_1
    sta MUSIC_SQUARE_PATTERN + 1
    lda #<Song_1_Triangle_Pattern_1
    sta MUSIC_TRIANG_PATTERN
    lda #>Song_1_Triangle_Pattern_1
    sta MUSIC_TRIANG_PATTERN + 1
    rts

doTriggerAudio:
    jsr doTriggerSquareMusic
    jsr doTriggerTriangleMusic
    inc AUDIO_PATTERN_COUNTER
    lda AUDIO_PATTERN_COUNTER
    ; if we get to 160 we loop!
    cmp #160
    beq :+
    rts
:
    jsr initializeAudioEngine
    rts

doTriggerTriangleMusic:
    ldy AUDIO_NOTE_TRIANG_IDX
    ; load the trigger cycle of the actual note
    lda (MUSIC_TRIANG_PATTERN),y
    ; this might be FF, this never matches always leaves
    cmp AUDIO_PATTERN_COUNTER
    bne @done
    ; we found at X something to play, load the note offset
    iny
    lda (MUSIC_TRIANG_PATTERN),y
    tax
    cpx #$ff
    ; if we loaded a FF, this is a silence
    bne :+
        jsr doSilenceTriangular
        jmp @consume
    :
    jsr doPlayTriangularNote
@consume:
    ; consume the audio pattern note
    inc AUDIO_NOTE_TRIANG_IDX
    inc AUDIO_NOTE_TRIANG_IDX
@done:
    rts


doTriggerSquareMusic:
    ldy AUDIO_NOTE_SQUARE_IDX
    ; load the trigger cycle of the actual note
    lda (MUSIC_SQUARE_PATTERN),y
    ; this might be FF, this never matches always leaves
    cmp AUDIO_PATTERN_COUNTER
    bne @done
    ; we found at X something to play, load the note offset
    iny
    lda (MUSIC_SQUARE_PATTERN),y
    tax
    cpx #$ff
    ; if we loaded a FF, this is a silence
    bne :+
        jsr doSilenceChannel
        jmp @consume
    :
    jsr doPlayNote
@consume:
    ; consume the audio pattern note
    inc AUDIO_NOTE_SQUARE_IDX
    inc AUDIO_NOTE_SQUARE_IDX
@done:
    rts


doSilenceTriangular:
    lda #$00
    sta $4008
    rts

doSilenceChannel:
    lda #%10110000
    sta $4000
    rts

; the note period offset is in x
doPlayTriangularNote:
    lda periodTableLo,x
    sta $400A
    lda periodTableHi,x
    ora #%10100000
    sta $400B
    lda #$ff
    sta $4008
    rts

doPlayNote:
    lda periodTableLo,x
    sta $4002 ; TTTTTTTT (low bits of timer)
    lda periodTableHi,x
    ora #%00000000
    sta $4003 ; LLLLL TTT (lenght counter load + high bits timer)
    lda #%10111111 
    sta $4000 ; DD L C VVVV (duty, length counter halt, constant vol, envelope)
    rts

       ; A   A#   B   C  C#   D  D#   E   F  F#   G  G#
periodTableLo:
  .byte $f1,$7f,$13,$ad,$4d,$f3,$9d,$4c,$00,$b8,$74,$34  ; 1
  .byte $f8,$bf,$89,$56,$26,$f9,$ce,$a6,$80,$5c,$3a,$1a  ; 2
  .byte $fb,$df,$c4,$ab,$93,$7c,$67,$52,$3f,$2d,$1c,$0c  ; 3
  .byte $fd,$ef,$e1,$d5,$c9,$bd,$b3,$a9,$9f,$96,$8e,$86  ; 4
  .byte $7e,$77,$70,$6a,$64,$5e,$59,$54,$4f,$4b,$46,$42  ; 5
  .byte $3f,$3b,$38,$34,$31,$2f,$2c,$29,$27,$25,$23,$21  ; 6
  .byte $1f,$1d,$1b,$1a,$18,$17,$15,$14                  ; 7
periodTableHi:
  .byte $07,$07,$07,$06,$06,$05,$05,$05,$05,$04,$04,$04 ; 1
  .byte $03,$03,$03,$03,$03,$02,$02,$02,$02,$02,$02,$02 ; 2
  .byte $01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01,$01 ; 3
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 4
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 5
  .byte $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 6
  .byte $00,$00,$00,$00,$00,$00,$00,$00                 ; 7

Song_1_Square_Pattern_1:
.byte $00,$1D,$14,$23,$28,$21,$3C,$FF,$50,$1D,$64,$FF,$78,$28,$8C,$FF
.byte $FF
Song_1_Triangle_Pattern_1:
.byte $00,$2C,$05,$FF,$09,$2C,$0D,$FF,$14,$2C,$19,$FF,$1E,$2D,$24,$FF
.byte $28,$2E,$2C,$FF,$32,$2F,$36,$FF,$50,$31,$56,$FF,$5A,$2F,$5F,$FF
.byte $64,$2D,$69,$FF,$6E,$2B,$73,$FF
.byte $FF
