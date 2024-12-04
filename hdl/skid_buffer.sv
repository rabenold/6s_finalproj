`default_nettype none

//based on nice walkthrough and design here:
//https://fpgacpu.ca/fpga/Pipeline_Skid_Buffer.html

module skid_buffer #
	(
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 32,
		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32
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

	logic [C_S00_AXIS_TDATA_WIDTH-1 : 0] tdata_buffer;
  logic [(C_S00_AXIS_TDATA_WIDTH/8)-1: 0] tstrb_buffer;
  logic tlast_buffer;

  enum { EMPTY, BUSY, FULL } state;

  logic insert;
  logic remove;
  always_comb begin
    insert = (s00_axis_tvalid  == 1'b1) && (s00_axis_tready  == 1'b1);
    remove = (m00_axis_tvalid == 1'b1) && (m00_axis_tready == 1'b1);
  end

  logic load; // Empty datapath inserts data into output register.
  logic flow; // New inserted data into output register as the old data is removed.
  logic fill; // New inserted data into buffer register. Data not removed from output register.
  logic flush; // Move data from buffer register into output register. Remove old data. No new data inserted.
  logic unload; // Remove data from output register, leaving the datapath empty.

  always_comb begin
    load    = (state == EMPTY) && (insert == 1'b1) && (remove == 1'b0);
    flow    = (state == BUSY)  && (insert == 1'b1) && (remove == 1'b1);
    fill    = (state == BUSY)  && (insert == 1'b1) && (remove == 1'b0);
    unload  = (state == BUSY)  && (insert == 1'b0) && (remove == 1'b1);
    flush   = (state == FULL)  && (insert == 1'b0) && (remove == 1'b1);
  end
  always_ff @(posedge s00_axis_aclk) begin
    if (~s00_axis_aresetn)begin
      s00_axis_tready <= 1; //on reset set to 1 (ready for data by default)
      state <= EMPTY;
      m00_axis_tvalid <= 0; //on reset set to 0 (assume have nothing)
    end else begin
      case (state)
        EMPTY: begin
          state <=            load? BUSY  :EMPTY;
          m00_axis_tvalid <=  load?1      :0;
          s00_axis_tready <= 1;
        end
        BUSY: begin
          state <=            unload?EMPTY:fill?FULL  :BUSY;
          s00_axis_tready <=  unload?1    :fill?0     :1;
          m00_axis_tvalid <=  unload?0    :fill?1     :1; //make it 0 in example
        end
        FULL: begin
          state <=            flush? BUSY :FULL;
          s00_axis_tready <=  flush? 1    : 0;
          m00_axis_tvalid <= 1;
        end
        default: begin
          state <= EMPTY;
        end
      endcase
    end
  end

  logic data_out_wren;
  logic data_buffer_wren;
  logic use_buffered_data;

  always_comb begin
    data_out_wren     = (load  == 1'b1) || (flow == 1'b1) || (flush == 1'b1);
    data_buffer_wren  = (fill  == 1'b1);
    use_buffered_data = (flush == 1'b1);
  end
  always_ff @(posedge s00_axis_aclk)begin
    if (~s00_axis_aresetn)begin
      tdata_buffer <= 0;
      tstrb_buffer <= 0;
      tlast_buffer <= 0;
    end else if (data_buffer_wren)begin
      tdata_buffer <= s00_axis_tdata;
      tstrb_buffer <= s00_axis_tstrb;
      tlast_buffer <= s00_axis_tlast;
    end
    if (~s00_axis_aresetn)begin
      m00_axis_tdata <= 0;
      m00_axis_tstrb <= 0;
      m00_axis_tlast <= 0;
    end else if (data_out_wren)begin
      m00_axis_tdata <= use_buffered_data?tdata_buffer:s00_axis_tdata;
      m00_axis_tstrb <= use_buffered_data?tstrb_buffer:s00_axis_tstrb;
      m00_axis_tlast <= use_buffered_data?tlast_buffer:s00_axis_tlast;
    end
  end
endmodule

`default_nettype wire
