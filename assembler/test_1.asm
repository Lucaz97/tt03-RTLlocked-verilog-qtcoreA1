; this program will load the value at address 13, decrement it in a loop till its zero, then 
; starting from 0b11111111, overflow it, then increment once more to get to 1
; tests: M[13] = 0
;        M[12] = 1
; THIS IS FOR THE LOCKED VERSION OF QTCORE-A1, WHICH NEEDS TO BE UNLOCKED
; UNLOCKING IS DONE WITH THE DATA COMMANDS AT ADDRESS 15 AND 16
0: LDA 13       ; load value from address 13 to accumulator
1: BEQ_FWD      ; if accumulator is zero, skip to 4
2: DEC          ; decrement the accumulator
3: STA 13       ; store accumulator value at address 13
4: BNE_BWD      ; if accumulator is not zero, jump back to 2
5: ADDI 15      ; the accumulator is set to 15
6: SHL4
7: ADDI 15      ; the accumulator is now 0b11111111
8: ADDI 1
9: STA 12       ; store accumulator at 12
10: BEQ_BWD     ; jump back to 8 if zero
11: HLT

13: DATA 16     ; store the initial value (16) at address 10
15: DATA 249    ; logic locking unlock key (program will not work without this)
16: DATA 191    ; logic locking unlock key (program will not work without this)
