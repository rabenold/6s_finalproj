module huffman_lut (
    input logic [7:0] value,
    input logic [7:0] count,
    output logic [15:0] huff_code 
);

//bigass lut for huffman codes 
// from https://www.w3.org/Graphics/JPEG/itu-t81.pdf
//(run,size) 
always_comb begin
    if (value == 8'b0 && count == 0)
        huff_code = 1'b0;
    else if (value == 0 && count == 1)
        huff_code = 2'b01; 
    else if (value == 0 && count == 2)
        huff_code = 3'b100;
    else if (value == 0 && count == 3)
        huff_code = 4'b1010;    
    else if (value == 0 && count == 4)
        huff_code = 5'b11000;
    else if (value == 0 && count == 5)
        huff_code = 5'b11001;
    else if (value == 0 && count == 6)
        huff_code = 6'b111000;
    else if (value == 0 && count == 7)
        huff_code = 7'b1111000;
    else if (value == 0 && count == 8)
        huff_code = 9'b111110100;
    else if (value == 0 && count == 9)
        huff_code = 10'b1111110110;
    else if (value == 0 && count == 10)
        huff_code = 12'b111111110100;
    else if (value == 1 && count == 1)
        huff_code = 4'b1011;
    else if (value == 1 && count == 2)
        huff_code = 6'b111001;
    else if (value == 1 && count == 3)
        huff_code = 8'b11110110;
    else if (value == 1 && count == 4)
        huff_code = 9'b111110101;
    else if (value == 1 && count == 5)
        huff_code = 11'b11111110110;
    else if (value == 1 && count == 6)
        huff_code = 12'b111111110101;
    else if (value == 1 && count == 7)
        huff_code = 16'b1111111110001000;
    else if (value == 1 && count == 8)
        huff_code = 16'b1111111110001001;
    else if (value == 1 && count == 9)
        huff_code = 16'b1111111110001010;
    else if (value == 1 && count == 10)
        huff_code = 16'b1111111110001011;
    else if (value == 2 && count == 1)
        huff_code = 5'b11010;
    else if (value == 2 && count == 2)
        huff_code = 8'b11110111;
    else if (value == 2 && count == 3)
        huff_code = 10'b1111110111;
    else if (value == 2 && count == 4)
        huff_code = 12'b111111110110;
    else if (value == 2 && count == 5)
        huff_code = 12'b111111111000010;
    else if (value == 2 && count == 6)
        huff_code = 12'b1111111110001100;
    else if (value == 2 && count == 7)
        huff_code = 12'b1111111110001101;
    else if (value == 2 && count == 8)
        huff_code = 12'b1111111110001110;
    else if (value == 2 && count == 9)
        huff_code = 12'b1111111110001111;
    else if (value == 2 && count == 10)
        huff_code = 13'b1111111110010000;
    else if (value == 3 && count == 1)
        huff_code = 5'b11011;
    else if (value == 3 && count == 2)
        huff_code = 8'b11111000;
    else if (value == 3 && count == 3)
        huff_code = 10'b1111111000;
    else if (value == 3 && count == 4)
        huff_code = 12'b111111110111;
    else if (value == 3 && count == 5)
        huff_code = 13'b1111111110010001;
    else if (value == 3 && count == 6)
        huff_code = 13'b1111111110010010;
    else if (value == 3 && count == 7)
        huff_code = 13'b1111111110010011;
    else if (value == 3 && count == 8)
        huff_code = 13'b1111111110010100;
    else if (value == 3 && count == 9)
        huff_code = 13'b1111111110010101;
    else if (value == 3 && count == 10)
        huff_code = 13'b1111111110010110;
    else if (value == 4 && count == 1)
        huff_code = 6'b111010;
    else if (value == 4 && count == 2)
        huff_code = 9'b111110110;
    else if (value == 4 && count == 3)
        huff_code = 13'b1111111110010111;
    else if (value == 4 && count == 4)
        huff_code = 13'b1111111110011000;
    else if (value == 4 && count == 5)
        huff_code = 13'b1111111110011001;
    else if (value == 4 && count == 6)
        huff_code = 13'b1111111110011010;
    else if (value == 4 && count == 7)
        huff_code = 13'b1111111110011011;
    else if (value == 4 && count == 8)
        huff_code = 13'b1111111110011100;
    else if (value == 4 && count == 9)
        huff_code = 13'b1111111110011101;
    else if (value == 4 && count == 10)
        huff_code = 13'b1111111110011110;
    else if (value == 5 && count == 1)
        huff_code = 7'b111011;
    else if (value == 5 && count == 2)
        huff_code = 10'b1111111001;
    else if (value == 5 && count == 3)
        huff_code = 13'b1111111110011111;
    else if (value == 5 && count == 4)
        huff_code = 13'b1111111110100000;
    else if (value == 5 && count == 5)
        huff_code = 13'b1111111110100001;
    else if (value == 5 && count == 6)
        huff_code = 13'b1111111110100010;
    else if (value == 5 && count == 7)
        huff_code = 13'b1111111110100011;
    else if (value == 5 && count == 8)
        huff_code = 13'b1111111110100100;
    else if (value == 5 && count == 9)
        huff_code = 13'b1111111110100101;
    else if (value == 5 && count == 10)
        huff_code = 13'b1111111110100110;
    else if (value == 6 && count == 1)
        huff_code = 7'b1111001;
    else if (value == 6 && count == 2)
        huff_code = 11'b11111110111;
    else if (value == 6 && count == 3)
        huff_code = 13'b1111111110100111;
    else if (value == 6 && count == 4)
        huff_code = 13'b1111111110101000;
    else if (value == 6 && count == 5)
        huff_code = 13'b1111111110101001;
    else if (value == 6 && count == 6)
        huff_code = 13'b1111111110101010;
    else if (value == 6 && count == 7)
        huff_code = 13'b1111111110101011;
    else if (value == 6 && count == 8)
        huff_code = 13'b1111111110101100;
    else if (value == 6 && count == 9)
        huff_code = 13'b1111111110101101;
    else if (value == 6 && count == 10)
        huff_code = 13'b1111111110101110;
    else if (value == 7 && count == 1)
        huff_code = 7'b1111010;
    else if (value == 7 && count == 2)
        huff_code = 11'b11111111000;
    else if (value == 7 && count == 3)
        huff_code = 13'b1111111110101111;
    else if (value == 7 && count == 4)
        huff_code = 13'b1111111110110000;
    else if (value == 7 && count == 5)
        huff_code = 13'b1111111110110001;
    else if (value == 7 && count == 6)
        huff_code = 13'b1111111110110010;
    else if (value == 7 && count == 7)
        huff_code = 13'b1111111110110011;
    else if (value == 7 && count == 8)
        huff_code = 13'b1111111110110100;
    else if (value == 7 && count == 9)
        huff_code = 13'b1111111110110101;
    else if (value == 7 && count == 10)
        huff_code = 13'b1111111110110110;
    else if (value == 8 && count == 1)
        huff_code = 8'b11111001;
    else if (value == 8 && count == 2)
        huff_code = 13'b1111111110110111;
    else if (value == 8 && count == 3)
        huff_code = 13'b1111111110111000;
    else if (value == 8 && count == 4)
        huff_code = 13'b1111111110111001;
    else if (value == 8 && count == 5)
        huff_code = 13'b1111111110111010;
    else if (value == 8 && count == 6)
        huff_code = 13'b1111111110111011;
    else if (value == 8 && count == 7)
        huff_code = 13'b1111111110111100;
    else if (value == 8 && count == 8)
        huff_code = 13'b1111111110111101;
    else if (value == 8 && count == 9)
        huff_code = 13'b1111111110111110;
    else if (value == 8 && count == 10)
        huff_code = 13'b1111111110111111;
    else if (value == 9 && count == 1)
        huff_code = 9'b111110111;
    else if (value == 9 && count == 2)
        huff_code = 16'b1111111111000000;
    else if (value == 9 && count == 3)
        huff_code = 16'b1111111111000001;
    else if (value == 9 && count == 4)
        huff_code = 16'b1111111111000010;
    else if (value == 9 && count == 5)
        huff_code = 16'b1111111111000011;
    else if (value == 9 && count == 6)
        huff_code = 16'b1111111111000100;
    else if (value == 9 && count == 7)
        huff_code = 16'b1111111111000101;
    else if (value == 9 && count == 8)
        huff_code = 16'b1111111111000110;
    else if (value == 9 && count == 9)
        huff_code = 16'b1111111111000111;
    else if (value == 9 && count == 10)
        huff_code = 16'b1111111111001000;
    else if (value == 'A' && count == 1)
        huff_code = 9'b111111000;
    else if (value == 'A' && count == 2)
        huff_code = 16'b1111111;
    else if (value == 'C' && count == 6)
        huff_code = 16'b1111111111011111;
    else if (value == 'C' && count == 7)
        huff_code = 16'b1111111111100000;
    else if (value == 'C' && count == 8)
        huff_code = 16'b1111111111100001;
    else if (value == 'C' && count == 9)
        huff_code = 16'b1111111111100010;
    else if (value == 'C' && count == 'A')
        huff_code = 16'b1111111111100011;
    else if (value == 'D' && count == 1)
        huff_code = 11'b11111111001;
    else if (value == 'D' && count == 2)
        huff_code = 16'b1111111111100100;
    else if (value == 'D' && count == 3)
        huff_code = 16'b1111111111100101;
    else if (value == 'D' && count == 4)
        huff_code = 16'b1111111111100110;
    else if (value == 'D' && count == 5)
        huff_code = 16'b1111111111100111;
    else if (value == 'D' && count == 6)
        huff_code = 16'b1111111111101000;
    else if (value == 'D' && count == 7)
        huff_code = 16'b1111111111101001;
    else if (value == 'D' && count == 8)
        huff_code = 16'b1111111111101010;
    else if (value == 'D' && count == 9)
        huff_code = 16'b1111111111101011;
    else if (value == 'D' && count == 'A')
        huff_code = 16'b1111111111101100;
    else if (value == 'E' && count == 1)
        huff_code = 14'b11111111100000;
    else if (value == 'E' && count == 2)
        huff_code = 16'b1111111111101101;
    else if (value == 'E' && count == 3)
        huff_code = 16'b1111111111101110;
    else if (value == 'E' && count == 4)
        huff_code = 16'b1111111111101111;
    else if (value == 'E' && count == 5)
        huff_code = 16'b1111111111110000;
    else if (value == 'E' && count == 6)
        huff_code = 16'b1111111111110001;
    else if (value == 'E' && count == 7)
        huff_code = 16'b1111111111110010;
    else if (value == 'E' && count == 8)
        huff_code = 16'b1111111111110011;
    else if (value == 'E' && count == 9)
        huff_code = 16'b1111111111110100;
    else if (value == 'E' && count == 'A')
        huff_code = 16'b1111111111110101;
    else if (value == 'F' && count == 0)
        huff_code = 10'b1111111010;
    else if (value == 'F' && count == 1)
        huff_code = 14'b111111111000011;
    else if (value == 'F' && count == 2)
        huff_code = 16'b1111111111110110;
    else if (value == 'F' && count == 3)
        huff_code = 16'b1111111111110111;
    else if (value == 'F' && count == 4)
        huff_code = 16'b1111111111111000;
    else if (value == 'F' && count == 5)
        huff_code = 16'b1111111111111001;
    else if (value == 'F' && count == 6)
        huff_code = 16'b1111111111111010;
    else if (value == 'F' && count == 7)
        huff_code = 16'b1111111111111011;
    else if (value == 'F' && count == 8)
        huff_code = 16'b1111111111111100;
    else if (value == 'F' && count == 9)
        huff_code = 16'b1111111111111101;
    else if (value == 'F' && count == 'A')
        huff_code = 16'b1111111111111110;
    end 
endmodule

