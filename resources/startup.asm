
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, X
  STA $0100, X
  STA $0300, X
  STA $0400, X
  STA $0500, X
  STA $0600, X
  STA $0700, X
  LDA #$FE
  STA $0200, X
  INX
  BNE clrmem
  
vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2

LoadPalettes:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006             ; write the high byte of $3F00 address
  LDA #$00
  STA $2006             ; write the low byte of $3F00 address
  LDX #$00              ; start out at 0
.LoadPalettesLoop:
  LDA palette, x        ; load data from address (palette + x)
  STA $2007             ; write to PPU
  INX                   
  CPX #$20              ; copying 32 bytes = 2 palettes
  BNE .LoadPalettesLoop 

;LoadSprites:
;  LDX #$00              ; start at 0
;.LoadSpritesLoop:
;  LDA sprites, x        ; load data from address (sprites +  x)
;  STA $0200, x          ; Sprite registers start at $0200
;  INX                   
;  CPX #$20              ; 32 total bytes for the 8 sprites
;  BNE .LoadSpritesLoop  
                
;LoadBackground:
;    LDA $2002             ; read PPU status to reset the high/low latch
;    LDA #$20
;    STA $2006             ; write the high byte of $2000 address
;    LDA #$00
;    STA $2006             ; write the low byte of $2000 address
  
;    LDA #LOW(background)
;    STA pointerLo       ; put the low byte of the address of background into pointer
;    LDA #HIGH(background)
;    STA pointerHi       ; put the high byte of the address into pointer
    
;    LDX #$00           
;    LDY #$00            ; inside loop counter
;    OutsideLoop:
;      InsideLoop:
;        LDA [pointerLo], y  ; copy one background byte from address in pointer (Lo->Hi) + Y
;        STA $2007           ; this runs 256 * 4 times
;        
;        INY                 
;        CPY #$00
;        BNE InsideLoop      ; run inside loop 256 until variable ticks back over to 00
;        
;        INC pointerHi       ; increate high byte after all low bytes are iterated through
;        
;        INX
;        CPX #$04
;        BNE OutsideLoop     ; run outside loop 4 times

LoadBackground:
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006             ; write the high byte of $2000 address
  LDA #$00
  STA $2006             ; write the low byte of $2000 address

  LDA #LOW(background)
  STA pointerLo       ; put the low byte of the address of background into pointer
  LDA #HIGH(background)
  STA pointerHi       ; put the high byte of the address into pointer

  LDX #$00           
  LDY #$00            ; inside loop counter
.BackgroundLoop:
  LDA [pointerLo], y  ; copy one background byte from address in pointer (Lo->Hi) + Y
  STA pointerLo2
  INY
  LDA [pointerLo], y
  STA pointerHi2

  ;Pointer1 (Background) stores two-byte address for reusasble tile data, now in Pointer2 (Tile_Question)
  ;LDA [pointerLo2], $00 ; copy reusable tile data
  STY temp
  LDY #$00
.RowLoop:
  LDA [pointerLo2], y ; copy reusable tile data
  STA $2007           ; this runs 32 * 30 times
  INY
  CPY #$20            ; resuable tile data contains 32 tile values
  BNE .RowLoop
  
  LDY temp
  INY                 
  CPY #$00
  BEQ .IncBackgroundLoop      ; run inside loop 256 until variable ticks back over to 00

  INX
  CPX #$1E
  BCC .BackgroundLoop        ; run outside loop 30 times (for 30 rows)
  
.IncBackgroundLoop:
  INC pointerHi       ; increate high byte after all low bytes are iterated through, goes back through loop again if more are left in the next hi byte

  INX
  CPX #$1E
  BCC .BackgroundLoop     ; run outside loop 30 times (for 30 rows)
  

  ;; Configuring the PPU Registers
  ;; Bits 0 - 1 : Background nametable select
  ;; Bit 2 : Increment Mode for scrolling (0 = across, 1 = down)
  ;; Bit 3 : Sprite pattern table select
  ;; Bit 4 : Background pattern table select
  ;; Bit 5 : Sprite size (0 = 8x8, 1 = 8x16)
  ;; Bit 6 : PPU Master/Slave (rarely used)
  ;; Bit 7 : Enable NMI (Non-Maskable Interrupt) at the start of VBLANK (0 = disabled, 1 = enabled)
  ;LDA #%10010000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  LDA #%10000000
  STA $2000
  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA $2001

  JSR OnInit

Forever:
  JMP Forever     ; loop forever, prevents unexpected end of program?
  


NMI:
  LDA #$00
  STA $2003       ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014       ; set the high byte (02) of the RAM address, start the transfer

LatchController:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016       ; tell both the controllers to latch buttons

ReadController1:
  LDA #$01
  STA $4016
  LDA #$00
  STA $4016
  LDY buttons1        ; Y = previous button inputs
  STY prevButtons1
  LDX #$08            ; Eight inputs: A, B, Select, Start, Up, Down, Left, Right
ReadController1Loop:  ; player input is read one at a time from first bit of $4016
  LDA $4016           ; Only right-most bit tells if button is pressed or not
  LSR A               ; Shifts bits right, pushing value of button press into carry
  ROL buttons1        ; Rotates carry into the right side of variable
  DEX
  BNE ReadController1Loop ; By end, buttons1 has value of all current button presses in order
  LDX buttons1        ; X = current button inputs

ReadDirection:
  ; N ($00)
  ; NE ($01)
  ; NW ($02)
  ; S ($03)
  ; SE ($04)
  ; SW ($05)
  ; E ($06)
  ; W ($07)
  
  TXA
  AND #%00001111 ; Get only directional inputs
  BEQ ReadA       ; No direction, keep previous value
  LDX #$00
  TAY
  AND #%00001000 ; North (N, NE, NW)
  BNE .ReadDirection_EW
  LDX #$03
  TYA
  AND #%00000100 ; South (S, SE, SW)
  BNE .ReadDirection_EW
  LDX #$05
.ReadDirection_EW
  TYA
  AND #%00000011 ; Get only L/R inputs
  BEQ .ReadDirection_Done
  INX
  TYA
  AND #%00000010 ; East (E, NE, SE)
  BNE .ReadDirection_Done
  INX
.ReadDirection_Done
  STX playerDirection


ReadA:
  LDA buttons1
  AND #%10000000  ; A
  BNE .ADown
.AUp:
  LDA buttons1Held
  AND #%01111111  ; Turn off A
  STA buttons1Held
  JMP ReadB
.ADown:
  TYA
  AND #%10000000  ; A
  BEQ .APress
  LDA buttons1Held
  ORA #%10000000   ; A
  STA buttons1Held
.APress:
  JSR OnInputA

ReadB:
  LDA buttons1
  AND #%01000000  ; B
  BNE .BDown
.BUp:
  LDA buttons1Held
  AND #%10111111  ; Turn off B
  STA buttons1Held
  JMP ReadSl
.BDown:
  LDA prevButtons1
  AND #%01000000  ; B
  BEQ .BPress
  LDA buttons1Held
  ORA #%01000000   ; B
  STA buttons1Held
.BPress:
  JSR OnInputB
ReadSl:
  LDA buttons1
  AND #%00100000  ; Select
  BNE .SlDown
.SlUp:
  LDA buttons1Held
  AND #%11011111  ; Turn off Select
  STA buttons1Held
  JMP ReadSt
.SlDown:
  LDA prevButtons1
  AND #%00100000  ; Select
  BEQ .SlPress
  LDA buttons1Held
  ORA #%00100000   ; Select
  STA buttons1Held
.SlPress:
  JSR OnInputSl
ReadSt:
  LDA buttons1
  AND #%00010000  ; Start
  BNE .StDown
.SlUp:
  LDA buttons1Held
  AND #%11101111  ; Turn off Start
  STA buttons1Held
  JMP ReadU
.StDown:
  LDA prevButtons1
  AND #%00010000  ; Start
  BEQ .StPress
  LDA buttons1Held
  ORA #%00010000   ; Start
  STA buttons1Held
.StPress:
  JSR OnInputSt
ReadU:
  LDA buttons1
  AND #%00001000  ; Up
  BNE .UDown
.UUp:
  LDA buttons1Held
  AND #%11110111  ; Turn off Up
  STA buttons1Held
  JMP ReadD
.UDown:
  LDA prevButtons1
  AND #%00001000  ; Up
  BEQ .UPress
  LDA buttons1Held
  ORA #%00001000   ; Up
  STA buttons1Held
.UPress:
  JSR OnInputU
ReadD:
  LDA buttons1
  AND #%00000100  ; Down
  BNE .DDown
.DUp:
  LDA buttons1Held
  AND #%11111011  ; Turn off Down
  STA buttons1Held
  JMP ReadL
.DDown:
  LDA prevButtons1
  AND #%00000100  ; Down
  BEQ .DPress
  LDA buttons1Held
  ORA #%00000100   ; Down
  STA buttons1Held
.DPress:
  JSR OnInputD
ReadL:
  LDA buttons1
  AND #%00000010  ; Left
  BNE .LDown
.LUp:
  LDA buttons1Held
  AND #%11111101  ; Turn off Left
  STA buttons1Held
  JMP ReadR
.LDown:
  LDA prevButtons1
  AND #%00000010  ; Left
  BEQ .LPress
  LDA buttons1Held
  ORA #%00000010   ; Left
  STA buttons1Held
.LPress:
  JSR OnInputL
ReadR:
  LDA buttons1
  AND #%00000001  ; Right
  BNE .RDown
.RUp:
  LDA buttons1Held
  AND #%11111110  ; Turn off Right
  STA buttons1Held
  JMP ReadDone
.RDown:
  LDA prevButtons1
  AND #%00000001  ; Right
  BEQ .RPress
  LDA buttons1Held
  ORA #%00000001   ; Right
  STA buttons1Held
.RPress:
  JSR OnInputR
ReadDone:

  JSR OnTick

  ;;This is the PPU clean up section, so rendering the next frame starts properly.
  LDA #%10000000   ; enable NMI, sprites from Pattern Table 0, background from Pattern Table 1
  STA $2000
  LDA #%00011110   ; enable sprites, enable background, no clipping on left side
  STA $2001
  LDA #$00        ;;tell the ppu there is no background scrolling
  STA $2005
  STA $2005

  RTI             ; return from interrupt

;; Additional Functions

;; DrawText
;; ;; Draws text from a variable to the background (all at once)
;; ;; Parameters:
;; ;; ;; pointerHi - high byte of text variable pointer (Example: #HIGH(textRow_HelloWorld))
;; ;; ;; pointerLo - low byte of text variable pointer (Example: #LOW(textRow_HelloWorld))
;; ;; ;; startHi   - high byte of the starting background tile (Example: #$20)
;; ;; ;; startLo   - low byte of the starting background type (Excample: #$00)
DrawText:
  ; 32 tiles per row, 30 rows
  ; $2000 = first row
  ; $2020 = second row
  ; $21E0 = middle of screen

  LDA $2002             ; read PPU status to reset the high/low latch
  LDA startHi
  STA $2006             ; write the high byte of $2000 address
  LDA startLo
  STA $2006             ; write the low byte of $2000 address

  ;LDA #HIGH(textRow_TestingMaximumStringLength)
  ;STA pointerHi       ; put the high byte of the address into pointer
  ;LDA #LOW(textRow_TestingMaximumStringLength)
  ;STA pointerLo       ; put the low byte of the address of background into pointer

  LDX #$00           
  LDY #$00            ; inside loop counter
.TextLoop:
  LDA [pointerLo], y  ; copy one background byte from address in pointer (Lo->Hi) + Y
  BEQ .TextLoopSkip   ; if the character is blank, skip drawing/overwriting existing tile
  STA $2007           ; this runs up to 32 times
  JMP .TextLoopInc
.TextLoopSkip
  LDA $2007           ; reading from $2000 will skip over the tile without writing to it
.TextLoopInc
  INX
  CPX #$00            ; ticks over once all low bytes are iterated through
  BEQ .IncTextLoop
  
  INY                 
  CPY #$20
  BCC .TextLoop      ; run loop 32 times (for 32 tiles)

.IncTextLoop:
  INC pointerHi       ; increate high byte after all low bytes are iterated through, goes back through loop again if more are left in the next hi byte

  INY                 
  CPY #$20
  BCC .TextLoop      ; run loop 32 times (for 32 tiles)

  ; Have to set the PPU latch back when done (redundant, find where this can be done last)
  LDA $2002             ; read PPU status to reset the high/low latch
  LDA #$20
  STA $2006             ; write the high byte of $2000 address
  LDA #$00
  STA $2006             ; write the low byte of $2000 address

  RTS

;; LoadSpriteAddress
;; ;; Gets sprite address (low byte) from sprite number
;; ;; Parameters:
;; ;; ;; spriteNo   - Sprite number
;; ;; Returns:
;; ;; ;; spriteAddr - Starting sprite address (low byte) Ex: Sprite 0 = $0200 = $00, Sprite 1 = $04, etc.
LoadSpriteAddress:
  ; 64 max sprites, 4 bytes of information each. Sprite 0 = $0200-$0203, Sprite 1 = $0204-0207, etc. $0200 - $02FF
  LDX #$00
  LDY spriteNo
  CPY #$00
  BNE .LoadSpriteAddress_GetToSprite
  STX spriteAddr
  RTS
.LoadSpriteAddress_GetToSprite ;Gets to correct starting address for sprite (increments by 4)
  INX
  INX
  INX
  INX
  DEY
  CPY #$00
  BNE .LoadSpriteAddress_GetToSprite
  STX spriteAddr
  RTS

;; GetNewSpriteAddress
;; ;; Finds first sprite address avaialble. Avaialble sprite is determined by if the tile number is zero
;; ;; Returns:
;; ;; ;; spriteNo   - Sprite number that is a first available
;; ;; ;; spriteAddr - Starting sprite address (low byte) Ex: Sprite 0 = $0200 = $00, Sprite 1 = $04, etc.
GetNewSpriteAddress:
  ; 64 max sprites, 4 bytes of information each. Sprite 0 = $0200-$0203, Sprite 1 = $0204-0207, etc. $0200 - $02FF
  LDX #$00
  LDY #$00
.GetNewSpriteAddress_Loop:
  LDA $0202, X ; Checks the attibutes of each sprite
  CMP #$FE
  BEQ .GetNewSpriteAddress_Complete ; If attributes is #$FE, sprite has not been written to and can be overwritten. Attributes used because unused bits would make this never occur
  INX
  INX
  INX
  INX
  INY
  JMP .GetNewSpriteAddress_Loop
  ; No available sprites. What do we do here? Currently, it will overwrite Sprite 63 (the last sprite)
.GetNewSpriteAddress_Complete:
  STX spriteAddr
  STY spriteNo
  RTS

;; UpdateSprite
;; ;; Updates sprite information
;; ;; Parameters:
;; ;; ;; spriteNo   - Sprite number (optional if spriteAddr)
;; ;; ;; spriteAddr  - Sprite's starting address (or $00 to load it using spriteNo)
;; ;; ;; spriteDataPos - 0 = Y Pos, 1 = Tile Number, 2 = Attributes, 3 = X Pos
;; ;; ;; value      - New value
UpdateSprite:
  ; 64 max sprites, 4 bytes of information each. Sprite 0 = $0200-$0203, Sprite 1 = $0204-0207, etc. $0200 - $02FF
  ; Attributes:
  ;; Bit 7 - flip sprite vertically
  ;; Bit 6 - slip sprite horizontally
  ;; Bit 5 - Priority (0 = in front of background, 1 = behind background)
  ;; Bit 4, 3 and 2 - None
  ;; Bit 1 and 0 = Color pallete ($00 - $04)
  LDX spriteAddr
  BNE .UpdateSprite_GetToSpriteData ; Sprite address already loaded
  JSR LoadSpriteAddress
  LDX spriteAddr
.UpdateSprite_GetToSpriteData ;Gets to the correct sprite data byte (0-3)
  LDY spriteDataPos
  CPY #$00
  BEQ .UpdateSprite_StartSpriteWrite
.UpdateSprite_SpriteDataLoop
  INX
  DEY
  CPY #$00
  BNE .UpdateSprite_SpriteDataLoop
.UpdateSprite_StartSpriteWrite
  LDA value
  STA $0200, X
  RTS

;; GetSpriteData
;; ;; Gets sprite information
;; ;; Parameters:
;; ;; ;; spriteNo   - Sprite number (optional if spriteAddr)
;; ;; ;; spriteAddr  - Sprite's starting address (or $00 to load it using spriteNo)
;; ;; ;; spriteDataPos - 0 = Y Pos, 1 = Tile Number, 2 = Attributes, 3 = X Pos
;; ;; Returns:
;; ;; ;; spriteAddr  - Sprite's starting address
;; ;; ;; value      - New value
GetSpriteData:
  ; 64 max sprites, 4 bytes of information each. Sprite 0 = $0200-$0203, Sprite 1 = $0204-0207, etc. $0200 - $02FF
  ; Attributes:
  ;; Bit 7 - flip sprite vertically
  ;; Bit 6 - slip sprite horizontally
  ;; Bit 5 - Priority (0 = in front of background, 1 = behind background)
  ;; Bit 4, 3 and 2 - None
  ;; Bit 1 and 0 = Color pallete ($00 - $04)
  LDX spriteAddr
  BNE .GetSpriteData_GetToSpriteData ; Sprite address already loaded
  LDX #$00
  STX spriteAddr
  JSR LoadSpriteAddress
  LDX spriteAddr
.GetSpriteData_GetToSpriteData: ;Gets to the correct sprite data byte (0-3)
  LDY spriteDataPos
  CPY #$00
  BEQ .GetSpriteData_Complete
.GetSpriteData_SpriteDataLoop:
  INX
  DEY
  CPY #$00
  BNE .GetSpriteData_SpriteDataLoop
.GetSpriteData_Complete:
  LDA $0200, X
  STA value
  RTS

;; IncSpritePosition
;; ;; Increment/decrement sprite position X or Y
;; ;; Parameters:
;; ;; ;; spriteNo   - Sprite number (optional if spriteAddr)
;; ;; ;; spriteAddr  - Sprite's starting address (or $00 to load it using spriteNo)
;; ;; ;; spriteDataPos - 0 = Y Pos, 3 = X Pos
;; ;; ;; option         - 0 = Increment, 1 = Decrement
IncSpritePos:
  ; 64 max sprites, 4 bytes of information each. Sprite 0 = $0200-$0203, Sprite 1 = $0204-0207, etc. $0200 - $02FF
  ; Attributes:
  ;; Bit 7 - flip sprite vertically
  ;; Bit 6 - slip sprite horizontally
  ;; Bit 5 - Priority (0 = in front of background, 1 = behind background)
  ;; Bit 4, 3 and 2 - None
  ;; Bit 1 and 0 = Color pallete ($00 - $04)
  LDX spriteAddr
  BNE .IncSpritePos_GetToSpriteData ; Sprite address already loaded
  JSR LoadSpriteAddress
  LDX spriteAddr
.IncSpritePos_GetToSpriteData: ;Gets to the correct sprite data byte (0-3)
  LDA option
  BEQ .IncSpritePos_Inc
  JMP .IncSpritePos_Dec
.IncSpritePos_Inc:
  LDA spriteDataPos
  BEQ .IncSpritePos_IncY
  JMP .IncSpritePos_IncX
.IncSpritePos_Dec:
  LDA spriteDataPos
  BEQ .IncSpritePos_DecY
  JMP .IncSpritePos_DecX
.IncSpritePos_IncX:
  INC $0203, X
  JMP .IncSpritePos_Complete
.IncSpritePos_IncY:
  INC $0200, X
  JMP .IncSpritePos_Complete
.IncSpritePos_DecX:
  DEC $0203, X
  JMP .IncSpritePos_Complete
.IncSpritePos_DecY:
  DEC $0200, X
  JMP .IncSpritePos_Complete
.IncSpritePos_Complete:
  RTS

;; Override Funcions

;OnInit:
;  RTS
;OnTick:
;  RTS
;OnInputA:
;  RTS
;OnInputB:
;  RTS
OnInputSl:
  RTS
OnInputSt:
  RTS
;OnInputU:
;  RTS
;OnInputD:
;  RTS
;OnInputL:
;  RTS
;OnInputR:
;  RTS

