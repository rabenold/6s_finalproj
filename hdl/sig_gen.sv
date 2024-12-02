`timescale 1ns / 1ps
`default_nettype none

module video_sig_gen
#(
  parameter ACTIVE_H_PIXELS = 1280,
  parameter H_FRONT_PORCH = 110,
  parameter H_SYNC_WIDTH = 40,
  parameter H_BACK_PORCH = 220,
  parameter ACTIVE_LINES = 720,
  parameter V_FRONT_PORCH = 5,
  parameter V_SYNC_WIDTH = 5,
  parameter V_BACK_PORCH = 20,
  parameter FPS = 60)
(
  input wire pixel_clk_in,
  input wire rst_in,
  output logic [$clog2(TOTAL_PIXELS)-1:0] hcount_out,
  output logic [$clog2(TOTAL_LINES)-1:0] vcount_out,
  output logic vs_out, //vertical sync out
  output logic hs_out, //horizontal sync out
  output logic ad_out,
  output logic nf_out, //single cycle enable signal
  output logic [5:0] fc_out); //frame

  localparam TOTAL_PIXELS = 0; //figure this out
  localparam TOTAL_LINES = 0; //figure this out

  logic [$clog2(TOTAL_PIXELS)-1:0] hcount;
  logic [$clog2(TOTAL_PIXELS)-1:0] vcount;

  always_ff @( pixel_clk_in ) begin
    if(rst_in)begin
        hcount_out <= 0; 
        vcount_out <= 0; 
        vs_out <= 0;
        hs_out <= 0; 
        ad_out <= 0; 
        nf_out <= 0;
        fc_out <= 5'b0; 

    end 



    
  end


endmodule


`default_nettype wire // prevents system from inferring an undeclared logic (good practice)
