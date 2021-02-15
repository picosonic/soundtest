; OS defines
INCLUDE "os.asm"

ORG &1200

.start

  ; Entry point
  JSR sound_init

  ; Stop foreground code here (music will play from VBLANK event)
.stop
  JMP stop

  ; Back to OS
  RTS

.sound_init
{
  ; Define ENVELOPE
  LDA #&08
  LDX #envelope MOD 256
  LDY #envelope DIV 256
  JSR OSWORD

  ; Set up event handler
  SEI
  LDA #eventv_handler MOD 256:STA EVNTV
  LDA #eventv_handler DIV 256:STA EVNTV+1
  CLI

  ; Enable start of vertical sync event
  LDA #&0E
  LDX #&04
  JSR OSBYTE

  RTS

.envelope
  EQUB 1   ; Envelope number
  EQUB 2   ; Length of each step (hundredths of a second) and auto repeat (top bit)
  EQUB 0   ; Change of pitch per step in section 1
  EQUB 0   ; Change of pitch per step in section 2
  EQUB 0   ; Change of pitch per step in section 3
  EQUB 1   ; Number of steps in section 1
  EQUB 2   ; Number of steps in section 2
  EQUB 3   ; Number of steps in section 3
  EQUB 100 ; Change of amplitude per step during attack phase
  EQUB 1   ; Change of amplitude per step during decay phase
  EQUB 255 ; Change of amplitude per step during sustain phase
  EQUB 254 ; Change of amplitude per step during release phase
  EQUB 126 ; Target level at end of attack phase
  EQUB 126 ; Target level at end of decay phase
}

.eventv_handler
{
  ; Return if counter not zero (i.e. only do something every 8th call)
  INC counter
  LDA counter:AND #&07
  BNE done

  INC progress

  ; Start with channel &11 (Channel 1 with flush enabled)
  LDA #&11:STA soundparams

  ; Read melody data for each of the three channels
  LDX progress:LDA melody, X:JSR sound_play_note
  LDX progress:LDA melody+&100, X:JSR sound_play_note
  LDX progress:LDA melody+&200, X:JSR sound_play_note

.done

  RTS
}

.sound_play_note
{
  ; Skip when pitch is zero (it's a rest)
  BEQ done

  ; Set pitch LSB
  STA soundparams+4

  ; Set all MSB to zero
  LDA #&00
  STA soundparams+1
  STA soundparams+3
  STA soundparams+5
  STA soundparams+7

  ; Use envelope 1 for amplitude
  LDA #&01
  STA soundparams+2
  ; Set duration of 1
  STA soundparams+6

  ; Set pointer to sound params in XY
  LDX #soundparams MOD 256
  LDY #soundparams DIV 256

  ; Action OS sound function
  LDA #&07:JSR OSWORD

  ; Go to next sound channel
  INC soundparams

.done
  RTS
}

; Skip counter
.counter
  EQUB &00

; Progress through melody
.progress
  EQUB &00

; Sound parameter block
.soundparams
  EQUB &00 ; Channel LSB
  EQUB &00 ; Channel MSB
  EQUB &00 ; Amplitude LSB
  EQUB &00 ; Amplitude MSB
  EQUB &00 ; Pitch LSB
  EQUB &00 ; Pitch MSB
  EQUB &00 ; Duration LSB
  EQUB &00 ; Duration MSB

ALIGN &100

; Melody data
.melody
INCBIN "MELODY.beeb"

.end

SAVE "SOUNDS", start, end