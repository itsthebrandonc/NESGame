metatiles:  ;8 x 8 = 64 bytes
  ; each byte represents a 4x4 tile set on the screen
  ; two bits per 2x2 tile section, set pallet color 0-3
  ;metatiles layout:
  ;;;;;;;;;;;
  ; 00 ; 01 ;
  ;;;;;;;;;;;
  ; 02 ; 03 ;
  ;;;;;;;;;;;
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000
  .db %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000, %00000000 ;I think only the tops are used in last row

;tile_0:
;  .db %00000000, %00000000, %00000000, %00000000

palette:
  ; color pallet based on NES standards, first color is background color and must match
  .db $0D,$29,$1A,$21,  $2D,$36,$17,$0F,  $2D,$30,$21,$0F,  $2D,$27,$17,$0F   ;;background palette
  .db $0D,$05,$26,$30,  $0D,$20,$10,$00,  $2D,$1C,$15,$14,  $2D,$02,$38,$3C   ;;sprite palette

sprites:
  ; Y Postion, Tile Number, Attributes, X Position

  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used

