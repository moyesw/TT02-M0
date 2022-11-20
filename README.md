![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg)

# M0: A 16-bit SUBLEQ Microprocessor

The M0 is a 16-bit, bit serial microprocessor based upon the SUBLEQ architecture. The only external devices needed for operation are a SPI RAM, SPI ROM, and clock source. The entire ROM and RAM are available for user code.  All registers and logic are contained within the M0 itself. A transmit UART is included for serial output. The M0 was designed for the TinyTapeout educational project, see https://tinytapeout.com for more.

The M0 interoperates with Oleg Mazonka's HSQ C-compiler for SUBLEQ. 

## M0 Architecture
The M0 is a SUBLEQ (SUBtract and jump if Less than or EQual) microprocessor. All data is represented using signed 16-bit two's complement words. The M0 uses a word addressable address space with 65,536 unique addresses (128 KBytes). 

Address map:
- 0000-7FFF RAM (connected to SPI CS0)
- 8000-FFFF ROM (connected to SPI CS1)`

Special addresses:
- 8000 = Reset value of the M0 Program Counter
- FFFF = UART Transmits on write

## A brief introduction to the SUBLEQ architecture
The M0 is a One Instruction Set Computer (OISC) that uses the "SUBLEQ A, B, C" instruction. M0 instructions have no opcode, but instead consists of three 16-bit words for the A, B, and C operands. The A and B operands are pointers to the data to act upon. The value at A is subtracted from the value at B, and the result is stored back into address B. If the result stored in B is less than or equal to zero, the program counter is set to C, otherwise execution continues to the next instruction.

The SUBLEQ A, B, C instruction cycle:
```
A = mem[PC]; B = mem[PC+1]; C = mem[PC+2];
mem[B] = mem[B] - mem[A]
if (mem[B] <= 0)
  PC = C;
else
  PC = PC + 3;
```

SUBLEQ code is frequently constructed using primitives built out of the basic SUBLEQ instruction in conjunction with known constants. Indirection is accomplished using self-modifying code. The example primitives below make use of Temp (a scratch memory address), Zero (an address known to hold zero), and Neg1 (an address known to hold 0xFFFF):
```
Jump to AdrX:
  SUBLEQ Zero, Zero, AdrX 

Zero AdrX:
  SUBLEQ AdrX, AdrX, PC+3

Increment AdrX:
  SUBLEQ Neg1, AdrX, PC+3

Move AdrX to AdrY:	  
  SUBLEQ Temp, Temp, PC+3  ; Temp=0
  SUBLEQ AdrY, AdrY, PC+3  ; AdrY=0
  SUBLEQ AdrX, Temp, PC+3  ; Temp= -AdrX
  SUBLEQ Temp, AdrY, PC+3  ; AdrY= -Temp (i.e. AdrX)

AdrZ= AdrX + AdrY:
  SUBLEQ Temp, Temp, PC+3  ; Temp=0
  SUBLEQ AdrZ, AdrZ, PC+3  ; AdrZ=0
  SUBLEQ AdrX, Temp, PC+3  ; Temp= -AdrX
  SUBLEQ AdrY, Temp, PC+3  ; Temp= -AdrX -AdrY
  SUBLEQ Temp, AdrZ, PC+3  ; AdrZ= -Temp (i.e. AdrX+AdrY)
			  
Output bits 7:0 of AddrX to UART	  
  SUBLEQ AdrX, FFFFh, PC+3 ; Address -1 is a special address
```
## Notes on interoperability
Nearly all SUBLEQ code found in the literature is designed to start at address 0 and execute out of RAM. To give the M0 the option to boot from ROM, the M0 starts fetching from address 0x8000. The user may place a startup routine in ROM to jump to RAM at address 0000. For example the instruction 8002 8002 0000 may be used to jump from 8000 to 0000.

Many SUBLEQ implementations treat fetching an instruction from a negative address as a signal to halt and exit. The M0, being a microprocessor, has no concept of 'exiting', and instead places its ROM in the range 8000-FFFF (the negative number space). Halting can be implemented using a branch to self instruction, and reset may be used to restart execution.

SUBLEQ implementations differ in behavior if an instruction's B operand attempts to modify the running instruction's own C operand. In the M0, the write will occur before C is fetched.

M0 is unique in having ROM, and the following should be considered:
- self-modifying code will not function correctly in ROM
- The M0 will branch based upon the result of subtracting mem[B]-mem[A], regardless if mem[B] was successfully changed in memory.
- SUBLEQ programs can take advantage of immutable constants in ROM, for example non-destructive comparisons become possible.
- The user may opt for attaching two SRAMs to the M0 instead of a ROM and RAM. It is the users responsibility to load executable content into RAM before reset is released.

## C compiler
Oleg Mazonka's C to SUBLEQ compiler can be found here: https://web.archive.org/web/20210923232655/http://mazonka.com/subleq/hsq.html

Use the -q option to generate SUBLEQ code. The decimal output should be converted into 16-bit values, and stored starting at address 0x0000. Be aware that the compiler uses words immediately after the end of the program for storage of data/stack.

## External connections
Inputs:
| pin | name | Description |
| --- | --- | --- |
|0|clk|Clock input| 
|1|rst|Reset(active high, run when low)|
|2|spi_miso|SPI ASIC input, target output|
|3|unused|(reserved for UART RX)|
|4|unused||
|5|unused||
|6|unused||
|7|unused||

Outputs: 
| pin | name | Description |
| --- | --- | --- |
|0|spi_cs0|SPI Chip Select for RAM, Words 0000-7FFF|
|1|spi_cs1|SPI Chip Select for ROM, Words 8000-FFFF|
|2|spi_clk|SPI Clock|
|3|spi_mosi|SPI ASIC output, target input|
|4|uart_tx|Serial port, ASIC Transmit|
|5|unused||
|6|unused||
|7|!clk|debug clock|

The UART operates at a baud rate equal to one half of the input clock frequency on pin in0. Proper receiving of serial output is timing sensitive. TinyTapeout02 uses a scan chain based input/output scheme which may introduce jitter as the clock speed nears the scan chain speed. Therefore, care should be taken in how the M0 is clocked. The out7 pin reflects an inverted copy of in0, and may be used to monitor the quality of the M0 input and output timing.

The M0 is designed to interface with the following SPI devices:
- Microchip 23LC512 SPI SRAM     (CS0)
- Microchip 25LC512 SPI NOR ROM  (CS1)

Note: By design, the spi_clk is lowered before deasserting the chip select. This will cause the SPI ROM or RAM to output the leading bit of the data at the next address. The M0 ignores this input.

## Important notes on SPI ROM and RAM content
For silicon area efficiency the M0 bit reverses its SPI addresses and SPI data. When preparing SPI ROM, or battery backed SPI RAM content for use by the M0, this bit order inversion must be taken into consideration.
```
in_msb = (in_addr >> 15) & 1;
in_addr = in_addr & 16'h7FFF;

in_addr = ((in_addr & 16'hFF00) >> 8) | ((in_addr & 16'h00FF) << 8);
in_addr = ((in_addr & 16'hF0F0) >> 4) | ((in_addr & 16'h0F0F) << 4);
in_addr = ((in_addr & 16'hCCCC) >> 2) | ((in_addr & 16'h3333) << 2);
in_addr = ((in_addr & 16'hAAAA) >> 1) | ((in_addr & 16'h5555) << 1);

in_data = ((in_data & 16'hFF00) >> 8) | ((in_data & 16'h00FF) << 8);
in_data = ((in_data & 16'hF0F0) >> 4) | ((in_data & 16'h0F0F) << 4);
in_data = ((in_data & 16'hCCCC) >> 2) | ((in_data & 16'h3333) << 2);
in_data = ((in_data & 16'hAAAA) >> 1) | ((in_data & 16'h5555) << 1);

if (in_msb) begin
  rom.MemoryBlock[in_addr] = (in_data >> 8) & 16'h00FF;
  rom.MemoryBlock[in_addr+1] = in_data & 16'h00FF;
end else begin
  ram.MemoryBlock[in_addr] = (in_data >> 8) & 16'h00FF;
  ram.MemoryBlock[in_addr+1] = in_data & 16'h00FF;
end
```

The M0 will only work with SPI devices that use a 16-bit SPI address. Larger ROMs with 24 or 32-bit addresses will NOT work.

## Performance
The M0, due to its bit serial nature and interface with the SPI bus, requires 504 input clocks per instruction. The predicted 12500 Hz scan chain update rate on TinyTapeout02 would yield an input clock of 6250 Hz, leading to 12.4 SUBLEQ instructions per second.
