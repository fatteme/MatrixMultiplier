module adder(
        input_a,
        input_b,
        input_a_stb,
        input_b_stb,
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

  reg       s_output_z_stb;
  reg       [31:0] s_output_z;
  reg       s_input_a_ack;
  reg       s_input_b_ack;

  reg       [3:0] state;
  localparam  get_a               = 4'd0,
              get_b               = 4'd1,
              unpack              = 4'd2,
              special_cases       = 4'd3,
              mantissa_alignment  = 4'd4,
              add                 = 4'd5,
              normalise           = 4'd6,
              normalise_add       = 4'd7,
              normalise_sub       = 4'd8,
              pack                = 4'd9,
              put_z               = 4'd10;
  
  reg       [31:0] a, b, z;
  reg       [23:0] a_m, b_m, z_m;
  reg       [7:0] a_e, b_e, z_e;
  reg       a_s, b_s, z_s;

  always @(posedge clk or negedge rst)
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
        if (isNaN({a_s,a_e,a_m}) || isNaN({b_s,b_e,b_m})) begin
          setNaN();
          
          state <= put_z;
        //if a is inf and b is inf return NaN
        end else if (isInf({a_s,a_e,a_m}) && isInf({b_s,b_e,b_m})) begin
          if (a_s ^ b_s) begin
            setNaN();
          end else begin
            setInf(a_s);
          end

          state <= put_z;
        //if a is inf or b is zero return a
        end else if (isInf({a_s,a_e,a_m}) || isZero({b_s,b_e,b_m}))  begin
          z <= a;
          
          state <= put_z;
        //if b is inf or a in zero return b
        end else if (isInf({b_s,b_e,b_m}) || isZero({a_s,a_e,a_m}))  begin
          z <= b;

          state <= put_z;
        
        end else begin
           state <= mantissa_alignment;
        end
      end
      
      mantissa_alignment:
      begin
          if (b_e == a_e) begin
              z_e <= a_e;
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
          z_s <= a_s;
          if (a_s ^ b_s) begin 
              z_m <= a_m + (~b_m) + 1;
              state <= normalise_sub;
          end else begin
              z_m <= a_m + b_m;
              state <= normalise_add;
          end
      end

      normalise_add:
      begin
          if (z_m[23]) begin
              z_m <= z_m >> 1;
              z_e <= z_e + 1;
          end
          state <= pack;
      end
      
      normalise_sub:
      begin
        if (z_m==0) begin
          z_m <= 0;
          z_e <= 0;
          z_s <= 0;

          state <= pack;
        end else if (z_m[23]) begin
          z_m <= ~z_m + 1;
          z_s <= ~a_s;
          state <= normalise;
        end else begin
          state <= normalise;
        end
      end

      normalise:
      begin
        if (z_m[22])  begin
          state <= pack;
        end else begin
          z_m <= z_m <<1;
          z_e <= z_e - 1 ;
        end
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

  function isNaN(input [31:0]number);begin
    if (number[30:23] == 255 && number[22:0] != 0) begin
        isNaN = 1;
    end else begin
      isNaN = 0;
    end
  end
  endfunction

  function isInf(input [31:0]number);begin
    if (number[30:23] == 255 && number[22:0] == 0) begin
        isInf = 1;
    end else begin
      isInf = 0;
    end
  end
  endfunction
  
  function isZero(input [31:0]number);begin
    if (number[30:0] == 0) begin
        isZero = 1;
    end else begin
      isZero = 0;
    end
  end
  endfunction

  task setNaN();
  begin
    z[31] <= 1;
    z[30:23] <= 255;
    z[22] <= 1;
    z[21:0] <= 0;      
  end
  endtask
  
  task setInf(input sign);
  begin
    z[31] <= sign;
    z[30:23] <= 255;
    z[22:0] <= 0;
  end
  endtask

endmodule