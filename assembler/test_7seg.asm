0: LDA 13 ; load the value of the counter
1: ADD 15 ; the LED constants offset
2: LDAR   ; Load LED pattern with counter value+offset
3: STA 14 ; store LED pattern to LEDs
4: LDA 13 ; load the value of the counter
5: ADDI 1 ; increment
6: STA 13 ; store the value of the counter
7: CLR      ; set ACC=0
8: JMP     ; jump to address 0
13: DATA 0 ;the counter

15: DATA 249    ; logic locking unlock key (program will not work without this)
16: DATA 191    ; logic locking unlock key (program will not work without this)