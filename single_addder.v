module adder(
        input_a,
        input_b,
        input_a_stb,
        input_b_stb,
//        add_sub_not,
        output_z_ack,
        clk,
        rst,
        output_z,
        output_z_stb,
        input_a_ack,
        input_b_ack);

  input     clk;
  input     rst;

  input     [31:0] input_a;
  input     input_a_stb;
  output    input_a_ack;

  input     [31:0] input_b;
  input     input_b_stb;
  output    input_b_ack;

  output    [31:0] output_z;
  output    output_z_stb;
  input     output_z_ack;

//  input     add_sub_not;

  reg       s_output_z_stb;
  reg       [31:0] s_output_z;
  reg       s_input_a_ack;
  reg       s_input_b_ack;

  reg       [3:0] state;
  parameter get_a         = 4'd0,
            get_b         = 4'd1,
            unpack        = 4'd2,
            special_cases = 4'd3,
            mantissa_alignment   = 4'd4,
            add   = 4'd5,
            normalise    = 4'd6,
            pack   = 4'd7,
            put_z   = 4'd8;
  reg       [31:0] a, b, z;
  reg       [23:0] a_m, b_m, z_m;
  reg       [9:0] a_e, b_e, z_e;
  reg       a_s, b_s, z_s;

  always @(posedge clk)
  begin

    case(state)

      get_a:
      begin
        s_input_a_ack <= 1;
        if (s_input_a_ack && input_a_stb) begin
          a <= input_a;
          s_input_a_ack <= 0;
          state <= get_b;
        end
      end

      get_b:
      begin
        s_input_b_ack <= 1;
        if (s_input_b_ack && input_b_stb) begin
          b <= input_b;
          s_input_b_ack <= 0;
          state <= unpack;
        end
      end

      unpack:
      begin
        a_m <= a[22 : 0];
        b_m <= b[22 : 0];
        a_e <= a[30 : 23];
        b_e <= b[30 : 23];
        a_s <= a[31];
        b_s <= b[31];
        state <= special_cases;
      end

      special_cases:
      begin
        //if a is NaN or b is NaN return NaN 
        if ((a_e == 255 && a_m != 0) || (b_e == 255 && b_m != 0)) begin
          z[31] <= 1;
          z[30:23] <= 255;
          z[22:0] <= 1;
          z[21:0] <= 0;
          
          state <= put_z;
        //if a is inf and b is inf return NaN
        end else if ((a_e == 255 && a_m == 0) && (b_e == 255 && b_m == 0)) begin
          z[31] <= 1;
          z[30:23] <= 255;
          z[22:0] <= 1;
          z[21:0] <= 0;

          state <= put_z;
        //if a is inf or b is zero return a
        end else if (((a_e == 255) && (a_m == 0)) || ((b_m == 0) && (b_e == 0)))  begin
          z <= a;
          
          state <= put_z;
        //if b is inf or a in zero return b
        end else if (((b_e == 255) && (b_m == 0)) || ((a_m == 0) && (a_e == 0))) begin
          z <= b;

          state <= put_z;
        
        end else begin
        //   //Denormalised Number
        //   if ($signed(a_e) == -127) begin
        //     a_e <= -126;
        //   end else begin
        //     a_m[23] <= 1;
        //   end
        //   //Denormalised Number
        //   if ($signed(b_e) == -127) begin
        //     b_e <= -126;
        //   end else begin
        //     b_m[23] <= 1;
        //   end
           state <= mantissa_alignment;
        end
      end
      
      mantissa_alignment:
      begin
          if (b_m == a_m) begin
              state <= add;
          end else if (a_e < b_e) begin
              a_e <= a_e + 1;
              a_m <= a_m >> 1;
          end else begin
              b_e <= b_e + 1;
              b_m <= b_m >> 1;    
          end
      end
      
      add:
      begin
          if (a_s ^ b_s) begin    
              z_m <= a_m + (~b_m) + 1;
          end else begin
              z_m <= a_m + b_m;
          end
          state <= normalise;
      end

      normalise:
      begin
          if (z_m[23]) begin
              z_m <= z_m >> 1;
              z_e <= z_e + 1;
          end
          state <= pack;
      end
      
      pack:
      begin
        z[22 : 0] <= z_m[22:0];
        z[30 : 23] <= z_e[7:0];
        z[31] <= z_s;
        if ($signed(z_e) == -126 && z_m[23] == 0) begin
          z[30 : 23] <= 0;
        end
        //if overflow occurs, return inf
        if ($signed(z_e) > 127) begin
          z[22 : 0] <= 0;
          z[30 : 23] <= 255;
          z[31] <= z_s;
        end
        state <= put_z;
      end

      put_z:
      begin
        s_output_z_stb <= 1;
        s_output_z <= z;
        if (s_output_z_stb && output_z_ack) begin
          s_output_z_stb <= 0;
          state <= get_a;
        end
      end

    endcase

    if (rst == 1) begin
      state <= get_a;
      s_input_a_ack <= 0;
      s_input_b_ack <= 0;
      s_output_z_stb <= 0;
    end

  end
  assign input_a_ack = s_input_a_ack;
  assign input_b_ack = s_input_b_ack;
  assign output_z_stb = s_output_z_stb;
  assign output_z = s_output_z;

endmodule