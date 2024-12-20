`default_nettype none // prevents system from inferring an undeclared logic (good practice)

module minimum_coded_unit #
  (parameter integer U_VALUE = 0,
   parameter integer V_VALUE = 0
   )
  (
    input wire clk_in,
    input wire rst_in,
    input wire ready_in,
    input wire [7:0] pixel_val,
    input wire [2:0] x,
    input wire [2:0] y,
    input wire [9:0] quantizer,
    output logic [10:0] val_out,
    output logic ready_out
  );

  logic signed [63:0]  cum_sum;
  logic [7:0] horiz_cos_temp;
  logic [7:0] vert_cos_temp;
  logic [4:0] horiz_cos_in;
  logic [4:0] vert_cos_in;

  logic signed [11:0] horiz_cos_out;
  logic signed [11:0] vert_cos_out;
  logic signed [63:0] pre_out;
  logic signed [63:0] temp_val_out;

  //assign temp_val_out = $signed(pre_out>>>$signed(40));

  logic round_up;
  logic is_neg;
  assign round_up = pre_out[39];
  assign is_neg = pre_out[63];
  always_comb begin
    
    if (is_neg) begin
        temp_val_out = $signed((pre_out>>>$signed(40))+round_up);
        //temp_val_out = $signed((pre_out>>>$signed(40)));
    end else begin
        temp_val_out = $signed((pre_out>>>$signed(40))+round_up);
        //temp_val_out = $signed((pre_out>>>$signed(40)));
    end

  end

  assign val_out = temp_val_out[10:0];

  logic [10:0] alpha_coeff;
  always_comb begin
    if (U_VALUE==0 && V_VALUE == 0) begin
        alpha_coeff = 128;
    end else if (U_VALUE!=0 && V_VALUE!=0) begin
        alpha_coeff = 256;
    end else begin
        alpha_coeff = 181;
    end
  end

  logic [20:0] quantized_alpha;


  assign horiz_cos_temp = (((x<<1)+1)*U_VALUE);
  assign vert_cos_temp = (((y<<1)+1)*V_VALUE);

  assign horiz_cos_in = horiz_cos_temp[4:0];
  assign vert_cos_in = vert_cos_temp[4:0];
        
  logic calc_out;

  cosine_lut lut_horiz(.clk_in(clk_in), .rst_in(rst_in), .phase_in(horiz_cos_in), .amp_out(horiz_cos_out));
  cosine_lut lut_vert(.clk_in(clk_in), .rst_in(rst_in), .phase_in(vert_cos_in), .amp_out(vert_cos_out));

  always_ff @(posedge clk_in) begin
    
    if (rst_in) begin
        cum_sum <= 0;
        calc_out <= 0;
        pre_out <= 0;
        ready_out <= 0;
        quantized_alpha <= 0;
    end else begin
        quantized_alpha <= alpha_coeff*quantizer;
        if (ready_in) begin
            cum_sum <= cum_sum + horiz_cos_out*vert_cos_out*$signed(pixel_val);
        end else begin
            cum_sum <= cum_sum;
        end
        if (y == 7 && x == 7) begin
            calc_out <= 1'b1;
        end else begin
            calc_out <= 0;
        end
        if (calc_out) begin
            pre_out <= cum_sum*$signed(quantized_alpha);
            calc_out <= 0;
            ready_out <= 1;
        end else begin
            ready_out <= 0;
        end
    end
  end

endmodule


module dct_block #
  (
    parameter integer C_S00_AXIS_TDATA_WIDTH  = 64,
    parameter integer C_M00_AXIS_TDATA_WIDTH  = 64,
    parameter logic IS_CHROMINANCE = 0
  )
  (
  // Ports of Axi Slave Bus Interface S00_AXIS
  input wire  s00_axis_aclk, s00_axis_aresetn,
  input wire  s00_axis_tlast, s00_axis_tvalid,
  input wire [C_S00_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
  input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1: 0] s00_axis_tstrb,
  output logic  s00_axis_tready,
 
  // Ports of Axi Master Bus Interface M00_AXIS
  input wire  m00_axis_aclk, m00_axis_aresetn,
  input wire  m00_axis_tready,
  output logic  m00_axis_tvalid, m00_axis_tlast,
  output logic [C_M00_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
  output logic [(C_M00_AXIS_TDATA_WIDTH/8)-1: 0] m00_axis_tstrb,
  
  //non AXI outputs for actual use
  output logic [10:0] dct_out [7:0][7:0],
  output logic dct_out_ready
  );

  logic ready_in [7:0][7:0];
  logic ready_out [7:0][7:0];
  logic signed [10:0] val_out [7:0][7:0];
  logic [9:0] quant_divisor [7:0][7:0];
  logic [2:0] current_x, current_y;
  logic [7:0] pixel;
  logic [63:0] completed_dct;
  logic no_new_data;

  assign s00_axis_tready = 1'b1;
  assign m00_axis_tstrb = 16;

  assign pixel = s00_axis_tdata[7:0];

  logic [1:0] state;

  genvar u,v;
  generate
    for (u = 0; u < 8; u=u+1) begin : horiz_loop // <-- example block name  
        for (v = 0; v < 8; v=v+1) begin : vert_loop
          minimum_coded_unit #(.U_VALUE(u), .V_VALUE(v))
            block_unit(
                .clk_in(s00_axis_aclk),
                .rst_in(~s00_axis_aresetn),
                .ready_in(s00_axis_tvalid),
                .pixel_val(pixel),
                .x(current_x),
                .y(current_y),
                .quantizer(quant_divisor[u][v]),
                .val_out(val_out[u][v]),
                .ready_out(ready_out[u][v])
            );

            quantizer_lut quantize_value(
                .u(u), 
                .v(v), 
                .is_chrominance(IS_CHROMINANCE), 
                .inv_divisor(quant_divisor[u][v])
            );

            always_ff @(posedge s00_axis_aclk) begin
                if (~s00_axis_aresetn) begin
                    ready_in[u][v] <= 0;
                    dct_out[u][v] <= 0;
                end else begin
                    if (m00_axis_tready) begin
                        if (s00_axis_tvalid) begin
                            if (current_x == u && current_y == v && ~no_new_data) begin
                                ready_in[u][v] = 1;
                            end else begin
                                ready_in[u][v] = 0;
                            end
                        end

                        if (ready_out[u][v]) begin

                            completed_dct[(v<<3)+u] <= 1'b1;
                            dct_out[u][v] <= val_out[u][v];
                        end
                    end
                end
            end
        end
    end
  endgenerate

  logic [2:0] out_x_count, out_y_count;
  logic delivered_last;

  always_ff @(posedge s00_axis_aclk) begin
    if (~s00_axis_aresetn) begin
        completed_dct = 0;
        current_x = 0;
        current_y = 0;
        no_new_data <= 0;
        out_x_count <= 0;
        out_y_count <= 0;
        m00_axis_tvalid <= 0;
        delivered_last <= 0;
        dct_out_ready <= 0;
    end else begin
        if (m00_axis_tready) begin
            if (s00_axis_tvalid) begin
                current_x <= current_x + 1;
                if (current_x == 7) begin
                    current_y <= current_y+1;
                    if (current_y == 7) begin
                        no_new_data <= 1;
                    end
                end
            end
            if (completed_dct == 64'hffff_ffff_ffff_ffff) begin
                dct_out_ready <= 1;

                
                m00_axis_tdata <= $signed(val_out[out_x_count][out_y_count]);

                if (out_x_count==7 && out_y_count == 7) begin
                    delivered_last <= 1'b1;
                end 
                if (~delivered_last) begin
                    m00_axis_tvalid <= 1'b1;
                end else begin
                    m00_axis_tvalid <= 1'b0;
                end
                if (out_x_count == 7) begin
                    out_y_count <= out_y_count+1;
                end
                out_x_count <= out_x_count+1;
            end
        end
    end
  end

endmodule

//6bit sine lookup, 8bit depth
module cosine_lut(input wire [4:0] phase_in, input wire clk_in, input wire rst_in, output logic[11:0] amp_out);
  logic signed [11:0]  pre_out;
  assign amp_out = pre_out;
  always_comb begin //always_ff @(posedge clk_in)begin
    if (rst_in)begin
      pre_out = 0;
    end else begin
      case(phase_in)
       5'd0: pre_out=1024;
       5'd1: pre_out=1004;
       5'd2: pre_out=946;
       5'd3: pre_out=851;
       5'd4: pre_out=724;
       5'd5: pre_out=568;
       5'd6: pre_out=391;
       5'd7: pre_out=199;
       5'd8: pre_out=0;
       5'd9: pre_out=-199;
       5'd10: pre_out=-391;
       5'd11: pre_out=-568;
       5'd12: pre_out=-724;
       5'd13: pre_out=-851;
       5'd14: pre_out=-946;
       5'd15: pre_out=-1004;
       5'd16: pre_out=-1024;
       5'd17: pre_out=-1004;
       5'd18: pre_out=-946;
       5'd19: pre_out=-851;
       5'd20: pre_out=-724;
       5'd21: pre_out=-568;
       5'd22: pre_out=-391;
       5'd23: pre_out=-199;
       5'd24: pre_out=0;
       5'd25: pre_out=199;
       5'd26: pre_out=391;
       5'd27: pre_out=568;
       5'd28: pre_out=724;
       5'd29: pre_out=851;
       5'd30: pre_out=946;
       5'd31: pre_out=1004;
     endcase
   end
  end
endmodule

module quantizer_lut(input wire [2:0] u, input wire [2:0] v, input wire is_chrominance, output logic[9:0] inv_divisor);
  always_comb begin
    if (~is_chrominance) begin
        if (u==0 && v==0 ) begin
            inv_divisor = 64;
        end else if (u==1 && v==0 ) begin
            inv_divisor = 93;
        end else if (u==2 && v==0 ) begin
            inv_divisor = 102;
        end else if (u==3 && v==0 ) begin
            inv_divisor = 64;
        end else if (u==4 && v==0 ) begin
            inv_divisor = 43;
        end else if (u==5 && v==0 ) begin
            inv_divisor = 26;
        end else if (u==6 && v==0 ) begin
            inv_divisor = 20;
        end else if (u==7 && v==0 ) begin
            inv_divisor = 17;
        end else if (u==0 && v==1 ) begin
            inv_divisor = 85;
        end else if (u==1 && v==1 ) begin
            inv_divisor = 85;
        end else if (u==2 && v==1 ) begin
            inv_divisor = 73;
        end else if (u==3 && v==1 ) begin
            inv_divisor = 54;
        end else if (u==4 && v==1 ) begin
            inv_divisor = 39;
        end else if (u==5 && v==1 ) begin
            inv_divisor = 18;
        end else if (u==6 && v==1 ) begin
            inv_divisor = 17;
        end else if (u==7 && v==1 ) begin
            inv_divisor = 19;
        end else if (u==0 && v==2 ) begin
            inv_divisor = 73;
        end else if (u==1 && v==2 ) begin
            inv_divisor = 79;
        end else if (u==2 && v==2 ) begin
            inv_divisor = 64;
        end else if (u==3 && v==2 ) begin
            inv_divisor = 43;
        end else if (u==4 && v==2 ) begin
            inv_divisor = 26;
        end else if (u==5 && v==2 ) begin
            inv_divisor = 18;
        end else if (u==6 && v==2 ) begin
            inv_divisor = 15;
        end else if (u==7 && v==2 ) begin
            inv_divisor = 18;
        end else if (u==0 && v==3 ) begin
            inv_divisor = 73;
        end else if (u==1 && v==3 ) begin
            inv_divisor = 60;
        end else if (u==2 && v==3 ) begin
            inv_divisor = 47;
        end else if (u==3 && v==3 ) begin
            inv_divisor = 35;
        end else if (u==4 && v==3 ) begin
            inv_divisor = 20;
        end else if (u==5 && v==3 ) begin
            inv_divisor = 12;
        end else if (u==6 && v==3 ) begin
            inv_divisor = 13;
        end else if (u==7 && v==3 ) begin
            inv_divisor = 17;
        end else if (u==0 && v==4 ) begin
            inv_divisor = 57;
        end else if (u==1 && v==4 ) begin
            inv_divisor = 47;
        end else if (u==2 && v==4 ) begin
            inv_divisor = 28;
        end else if (u==3 && v==4 ) begin
            inv_divisor = 18;
        end else if (u==4 && v==4 ) begin
            inv_divisor = 15;
        end else if (u==5 && v==4 ) begin
            inv_divisor = 9;
        end else if (u==6 && v==4 ) begin
            inv_divisor = 10;
        end else if (u==7 && v==4 ) begin
            inv_divisor = 13;
        end else if (u==0 && v==5 ) begin
            inv_divisor = 43;
        end else if (u==1 && v==5 ) begin
            inv_divisor = 29;
        end else if (u==2 && v==5 ) begin
            inv_divisor = 19;
        end else if (u==3 && v==5 ) begin
            inv_divisor = 16;
        end else if (u==4 && v==5 ) begin
            inv_divisor = 13;
        end else if (u==5 && v==5 ) begin
            inv_divisor = 10;
        end else if (u==6 && v==5 ) begin
            inv_divisor = 9;
        end else if (u==7 && v==5 ) begin
            inv_divisor = 11;
        end else if (u==0 && v==6 ) begin
            inv_divisor = 21;
        end else if (u==1 && v==6 ) begin
            inv_divisor = 16;
        end else if (u==2 && v==6 ) begin
            inv_divisor = 13;
        end else if (u==3 && v==6 ) begin
            inv_divisor = 12;
        end else if (u==4 && v==6 ) begin
            inv_divisor = 10;
        end else if (u==5 && v==6 ) begin
            inv_divisor = 8;
        end else if (u==6 && v==6 ) begin
            inv_divisor = 9;
        end else if (u==7 && v==6 ) begin
            inv_divisor = 10;
        end else if (u==0 && v==7 ) begin
            inv_divisor = 14;
        end else if (u==1 && v==7 ) begin
            inv_divisor = 11;
        end else if (u==2 && v==7 ) begin
            inv_divisor = 11;
        end else if (u==3 && v==7 ) begin
            inv_divisor = 10;
        end else if (u==4 && v==7 ) begin
            inv_divisor = 9;
        end else if (u==5 && v==7 ) begin
            inv_divisor = 10;
        end else if (u==6 && v==7 ) begin
            inv_divisor = 10;
        end else if (u==7 && v==7 ) begin
            inv_divisor = 10;
        end
    end else begin
        if (u==0 && v==0 ) begin
            inv_divisor = 60;
        end else if (u==1 && v==0 ) begin
            inv_divisor = 57;
        end else if (u==2 && v==0 ) begin
            inv_divisor = 43;
        end else if (u==3 && v==0 ) begin
            inv_divisor = 22;
        end else if (u==4 && v==0 ) begin
            inv_divisor = 10;
        end else if (u==5 && v==0 ) begin
            inv_divisor = 10;
        end else if (u==6 && v==0 ) begin
            inv_divisor = 10;
        end else if (u==7 && v==0 ) begin
            inv_divisor = 10;
        end else if (u==0 && v==1 ) begin
            inv_divisor = 57;
        end else if (u==1 && v==1 ) begin
            inv_divisor = 49;
        end else if (u==2 && v==1 ) begin
            inv_divisor = 39;
        end else if (u==3 && v==1 ) begin
            inv_divisor = 16;
        end else if (u==4 && v==1 ) begin
            inv_divisor = 10;
        end else if (u==5 && v==1 ) begin
            inv_divisor = 10;
        end else if (u==6 && v==1 ) begin
            inv_divisor = 10;
        end else if (u==7 && v==1 ) begin
            inv_divisor = 10;
        end else if (u==0 && v==2 ) begin
            inv_divisor = 43;
        end else if (u==1 && v==2 ) begin
            inv_divisor = 39;
        end else if (u==2 && v==2 ) begin
            inv_divisor = 18;
        end else if (u==3 && v==2 ) begin
            inv_divisor = 10;
        end else if (u==4 && v==2 ) begin
            inv_divisor = 10;
        end else if (u==5 && v==2 ) begin
            inv_divisor = 10;
        end else if (u==6 && v==2 ) begin
            inv_divisor = 10;
        end else if (u==7 && v==2 ) begin
            inv_divisor = 10;
        end else if (u==0 && v==3 ) begin
            inv_divisor = 22;
        end else if (u==1 && v==3 ) begin
            inv_divisor = 16;
        end else if (u==2 && v==3 ) begin
            inv_divisor = 10;
        end else if (u==3 && v==3 ) begin
            inv_divisor = 10;
        end else if (u==4 && v==3 ) begin
            inv_divisor = 10;
        end else if (u==5 && v==3 ) begin
            inv_divisor = 10;
        end else if (u==6 && v==3 ) begin
            inv_divisor = 10;
        end else if (u==7 && v==3 ) begin
            inv_divisor = 10;
        end else if (u==0 && v==4 ) begin
            inv_divisor = 10;
        end else if (u==1 && v==4 ) begin
            inv_divisor = 10;
        end else if (u==2 && v==4 ) begin
            inv_divisor = 10;
        end else if (u==3 && v==4 ) begin
            inv_divisor = 10;
        end else if (u==4 && v==4 ) begin
            inv_divisor = 10;
        end else if (u==5 && v==4 ) begin
            inv_divisor = 10;
        end else if (u==6 && v==4 ) begin
            inv_divisor = 10;
        end else if (u==7 && v==4 ) begin
            inv_divisor = 10;
        end else if (u==0 && v==5 ) begin
            inv_divisor = 10;
        end else if (u==1 && v==5 ) begin
            inv_divisor = 10;
        end else if (u==2 && v==5 ) begin
            inv_divisor = 10;
        end else if (u==3 && v==5 ) begin
            inv_divisor = 10;
        end else if (u==4 && v==5 ) begin
            inv_divisor = 10;
        end else if (u==5 && v==5 ) begin
            inv_divisor = 10;
        end else if (u==6 && v==5 ) begin
            inv_divisor = 10;
        end else if (u==7 && v==5 ) begin
            inv_divisor = 10;
        end else if (u==0 && v==6 ) begin
            inv_divisor = 10;
        end else if (u==1 && v==6 ) begin
            inv_divisor = 10;
        end else if (u==2 && v==6 ) begin
            inv_divisor = 10;
        end else if (u==3 && v==6 ) begin
            inv_divisor = 10;
        end else if (u==4 && v==6 ) begin
            inv_divisor = 10;
        end else if (u==5 && v==6 ) begin
            inv_divisor = 10;
        end else if (u==6 && v==6 ) begin
            inv_divisor = 10;
        end else if (u==7 && v==6 ) begin
            inv_divisor = 10;
        end else if (u==0 && v==7 ) begin
            inv_divisor = 10;
        end else if (u==1 && v==7 ) begin
            inv_divisor = 10;
        end else if (u==2 && v==7 ) begin
            inv_divisor = 10;
        end else if (u==3 && v==7 ) begin
            inv_divisor = 10;
        end else if (u==4 && v==7 ) begin
            inv_divisor = 10;
        end else if (u==5 && v==7 ) begin
            inv_divisor = 10;
        end else if (u==6 && v==7 ) begin
            inv_divisor = 10;
        end else if (u==7 && v==7 ) begin
            inv_divisor = 10;
        end
    end
  end

endmodule


`default_nettype wire