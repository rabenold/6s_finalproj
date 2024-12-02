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
  output logic vs_out, //vertical sync out, high in v sync 
  output logic hs_out, //horizontal sync out, high in h sync 
  output logic ad_out, // low in blanking or sync 
  output logic nf_out, //single cycle enable signal... h = 1280, v = 720 
  output logic [5:0] fc_out); //frame

  localparam H_max = ACTIVE_H_PIXELS+H_FRONT_PORCH+H_SYNC_WIDTH+H_BACK_PORCH; 
  localparam V_max = ACTIVE_LINES+V_FRONT_PORCH+V_SYNC_WIDTH+V_BACK_PORCH; 
  localparam TOTAL_PIXELS = H_max; 
  localparam TOTAL_LINES = V_max; 
  

  logic [$clog2(TOTAL_PIXELS)-1:0] hcount;
  logic [$clog2(TOTAL_PIXELS)-1:0] vcount;

  always_ff @(posedge pixel_clk_in) begin
    if(rst_in)begin
      hcount <= 0;
      vcount <= 0;
      ad_out <= 0;
      fc_out <= 0;
      vs_out <= 0;
      hs_out <= 0; 
      nf_out <= 0;  
      hcount_out <= 0; 
      vcount_out <= 0; 
    end 
    else begin
      //incrementing on the pixel clock  
      hcount <= hcount<H_max ? hcount+1 : 0; 
      if (hcount == H_max)  
        vcount <= vcount+1;
      else if (vcount == V_max)
        vcount <= 0;
      else vcount <= vcount;
    end 
  end 
always_comb begin
  //comb stuff 
  if (!rst_in) begin
    hcount_out = hcount; 
    vcount_out = vcount; 
    fc_out = hcount == ACTIVE_H_PIXELS && vcount == ACTIVE_LINES ? fc_out + 1 : fc_out;   
    vs_out = vcount > TOTAL_LINES-1 ? 1 : 0;
    hs_out = hcount > ACTIVE_H_PIXELS ? 1 : 0; 

    ad_out = hcount >= ACTIVE_H_PIXELS || vcount >= ACTIVE_LINES ? 0 : 1;  
    nf_out = hcount == ACTIVE_H_PIXELS && vcount == ACTIVE_LINES ? 1 : 0;    
  end  
end 
endmodule






`default_nettype wire // prevents system from inferring an undeclared logic (good practice)
