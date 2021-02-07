

`timescale 1ns / 1ns
module inner_product_TB();

localparam element_length = 32;
localparam number_of_elements = 4;

reg [element_length * number_of_elements - 1 : 0] In1 ;
reg [element_length * number_of_elements - 1 : 0] In2 ;
reg clk = 0;
reg rst = 0; 
reg row_i_stb, column_i_stb;
reg out_o_ack = 1;
wire row_i_ack, column_i_ack, out_o_stb;
wire [element_length-1:0] out;

inner_product #(4) i1(.row(In1), .column(In2), .clk(clk), .rst(rst), .out(out), .row_i_stb(row_i_stb), 
	.column_i_stb(column_i_stb), .out_o_ack(out_o_ack), .row_i_ack(row_i_ack), .column_i_ack(column_i_ack), .out_o_stb(out_o_stb));

always #10 clk=~clk;

initial begin
    $display("this is a test for inner product module");
    In1 = 0;
    In2 = 0;
    rst = 1;
    #1000
    rst = 1;
    In1 = 128'b01000001001011000000000000000000010000001011110001111010111000010100000011001111010111000010100101000000100111110101110000101001; // 10.75-5.89-6.48-4.98
    In2 = 128'b00111111101011110101110000101001010000000000000000000000000000000100000101110101101011010100001101000000111000000000000000000000; // 1.37-2-15.3548-7
    row_i_stb = 1;
    column_i_stb = 1;
    wait (row_i_ack & column_i_ack);
    row_i_stb <= 0;
    column_i_stb <= 0;
    wait (out_o_stb);
    $display("output is %b", out);
    // out_o_ack <= 1;
    #5000;
    $stop;  
    $finish;   
  end




endmodule