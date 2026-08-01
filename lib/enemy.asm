;; SpawnEnemy
;; ;; Loads enemy sprite
;; ;; Parameters:
;; ;; ;; spriteData - 4 bytes: Y Pos (top left), Tile Number (top left), Attributes, X Pos (top left)
SpawnEnemy:
  ; Sprites 4-23 reserved for enemies
  ; Sprite 4 (top left) = $0210-$0213, Sprite 5 (top right) = $0214-0217, Sprite 6 (bottom left) = $0218-$021B, Sprite 7 (bottom right) = $021C-$021F

  ; Find available spot in bullet array
  LDX #$00
  STX spriteAddr
.SpawnEnemy_GetNewIndexLoop:
  LDA enemyArray, X
  BEQ .SpawnEnemy_GetNewIndexEnd
  INX
  INX
  CPX #$0A
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

  ;If index of #$08, no shift needed (end of array)
  LDX index
  CMP #$08
  BEQ .DeleteAndShiftEnemies_Complete
.DeleteAndShiftEnemies_ShiftRemaining
  ;Shift all remaining enemies
  LDY index
  TYA
  TAX
  INX
  INX
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
  CPX #$0A
  BEQ .DeleteAndShiftEnemies_Complete
  JMP .DeleteAndShiftEnemies_ShiftLoop
.DeleteAndShiftEnemies_Complete
  RTS