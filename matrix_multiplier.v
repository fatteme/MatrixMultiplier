module matrix_multiplier #(
	parameter m = 4,
	parameter p = 4,
	parameter n = 4,
	localparam word_width = 32
	)(
	output reg [0:m*n*word_width-1] matrix_C,
	output reg c_stb,
	output reg a_ack,
	output reg b_ack,
	input [0:m*p*word_width-1] matrix_A, 
	input [0:p*n*word_width-1] matrix_B, 
	input a_stb,
	input b_stb,
	input c_ack,
	input clk,
	input rst
// Product of A(m*p) and B(p*n) results C(m*n)
);

integer cw = 0; // column_count // indicates which column of matrix C is being calculated right now.
wire [0:m*word_width-1] vip_result;  // vip: vector inner product
reg vip_result_ack;
wire [0:m-1] vip_result_stb;
reg [0:p*word_width-1] vip_column; // is loaded by column cw of matrix B
reg vip_column_stb;
wire [0:m-1] vip_column_ack;
reg vip_matrix_a_stb;
wire [0:m-1] vip_matrix_a_ack;

localparam WAIT = 3'b000;
localparam VIP_LOAD = 3'b001;
localparam VIP_CALC = 3'b010;
localparam VIP_DONE = 3'b011;
localparam DONE = 3'b100;


reg [2:0] state = WAIT;
reg [2:0] next_state = WAIT;


always @(posedge clk or negedge rst) begin
	if (!rst) begin
		state <= WAIT;
	end else begin
		if (state == VIP_CALC & next_state == VIP_DONE) cw <= cw + 1;
		state <= next_state;
	end 
end

integer index, index2;
always @(*) begin
	case(state)
		WAIT: begin
			if (a_stb & b_stb) begin
				next_state <= VIP_LOAD;
				a_ack <= 1;
				b_ack <= 1;
				cw <= 0;
				c_stb <= 0;
			end else begin
				a_ack <= 0;
				a_ack <= 0;
				next_state <= state;
			end 
		end
		
		VIP_LOAD: begin
			for(index = 0; index < p; index = index + 1)
				vip_column[index*word_width +: word_width] <= matrix_B[(index*p+cw)*word_width +: word_width];
			vip_column_stb <= 1;
			vip_matrix_a_stb <= 1;
			vip_result_ack <= 0;
			if ((&vip_column_ack) & (&vip_matrix_a_ack)) 
				next_state <= VIP_CALC;
			else next_state <= state;
		end
		VIP_CALC: begin
			vip_column_stb <= 0;
			vip_matrix_a_stb <= 0;
			if (&vip_result_stb) begin
				for (index2 = 0; index2 < m; index2 = index2 + 1)
					matrix_C[(index2*m+ cw)*word_width +: word_width] <= vip_result[index2*word_width +: word_width];
				vip_result_ack <= 1;
				next_state <= VIP_DONE;
			end else next_state <= state;
		end
		VIP_DONE: begin
			if (cw != n) begin
				next_state <= VIP_LOAD;
				vip_result_ack <= 1;
			end else next_state <= DONE;
		end
		DONE: begin
			c_stb <= 1;
			a_ack <= 1;
			b_ack <= 1;
			if (c_ack) begin
				next_state <= WAIT;
			end else next_state <= state;
		end
		default: next_state <= WAIT;
	endcase
end

	
genvar i;
generate
	for (i = 0; i<m; i=i+1) begin
		inner_product #(n) vip(
			.out(vip_result[i*word_width +: word_width]),
			.row_i_ack(vip_matrix_a_ack[i]),
			.column_i_ack(vip_column_ack[i]),
			.out_o_stb(vip_result_stb[i]),
			.row(matrix_A[i*p*word_width +: p*word_width]),
			.row_i_stb(vip_matrix_a_stb),
			.column_i_stb(vip_column_stb),
			.out_o_ack(vip_result_ack),
			.column(vip_column),
			.clk(clk),
			.rst(rst)
		);
	end
endgenerate

endmodule 