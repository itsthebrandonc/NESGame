  ;;;;;;;;;;;     ROM Header      ;;;;;;;;;;;;;;;
  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Sprites / Pallets / Background
  
  .bank 1
  .org $E000    ;;align the background data so the lower address is $00
  .include "resources/background.asm"
  .include "resources/attributes.asm"
  
;;;;;;;;;;;;;;  
  
  .bank 2
  .org $0000
  .incbin "resources/NESGame.chr"   ;includes 8KB graphics file


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  .rsset $0000    ; put pointers in zero page

;Generic variables
pointerLo .rs 1   ; pointers declared in RAM (each .rs goes to next register)
pointerHi .rs 1   ; low byte first, high byte immediately after
pointerLo2 .rs 1
pointerHi2 .rs 1  ; low byte first, high byte immediately after
startLo .rs 1     ; low byte first, high byte immediately after
startHi .rs 1
temp .rs 1
value .rs 1

;Button variables
buttons1 .rs 1
buttons1Held .rs 1

;Text variables
textTruncStart .rs 1
textTruncEnd .rs 1
textLength .rs 1
textCooldown .rs 1
textIsDrawing .rs 1

;Sprite variables
spriteNo .rs 1
spriteAddr .rs 1
spriteDataPos .rs 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  .bank 0
  .org $C000 
  .include "resources/startup.asm"

OnInit:
  ;CREATING NEW SPRITE
  JSR GetNewSpriteAddress ;Gets sprite no/addr available
  LDX #$00
  LDY #$80
  STX spriteDataPos
  STY value
  JSR UpdateSprite ;Sets Y Pos
  INX
  LDY #$40
  STX spriteDataPos
  STY value
  JSR UpdateSprite ;Sets Tile Number
  INX
  LDY #$00
  STX spriteDataPos
  STY value
  JSR UpdateSprite ;Sets attributes
  INX
  LDY #$80
  STX spriteDataPos
  STY value
  JSR UpdateSprite ;Sets X Pos

  RTS


OnInputA:
  ;DRAWING TEXT
  ;; Setting text variable
  LDA #HIGH(textRow_HelloWorld)
  STA pointerHi       ; put the high byte of the address into pointer
  LDA #LOW(textRow_HelloWorld)
  STA pointerLo       ; put the low byte of the address of background into pointer
  ;; Setting draw position
  LDA #$21
  STA startHi
  LDA #$E0
  STA startLo
  ;; Running draw function
  JSR DrawText

  RTS

OnInputL:
  ;Move character left
  LDA #$00
  STA spriteNo
  LDA #$03
  STA spriteDataPos
  JSR GetSpriteData
  LDA value
  BEQ .OnInputLComplete
  DEC value
  JSR UpdateSprite
.OnInputLComplete:
  RTS