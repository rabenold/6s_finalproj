`timescale 1ns / 1ps
`default_nettype none


module frequency_table #(parameter TABLE_SIZE = 256, parameter DATA_WIDTH = 8)(
    input logic clk,
    input rst_in,
    input logic [DATA_WIDTH-1:0] data_in,
    input logic valid_in,
    output logic [31:0] freq_table [TABLE_SIZE-1:0]
);

//table size 256 - track pix vals ranging from 0 to 255 
//create a frequency table 

always_ff @(posedge clk) begin
    if (rst_in ) begin
        //set everything to 0 
        foreach (freq_table[i]) begin
            freq_table[i] <= 32'b0; 
        end 
    end else if (valid_in) begin
        freq_table[data_in]<= freq_table[data_in]+1; 
    end 
end 
endmodule 


`default_nettype wire

