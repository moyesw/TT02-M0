///////////////////////////////////////////////////////////////////////////
// M0 top level
//
// Copyright 2022 William Moyes
//

`default_nettype none
`timescale 100us/10ps

module m0_top_module (
  input  [7:0] io_in,
  output [7:0] io_out
);

  // --- Inputs ---
  wire clk     = io_in[0];      // System clock (~6000 Hz)
  wire rst     = io_in[1];      // Reset line, active high
  wire spi_miso= io_in[2];      // SPI bus, ASIC input, target output
  wire uart_rx = io_in[3];      // Serial port, ASIC Receive
  wire in4     = io_in[4];
  wire in5     = io_in[5];
  wire in6     = io_in[6];
  wire in7     = io_in[7];

  // --- Outputs ---
  wire spi_cs0;
  wire spi_cs1;
  wire spi_clk;
  wire spi_mosi;
  wire uart_tx;
  wire out5;
  wire out6;
  wire out7;
  
  wire [7:0] io_out;
  assign io_out[0] = spi_cs0;  // SPI bus, Chip Select for ROM, Words 0000-7FFF
  assign io_out[1] = spi_cs1;  // SPI bus, Chip Select for RAM, Words 8000-FFFF
  assign io_out[2] = spi_clk;  // SPI bus, Clock
  assign io_out[3] = spi_mosi; // SPI bus, ASIC output, target input
  assign io_out[4] = uart_tx;  // Serial port, ASIC Transmit
  assign io_out[5] = out5;
  assign io_out[6] = out6;
  assign io_out[7] = out7;
    

  reg [6:0]  SPIphase;
  
  always @(posedge clk) begin
    if (rst)
      SPIphase <= 7'h41;
    else if (SPIphase == 7'h53)
      SPIphase <= 7'h00;
    else 
      SPIphase <= SPIphase + 1;
  end
  
  
  reg r_cs0;
  reg r_clk;
  reg r_mosi;
  
  always @(posedge clk) begin
    r_cs0 <= rst || (SPIphase == 7'h41) || (SPIphase == 7'h42);
    r_clk <= SPIphase[0] && (SPIphase != 7'h41) && (SPIphase != 7'h43);
    r_mosi <= (SPIphase >= 7'h50) && (SPIphase <= 7'h53);
  end
  
  assign spi_cs0 = r_cs0;
  assign spi_cs1 = 1'b1;
  assign spi_clk = r_clk;
  assign spi_mosi = r_mosi;
  
   
  

endmodule



