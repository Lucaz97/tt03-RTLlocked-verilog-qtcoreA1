; This program tests the btn and LEDs
; will switch between 0 and 7 pressing the button
;
; BTNs and LEDS are at address 17, btn at LSB
0: ADDI 14 ; load the btn and LEDS
1: STA 14 ; load the btn and LEDS
2: LDA 14 ; load the btn and LEDS
3: AND 12 ; mask the btn
4: BNE_BWD ; if btn&1 is not zero then branch back to 2
5: LDA 13 ; load the btn and LEDS
6: STA 14 ; load the btn and LEDS
7: LDA 14 ; load the btn and LEDS
8: AND 12 ; mask the btn
9: BEQ_BWD ; if btn&1 is zero then branch back to 7
;
; the button has now done a transition from low to high
;
10: CLR
11: JMP
;
; data
12: DATA 1;
13: DATA 126 ;
15: DATA 249    ; logic locking unlock key (program will not work without this)
16: DATA 191    ; logic locking unlock key (program will not work without this)