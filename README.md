![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg)

# QTcore-A1

*Author*: Original microcontroller: Hammond Pearce; Locked version: Luca Collini

*Description*: A RTL locked accumulator-based 8-bit microarchitecture designed via GPT-4 conversations.

The original QTCore-A1 from Hammond Pearce is a basic accumulator-based 8-bit microarchitecture (with an emphasis on the micro). It is a Von Neumann design (shared data and instruction memory).
Its original specs can be found here: https://github.com/kiwih/tt03-verilog-qtcoreA1

In order to lock the design, I had to make some space so I cut off 2 (8bit) memory registers (as a 16 bit register was added to store the locking key) and the memory mapped constants.
I locked the ALU with 6 bits, locking 1 operation an 3 constants, and the control unit with 10 bits, locking an 8 bit constnt used twice and 2 branches. This locking techniques are the same one first presented in ASSURE: https://arxiv.org/abs/2010.05344

I also locked the ISA to ALU opcodes module using a novel RTL locking technique to lock case statements. 
The case variable is xored with the locking key and all case constants are replaced with the results of the original value xored with the right key.
In this way the case statement works as originally intended only with the right key. 
To implement this locking technique I used ChatGPT with the GPT4 version. It was able to modify the isa_to_alu_opcode module
by describing the technique, the key value to use, and the original module. The structure was correct from the first response, some additional
back and forth was required for it to get the right values for the case constants (apparently gpt4 struggles a bit with xor operations).

The correct key is provided to allow everyone to use this design: 1011 1111 1111 1001
We store the key in a scan chained register. In order to have the design working, your assembly should end with this two lines:
```
15: DATA 249    ; logic locking unlock key (program will not work without this)
16: DATA 191    ; logic locking unlock key (program will not work without this)
```

## How it works
Example program:

```
; This program tests the btn and LEDs
; will switch between 0 and 7 pressing the button
;
; BTNs and LEDS are at address 17, btn at LSB
0: ADDI 7 ; load the btn and LEDS
1: STA 17 ; load the btn and LEDS
2: LDA 17 ; load the btn and LEDS
3: AND 16 ; mask the btn
4: BNE_BWD ; if btn&1 is not zero then branch back to 0
5: LDA 13 ; load the btn and LEDS
6: STA 17 ; load the btn and LEDS
7: LDA 17 ; load the btn and LEDS
8: AND 16 ; mask the btn
9: BEQ_BWD ; if btn&1 is zero then branch back to 3
;
; the button has now done a transition from low to high
;
10: CLR
11: JMP
;
; data
13: DATA 127 ;
15: DATA 249    ; logic locking unlock key (program will not work without this)
16: DATA 191    ; logic locking unlock key (program will not work without this)
```


C code to load the previously-discussed example program (e.g. via the STM32 HAL) is provided:
```
//The registers are presented in reverse order to 
// the table as we load them MSB first.
uint8_t program_led_btn[21] = {
    0b00000000, //IOREG
    0b10111111, //MEM[16]
    0b11111001, //MEM[15]
    0b00000000, //MEM[14]
    0b01111111, //MEM[13]
    0b00000000, //MEM[12]
    0b11110000, //MEM[11]
    0b11111101, //MEM[10]
    0b11110011, //MEM[9]
    0b10010000, //MEM[8]
    0b00010001, //MEM[7]
    0b00110001, //MEM[6]
    0b00001101, //MEM[5]
    0b11110101, //MEM[4]
    0b10010000, //MEM[3]
    0b00010001, //MEM[2]
    0b00110001, //MEM[1]
    0b11100111, //MEM[0]
    0b00000000, //ACC
    0b00000000, //IR
    0b00000001 //PC[5bit], CU[3bit]
};

//... this will go in the SPI peripheral initialization code
hspi1.Init.Mode = SPI_MODE_MASTER;
hspi1.Init.Direction = SPI_DIRECTION_2LINES;
hspi1.Init.DataSize = SPI_DATASIZE_8BIT;
hspi1.Init.CLKPolarity = SPI_POLARITY_LOW;
hspi1.Init.CLKPhase = SPI_PHASE_1EDGE;
hspi1.Init.NSS = SPI_NSS_SOFT;
//...
hspi1.Init.FirstBit = SPI_FIRSTBIT_MSB;
hspi1.Init.TIMode = SPI_TIMODE_DISABLE;
//...

//... this will go in your main or similar
uint8_t *program = program_led_btn;
//on the first run, scan_out will give us the reset value of the 
// processor
HAL_GPIO_WritePin(SPI_SCAN_CS_GPIO_Port, SPI_SCAN_CS_Pin, 0);
HAL_Delay(100);
HAL_SPI_TransmitReceive(&hspi1, program, scan_out, 21, HAL_MAX_DELAY);
HAL_Delay(100);
HAL_GPIO_WritePin(SPI_SCAN_CS_GPIO_Port, SPI_SCAN_CS_Pin, 1);
//we can check if the program loaded correctly by immediately scanning 
// it back in again, it will be unloaded to scan_out
HAL_GPIO_WritePin(SPI_SCAN_CS_GPIO_Port, SPI_SCAN_CS_Pin, 0);
HAL_Delay(100);
HAL_SPI_TransmitReceive(&hspi1, program, scan_out, 21, HAL_MAX_DELAY);
HAL_Delay(100);
HAL_GPIO_WritePin(SPI_SCAN_CS_GPIO_Port, SPI_SCAN_CS_Pin, 1);
//Check if the program loaded correctly
for(int i = 0; i < 21; i++) {
if(program[i] != scan_out[i]) {
    while(1); //it failed
}
}
```

### Running a program

Once the program is loaded (using the above code or similar), we can run a program.
This is as easy as providing a clock signal to the processor and setting the processor enable line high.
We do this using the SPI as follows:
```
uint8_t dummy; //a dummy value
HAL_GPIO_WritePin(SPI_PROC_CS_GPIO_Port, SPI_PROC_CS_Pin, 0);
//...
//run this in a loop
HAL_SPI_TransmitReceive(&hspi1, &dummy, &dummy, 1, HAL_MAX_DELAY);
```

The processor will ignore any value being shifted in on the MOSI data line during operation.
However, it does provide a nice feature in that the processor will emit the current value of the processor_halt signal on the MISO line.
This means that we can improve the code to run this process in a loop and catch when the program reaches a HLT instruction:
```
HAL_Delay(100);
HAL_GPIO_WritePin(SPI_PROC_CS_GPIO_Port, SPI_PROC_CS_Pin, 0);
dummy = 0;
while(1) {
HAL_SPI_TransmitReceive(&hspi1, &dummy, &dummy, 1, HAL_MAX_DELAY);
if(dummy == 0xFF)
    break;
}
HAL_GPIO_WritePin(SPI_PROC_CS_GPIO_Port, SPI_PROC_CS_Pin, 1);
HAL_Delay(100);
```
Of course, the example program does not HLT, so we will not reach this point in this code. But, it works for other programs that do contain a HLT instruction.

Once you have the provided example program running, you will be able to press the button and see how the LEDs are toggled.

# Tiny Tapeout Information Follows

## What is Tiny Tapeout?

TinyTapeout is an educational project that aims to make it easier and cheaper than ever to get your digital designs manufactured on a real chip!

Go to https://tinytapeout.com for instructions!

### Resources

* [FAQ](https://tinytapeout.com/faq/)
* [Digital design lessons](https://tinytapeout.com/digital_design/)
* [Learn how semiconductors work](https://tinytapeout.com/siliwiz/)
* [Join the community](https://discord.gg/rPK2nSjxy8)
