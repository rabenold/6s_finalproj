module huffman_encoding(
    input logic clk_in,
    input logic rst_in,
    input logic start,
    input logic [7:0] value_in [0:63],   // value array 
    input logic [7:0] count_in [0:63],   // count array 
    output logic [1023:0] code_out,   // 16 * 64
    output logic done
);

    logic [1023:0] huff_code;  // Output Huffman codes for 64 entries
    logic [9:0] counter;  // Counter for looping over 64 entries


    logic [7:0] local_val_in; 
    logic [7:0] local_count_in;
    logic [15:0] local_huff_code; 

    huffman_lut lut_inst (
        .value(local_val_in),        // Input value
        .count(local_huff_code),        // Input count
        .huff_code(local_huff_code)       // Output huffman code
    );

    // input logic [7:0] value, 
    // input logic [7:0] count,
    // output logic [15:0] huff_code 

    logic flag;
    logic code_done; 
    always_ff @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            counter <= 0;
            code_done <=0; 
            huff_code <= 0;
            done <= 0;
            local_val_in <= 0; 
            local_count_in <= 0;
            local_huff_code <=0;
            flag<=0; 
        end
        else begin
            if (counter<64)begin
                //load data every cycle      
                local_val_in <= value_in[counter];
                local_count_in <= count_in[counter]; 
                counter <= counter + 1; 
            end
            else begin
                //last one.
                code_done<= 1;
                huff_code[counter*16 +: 16] <= local_huff_code; 

            end  
            if(!flag) begin
                //load data on first cycle. wait 1
                flag <= 1; 
            end 
            else begin
                huff_code[counter*16 +: 16] <= local_huff_code; 
            end 

        end
    end

    always_comb begin
        done = 1; 
        code_out = huff_code;
    end 
endmodule



