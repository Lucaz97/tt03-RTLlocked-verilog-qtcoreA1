; this program will load the value at address 13,
; then we do a series of operations that should keep acc value invariated 
; tests: M[13] = 0
;        M[12] = 1
; THIS IS FOR THE LOCKED VERSION OF QTCORE-A1, WHICH NEEDS TO BE UNLOCKED
; UNLOCKING IS DONE WITH THE DATA COMMANDS AT ADDRESS 15 AND 16
0: LDA 13       ; load value from address 13 to accumulator
1: SHL          ; shift left
2: SHR          ; shift right
3: ROR          ; ROTATE RIGHT
4: ROL          ; ROTATE LEFT
5: XOR 13       ; xor with itself
6: XOR 13      ; set back to its value
7: SUB 13         ; subtract its value
8: ADD 13      ; set to its value
9: ADDI 1     ;
10: HLT  ;

13: DATA 1     ; store the initial value (16) at address 10
15: DATA 249    ; logic locking unlock key (program will not work without this)
16: DATA 191    ; logic locking unlock key (program will not work without this)
