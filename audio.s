initializeAudioEngine:
    lda #0
    sta AUDIO_PATTERN_COUNTER
    sta AUDIO_NOTE_IDX
    rts


doTriggerAudio:
    ldx AUDIO_NOTE_IDX
    ; load the trigger cycle of the actual note
    lda pattern_addr, x
    ; this might be FF, this never matches always leaves
    cmp AUDIO_PATTERN_COUNTER
    bne @done
    ; we found at X something to play, so we load the note
    ldy pattern_addr+1, x
    ; if we loaded a zero, this is a silence
    bne :+
        jsr doSilenceChannel
        jmp @consume
    :
    ; otherwise load the other byte and call play
    sty $00
    ldy pattern_addr+2, x
    sty $01
    jsr doPlayNote
@consume:
    ; consume the audio pattern note
    inc AUDIO_NOTE_IDX
    inc AUDIO_NOTE_IDX
    inc AUDIO_NOTE_IDX
@done:
	inc AUDIO_PATTERN_COUNTER
    lda AUDIO_PATTERN_COUNTER
    cmp #160
    beq :+
	rts
:
    jsr initializeAudioEngine
    rts

doSilenceChannel:
	lda #%10110000
	sta $4000
    rts

; the note bytes are in 00 and 01
doPlayNote:
    lda $00
    sta $4002
    lda $01
    ora #%10100000
	sta $4003
	lda #%10111111
	sta $4000
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

; encoding a pattern
.byte 160 ; pattern length
pattern_addr:
.byte 0, $7c, $01 ; at 0 play D3
.byte 20, $0c, $01 ; at 20 play G#3
.byte 40, $2d, $01 ; at 40 play F#3
.byte 60, $00, $00 ; at 60 stop
.byte 80, $7c, $01 ; at 80 play D3
.byte 100, $00, $00 ; at 100 stop
.byte 120, $c9, $00 ; at 120 play C#4
.byte 140, $00, $00 ; at 140 stop
.byte $ff ; at 160 will loop


; Project Version="2.1.0" TempoMode="FamiStudio" Name="Untitled" Author="Unknown"
; 	Instrument Name="Instrument 1"
; 		Envelope Type="DutyCycle" Length="1" Values="2"
; 	Song Name="Song 1" Length="1" LoopPoint="0" PatternLength="16" BarLength="4" NoteLength="10"
; 		Channel Type="Square1"
; 			Pattern Name="Pattern 1"
; 				Note Time="0" Value="D3" Instrument="Instrument 1"
; 				Note Time="20" Value="G#3" Instrument="Instrument 1"
; 				Note Time="40" Value="F#3" Instrument="Instrument 1"
; 				Note Time="60" Value="Stop"
; 				Note Time="80" Value="D3" Instrument="Instrument 1"
; 				Note Time="100" Value="Stop"
; 				Note Time="120" Value="C#4" Instrument="Instrument 1"
; 				Note Time="140" Value="Stop"
; 			PatternInstance Time="0" Pattern="Pattern 1"
; 		Channel Type="Square2"
; 		Channel Type="Triangle"
; 		Channel Type="Noise"
; 		Channel Type="DPCM"
