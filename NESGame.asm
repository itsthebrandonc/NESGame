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
index .rs 1
option .rs 1
direction .rs 1
speed .rs 1

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
fireCooldown .rs 1

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

OnTick:
  JSR UpdateBullets

  RTS

OnInputB:
  LDA buttons1Held
  AND #%01000000
  BEQ .OnInputB_Press
  RTS
.OnInputB_Press:
  LDA fireCooldown
  BNE .OnInputB_CooldownTimer
  JSR SpawnBullet
  LDA #$01
  STA fireCooldown
  RTS
.OnInputB_CooldownTimer:
  DEC fireCooldown
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
  STA spriteAddr
.SpawnBullet_GetNewIndexLoop:
  LDA bulletArray, X
  BEQ .SpawnBullet_GetNewIndexEnd
  INX
  INX
  CPX #$20
  BEQ .SpawnBullet_DeleteFirstBullet
  JMP .SpawnBullet_GetNewIndexLoop
.SpawnBullet_DeleteFirstBullet:
  LDX bulletArray
  STX spriteAddr ; Reusing existing Sprite Address instead of finding another one
  LDX #$00
  STX index
  JSR DeleteAndShiftBullets
  LDX #$1E ; Puts new bullet at end of array
.SpawnBullet_GetNewIndexEnd: ; X now contains the available spot in the bullet array
  STX index
  LDA spriteAddr
  BNE .SpawnBullet_SetBullet ; Sprite Address being reused from a previous bullet (after deleting first bullet)
  JSR GetNewSpriteAddress
.SpawnBullet_SetBullet
  LDX index
  LDA spriteAddr
  STA bulletArray, X ; Sprite Address stored in Bullet object's first byte
  INX
  LDA playerDirection
  STA bulletArray, X ; Direction stored in Bullet object's second byte
  TAY

  ; spriteData - 4 bytes: Y Pos (top left), Tile Number (top left), Attributes, X Pos (top left)
  CPY #$06
  BCS .SpawnBullet_SetYPlayerPos ; E or W, no need to shift Y
  CPY #$03
  BCC .SpawnBullet_SetNorth
  JMP .SpawnBullet_SetSouth
.SpawnBullet_SetNorth:
  LDX $0200 ; player Y pos
  CPX #$08
  BCC .SpawnBullet_Return
  TXA
  LDX spriteAddr
  SEC
  SBC #$08
  STA $0200, X
  CPY #$00
  BEQ .SpawnBullet_SetXPlayerPos
  CPY #$01
  BEQ .SpawnBullet_SetEast
  JMP .SpawnBullet_SetWest
.SpawnBullet_SetSouth:
  LDX $0200 ; player Y pos
  CPX #$F7
  BCS .SpawnBullet_Return
  TXA
  LDX spriteAddr
  CLC
  ADC #$10
  STA $0200, X
  CPY #$03
  BEQ .SpawnBullet_SetXPlayerPos
  CPY #$04
  BEQ .SpawnBullet_SetEast
  JMP .SpawnBullet_SetWest
.SpawnBullet_SetYPlayerPos:
  LDX spriteAddr
  LDA $0200 ; player Y pos
  STA $0200, X
  CPY #$06
  BEQ .SpawnBullet_SetEast
  JMP .SpawnBullet_SetWest
.SpawnBullet_SetEast:
  LDX $0203 ; player X pos
  CPX #$EA
  BCS .SpawnBullet_Return
  TXA
  LDX spriteAddr
  CLC
  ADC #$16
  STA $0203, X
  JMP .SpawnBullet_PosComplete
.SpawnBullet_SetWest:
  LDX $0203 ; player X pos
  CPX #$08
  BCC .SpawnBullet_Return
  TXA
  LDX spriteAddr
  SEC
  SBC #$08
  STA $0203, X
  JMP .SpawnBullet_PosComplete
.SpawnBullet_SetXPlayerPos:
  LDX spriteAddr
  LDA $0203 ; player X pos
  STA $0203, X
.SpawnBullet_PosComplete
  LDA #$42  ; bullet sprite
  STA $0201, X
  LDA #$00
  STA $0202, X
.SpawnBullet_Return
  RTS

;; UpdateBullets
;; ;; Moves all bullets on screen
UpdateBullets:
  LDX #$0
.UpdateBullets_Loop:
  STX index
  LDA bulletArray, X
  BEQ .UpdateBullets_Inc
  JSR MoveBullet
.UpdateBullets_Inc:
  LDX index
  INX
  INX
  CPX #$20
  BEQ .UpdateBullets_Complete
  JMP .UpdateBullets_Loop
.UpdateBullets_Complete
  RTS

;; MoveBullet
;; ;; Moves bullet one tick forward in given direction
;; ;; Bullet Object: 2 Bytes.
;; ;; ;; Bullet Sprite Address
;; ;; ;; Bullet Direction
;; ;; Parameters:
;; ;; ;; index - starting array index of bullet.
MoveBullet:
  LDX #$02
  STX speed
  LDX index
  LDA bulletArray, X ; Sprite Address
  STA spriteAddr
  INX
  LDA bulletArray, X ; Direction
  STA direction
  TAY
  CPY #$07
  BNE .MoveBullet_Check1 ; W
  JMP .MoveBullet_West
.MoveBullet_Check1:
  CPY #$06
  BNE .MoveBullet_Check2 ; E
  JMP .MoveBullet_East
.MoveBullet_Check2:
  CPY #$03
  BCS .MoveBullet_Check3
  JMP .MoveBullet_North ; N, NE, NW
.MoveBullet_Check3:
  JMP .MoveBullet_South ; S, SE, SW
.MoveBullet_North:
  LDX spriteAddr
  LDA $0200, X
  STA temp
  SEC
  SBC speed
  CMP temp
  BCC .MoveBullet_North2 ; Less than previous value. Bullet not looped.
  JMP .MoveBullet_Delete
.MoveBullet_North2:
  LDX #$00
  STX spriteDataPos
  STA value
  JSR UpdateSprite
  LDY direction
  BEQ .MoveBullet_Complete
  CPY #$01
  BEQ .MoveBullet_East
  JMP .MoveBullet_West
.MoveBullet_South:
  LDX spriteAddr
  LDA $0200, X
  STA temp
  CLC
  ADC speed
  CMP temp
  BCS .MoveBullet_South2 ; More than previous value. Bullet not looped.
  JMP .MoveBullet_Delete
.MoveBullet_South2:
  LDX #$00
  STX spriteDataPos
  STA value
  JSR UpdateSprite
  LDY direction
  CPY #$03
  BEQ .MoveBullet_Complete
  CPY #$04
  BEQ .MoveBullet_East
  JMP .MoveBullet_West
.MoveBullet_East:
  LDX spriteAddr
  LDA $0203, X
  STA temp
  CLC
  ADC speed
  CMP temp
  BCS .MoveBullet_East2 ; More than previous value. Bullet not looped.
  JMP .MoveBullet_Delete
.MoveBullet_East2:
  LDX #$03
  STX spriteDataPos
  STA value
  JSR UpdateSprite
  JMP .MoveBullet_Complete
.MoveBullet_West:
  LDX spriteAddr
  LDA $0203, X
  STA temp
  SEC
  SBC speed
  CMP temp
  BCC .MoveBullet_West2 ; Less than previous value. Bullet not looped.
  JMP .MoveBullet_Delete
.MoveBullet_West2:
  LDX #$03
  STX spriteDataPos
  STA value
  JSR UpdateSprite
.MoveBullet_Complete:
  RTS
.MoveBullet_Delete:
  JSR DeleteAndShiftBullets
  LDX index
  CMP #$18
  BEQ .MoveBullet_Complete
  DEX
  DEX
  STX index ; In case objects are shifted, check the previous index again
  RTS

;; DeleteAndShiftBullets
;; ;; Deletes bullet in array and shifts everything to the right left (FIFO)
;; ;; Parameters:
;; ;; ;; index - starting index of the bullet to be removed
DeleteAndShiftBullets:
  ;Delete sprite info
  LDA #$00
  LDX index
  LDY bulletArray, X
  STA $0200, Y
  STA $0201, Y
  STA $0203, Y
  LDA #$FE
  STA $0202, Y ; #$FE is being used as a unique identifier in attributes to indicate sprite is not written to

  ;Clear object
  LDA #$00
  STA bulletArray, X
  INX
  STA bulletArray, X

  ;If index of #$18, no shift needed (end of array)
  LDX index
  CMP #$18
  BEQ .DeleteAndShiftBullets_Complete
.DeleteAndShiftBullets_ShiftRemaining
  ;Shift all remaining bullets
  LDY index
  TYA
  TAX
  INX
  INX
.DeleteAndShiftBullets_ShiftLoop
  LDA bulletArray, X
  BEQ .DeleteAndShiftBullets_Complete
  STA bulletArray, Y
  LDA #$00
  STA bulletArray, X
  INX
  INY
  LDA bulletArray, X
  STA bulletArray, Y
  LDA #$00
  STA bulletArray, X
  INX
  INY
  CPX #$20
  BEQ .DeleteAndShiftBullets_Complete
  JMP .DeleteAndShiftBullets_ShiftLoop
.DeleteAndShiftBullets_Complete
  RTS