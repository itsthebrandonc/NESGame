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

  ;Inits playerGrid at 0
  LDX #$00
  STX playerGrid

  RTS

;; SetCharacterGridMove_Left
;; ;; Flags character to move to leftward gridpoint
SetCharacterGridMove_Left:
  LDX playerGridMoving
  BEQ .SetCharacterGridMove_LeftSetDir
  LDX playerDirection
  CPX #$07
  BEQ .SetCharacterGridMove_LeftComplete ; If West, no change needed
  CPX #$06
  BNE .SetCharacterGridMove_LeftComplete ; If N/S, cannot change to left
.SetCharacterGridMove_LeftSetDir:
  LDY #$00
  CPY playerGrid
  BEQ .SetCharacterGridMove_LeftComplete ; If leftmost gridpoint, cannot move left
.SetCharacterGridMove_LeftCheckLoop:
  TYA
  CLC
  ADC #$04
  TAY
  CPY playerGrid
  BEQ .SetCharacterGridMove_LeftComplete ; If leftmost gridpoint, cannot move left
  BCC .SetCharacterGridMove_LeftCheckLoop ; Loop until Y is greater than playerGrid
.SetCharacterGridMove_LeftSetContinue:
  DEC playerGrid
  LDX #07
  STX playerDirection
  LDX #$01
  STX playerGridMoving
.SetCharacterGridMove_LeftComplete
  RTS

;; SetCharacterGridMove_Right
;; ;; Flags character to move to rightward gridpoint
SetCharacterGridMove_Right:
  LDX playerGridMoving
  BEQ .SetCharacterGridMove_RightSetDir
  LDX playerDirection
  CPX #$06
  BEQ .SetCharacterGridMove_RightComplete ; If East, no change needed
  CPX #$07
  BNE .SetCharacterGridMove_RightComplete ; If N/S, cannot change to right
.SetCharacterGridMove_RightSetDir:
  LDY #$03
  CPY playerGrid
  BEQ .SetCharacterGridMove_RightComplete ; If rightmost gridpoint, cannot move right
.SetCharacterGridMove_RightCheckLoop:
  TYA
  CLC
  ADC #$04
  TAY
  CPY playerGrid
  BEQ .SetCharacterGridMove_RightComplete ; If rightmost gridpoint, cannot move right
  BCC .SetCharacterGridMove_RightCheckLoop ; Loop until Y is greater than playerGrid
.SetCharacterGridMove_RightSetContinue:
  INC playerGrid
  LDX #06
  STX playerDirection
  LDX #$01
  STX playerGridMoving
.SetCharacterGridMove_RightComplete
  RTS

;; SetCharacterGridMove_Up
;; ;; Flags character to move to upward gridpoint
SetCharacterGridMove_Up:
  LDX playerGridMoving
  BEQ .SetCharacterGridMove_UpSetDir
  LDX playerDirection
  CPX #$00
  BEQ .SetCharacterGridMove_UpComplete ; If North, no change needed
  CPX #$03
  BNE .SetCharacterGridMove_UpComplete ; If E/W cannot change to up
.SetCharacterGridMove_UpSetDir:
  LDY playerGrid
  CPY #$04
  BCC .SetCharacterGridMove_UpComplete ; If top row, cannot move up
  TYA
  SEC
  SBC #$04
  STA playerGrid
  LDX #00
  STX playerDirection
  LDX #$01
  STX playerGridMoving
.SetCharacterGridMove_UpComplete
  RTS

;; SetCharacterGridMove_Dowm
;; ;; Flags character to move to downward gridpoint
SetCharacterGridMove_Down:
  LDX playerGridMoving
  BEQ .SetCharacterGridMove_DownSetDir
  LDX playerDirection
  CPX #$03
  BEQ .SetCharacterGridMove_DownComplete ; If South, no change needed
  CPX #$00
  BNE .SetCharacterGridMove_DownComplete ; If E/W cannot change to down
.SetCharacterGridMove_DownSetDir:
  LDY playerGrid
  CPY #$0C
  BCS .SetCharacterGridMove_DownComplete ; If bottom row, cannot move down
  TYA
  CLC
  ADC #$04
  STA playerGrid
  LDX #03
  STX playerDirection
  LDX #$01
  STX playerGridMoving
.SetCharacterGridMove_DownComplete
  RTS

;; MoveCharacterOnGrid
;; ;; Moves character along grid in set playerDirection until it reaches playerGrid
MoveCharacterOnGrid:
  LDA playerGridMoving
  BNE .MoveCharacterOnGrid_Continue
  RTS
.MoveCharacterOnGrid_Continue:
  ; Store current player position in spriteData
  LDA $0203
  LDX #$03
  STA spriteData, X ; character top left X Pos
  LDA $0200
  STA spriteData ; character lop left Y Pos
  
  ; Store destination gridpoint position in spriteData2
  LDA playerGrid
  ASL A ; X,Y position of gridpoint is 2x the gridpoint number
  TAX
  LDA gridpoints, X 
  LDY #$03
  STA spriteData2, Y ; gridpoint X Pos
  INX
  LDA gridpoints, X
  STA spriteData2 ; gridpoint Y pos

  LDX playerDirection
  CPX #$00
  BEQ .MoveCharacterOnGrid_Up
  CPX #$03
  BEQ .MoveCharacterOnGrid_Down
  CPX #$06
  BEQ .MoveCharacterOnGrid_Right
  CPX #$07
  BEQ .MoveCharacterOnGrid_Left
  RTS
.MoveCharacterOnGrid_Up:
  LDA spriteData
  CMP spriteData2
  BEQ .MoveCharacterOnGrid_YReached
  BCC .MoveCharacterOnGrid_YSnap
.MoveCharcterOnGrid_UpInc:
  DEC $0200 ; top left Y Pos
  DEC $0204 ; top right Y Pos
  DEC $0208 ; bottom left Y Pos
  DEC $020C ; bottom right Y Pos
  JMP .MoveCharacterOnGrid_YComplete
.MoveCharacterOnGrid_Down:
  LDA spriteData
  CMP spriteData2
  BEQ .MoveCharacterOnGrid_YReached
  BCS .MoveCharacterOnGrid_YSnap
.MoveCharcterOnGrid_DownInc:
  INC $0200 ; top left Y Pos
  INC $0204 ; top right Y Pos
  INC $0208 ; bottom left Y Pos
  INC $020C ; bottom right Y Pos
  JMP .MoveCharacterOnGrid_YComplete
.MoveCharacterOnGrid_YSnap:
  LDA spriteData2
  STA $0200 ; top left Y Pos
  STA $0204 ; top right Y Pos
  CLC
  ADC #$08 ; shift down tiles
  STA $0207 ; bottom left Y Pos
  STA $020F ; bottom right Y Pos
.MoveCharacterOnGrid_YReached:
  LDA #$00
  STA playerGridMoving
.MoveCharacterOnGrid_YComplete:
  RTS
.MoveCharacterOnGrid_Left:
  LDX #$03
  LDY spriteData2, X
  STY temp
  LDY spriteData, X
  CPY temp
  BEQ .MoveCharacterOnGrid_XReached
  BCC .MoveCharacterOnGrid_XSnap
.MoveCharacterOnGrid_LeftInc:
  DEC $0203 ; top left X Pos
  DEC $0207 ; top right X Pos
  DEC $020B ; bottom left X Pos
  DEC $020F ; bottom right X Pos
  JMP .MoveCharacterOnGrid_XComplete
.MoveCharacterOnGrid_Right:
  LDX #$03
  LDY spriteData2, X
  STY temp
  LDY spriteData, X
  CPY temp
  BEQ .MoveCharacterOnGrid_XReached
  BCS .MoveCharacterOnGrid_XSnap
.MoveCharacterOnGrid_RightInc:
  INC $0203 ; top left X Pos
  INC $0207 ; top right X Pos
  INC $020B ; bottom left X Pos
  INC $020F ; bottom right X Pos
  JMP .MoveCharacterOnGrid_XComplete
.MoveCharacterOnGrid_XSnap:
  LDA temp
  STA $0203 ; top left X Pos
  STA $020B ; bottom left X Pos
  CLC
  ADC #$08 ; shift right tiles
  STA $0207 ; top right X Pos
  STA $020F ; bottom right X Pos
.MoveCharacterOnGrid_XReached:
  LDA #$00
  STA playerGridMoving
.MoveCharacterOnGrid_XComplete:
  RTS

;; MoveCharacterLeft_Free
;; ;; Moves all character sprites left freely
MoveCharacterLeft_Free:
  ; Sprite 0 (top left) = $0200-$0203, Sprite 1 (top right) = $0204-0207, Sprite 2 (bottom left) = $0208-$020B, Sprite 3 (bottom right) = $020C-$020F
  LDA $0203 ; top left X Pos
  BEQ .MoveCharacterLeftComplete ; if 0, cannot move left
  DEC $0203 ; top left X Pos
  DEC $0207 ; top right X Pos
  DEC $020B ; bottom left X Pos
  DEC $020F ; bottom right X Pos
.MoveCharacterLeftComplete
  RTS

;; MoveCharacterRight_Free
;; ;; Moves all character sprites right freely
MoveCharacterRight_Free:
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

;; MoveCharacterUp_Free
;; ;; Moves all character sprites up freely
MoveCharacterUp_Free:
  ; Sprite 0 (top left) = $0200-$0203, Sprite 1 (top right) = $0204-0207, Sprite 2 (bottom left) = $0208-$020B, Sprite 3 (bottom right) = $020C-$020F
  LDA $0200 ; top left Y Pos
  BEQ .MoveCharacterUpComplete ; if $00, cannot move up
  DEC $0200 ; top left Y Pos
  DEC $0204 ; top right Y Pos
  DEC $0208 ; bottom left Y Pos
  DEC $020C ; bottom right Y Pos
.MoveCharacterUpComplete
  RTS

;; MoveCharacterDown_Free
;; ;; Moves all character sprites down freely
MoveCharacterDown_Free:
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