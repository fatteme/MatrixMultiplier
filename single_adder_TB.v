`timescale 1ns/1ns 

module adder_TB();
  reg clk=0, rst=1;
  reg   [31:0] a, b;
  wire   [31:0] z;
  reg a_stb, b_stb, z_ack;
  wire a_ack, b_ack, z_stb;
  
  always #10 clk=~clk;  // 25MHz
  
  adder adder_1(
    .clk(clk),
    .rst(rst),
    .input_a(a),
    .input_a_stb(a_stb),
    .input_a_ack(a_ack),
    .input_b(b),
    .input_b_stb(b_stb),
    .input_b_ack(b_ack),
    .output_z(z),
    .output_z_stb(z_stb),
    .output_z_ack(z_ack));

  initial begin
    $display("this is a test for floating point adder");
    $monitor("result of %b +  %b  = %b", a, b, z);
    a = 0;
    b = 0;
    rst = 1;
    #1000
    rst = 0;
    // 0 + 1
    // a = {32{1'b0}};
    // b = {{31{1'b0}},1'b1};
    
    // 1 + 1
    a ={{31{1'b0}},1'b1};
    b = {{31{1'b0}},1'b1};
    a_stb = 1;
    b_stb = 1;
    #3000;
    $stop;  
  end
endmodule
