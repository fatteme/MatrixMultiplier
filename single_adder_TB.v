`timescale 1ns/1ns 

module adder_TB();
  reg clk=0, rst=1;
  reg   [31:0] a, b, one, two, mone, mtwo;
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
    $monitor("result of %b +  %b  = %b and z_s,z_e,z_m, is %b,%b,%b \n",
            a, b, z,adder_1.z_s,adder_1.z_e,adder_1.z_m);
    
    //{s, e, m}
    one   = { 1'b0 , 1'b0,{7{1'b1}} , {{21{1'b0}},2'b01} };
    two   = { 1'b0 , 1'b0,{7{1'b1}} , {{21{1'b0}},2'b10} };
    mone  = { 1'b1 , 1'b0,{7{1'b1}} , {{22{1'b0}},2'b01} };
    mtwo  = { 1'b1 , 1'b0,{7{1'b1}} , {{21{1'b0}},2'b10} };


    a = 0;
    b = 0;
    rst = 1;
    #1000
    rst = 0;
    // 0 + 1
    a = mtwo;
    b = one;
    a_stb = 1;
    b_stb = 1;
    #3000;
    $stop;  
    $finish;
  end
endmodule
