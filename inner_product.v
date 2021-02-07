`timescale 1ns / 1ns

module inner_product #(parameter number_of_elements = 4)(
    out, 
    row_i_ack,
    column_i_ack,
    out_o_stb,
    row,
    row_i_stb, 
    column_i_stb, 
    out_o_ack,
    column, 
    clk, 
    rst 
);

    localparam word_width = 32;
    
    
    input [word_width * number_of_elements - 1 : 0] row;
    input  row_i_stb; 
    output row_i_ack;
    
    input [word_width * number_of_elements - 1 : 0] column; 
    input  column_i_stb; 
    output column_i_ack;
    
    input  out_o_ack;
    output out_o_stb;
    output [word_width-1:0] out; 
    
    input clk; 
    input rst; 

    reg s_row_i_ack;
    reg s_column_i_ack;
    reg s_out_o_stb;


    localparam  state_idle          = 3'd0,
                state_mult_elements = 3'd1,
                state_wait_for_mult = 3'd2,
                state_add_elements  = 3'd3,
                state_wait_for_add  = 3'd4,
                state_out_is_ready  = 3'd5;

    reg [2:0] state;
    reg [word_width-1:0] inner_product_result = 32'b0;
    
    // fp_mult signals
    wire [word_width-1:0] mul_out [1:number_of_elements];
    wire mul_out_stb [1:number_of_elements];
    wire mul_in1_ack [1:number_of_elements];
    wire mul_in2_ack [1:number_of_elements];
    reg mul_rst = 0;
    reg mul_in1_stb = 0;
    reg mul_in2_stb = 0;
    reg mul_out_ack = 0;
    reg mul_out_full_stb = 1;
    reg res_ack = 0;

    // fp_add signals
    wire [word_width-1:0] adder_out;
    wire adder_out_stb;
    wire adder_in1_ack;
    wire adder_in2_ack;
    reg adder_out_ack = 0;
    reg adder_in1_stb = 0;
    reg adder_in2_stb = 0;
    reg adder_rst = 1;

    integer k,t;
    genvar i,j,l;
    generate
        for(i=1; i <= number_of_elements ; i=i+1) begin
            multiplier fp_mult(
                .input_a(row[word_width * i - 1 : word_width * (i-1)]),
                .input_b(column[word_width * i - 1 : word_width * (i-1)]),
                .input_a_stb(mul_in1_stb),
                .input_b_stb(mul_in2_stb),
                .output_z_ack(mul_out_ack),
                .clk(clk),
                .rst(mul_rst),
                .output_z(mul_out[i]),
                .output_z_stb(mul_out_stb[i]),
                .input_a_ack(mul_in1_ack[i]),
                .input_b_ack(mul_in2_ack[i])
            );  
        end
    endgenerate
    integer g =0;
    always @* begin
        g = 1; 
        mul_out_full_stb = 1;
        for(g=1;g<=number_of_elements;g=g+1)begin
            mul_out_full_stb = mul_out_full_stb & mul_out_stb[g];
        end
    end


    integer index = 1;
    adder fp_add(
        .input_a(mul_out[index]),
        .input_b(inner_product_result),
        .input_a_stb(adder_in1_stb),
        .input_b_stb(adder_in2_stb),
        .output_z_ack(adder_out_ack),
        .clk(clk),
        .rst(adder_rst),
        .output_z(adder_out),
        .output_z_stb(adder_out_stb),
        .input_a_ack(adder_in1_ack),
        .input_b_ack(adder_in2_ack)
    );

    always @(posedge clk, negedge rst) begin
        if(!rst) begin
            state <= state_idle;
            mul_rst <= 1;
            adder_rst <= 1;
            // ##
            s_row_i_ack <= 0;
            s_column_i_ack <= 0;
            s_out_o_stb <= 0;
        end
        else begin
            case (state)
                state_idle: begin
                    if (row_i_stb & column_i_stb & out_o_ack) begin
                        state <= state_mult_elements;
                        mul_in1_stb <= 1;
                        mul_in2_stb <= 1;
                        mul_rst <= 0;
                        // ##
                        s_row_i_ack <= 1;
                        s_column_i_ack <= 1;
                    end
                    else begin
                        state <= state_idle;
                        mul_rst <= 1;
                        mul_out_ack <= 0;
                        res_ack <= 0;
                        mul_in1_stb <= 0;
                        mul_in2_stb <= 0;
                        // ##
                        s_row_i_ack <= 0;
                        s_column_i_ack <= 0;
                        s_out_o_stb <= 0;
                    end
                end
                
                state_mult_elements: begin
                    mul_in1_stb <= 1;
                    mul_in2_stb <= 1;
                    mul_out_ack <= 0;
                    state <= state_wait_for_mult;
                end
                
                state_wait_for_mult: begin
                    if(mul_out_full_stb) begin
                        state <= state_add_elements;
                        mul_rst <= 1;
                        adder_rst <= 0;
                        inner_product_result <= 0;
                        adder_in1_stb <= 1;
                        adder_in2_stb <= 1;
                    end
                    else begin
                        state <= state_wait_for_mult;
                    end
                end
                
                state_add_elements: begin
                    if(index != number_of_elements+1) begin
                        adder_rst <= 0;
                        adder_out_ack <= 0;            
                        adder_in1_stb <= 1;
                        adder_in2_stb <= 1;
                                        
                        state <= state_wait_for_add;
                    end else begin
                        state <= state_out_is_ready;
                    end
                end
                
                state_wait_for_add: begin
                    if (adder_out_stb) begin
                        inner_product_result <= adder_out;
                        index <= index + 1;
                        adder_in1_stb <= 0;
                        adder_in1_stb <= 0;
                        adder_rst <= 1;
                        adder_out_ack <= 1;
                        state <= state_add_elements;
                    end 
                    else begin
                        state <= state_wait_for_add;    
                    end
                end
                
                state_out_is_ready: begin
                    state <= state_idle;
                    mul_out_ack <= 0;
                    res_ack <= 0;
                    mul_in1_stb <= 0;
                    mul_in2_stb <= 0;
                    // ##
                    s_out_o_stb <= 1;
                end
                
                default: begin
                    state <= state_idle;
                end
            endcase
        end
    end

    assign out = inner_product_result;
    assign row_i_ack = s_row_i_ack;
    assign column_i_ack = s_column_i_ack;
    assign out_o_stb = s_out_o_stb;

endmodule



