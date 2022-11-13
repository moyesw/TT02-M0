///////////////////////////////////////////////////////////////////////////
// M0 top level
//
// Copyright 2022 William Moyes
//

`default_nettype none
`timescale 100us/10ps

module moyes0_top_module (
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


  wire SPI_Addr = ((SPIphase == 7'h53) || (SPIphase < 7'h1F)) && SPIphase[0];
  wire SPI_Data = ((SPIphase >= 7'h1F) && (SPIphase <= 7'h3E)) && SPIphase[0];
  wire SPI_LastBit = (SPIphase == 7'h41);

  reg ADBit;
  reg A15;
  reg Read_notWrite;

  reg [2:0]  CPUphase;
  always @(posedge clk) begin
    if (rst)
      CPUphase <= 3'd5;
    else if (!SPI_LastBit)
      CPUphase <= CPUphase;
    else begin
      if (CPUphase == 3'd5)
         CPUphase <= 3'd0;
      else
         CPUphase <= CPUphase + 3'd1;
    end
  end

  always @(posedge clk) begin
    // TODO:  This is a hack... replace with real code
    A15 <= 1'b0;
    ADBit <= 1'b0;
    Read_notWrite <= 1'b1;
  end


  reg r_cs0;
  reg r_cs1;
  reg r_clk;
  reg r_mosi;

  always @(posedge clk) begin

    // Drive CS0 and CS1
    if (!A15) begin
      r_cs0 <= rst || (SPIphase == 7'h41) || (SPIphase == 7'h42);
      r_cs1 <= 1;
    end else begin
      r_cs1 <= rst || (SPIphase == 7'h41) || (SPIphase == 7'h42);
      r_cs0 <= 1;
    end

    // Drive SPI_CLK
    r_clk <= SPIphase[0] && (SPIphase != 7'h41) && (SPIphase != 7'h43);

    // Drive MOSI
    if (SPIphase < 7'h40)
      r_mosi <= ADBit;
    else if (SPIphase < 7'h50)
      r_mosi <= 1'b0;
    else if (SPIphase < 7'h52)
      r_mosi <= 1'b1;
    else
      r_mosi <= Read_notWrite;
  end

  assign spi_cs0 = r_cs0;
  assign spi_cs1 = r_cs1;
  assign spi_clk = r_clk;
  assign spi_mosi = r_mosi;




endmodule

