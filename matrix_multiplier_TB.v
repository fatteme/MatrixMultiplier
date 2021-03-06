`timescale 1ns / 1ns
module matrix_multiplier_tb();
// parameter word_width = 6;
// parameter ww_square = 36;
// parameter word_width = 1;
// parameter ww_square = 1;
parameter word_width = 2;
parameter ww_square = 4;

reg [0:32 * ww_square - 1] matrix_1;
reg [0:32 * ww_square - 1] matrix_2;
reg [0:32 * ww_square - 1] matrix_3;
wire [0:32 * ww_square - 1] out;
reg [31:0] ROM_1 [0:ww_square-1];
reg [31:0] ROM_2 [0:ww_square-1];
reg [31:0] ROM_3 [0:ww_square-1];

wire c_stb, a_ack, b_ack;
reg rst = 0;
reg clk, c_ack = 0;
reg a_stb, b_stb;

integer i;
integer j;
integer k;
integer v;
initial begin
  clk = 0;
  forever #10 clk <= ~clk;
end

initial
begin
    rst = 1;

    $display("loading rom 3");
    $readmemb("matrix_op.txt", ROM_3);
    for(k = 0; k < ww_square; k = k + 1) begin
        matrix_3[k * 32 +: 32] = ROM_3[k];
    end

    #20;

    $display("loading rom 1");
    $readmemb("matrix_1.txt", ROM_1);
    for(i = 0; i < ww_square; i = i + 1) begin
        matrix_1[i * 32 +: 32] = ROM_1[i];
    end
    a_stb = 1;

    #20;

    $display("loading rom 2");
    $readmemb("matrix_2.txt", ROM_2);
    for(j = 0; j < ww_square; j = j + 1) begin
        matrix_2[j * 32 +: 32] = ROM_2[j];
    end
    b_stb = 1;

    #20;

    wait (a_ack & b_ack);
    a_stb = 0;
    b_stb = 0;

    #100;

    wait (c_stb);
    for(v = 0; v < ww_square; v = v + 1) begin
      $display("%b == %b is %b", matrix_3[v * 32 +: 32], out[v * 32 +: 32], (matrix_3[v * 32 +: 32]== out[v * 32 +: 32]));
    end
    c_ack = 1;
    # 5000;
    $stop;
end



matrix_multiplier #(.n(word_width), .m(word_width), .p(word_width)) mm (
    .matrix_C(out), .matrix_A(matrix_1), .matrix_B(matrix_2), .rst(rst), 
    .clk(clk), .a_stb(a_stb), .b_stb(b_stb), .c_stb(c_stb), .a_ack(a_ack), .b_ack(b_ack), .c_ack(c_ack));
endmodule
