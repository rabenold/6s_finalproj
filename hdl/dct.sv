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
    output logic [63:0] val_out,
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

  assign temp_val_out = $signed(pre_out>>>$signed(30));
  assign val_out = temp_val_out;

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
    end else begin
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
            pre_out <= cum_sum*$signed(alpha_coeff);
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
    parameter integer C_M00_AXIS_TDATA_WIDTH  = 64
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
  output logic [(C_M00_AXIS_TDATA_WIDTH/8)-1: 0] m00_axis_tstrb
  );

  logic ready_in [7:0][7:0];
  logic ready_out [7:0][7:0];
  logic signed [63:0] val_out [7:0][7:0];
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
                .val_out(val_out[u][v]),
                .ready_out(ready_out[u][v])
            );

            always_ff @(posedge s00_axis_aclk) begin
                if (~s00_axis_aresetn) begin
                    ready_in[u][v] <= 0;
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
                            completed_dct[(v<<3)+u] = 1'b1;
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
                
                m00_axis_tdata <= val_out[out_x_count][out_y_count];

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


`default_nettype wire