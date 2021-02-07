`timescale 1ns/1ns 

module adder_TB();
  reg clk=0, rst=1;
  reg   [31:0] a, b;
  reg   [31:0] one, two, neg_one, neg_two, pos_infinity, neg_infinity, nan;
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
    // $monitor("result of %b +  %b  = %b and z_s,z_e,z_m, is %b,%b,%b \n",
    //         a, b, z, adder_1.z_s, adder_1.z_e, adder_1.z_m);
    $monitor("result of %b +  %b  = %b\n",
            a, b, z);
    
    //{s, e, m}
    one           = 32'b00111111100000000000000000000000;
    two           = 32'b01000000000000000000000000000000;
    neg_one       = 32'b10111111100000000000000000000000;
    neg_two       = 32'b11000000000000000000000000000000;
    pos_infinity  = { 1'b0 , {8{1'b1}} , {23{1'b0}} };
    neg_infinity  = { 1'b1 , {8{1'b1}} , {21{1'b0}} };
    nan           = { 1'b1 , {8{1'b1}} , {{22{1'b0}},1'b1} };

    a = 0;
    b = 0;
    rst = 1;
    #1000
   
    // 1 + 1 (two positive numbers)
    $display("test0: 1 + 1");
    rst = 0;
    a = one;
    b = one;
    a_stb = 1;
    b_stb = 1;
    #1000;
    
    // 1 + (2) (two positive number)
    rst = 1;
    #1000
    $display("test1: 1 + 2");
    rst = 0;
    a_stb = 0;
    b_stb = 0;
    a = 32'b01000000000000000000000000000000;
    b = 32'b00111111100000000000000000000000;
    a_stb = 1;
    b_stb = 1;
    #1000;

    // 1 + (-2) (one positive and one negative number)
    rst = 1;
    #1000
    $display("test2: 1 + (-2)");
    rst = 0;
    a_stb = 0;
    b_stb = 0;
    a = one;
    b = neg_two;
    a_stb = 1;
    b_stb = 1;
    #1000;
    
    // -1 + 2 (one negative and one positive number)
    rst = 1;
    #1000
    $display("test3: -1 + 2");
    rst = 0;
    a_stb = 0;
    b_stb = 0;
    a = neg_one;
    b = two;
    a_stb = 1;
    b_stb = 1;
    #1000;

    // -1 + (-2) (two negative numbers)
    rst = 1;
    #1000
    $display("test4: -1 + (-2)");
    rst = 0;
    a_stb = 0;
    b_stb = 0;
    a = neg_one;
    b = neg_two;
    a_stb = 1;
    b_stb = 1;
    #1000;

    // 1 + nan (number and not a number)
    rst = 1;
    #1000
    $display("test5: 1 + NAN");
    rst = 0;
    a_stb = 0;
    b_stb = 0;
    a = one;
    b = nan;
    a_stb = 1;
    b_stb = 1;
    #1000;

    // pos_infinity + nan (infinity and not a number)
    rst = 1;
    #1000
    $display("test6: infinity + NAN");
    rst = 0;
    a_stb = 0;
    b_stb = 0;
    a = pos_infinity;
    b = nan;
    a_stb = 1;
    b_stb = 1;
    #1000;

    // neg_infinity + nan (infinity and not a number)
    rst = 1;
    #1000
    $display("test7: -infinity + NAN");
    rst = 0;
    a_stb = 0;
    b_stb = 0;
    a = neg_infinity;
    b = nan;
    a_stb = 1;
    b_stb = 1;
    #1000;

    // pos_infinity + number (infinity and a number)
    rst = 1;
    #1000
    $display("test8: infinity + 1");
    rst = 0;
    a_stb = 0;
    b_stb = 0;
    a = pos_infinity;
    b = one;
    a_stb = 1;
    b_stb = 1;
    #1000;

    // neg_infinity + number (infinity and a number)
    rst = 1;
    #1000
    $display("test9: -infinity + 1");
    rst = 0;
    a_stb = 0;
    b_stb = 0;
    a = neg_infinity;
    b = one;
    a_stb = 1;
    b_stb = 1;
    #1000;


    // pos_infinity + pos_infinity 
    rst = 1;
    #1000
    $display("test10: infinity + infinity");
    rst = 0;
    a_stb = 0;
    b_stb = 0;
    a = pos_infinity;
    b = pos_infinity;
    a_stb = 1;
    b_stb = 1;
    #1000;

    // neg_infinity + neg_infinity 
    rst = 1;
    #1000
    $display("test11: -infinity + (-infinity)");
    rst = 0;
    a_stb = 0;
    b_stb = 0;
    a = neg_infinity;
    b = neg_infinity;
    a_stb = 1;
    b_stb = 1;
    #1000;

    // pos_infinity + neg_infinity (pos_infinity + neg_infinity must be nan)
    rst = 1;
    #1000
    $display("test12: infinity + (-infinity)");
    rst = 0;
    a_stb = 0;
    b_stb = 0;
    a = pos_infinity;
    b = neg_infinity;
    a_stb = 1;
    b_stb = 1;
    #1000;

    $stop;  
    $finish;
  end
endmodule
