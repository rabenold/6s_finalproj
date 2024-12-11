`timescale 1ns / 1ps
`default_nettype none
module jpeg_encoder
  (
    parameter integer C_S00_AXIS_TDATA_WIDTH  = 32,
    parameter integer C_M00_AXIS_TDATA_WIDTH  = 32
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
     
     //move these to top level?
  //fill a frame buffer using one clock
  //use the push of a button to start reading from the frame buffer

  logic [7:0] r_in, g_in, b_in;
    assign r_in = s00_axis_tdata[23:16];
    assign g_in = s00_axis_tdata[15:8];
    assign b_in = s00_axis_tdata[7:0];
  	logic [19:0] yr;
    logic [19:0] yg;
    logic [19:0] yb;
    logic valids [1:0];
    logic valid_pixel;
    logic signed [7:0] pixel_in;


    always_ff @(posedge s00_axis_aclk) begin
        if (~s00_axis_aresetn) begin
            yr <= 0;
            yg <= 0;
            yb <= 0;
            valids[0] <= 0;
            valids[1] <= 0;
            valid_pixel <= 0;
            pixel_in <= 0
        end else begin
            if (s00_axis_tvalid && m00_axis_tready) begin
                yr[0] <= 10'h132 * r_in;
                yg[0] <= 10'h259 * g_in;
                yb[0] <= 10'h074 * b_in;
                valids[0] <= 1;
            end else begin
                valids[0] <= 0;
            end

            if (valids[0]) begin
                y1[0] <= yr[0] + yg[0] + yb[0];
                valids[1] <= 1;
            end else begin
                valids[1] <= 0;
            end

            if (valids[1]) begin
                valid_pixel <= 1;
                pixel_in <= y1[17:10] - 128;
            end else begin
                valid_pixel <= 0;
            end
        end    
    end
  
  //read one value out at a time
  //pipeline that read out value first into the YCrCb (notably can just get y)
  // subtract 128 from  (~3 clock cycles, needs to be pipelined then)
  //feed this value into the DCT module

  logic signed [10:0] dct_out [7:0][7:0];
  logic dct_out_ready;

  dct_block #
  (
    .C_S00_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH),
    .C_M00_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH),
    .IS_CHROMINANCE(0)
  )
  dct_that_might_work (
  // Ports of Axi Slave Bus Interface S00_AXIS
  .s00_axis_aclk(s00_axis_aclk), 
  .s00_axis_aresetn(s00_axis_aresetn),
  .s00_axis_tlast(s00_axis_tlast), 
  .s00_axis_tvalid(valid_pixel),
  .s00_axis_tdata(pixel_in),
  .s00_axis_tstrb(s00_axis_tstrb),
  .s00_axis_tready(),
 
  // Ports of Axi Master Bus Interface M00_AXIS
  .m00_axis_aclk(), 
  .m00_axis_aresetn(),
  .m00_axis_tready(),
  .m00_axis_tvalid(), 
  .m00_axis_tlast(),
  .m00_axis_tdata(),
  .m00_axis_tstrb(),
  
  //non AXI outputs for actual use
  .dct_out(dct_out),
  .dct_out_ready(dct_out_ready)
  );

  logic signed [10:0] zig_zag_dct [7:0][7:0];

  zig_zagger #(
    .DATA_WIDTH(11),
    .WITDH(8), 
    .HEIGHT(8))
  zig_zags (
        .input_matrix(dct_out),
        .zig_zag_out(zig_zag_dct),
    );

  // after ~64 cycles the DCT module will spit out a 8x8 matrix

    rle_encoder (
        .clk_in(s00_axis_aclk),
        .valid_in, 
        .rst_in,
        .data_in(zig_zag_dct),       // 64 elements
        .run_value(),   // Store up to 64 elements in 8-bit wide
        .run_count(),   // Store up to 64 counts in 8-bit wide
        .done(),                      // Done signal
        .indiv_elms()   //for counting how many unique elements 
    );

  // give that 8x8 matrix to the huffman stuff
  // use the output of huffman as transmission over UART
  //in top level

endmodule

`default_nettype wire

