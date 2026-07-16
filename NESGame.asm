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

;Button variables
buttons1 .rs 1
buttons1Held .rs 1
prevButtons1 .rs 1

;Generic variables
pointerLo .rs 1   ; pointers declared in RAM (each .rs goes to next register)
pointerHi .rs 1   ; low byte first, high byte immediately after
pointerLo2 .rs 1
pointerHi2 .rs 1  ; low byte first, high byte immediately after
startLo .rs 1     ; low byte first, high byte immediately after
startHi .rs 1
temp .rs 1
value .rs 1

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
spriteData .rs 4 ; Y Pos, Tile Number, Attributes, X Pos
playerDirection .rs 1 ; N ($00), NE ($01), NW ($02), S ($03), SE ($04), SW ($05), E ($06), W ($07)

;Bullet Array (32 Bytes, 16 Bullets * 2 Bytes)
;; ;; Bullet Object: 2 Bytes
;; ;; ;; Bullet Sprite Address
;; ;; ;; Bullet Direction
bulletArray .rs 32

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
  STA spriteData
  LDX #$01
  LDY #$40
  STA spriteData, X
  LDY #$00
  INX
  STA spriteData, X
  LDY #$80
  INX
  STA spriteData, X
  JSR SpawnCharacter

  RTS

OnInputB:
  LDA buttons1Held
  AND #%01000000
  BEQ .OnInputB_Press
  RTS
.OnInputB_Press:
  JSR SpawnBullet

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
  JSR MoveCharacterLeft
.OnInputLComplete:
  RTS

OnInputR:
  ;Move character right
  JSR MoveCharacterRight
  RTS

OnInputU:
  ;Move character up
  JSR MoveCharacterUp
.OnInputUComplete:
  RTS

OnInputD:
  ;Move character down
  JSR MoveCharacterDown
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
  LDA spriteData
  STA $0200 ; top left
  STA $0204 ; top right
  CLC
  ADC #$08    ; shift bottom sprites down
  STA $0208 ; bottom left
  STA $020C ; bottom right

  ;Tile Number
  LDY #$01
  LDA spriteData, Y
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
  LDA spriteData, Y
  STA $0202 ; top left
  STA $0206 ; top right
  STA $020A ; bottom left
  STA $020E ; bottom right

  ;X Pos
  INY
  LDA spriteData, Y
  STA $0203 ; top left
  STA $020B ; bottom left
  CLC
  ADC #$08 ; shift right tiles
  STA $0207 ; top right
  STA $020F ; bottom right

  RTS

;; MoveCharacterLeft
;; ;; Moves all character sprites left
MoveCharacterLeft:
  ; Sprite 0 (top left) = $0200-$0203, Sprite 1 (top right) = $0204-0207, Sprite 2 (bottom left) = $0208-$020B, Sprite 3 (bottom right) = $020C-$020F
  LDA $0203 ; top left X Pos
  BEQ .MoveCharacterLeftComplete ; if 0, cannot move left
  DEC $0203 ; top left X Pos
  DEC $0207 ; top right X Pos
  DEC $020B ; bottom left X Pos
  DEC $020F ; bottom right X Pos
.MoveCharacterLeftComplete
  RTS

;; MoveCharacterRight
;; ;; Moves all character sprites right
MoveCharacterRight:
  ; Sprite 0 (top left) = $0200-$0203, Sprite 1 (top right) = $0204-0207, Sprite 2 (bottom left) = $0208-$020B, Sprite 3 (bottom right) = $020C-$020F
  LDA $0207 ; top right X Pos
  CMP #$F7
  BEQ .MoveCharacterRightComplete ; if $F7, cannot move right
  INC $0203 ; top left X Pos
  INC $0207 ; top right X Pos
  INC $020B ; bottom left X Pos
  INC $020F ; bottom right X Pos
.MoveCharacterRightComplete
  RTS

;; MoveCharacterUp
;; ;; Moves all character sprites up
MoveCharacterUp:
  ; Sprite 0 (top left) = $0200-$0203, Sprite 1 (top right) = $0204-0207, Sprite 2 (bottom left) = $0208-$020B, Sprite 3 (bottom right) = $020C-$020F
  LDA $0200 ; top left Y Pos
  BEQ .MoveCharacterUpComplete ; if $00, cannot move up
  DEC $0200 ; top left Y Pos
  DEC $0204 ; top right Y Pos
  DEC $0208 ; bottom left Y Pos
  DEC $020C ; bottom right Y Pos
.MoveCharacterUpComplete
  RTS

;; MoveCharacterDown
;; ;; Moves all character sprites down
MoveCharacterDown:
  ; Sprite 0 (top left) = $0200-$0203, Sprite 1 (top right) = $0204-0207, Sprite 2 (bottom left) = $0208-$020B, Sprite 3 (bottom right) = $020C-$020F
  LDA $0208 ; bottom left Y Pos
  CMP #$E7
  BEQ .MoveCharacterDownComplete ; if $EY, cannot move down
  INC $0200 ; top left Y Pos
  INC $0204 ; top right Y Pos
  INC $0208 ; bottom left Y Pos
  INC $020C ; bottom right Y Pos
.MoveCharacterDownComplete
  RTS

;; SpawnBullet
;; ;; Spawns bullet at player location. Stores in bulletArray and creates sprite
;; ;; Parameter:
;; ;; ;; playerDirection - the direction that the bullet will be traveling in (N, NE, E, SE, S, SW, W, NW)
SpawnBullet:
  ; Find available spot in bullet array
  LDX #$00
.SpawnBullet_GetNewIndexLoop:
  LDA bulletArray, X
  BEQ .SpawnBullet_GetNewIndexEnd
  INX
  INX
  CPX #$20
  BEQ .SpawnBullet_DeleteFirstBullet
  JMP .SpawnBullet_GetNewIndexLoop
.SpawnBullet_DeleteFirstBullet:
  LDX #$00
  STX bulletArray
.SpawnBullet_GetNewIndexEnd: ; X now contains the available spot in the bullet array
  JSR GetNewSpriteAddress
  LDA spriteAddr
  STA bulletArray, X ; Sprite Address stored in Bullet object's first byte
  INX
  LDA playerDirection
  STA bulletArray, X ; Direction stored in Bullet object's second byte

  ; spriteData - 4 bytes: Y Pos (top left), Tile Number (top left), Attributes, X Pos (top left)
  LDX spriteAddr
  LDA $0200 ; player Y pos
  STA $0200, X
  LDA #$42  ; bullet sprite
  STA $0201, X
  LDA #$00
  STA $0202, X
  LDA $0203 ; player X pos
  STA $0203, X

  RTS