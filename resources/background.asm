tileRow_Empty:
  .db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .db $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ;.db cannot handle 32 values on one line, for some reason
tileRow_AllStars:
  .db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05 
  .db $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05 ;.db cannot handle 32 values on one line, for some reason
textRow_HelloWorld:
 .db $00,$00,$00,$00,$00,$00,$00,$00,$00,$27,$24,$2B,$2B,$2E,$00,$36
 .db $2E,$31,$2B,$23,$1A,$00,$1C,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; HELLO WORLD! ^

textRow_TestingMaximumStringLength:
 .db $33,$24,$32,$33,$28,$2D,$26,$00,$2C,$20,$37,$28,$2C,$34,$2C,$00
 .db $32,$33,$31,$28,$2D,$26,$00,$2B,$24,$2D,$26,$33,$27,$1A,$00,$1C ; TESTING MAXIMUM STRING LENGTH! ^

background:
    ;each row is 32 bytes, 30 rows are needed to fill the entire screen
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row
  .dw tileRow_AllStars ;; row