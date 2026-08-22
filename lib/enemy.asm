;; SpawnEnemy
;; ;; Loads enemy sprite
;; ;; Parameters:
;; ;; ;; spriteData - 4 bytes: Y Pos (top left), Tile Number (top left), Attributes, X Pos (top left)
SpawnEnemy:
  ; Sprites 4-23 reserved for enemies
  ; Sprite 4 (top left) = $0210-$0213, Sprite 5 (top right) = $0214-0217, Sprite 6 (bottom left) = $0218-$021B, Sprite 7 (bottom right) = $021C-$021F

  ; Find available spot in enemy array
  LDX #$00
  STX spriteAddr
.SpawnEnemy_GetNewIndexLoop:
  LDA enemyArray, X
  BEQ .SpawnEnemy_GetNewIndexEnd
  INX
  INX
  CPX #ENEMYARRAY_SIZE
  BEQ .SpawnEnemy_ArrayFull
  JMP .SpawnEnemy_GetNewIndexLoop
.SpawnEnemy_ArrayFull:
  RTS ; Do not spawn more enemies if there are max amount of screen
.SpawnEnemy_GetNewIndexEnd: ; X now contains the available spot in the enemy array
  STX index
  LDA #$04
  STA pointerLo
  LDA #$17
  STA pointerHi
  JSR GetNewSpriteAddress
.SpawnEnemy_SetEnemy
  LDX index
  LDA spriteAddr
  STA enemyArray, X ; Sprite Address stored in Enemy object's first byte

  ;Y Pos
  LDX spriteAddr
  LDA spriteData
  STA $0200, X ; top left
  STA $0204, X ; top right
  CLC
  ADC #$08    ; shift bottom sprites down
  STA $0208, X ; bottom left
  STA $020C, X ; bottom right

  ;Tile Number
  LDY #$01
  LDA spriteData, Y
  LDA #$43
  STA $0201, X ; top left
  TAY
  INY
  TYA
  STA $0205, X ; top right
  CLC
  ADC #$0F      ; next tiles are on the next row
  STA $0209, X
  TAY
  INY
  TYA
  STA $020D, X

  ;Attributes
  LDY #$02
  LDA spriteData, Y
  STA $0202, X ; top left
  STA $0206, X ; top right
  STA $020A, X ; bottom left
  STA $020E, X ; bottom right

  ;X Pos
  INY
  LDA spriteData, Y
  STA $0203, X ; top left
  STA $020B, X ; bottom left
  CLC
  ADC #$08 ; shift right tiles
  STA $0207, X ; top right
  STA $020F, X ; bottom right

  RTS

;; UpdateEnemies
;; ;; Move all enemies on screen and then check collision with player
UpdateEnemies:
  LDX #$0
.UpdateEnemies_MoveLoop:
  LDA enemyArray, X
  ;BEQ .UpdateEnemies_MoveInc ;If enemies shift properly, shouldn't be needed
  BEQ .UpdateEnemies_MoveComplete
  STX index
  JSR MoveEnemy
.UpdateEnemies_MoveInc:
  LDX index
  INX
  INX
  CPX #ENEMYARRAY_SIZE
  BEQ .UpdateEnemies_MoveComplete
  JMP .UpdateEnemies_MoveLoop
.UpdateEnemies_MoveComplete:
  LDX #$0
.UpdateEnemies_CollisionLoop
  LDA enemyArray, X
  ;BEQ .UpdateEnemies_CollsionInc ;If enemies shift properly, shouldn't be needed
  BEQ .UpdateEnemies_Complete
  STX index
  JSR CheckEnemyCollision
.UpdateEnemies_CollsionInc:
  LDX index
  INX
  INX
  CPX #ENEMYARRAY_SIZE
  BEQ .UpdateEnemies_Complete
  JMP .UpdateEnemies_CollisionLoop
.UpdateEnemies_Complete:
  RTS

;; MoveEnemy
;; ;; Moves enemy one tick forward in given direction
;; ;; Enemy Object: 2 Bytes.
;; ;; ;; Enemy Sprite Address
;; ;; ;; 3 unused bits, Enemy Direction (3 bits, 0-8), Enemy Fire Cooldown (2 bits, 0-4)
;; ;; Parameters:
;; ;; ;; index - starting array index of enemy.
MoveEnemy:
  LDX #$02
  STX speed
  LDX index
  LDA enemyArray, X ; Sprite Address
  STA spriteAddr
  INX
  LDA enemyArray, X ; Direction
  CMP #%00011100
  LSR A
  LSR A
  STA direction
  TAY
  CPY #$07
  BNE .MoveEnemy_Check1
  JMP .MoveEnemy_West ; W
.MoveEnemy_Check1:
  CPY #$06
  BNE .MoveEnemy_Check2
  JMP .MoveEnemy_East ; E
.MoveEnemy_Check2:
  CPY #$03
  BCS .MoveEnemy_Check3
  JMP .MoveEnemy_North ; N, NE, NW
.MoveEnemy_Check3:
  JMP .MoveEnemy_South ; S, SE, SW
.MoveEnemy_North:
  LDX spriteAddr
  LDA $0200, X
  STA temp
  SEC
  SBC speed
  CMP temp
  BCC .MoveEnemy_North2 ; Less than previous value. Enemy not looped.
  ;JMP .MoveEnemy_Delete
.MoveEnemy_North2:
  STA $0200, X ; top left
  STA $0204, X ; top right
  CLC
  ADC #$08    ; shift bottom sprites down
  STA $0208, X ; bottom left
  STA $020C, X ; bottom right

  LDY direction
  BEQ .MoveEnemy_CompleteEarly
  CPY #$01
  BEQ .MoveEnemy_East
  JMP .MoveEnemy_West
.MoveEnemy_South:
  LDX spriteAddr
  LDA $0200, X
  STA temp
  CLC
  ADC speed
  CMP temp
  BCS .MoveEnemy_South2 ; More than previous value. Enemy not looped.
  ;JMP .MoveEnemy_Delete
.MoveEnemy_South2:
  STA $0200, X ; top left
  STA $0204, X ; top right
  CLC
  ADC #$08    ; shift bottom sprites down
  STA $0208, X ; bottom left
  STA $020C, X ; bottom right

  LDY direction
  CPY #$03
  BEQ .MoveEnemy_CompleteEarly
  CPY #$04
  BEQ .MoveEnemy_East
  JMP .MoveEnemy_West
.MoveEnemy_CompleteEarly:
  JMP .MoveEnemy_Complete
.MoveEnemy_East;
  LDX spriteAddr
  LDA $0203, X
  STA temp
  CLC
  ADC speed
  CMP temp
  BCS .MoveEnemy_East2 ; More than previous value. Enemy not looped.
  ;JMP .MoveEnemy_Delete
.MoveEnemy_East2:
  STA $0203, X ; top left
  STA $020B, X ; bottom left
  CLC
  ADC #$08 ; shift right tiles
  STA $0207, X ; top right
  STA $020F, X ; bottom right

  JMP .MoveEnemy_Complete
.MoveEnemy_West:
  LDX spriteAddr
  LDA $0203, X
  STA temp
  SEC
  SBC speed
  CMP temp
  BCC .MoveEnemy_West2 ; Less than previous value. Enemy not looped.
  ;JMP .MoveEnemy_Delete
.MoveEnemy_West2:
  STA $0203, X ; top left
  STA $020B, X ; bottom left
  CLC
  ADC #$08 ; shift right tiles
  STA $0207, X ; top right
  STA $020F, X ; bottom right
.MoveEnemy_Complete
  RTS
;.MoveEnemy_Delete
;  JSR DeleteAndShiftEnemies
;  LDX index
;  INX
;  INX
;  CPX #ENEMYARRAY_SIZE 
;  BEQ .MoveEnemy_Complete
;  DEX
;  DEX
;  DEX
;  DEX
;  STX index ; In case objects are shifted, check the prevoius index again
;  RTS

;; CheckEnemyCollision
;; ;; Checks for enemy collision with player
;; ;; Enemy Object : 2 Bytes.
;; ;; ;; Enemy Sprite Address
;; ;; ;; 3 unused bits, Enemy Direction (3 bits, 0-8), Enemy Fire Cooldown (2 bits, 0-4)
;; ;; Parameters:
;; ;; ;; index - starting array index of enemy.
CheckEnemyCollision:
  RTS ; TODO - To implement


;; DeleteAndShiftEnemies
;; ;; Deletes enemy in array and shifts everything to the right left (FIFO)
;; ;; Parameters:
;; ;; ;; index - starting index of the enemy to be removed
DeleteAndShiftEnemies:
  ;Delete sprite info
  LDA #$00
  LDX index
  LDY enemyArray, X

  ;Sprite 1
  STA $0200, Y
  STA $0201, Y
  STA $0203, Y
  ;Sprite 2
  STA $0204, Y
  STA $0205, Y
  STA $0207, Y
  ;Sprite 3
  STA $0208, Y
  STA $0209, Y
  STA $020B, Y
  ;Sprite 4
  STA $020C, Y
  STA $020D, Y
  STA $020F, Y

  LDA #$FE      ; #$FE is being used as a unique identifier in attributes to indicate sprite is not written to
  STA $0202, Y  ; Sprite 1
  STA $0206, Y  ; Sprite 2
  STA $020A, Y  ; Sprite 3
  STA $020E, Y  ; Sprite 4

  ;Clear object
  LDA #$00
  STA enemyArray, X
  INX
  STA enemyArray, X

.DeleteAndShiftEnemies_ShiftRemaining
  ;Shift all remaining enemies
  LDY index
  TYA
  TAX
  INX
  INX
  CPX #ENEMYARRAY_SIZE
  BEQ .DeleteAndShiftEnemies_Complete
.DeleteAndShiftEnemies_ShiftLoop
  LDA enemyArray, X
  BEQ .DeleteAndShiftEnemies_Complete
  STA enemyArray, Y
  LDA #$00
  STA enemyArray, X
  INX
  INY
  LDA enemyArray, X
  STA enemyArray, Y
  LDA #$00
  STA enemyArray, X
  INX
  INY
  CPX #ENEMYARRAY_SIZE
  BEQ .DeleteAndShiftEnemies_Complete
  JMP .DeleteAndShiftEnemies_ShiftLoop
.DeleteAndShiftEnemies_Complete
  RTS