`timescale 1ns / 1ps
`default_nettype none // prevents system from inferring an undeclared logic (good practice)
 
module tmds_encoder(
  input wire clk_in,
  input wire rst_in,
  input wire [7:0] data_in,  // video data (red, green or blue)
  input wire [1:0] control_in, //for blue set to {vs,hs}, else will be 0
  input wire ve_in,  // video data enable, to choose between control or video signal
  output logic [9:0] tmds_out
);
 
  logic [8:0] q_m;
 
  tm_choice mtm(
    .data_in(data_in),
    .qm_out(q_m));
 
  //your code here.
  logic [4:0] tally;
  logic [4:0] num_ones;
  logic [4:0] num_zeroes;

  assign num_ones = $countones(q_m[7:0]);
  assign num_zeroes = 8 - $countones(q_m[7:0]);

  always_ff @(posedge clk_in) begin
      if(rst_in) begin
          tally <= 0;
          tmds_out <= 0;
      end else if (ve_in) begin
          if (tally == 0 || num_ones == num_zeroes) begin
              tmds_out[9] <= ~q_m[8];
              tmds_out[8] <= q_m[8];
              tmds_out[7:0] <= (q_m[8])? q_m[7:0]:~q_m[7:0];
              if (q_m[8] == 0) begin
                  tally <= tally + (num_zeroes - num_ones);
              end else begin
                  tally <= tally + (num_ones - num_zeroes);
              end
          end else begin
              if ((~tally[4] && num_ones > num_zeroes) || (tally[4] && num_zeroes > num_ones)) begin
                  tmds_out[9] <= 1;
                  tmds_out[8] <= q_m[8];
                  tmds_out[7:0] <= ~q_m[7:0];
                  tally <= tally + 2*q_m[8] + (num_zeroes - num_ones);
              end else begin
                  tmds_out[9] <= 0;
                  tmds_out[8] <= q_m[8];
                  tmds_out[7:0] <= q_m[7:0];
                  //tally <= (q_m[8])? (tally + (num_ones - num_zeroes)):(tally - 2 + (num_ones - num_zeroes));
                  tally <= tally - 2*!q_m[8] + (num_ones - num_zeroes);
              end
          end
      end else begin
          tally <= 0;
          case(control_in)
            2'b00: tmds_out <= 10'b1101010100;
            2'b01: tmds_out <= 10'b0010101011;
            2'b10: tmds_out <= 10'b0101010100;
            2'b11: tmds_out <= 10'b1010101011;
          endcase
      end
  end

 
endmodule
 
`default_nettype wire