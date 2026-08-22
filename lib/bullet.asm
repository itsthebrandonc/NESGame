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
  CPX #BULLETARRAY_SIZE
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
  LDA #$17
  STA pointerLo
  LDA #$3F
  STA pointerHi
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
;; ;; Moves all bullets on screen and then check collision with enemies
UpdateBullets:
  LDX #$0
.UpdateBullets_MoveLoop:
  STX index
  LDA bulletArray, X
  ;BEQ .UpdateBullets_MoveInc ;If bullets shift properly, shouldn't be needed
  BEQ .UpdateBullets_MoveComplete
  JSR MoveBullet
.UpdateBullets_MoveInc:
  LDX index
  INX
  INX
  CPX #BULLETARRAY_SIZE
  BEQ .UpdateBullets_MoveComplete
  JMP .UpdateBullets_MoveLoop
.UpdateBullets_MoveComplete:
  LDX #$0
.UpdateBullets_CollisionLoop:
  STX index
  LDA bulletArray, X
  ;BEQ .UpdateBullets_CollisionInc ;If bullets shift properly, shouldn't be needed
  BEQ .UpdateBullets_Complete
  JSR CheckBulletCollision
.UpdateBullets_CollisionInc:
  LDX index
  INX
  INX
  CPX #BULLETARRAY_SIZE
  BEQ .UpdateBullets_Complete
  JMP .UpdateBullets_CollisionLoop
.UpdateBullets_Complete:
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
  BNE .MoveBullet_Check1 
  JMP .MoveBullet_West ; W
.MoveBullet_Check1:
  CPY #$06
  BNE .MoveBullet_Check2
  JMP .MoveBullet_East ; E
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
  ;;LDX #$00
  ;;STX spriteDataPos
  ;;STA value
  ;;JSR UpdateSprite
  STA $0200, X
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
  ;;LDX #$00
  ;;STX spriteDataPos
  ;;STA value
  ;;JSR UpdateSprite
  STA $0200, X
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
  ;;LDX #$03
  ;;STX spriteDataPos
  ;;STA value
  ;;JSR UpdateSprite
  STA $0203, X
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
  ;;LDX #$03
  ;;STX spriteDataPos
  ;;STA value
  ;;JSR UpdateSprite
  STA $0203, X
.MoveBullet_Complete:
  RTS
.MoveBullet_Delete:
  JSR DeleteAndShiftBullets
  LDX index
  INX
  INX
  CPX #BULLETARRAY_SIZE
  BEQ .MoveBullet_Complete
  DEX
  DEX
  DEX
  DEX
  STX index ; In case objects are shifted, check the previous index again
  RTS

;; CheckBulletCollision
;; ;; Loops through all enemies for given bullet to check collision
;; ;; Bullet Object: 2 Bytes.
;; ;; ;; Bullet Sprite Address
;; ;; ;; Bullet Direction
;; ;; Parameters:
;; ;; ;; index - starting array index of bullet.
CheckBulletCollision:
  ; Gets Bullet position
  LDY index
  LDX bulletArray, Y
  ;STX spriteAddr
  LDA $0200, X ; Bullet Y Pos
  STA spriteData
  INX
  INX
  INX
  LDY #$03
  LDA $0200, X ; Bullet X Pos
  STA spriteData, Y

  ;TODO: Replace with enemy ID
  LDY #$00
  STY index2
.CheckBulletCollision_EnemyLoop:
  LDY index2
  LDX enemyArray, Y
  BEQ .CheckBulletCollision_Complete ; Enemy sprite reference empty
  LDA $0200, X ; Enemy Y Pos
  STA spriteData2
  INX
  INX
  INX
  LDY #$03
  LDA $0200, X ; Enemy X Pos
  STA spriteData2, Y
  JSR SpriteCollisionCheck
  LDY result
  BEQ .CheckBulletCollision_ContinueLoop
  JSR DeleteAndShiftBullets
  LDY index2
  STY index
  JSR DeleteAndShiftEnemies
  JMP .CheckBulletCollision_Complete
.CheckBulletCollision_ContinueLoop:
  LDY index2
  INY
  INY
  STY index2
  CPY #$14 ;Outside bullet array
  BNE .CheckBulletCollision_EnemyLoop
.CheckBulletCollision_Complete:
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
  CPX #BULLETARRAY_SIZE
  BEQ .DeleteAndShiftBullets_Complete
  JMP .DeleteAndShiftBullets_ShiftLoop
.DeleteAndShiftBullets_Complete
  RTS