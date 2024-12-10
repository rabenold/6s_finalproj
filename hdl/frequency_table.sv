
`timescale 1ns / 1ps
`default_nettype none


// 10 bit or 12 bit data width or 16 
// 16 for safety 
module frequency_table #(parameter TABLE_SIZE = 256, parameter DATA_WIDTH = 16)(
    input logic clk_in,
    input rst_in,
    input logic [DATA_WIDTH-1:0] data_in,
    input logic valid_in,
    output logic [7:0] freq_table_out [TABLE_SIZE-1:0],
    output logic ready
);
//log2(256) -> 8 hence [7:0]
//table size 256 - track pix vals ranging from 0 to 255 
//create a frequency table 
logic [7:0] count; 
logic [7:0] temp [TABLE_SIZE-1:0];
logic done; 

initial begin
    // Reset all elements of the temp array to 0
    for (int i = 0; i < TABLE_SIZE; i = i + 1) begin
        temp[i] = 0;
    end
    ready<=1;

end

always_ff @(posedge clk_in) begin
    if (rst_in) begin
        //set everything to 0 
        count<=0;
        done<=0;
    end 

    else if (ready && valid_in && count<TABLE_SIZE+1) begin
        count<=count+1; 
        
        temp[data_in] <= temp[data_in]+1;
    end 
    else if (count == TABLE_SIZE && !done)begin
        done<=1;      
        ready<=0; 
    end 

end 
assign freq_table_out = temp;

endmodule 

//have raw data that's been compressed. jpg file headers and stuff 
// put on hardware 

`default_nettype wire

