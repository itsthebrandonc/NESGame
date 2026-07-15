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
prevButtons1 .rs 1

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
spriteData_Y .rs 1
spriteData_TileNumber .rs 1
spriteData_Attr .rs 1
spriteData_X .rs 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  .bank 0
  .org $C000 
  .include "resources/startup.asm"

OnInit:
  ;CREATING NEW SPRITE
  ;JSR GetNewSpriteAddress ;Gets sprite no/addr available
  ;LDX #$00
  ;LDY #$80
  ;STX spriteDataPos
  ;STY value
  ;JSR UpdateSprite ;Sets Y Pos
  ;INX
  ;LDY #$40
  ;STX spriteDataPos
  ;STY value
  ;JSR UpdateSprite ;Sets Tile Number
  ;INX
  ;LDY #$00
  ;STX spriteDataPos
  ;STY value
  ;JSR UpdateSprite ;Sets attributes
  ;INX
  ;LDY #$80
  ;STX spriteDataPos
  ;STY value
  ;JSR UpdateSprite ;Sets X Pos

  ;Spawn Character
  ; Write top-left sprite info and pass it into SpawnCharacter function
  LDY #$80
  STA spriteData_Y
  LDX #$01
  LDY #$40
  STA spriteData_Y, X
  LDY #$00
  INX
  STA spriteData_Y, X
  LDY #$80
  INX
  STA spriteData_Y, X
  JSR SpawnCharacter

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

OnInputR:
  ;Move character right
  LDA #$00
  STA spriteNo
  LDA #$03
  STA spriteDataPos
  JSR GetSpriteData
  LDA value
  CMP #$F7
  BEQ .OnInputRComplete
  INC value
  JSR UpdateSprite
.OnInputRComplete:
  RTS

OnInputU:
  ;Move character up
  LDA #$00
  STA spriteNo
  LDA #$00
  STA spriteDataPos
  JSR GetSpriteData
  LDA value
  BEQ .OnInputUComplete
  DEC value
  JSR UpdateSprite
.OnInputUComplete:
  RTS

OnInputD:
  ;Move character down
  LDA #$00
  STA spriteNo
  LDA #$00
  STA spriteDataPos
  JSR GetSpriteData
  LDA value
  CMP #$E7
  BEQ .OnInputDComplete
  INC value
  JSR UpdateSprite
.OnInputDComplete:
  RTS

;; Additional Functions

;; SpawnCharacter
;; ;; Loads character sprite
;; ;; Parameters:
;; ;; ;; spriteData - 4 bytes: Y Pos (top left), Tile Number (top left), Attributes, X Pos (top left)
SpawnCharacter:
  ; Sprite 0 (top left) = $0200-$0203, Sprite 1 (top right) = $0204-0207, Sprite 2 (bottom left) = $0208-$020B, Sprite 3 (bottom right) = $020C-$020F
  ; Attributes:
  ;; Bit 7 - flip sprite vertically
  ;; Bit 6 - slip sprite horizontally
  ;; Bit 5 - Priority (0 = in front of background, 1 = behind background)
  ;; Bit 4, 3 and 2 - None
  ;; Bit 1 and 0 = Color pallete ($00 - $04)

  ;Y Pos
  LDA spriteData_Y
  STA $0200 ; top left
  STA $0204 ; top right
  CLC
  ADC #$08    ; shift bottom sprites down
  STA $0208 ; bottom left
  STA $020C ; bottom right

  ;Tile Number
  LDY #$01
  LDA spriteData_Y, Y
  LDA #$40
  STA $0201 ; top left
  TAX
  INX
  TXA
  STA $0205 ; top right
  CLC
  ADC #$0F      ; next tiles are on the next row
  STA $0209
  TAX
  INX
  TXA
  STA $020D

  ;Attributes
  INY
  LDA spriteData_Y, Y
  STA $0202 ; top left
  STA $0206 ; top right
  STA $020A ; bottom left
  STA $020E ; bottom right

  ;X Pos
  INY
  LDA spriteData_Y, Y
  STA $0203 ; top left
  STA $020B ; bottom left
  CLC
  ADC #$08 ; shift right tiles
  STA $0207 ; top right
  STA $020F ; bottom right

  RTS