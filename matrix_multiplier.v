module matrix_multiplier #(
	parameter m = 16,
	parameter p = 16,
	parameter n = 16,
	parameter word_width = 32
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
	input rst,
// Product of A(m*p) and B(p*n) results C(m*n)
);

integer cw = 0; // column_count // indicates which column of matrix C is being calculated right now.
wire [0:m*word_width-1] vip_result;  // vip: vector inner product
reg vip_result_ack;
reg [0:m-1] vip_result_stb;
reg [0:p*word_width-1] vip_column; // is loaded by column cw of matrix B
reg vip_column_stb;
wire [0:m-1] vip_column_ack;
reg vip_matrix_a_stb;
wire [0:m-1] vip_matrix_a_ack;

localparam WAIT = 2'b00;
localparam CALC = 2'b01;
localparam DONE = 2'b10;

localparam LOAD_SUB = 2'00;
localparam CALC_SUB = 2'01;
localparam DONE_SUB = 2'10;


reg [1:0] state = WAIT;
reg [1:0] next_state = WAIT;

reg [1:0] substate = WAIT;
reg [1:0] next_substate = WAIT;

always @(posedge clk or negedge rst) begin
	if (not rst) begin
		substate <= LOAD_SUB;
		state <= WAIT;
	end 
	else begin
		state <= next_state;
		substate <= next_substate;
	end 
end

always @(*) begin
	case(state)
		WAIT: begin
			if (a_stb and b_stb) begin
				next_state <= CALC;
				a_ack <= 0;
				b_ack <= 0;
				cw <= 0;
				c_stb <= 0;
			end 
			else next_state <= state;
		end
		CALC: begin
			if (cw == p) begin
				c_stb <= 1;
				next_state <= DONE;
			end
			else next_state <= state;
		end
		DONE: begin
			if (c_ack) begin
				next_state <= WAIT;
				a_ack <= 1;
				b_ack <= 1;
			end
			else next_state <= state;
		end
		default: next_state <= state;
	endcase
end

integer index, index2;

always @(*) begin
	if (state == CALC) begin
		case (substate)
			LOAD_SUB: begin
				if (&vip_column_ack) begin
					for(index = 0; index < p; index = index + 1)
						vip_column[index*word_width +: word_width] <= matrix_B[(index*p+cw)*word_width +: word_width];
					if (&vip_matrix_a_ack) begin
						next_substate <= CALC_SUB;
						vip_result_ack <= 1;
					end 
					else next_substate <= substate;
				end
				else next_substate <= substate;
			end
			CALC_SUB: begin
				if (&vip_result_stb) begin
					for (index2 = 0; index2 < m; index2 = index2 + 1)
						matrix_C[(index2*m+ cw)*word_width +: word_width] <= vip_result[index2*word_width +: word_width];
					next_substate <= DONE_SUB;
				end
				else next_substate <= substate;
			end
			DONE: begin
				cw = cw + 1;
				next_substate <= LOAD_SUB;
			end
		default: next_substate <= substate;
	endcase	
	end
end


genvar i;
generate
	for (i = 0; i<m; i=i+1) begin
		majid_module #(n)(
			.vip_result(vip_result[i*word_width +: word_width]),
			.vip_done(vip_done),
			.vip_row(matrix_A[i*p*word_width +: p*word_width]),
			.vip_column(vip_column),
			.clk(clk),
			.reset(rst),
			.start(vip_start)
		);
	end
endgenerate

endmodule 