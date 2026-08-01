  ;;;;;;;;;;;     ROM Header      ;;;;;;;;;;;;;;;
  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Sprites / Pallets / Background
  
  .bank 1
  .org $E000    ;;align the background data so the lower address is $00
  .include "lib/background.asm"
  .include "lib/attributes.asm"
  
;;;;;;;;;;;;;;  
  
  .bank 2
  .org $0000
  .incbin "lib/NESGame.chr"   ;includes 8KB graphics file


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

;Enemy Array (10 Bytes, 5 Enemies * 2 Bytes)
;; ;; Enemy Object: 2 Bytes
;; ;; ;; Enemy Sprite Address
;; ;; ;; 3 unused bits, Enemy Direction (3 bits, 0-8), Enemy Fire Cooldown (2 bits, 0-4)
enemyArray .rs 10

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; RESERVED SPRITES
; 64 max sprites, 4 bytes of information each. Sprite 0 = $0200-$0203, Sprite 1 = $0204-0207, etc. $0200 - $02FF
;
; Sprites 0-3 reserved for player (4 sprites big)
; Sprites 4-23 reserved for enemies (5 max enemies * 4 sprites big)
; Sprites 24-64 are general sprites (bullets)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  .bank 0
  .org $C000 
  .include "lib/startup.asm"
  .include "lib/character.asm"
  .include "lib/bullet.asm"
  .include "lib/enemy.asm"

OnInit:
  ;Spawn Character
  ; Write top-left sprite info and pass it into SpawnCharacter function
  LDA #$80
  STA spriteData
  LDA #$00
  LDX #$02
  STA spriteData, X
  LDA #$80
  INX
  STA spriteData, X
  JSR SpawnCharacter

  ;Spawn Enemy
  ; Write top-left sprite info and pass it into SpawnEnemy function
  LDA #$BC
  STA spriteData
  LDA #$01
  LDX #$02
  STA spriteData, X
  LDA #$BC
  INX
  STA spriteData, X
  JSR SpawnEnemy

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