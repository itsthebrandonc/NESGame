;; SpawnEnemy
;; ;; Loads enemy sprite
;; ;; Parameters:
;; ;; ;; spriteData - 4 bytes: Y Pos (top left), Tile Number (top left), Attributes, X Pos (top left)
SpawnEnemy:
  ; Sprites 4-23 reserved for enemies
  ; Sprite 4 (top left) = $0210-$0213, Sprite 5 (top right) = $0214-0217, Sprite 6 (bottom left) = $0218-$021B, Sprite 7 (bottom right) = $021C-$021F

  ;TODO: Create enemy array and get enemy ID
  LDX #$00 ; Replace with enemy ID
  TXA
  ASL A
  ASL A
  TAX

  ;Y Pos
  LDA spriteData
  STA $0210, X ; top left
  STA $0214, X ; top right
  CLC
  ADC #$08    ; shift bottom sprites down
  STA $0218, X ; bottom left
  STA $021C, X ; bottom right

  ;Tile Number
  LDY #$01
  LDA spriteData, Y
  LDA #$43
  STA $0211, X ; top left
  TAY
  INY
  TYA
  STA $0215, X ; top right
  CLC
  ADC #$0F      ; next tiles are on the next row
  STA $0219, X
  TAY
  INY
  TYA
  STA $021D, X

  ;Attributes
  LDY #$02
  LDA spriteData, Y
  STA $0212, X ; top left
  STA $0216, X ; top right
  STA $021A, X ; bottom left
  STA $021E, X ; bottom right

  ;X Pos
  INY
  LDA spriteData, Y
  STA $0213, X ; top left
  STA $021B, X ; bottom left
  CLC
  ADC #$08 ; shift right tiles
  STA $0217, X ; top right
  STA $021F, X ; bottom right

  RTS

;; DeleteEnemy
;; ;; Clears enemy sprite
DeleteEnemy:
  ; Sprites 4-23 reserved for enemies
  ; Sprite 4 (top left) = $0210-$0213, Sprite 5 (top right) = $0214-0217, Sprite 6 (bottom left) = $0218-$021B, Sprite 7 (bottom right) = $021C-$021F

  ;TODO: Create enemy array and get enemy ID
  LDX #$00 ; Replace with enemy ID
  TXA
  ASL A
  ASL A
  TAX

  ;Delete sprite info
  LDY #$04
.DeleteEnemy_Loop:
  LDA #$00
  STA $0210, X
  STA $0211, X
  STA $0213, X
  LDA #$FE
  STA $0212, X ; #$FE is being used as a unique identifier in attributes to indicate sprite is not written to
  INX
  INX
  INX
  INX
  DEY
  CPY #$00
  BEQ .DeleteEnemy_Complete
  JMP .DeleteEnemy_Loop
.DeleteEnemy_Complete:
  RTS