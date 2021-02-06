`timescale 1ns / 1ps
module inner_product
#(
parameter number_of_elements = 4
)
(
In1, In2, clk, rst, out, done, start
);


localparam element_length = 32;
localparam state_idle = 0;
localparam state_mult_elements = 1;
localparam state_wait_for_mult = 2;
localparam state_add_elements = 3;
localparam state_wait_for_add = 4;
localparam state_out_is_ready = 5;

input [element_length * number_of_elements - 1 : 0] In1 ;
input [element_length * number_of_elements - 1 : 0] In2 ;
input clk, rst, start;
output reg [element_length-1:0] out;
output reg done;

wire [element_length-1:0] temp1_vector [1:number_of_elements];
reg [2:0] state;
reg [element_length-1:0] temp_res = 32'b0;
reg [element_length-1:0] hResult;
// multiplier signals
reg rst_mult = 0;
reg in1_stb = 0;
reg in2_stb = 0;
reg in1_stb_adder = 0;
reg in2_stb_adder = 0;
reg output_ack = 0;
wire output_stb[1:number_of_elements];
wire in1_ack_mult[1:number_of_elements];
wire in2_ack_mult[1:number_of_elements];
wire in1_ack_adder[1:number_of_elements];
wire in2_ack_adder[1:number_of_elements];
reg output_ack_adder = 0;
reg in1_full_ack = 1;
reg in2_full_ack = 1;
reg output_full_stb = 1;

// adder signals
reg rst_adder = 0;
reg res_ack = 0;
wire res_ready[1:number_of_elements];
reg res_full_ready = 1;


integer k,t;
genvar i,j;
generate
    for(i=1; i <= number_of_elements ; i=i+1) 
        begin
            multiplier multiplieri(
                In1[32 * i - 1 : 32 * (i-1)],
                In2[32 * i - 1 : 32 * (i-1)],
                in1_stb,
                in2_stb,
                output_ack,
                clk,
                rst_mult,
                temp1_vector[i],
                output_stb[i],
                in1_ack_mult[i],
                in2_ack_mult[i]
            );

            always @* begin
                in1_full_ack = in1_full_ack & in1_ack_mult[i];
                in2_full_ack = in2_full_ack & in2_ack_mult[i];
                output_full_stb = output_full_stb & output_stb[i];
            end
        end
endgenerate

reg index = 1;

adder adder1(
    temp1_vector[index],
    
    temp_res,
    in1_stb_adder,
    in2_stb_adder,
    output_ack_adder,
    clk,
    rst_adder,
    hResult,
    res_ready[index],
    in1_ack_adder[index],
    in2_ack_adder[index]
);

always @(posedge clk, negedge rst) begin
    if(!rst)
    begin
        state <= state_idle;
        rst_mult <= 0;
        rst_adder <= 0;
    end
    else begin
        case (state)
            state_idle: begin
                    if (start) begin
                       state <= state_mult_elements;
                       rst_mult <= 1;
                    end
                    else begin
                        state <= state_idle;
                        rst_mult <= 0;
                        output_ack <= 0;
                        res_ack <= 0;
                        in1_stb <= 0;
                        in2_stb <= 0;
                    end
                end
            state_mult_elements: begin
                    in1_stb <= 1;
                    in2_stb <= 1;
                    output_ack <= 0;
                    state <= state_wait_for_mult;
                end
            state_wait_for_mult: begin
                   if(output_full_stb) begin
                        state <= state_add_elements;
                        rst_mult <= 1;
                        rst_adder <= 1;
                   end
                   else begin
                        state <= state_wait_for_mult;
                   end
                end
            state_add_elements: begin
                if(index != number_of_elements) begin
                    output_ack_adder <= 0;            
                    in1_stb_adder <= 1;
                    in1_stb_adder <= 1;
                    index <= index + 1;
                    
                    state <= state_wait_for_add;
                end else begin
                    state <= state_out_is_ready;
                end
            end
            
            state_wait_for_add: begin
                if (res_ready) begin
                    temp_res <= hResult;
                                
                    in1_stb_adder <= 0;
                    in1_stb_adder <= 0;
                    output_ack_adder <= 1;
                    state <= state_add_elements;
                end esle begin
                    state <= state_wait_for_add;    
                end
            end

            state_add_elements: begin
                    output_ack_adder <= 0;            
                    in1_stb_adder <= 1;
                    in1_stb_adder <= 1;
                    state <= state_wait_for_add;
                end
            state_wait_for_add: begin
                if(index == number_of_elements) begin
                    temp_res = hResult;
                    output_ack_adder = 1;
                    state <= state_out_is_ready;
                end
                else if(res_ready[index]) begin
                    index <= index + 1;
                    temp_res <= hResult;
                                
                    in1_stb_adder <= 0;
                    in1_stb_adder <= 0;
                    output_ack_adder <= 1;
                    state = state_add_elements;
                end
                else begin
                state = state_wait_for_add;
                end
                
            end
            state_out_is_ready: begin
                    done <= 1;
                    if (output_ack) begin
                        state <= state_idle;
                        out <= temp_res;
                        output_ack <= 0;
                        res_ack <= 0;
                        in1_stb <= 0;
                        in2_stb <= 0;
                    end
                    else begin
                        state <= state_out_is_ready;
                    end
                end
            default: begin
                    state <= state_idle;

                end
        endcase
    end
end
endmodule



