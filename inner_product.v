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
    
    output [word_width-1:0] out; 
    output row_i_ack;
    output column_i_ack;
    output out_o_stb;
    input [word_width * number_of_elements - 1 : 0] row;
    input row_i_stb; 
    input column_i_stb; 
    input out_o_ack;
    input [word_width * number_of_elements - 1 : 0] column; 
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

    wire [word_width-1:0] vector_mult_result [1:number_of_elements];
    reg [2:0] state;
    reg [word_width-1:0] temp_res = 32'b0;
    wire [word_width-1:0] hResult;
    // multiplier signals
    reg rst_mult = 0;
    reg in1_stb = 0;
    reg column_stb = 0;
    reg in1_stb_adder = 0;
    reg column_stb_adder = 0;
    reg output_ack = 0;
    wire output_stb [1:number_of_elements];
    wire in1_ack_mult[1:number_of_elements];
    wire column_ack_mult[1:number_of_elements];
    wire in1_ack_adder;
    wire column_ack_adder;
    reg output_ack_adder = 0;
    reg output_full_stb = 1;

    // adder signals
    reg rst_adder = 1;
    reg res_ack = 0;
    wire res_ready;
    reg res_full_ready = 1;


    integer k,t;
    genvar i,j,l;
    generate
        for(i=1; i <= number_of_elements ; i=i+1) 
            begin
                multiplier multiplieri(
                    row[32 * i - 1 : 32 * (i-1)],
                    column[32 * i - 1 : 32 * (i-1)],
                    in1_stb,
                    column_stb,
                    output_ack,
                    clk,
                    rst_mult,
                    vector_mult_result[i],
                    output_stb[i],
                    in1_ack_mult[i],
                    column_ack_mult[i]
                );

                
            end
    endgenerate
    integer g =0;
    always @* begin
        g = 1; 
        output_full_stb = 1;
            for(g=1;g<=number_of_elements;g=g+1)begin
                output_full_stb = output_full_stb & output_stb[g];
            end
    end


    integer index = 1;
    adder adder1(
        vector_mult_result[index],
        temp_res,
        in1_stb_adder,
        column_stb_adder,
        output_ack_adder,
        clk,
        rst_adder,
        hResult,
        res_ready,
        in1_ack_adder,
        column_ack_adder
    );

    always @(posedge clk, negedge rst) begin
        if(!rst)
        begin
            state <= state_idle;
            rst_mult <= 1;
            rst_adder <= 1;
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
                            in1_stb <= 1;
                            column_stb <= 1;
                            rst_mult <= 0;
                            // ##
                            s_row_i_ack <= 1;
                            s_column_i_ack <= 1;
                        end
                        else begin
                            state <= state_idle;
                            rst_mult <= 1;
                            output_ack <= 0;
                            res_ack <= 0;
                            in1_stb <= 0;
                            column_stb <= 0;
                            // ##
                            s_row_i_ack <= 0;
                            s_column_i_ack <= 0;
                            s_out_o_stb <= 0;
                        end
                    end
                state_mult_elements: begin
                        in1_stb <= 1;
                        column_stb <= 1;

                        output_ack <= 0;
                        state <= state_wait_for_mult;
                    end
                state_wait_for_mult: begin
                    if(output_full_stb) begin
                            state <= state_add_elements;
                            rst_mult <= 1;
                            rst_adder <= 0;
                            temp_res <= 0;
                            in1_stb_adder <= 1;
                            column_stb_adder <= 1;
                    end
                    else begin
                            state <= state_wait_for_mult;
                    end
                    end
            state_add_elements: begin
                    if(index != number_of_elements+1) begin
                        rst_adder <= 0;
                        output_ack_adder <= 0;            
                        in1_stb_adder <= 1;
                        column_stb_adder <= 1;
                                        
                        state <= state_wait_for_add;
                    end else begin
                        state <= state_out_is_ready;
                    end
                end
                state_wait_for_add: begin
                    if (res_ready) begin
                        temp_res <= hResult;
                        index <= index + 1;
                        in1_stb_adder <= 0;
                        in1_stb_adder <= 0;
                        rst_adder <= 1;
                        output_ack_adder <= 1;
                        state <= state_add_elements;
                    end 
                    else begin
                        state <= state_wait_for_add;    
                    end
                end
                state_out_is_ready: begin
                    state <= state_idle;
                    output_ack <= 0;
                    res_ack <= 0;
                    in1_stb <= 0;
                    column_stb <= 0;
                    // ##
                    s_out_o_stb <= 1;
                end
                default: begin
                        state <= state_idle;
                    end
            endcase
        end
    end
    assign out = temp_res;
    assign row_i_ack = s_row_i_ack;
    assign column_i_ack = s_column_i_ack;
    assign out_o_stb = s_out_o_stb;

endmodule



