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