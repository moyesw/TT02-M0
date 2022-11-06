/*\
|*| M0
|*|
|*| Copyright 2022 William Moyes
|*|
|*| TODO: Document Design
|*|
\*/
`default_nettype none


/*\
|*| shift_reg - A 16-bit shift register
|*|
\*/
module shift_reg (
  input clk,  // Input clock, shifts on positive edges
  input rst,  // Reset signal 
  input en,   // Enable shifting when true, 
  input in,   // Value to shift in
  output out  // Value to shift out
);
  
  reg r[15:0];
  assign out = r[0];  
  
  always @(posedge clk) begin
    if (rst) begin
      r[ 0] <= 0;
      r[ 1] <= 0;
      r[ 2] <= 0;
      r[ 3] <= 0;
      r[ 4] <= 0;
      r[ 5] <= 0;
      r[ 6] <= 0;
      r[ 7] <= 0;
      r[ 8] <= 0;
      r[ 9] <= 0;
      r[10] <= 0;
      r[11] <= 0;
      r[12] <= 0;
      r[13] <= 0;
      r[14] <= 0;
      r[15] <= 0; 
    end
    else if (en) begin
      r[ 0] <= r[ 1];
      r[ 1] <= r[ 2];
      r[ 2] <= r[ 3];
      r[ 3] <= r[ 4];
      r[ 4] <= r[ 5];
      r[ 5] <= r[ 6];
      r[ 6] <= r[ 7];
      r[ 7] <= r[ 8];
      r[ 8] <= r[ 9];
      r[ 9] <= r[10];
      r[10] <= r[11];
      r[11] <= r[12];
      r[12] <= r[13];
      r[13] <= r[14];
      r[14] <= r[15];
      r[15] <= in;
    end
  end
endmodule


/*\
|*| M0 top-level module
|*|
\*/
module m0_top_module (
  input  [7:0] io_in,
  output [7:0] io_out
);

  wire clk = io_in[0];
  wire rst = io_in[1];
  
  
  // pin 2 shift reg
  shift_reg r0(
    .clk(clk),
    .rst(rst),
    .en(1'b1),
    .in(io_in[2]),
    .out(io_out[2])
  );

  // pin 3 shift reg
  shift_reg r1(
    .clk(clk),
    .rst(rst),
    .en(1'b1),
    .in(io_in[3]),
    .out(io_out[3])
  );
  
  // pin 4 shift reg  
  shift_reg r2(
    .clk(clk),
    .rst(rst),
    .en(1'b1),
    .in(io_in[4]),
    .out(io_out[4])
  );
  
  // pin 5 shift reg
  shift_reg r3(
    .clk(clk),
    .rst(rst),
    .en(1'b1),
    .in(io_in[5]),
    .out(io_out[5])
  );
  
endmodule 

//=============================================================================
/*\
|*| M0 main test bench
|*|
\*/
`timescale 1us/1ns

module m0_testbench;
   
  wire [7:0] ins;
  wire [7:0] outs;
  m0_top_module m0(
    .io_in(ins),
    .io_out(outs)
  );
  
  reg test_clk;
  assign ins[0] = test_clk;
  
  reg test_rst;
  assign ins[1] = test_rst;


  reg test_r0;
  assign ins[2] = test_r0;
  reg test_r1;
  assign ins[3] = test_r1;
  reg test_r2;
  assign ins[4] = test_r2;
  reg test_r3;
  assign ins[5] = test_r3;
  reg [1:0] test_unused;
  assign ins[6] = test_unused[0];
  assign ins[7] = test_unused[1];
    
  initial begin
    $dumpfile("m0.vcd");
    $dumpvars;
  end
  
  parameter TestClkPeriod = (1000000/(12000*2)); // 12khz clock
  integer i;
  
  initial begin
    for (i = 0; i < 64; i = i + 1) begin
      #TestClkPeriod;
      test_clk = ~test_clk;
    end
    $finish;  
  end

  initial begin  
    test_clk = 0;
    test_rst = 1;
    test_r0 = 0;
    test_r1 = 0;
    test_r2 = 0;
    test_r3 = 0;
    test_unused[0] = 0;
    test_unused[1] = 0;
  end

  initial begin
    #(TestClkPeriod*2) test_rst <= 0;
  end
  
  initial begin
    #(TestClkPeriod*4-1) test_r0 <= 1;
  end

  initial begin
    #(TestClkPeriod*8-1) test_r1 <= 1;
  end
  

endmodule