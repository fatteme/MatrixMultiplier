module Multiplier();
reg [0:32 * 36 - 1] matrix_1;
reg [0:32 * 36 - 1] matrix_2;
reg [0:32 * 36 - 1] matrix_3;
reg [0:32 * 36 - 1] out;
reg [31:0] ROM_1 [0:35];
reg [31:0] ROM_2 [0:35];
reg [31:0] ROM_3 [0:35];

wire c_stb, a_ack, b_ack;
wire rst=0;
reg clk, c_ack, a_stb, b_stb;

integer i;
integer j;
integer k;
integer v;
initial begin
  clk = 0;
end

always begin
  #10 clk <= ~clk;
end

initial
begin
    $readmemb("matrix_1.txt", ROM_1);
    for(i = 0; i < 36; i = i + 1) begin
        matrix_1[i * 32 +: 32] = ROM_1[i];
    end
    a_stb = 1;
    $readmemb("matrix_2.txt", ROM_2);
    for(j = 0; j < 36; j = j + 1) begin
        matrix_2[j * 32 +: 32] = ROM_2[j];
    end
    b_stb = 1;
    $readmemb("matrix_op.txt", ROM_3);
    for(k = 0; k < 36; k = k + 1) begin
        matrix_3[k * 32 +: 32] = ROM_3[j];
    end
end

always @(c_stb) begin
  for(v = 0; v < 36; v = v + 1) begin
    $display("%b == %b", matrix_3[v * 32 +: 32], out[v * 32 +: 32]);
  end
end

matrix_multiplier #(.n(6), .m(6), .p(6)) mm (.matrix_C(out), .matrix_A(matrix_1), .matrix_B(matrix_2), .rst(rst), .clk(clk), .a_stb(a_stb), .b_stb(b_stb), .c_stb(c_stb), .a_ack(a_ack), .b_ack(b_ack), .c_ack(c_ack));
endmodule