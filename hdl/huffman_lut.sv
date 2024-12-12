
module huffman_lut (
    input logic [7:0] value,
    input logic [7:0] count,
    output logic [15:0] huff_code
);

//bigass lut for huffman codes 
// from https://www.w3.org/Graphics/JPEG/itu-t81.pdf
//(run,size) \

always_comb begin
    if (value == 8'b0 && count == 0)begin
        huff_code = 1'b0;
    end else if (value == 0 && count == 1)begin
        huff_code = 2'b01; 
    end else if (value == 0 && count == 2)begin
        huff_code = 3'b100;
    end else if (value == 0 && count == 3)begin
        huff_code = 4'b1010;    
    end else if (value == 0 && count == 4)begin
        huff_code = 5'b11000;
    end else if (value == 0 && count == 5)begin
        huff_code = 5'b11001;
    end else if (value == 0 && count == 6)begin
        huff_code = 6'b111000;
    end else if (value == 0 && count == 7)begin
        huff_code = 7'b1111000;
    end else if (value == 0 && count == 8)begin
        huff_code = 9'b111110100;
    end else if (value == 0 && count == 9)begin
        huff_code = 10'b1111110110;
    end else if (value == 0 && count == 10)begin
        huff_code = 12'b111111110100;
    end else if (value == 1 && count == 1)begin
        huff_code = 4'b1011;
    end else if (value == 1 && count == 2)begin
        huff_code = 6'b111001;
    end else if (value == 1 && count == 3)begin
        huff_code = 8'b11110110;
    end else if (value == 1 && count == 4)begin
        huff_code = 9'b111110101;
    end else if (value == 1 && count == 5)begin
        huff_code = 11'b11111110110;
    end else if (value == 1 && count == 6)begin
        huff_code = 12'b111111110101;
    end else if (value == 1 && count == 7)begin
        huff_code = 16'b1111111110001000;
    end else if (value == 1 && count == 8)begin
        huff_code = 16'b1111111110001001;
    end else if (value == 1 && count == 9)begin
        huff_code = 16'b1111111110001010;
    end else if (value == 1 && count == 10)begin
        huff_code = 16'b1111111110001011;
    end else if (value == 2 && count == 1)begin
        huff_code = 5'b11010;
    end else if (value == 2 && count == 2)begin
        huff_code = 8'b11110111;
    end else if (value == 2 && count == 3)begin
        huff_code = 10'b1111110111;
    end else if (value == 2 && count == 4)begin
        huff_code = 16'b111111110110;
    end else if (value == 2 && count == 5)begin
        huff_code = 16'b111111111000010;
    end else if (value == 2 && count == 6)begin
        huff_code = 16'b1111111110001100;
    end else if (value == 2 && count == 7)begin
        huff_code = 16'b1111111110001101;
    end else if (value == 2 && count == 8)begin
        huff_code = 16'b1111111110001110;
    end else if (value == 2 && count == 9)begin
        huff_code = 16'b1111111110001111;
    end else if (value == 2 && count == 10)begin
        huff_code = 16'b1111111110010000;
    end else if (value == 3 && count == 1)begin
        huff_code = 5'b11011;
    end else if (value == 3 && count == 2)begin
        huff_code = 8'b11111000;
    end else if (value == 3 && count == 3)begin
        huff_code = 10'b1111111000;
    end else if (value == 3 && count == 4)begin
        huff_code = 16'b111111110111;
    end else if (value == 3 && count == 5)begin
        huff_code = 16'b1111111110010001;
    end else if (value == 3 && count == 6)begin
        huff_code = 16'b1111111110010010;
    end else if (value == 3 && count == 7)begin
        huff_code = 16'b1111111110010011;
    end else if (value == 3 && count == 8)begin
        huff_code = 16'b1111111110010100;
    end else if (value == 3 && count == 9)begin
        huff_code = 16'b1111111110010101;
    end else if (value == 3 && count == 10)begin
        huff_code = 16'b1111111110010110;
    end else if (value == 4 && count == 1)begin
        huff_code = 6'b111010;
    end else if (value == 4 && count == 2)begin
        huff_code = 9'b111110110;
    end else if (value == 4 && count == 3)begin
        huff_code = 16'b1111111110010111;
    end else if (value == 4 && count == 4)begin
        huff_code = 16'b1111111110011000;
    end else if (value == 4 && count == 5)begin
        huff_code = 16'b1111111110011001;
    end else if (value == 4 && count == 6)begin
        huff_code = 16'b1111111110011010;
    end else if (value == 4 && count == 7)begin
        huff_code = 16'b1111111110011011;
    end else if (value == 4 && count == 8)begin
        huff_code = 16'b1111111110011100;
    end else if (value == 4 && count == 9)begin
        huff_code = 16'b1111111110011101;
    end else if (value == 4 && count == 10)begin
        huff_code = 16'b1111111110011110;
    end else if (value == 5 && count == 1)begin
        huff_code = 7'b111011;
    end else if (value == 5 && count == 2)begin
        huff_code = 16'b1111111001;
    end else if (value == 5 && count == 3)begin
        huff_code = 16'b1111111110011111;
    end else if (value == 5 && count == 4)begin
        huff_code = 16'b1111111110100000;
    end else if (value == 5 && count == 5)begin
        huff_code = 16'b1111111110100001;
    end else if (value == 5 && count == 6)begin
        huff_code = 16'b1111111110100010;
    end else if (value == 5 && count == 7)begin
        huff_code = 16'b1111111110100011;
    end else if (value == 5 && count == 8)begin
        huff_code = 16'b1111111110100100;
    end else if (value == 5 && count == 9)begin
        huff_code = 16'b1111111110100101;
    end else if (value == 5 && count == 10)begin
        huff_code = 16'b1111111110100110;
    end else if (value == 6 && count == 1)begin
        huff_code = 7'b1111001;
    end else if (value == 6 && count == 2)begin
        huff_code = 16'b11111110111;
    end else if (value == 6 && count == 3)begin
        huff_code = 16'b1111111110100111;
    end else if (value == 6 && count == 4)begin
        huff_code = 16'b1111111110101000;
    end else if (value == 6 && count == 5)begin
        huff_code = 16'b1111111110101001;
    end else if (value == 6 && count == 6)begin
        huff_code = 16'b1111111110101010;
    end else if (value == 6 && count == 7)begin
        huff_code = 16'b1111111110101011;
    end else if (value == 6 && count == 8)begin
        huff_code = 16'b1111111110101100;
    end else if (value == 6 && count == 9)begin
        huff_code = 16'b1111111110101101;
    end else if (value == 6 && count == 10)begin
        huff_code = 16'b1111111110101110;
    end else if (value == 7 && count == 1)begin
        huff_code = 7'b1111010;
    end else if (value == 7 && count == 2)begin
        huff_code = 16'b11111111000;
    end else if (value == 7 && count == 3)begin
        huff_code = 16'b1111111110101111;
    end else if (value == 7 && count == 4)begin
        huff_code = 16'b1111111110110000;
    end else if (value == 7 && count == 5)begin
        huff_code = 16'b1111111110110001;
    end else if (value == 7 && count == 6)begin
        huff_code = 16'b1111111110110010;
    end else if (value == 7 && count == 7)begin
        huff_code = 16'b1111111110110011;
    end else if (value == 7 && count == 8)begin
        huff_code = 16'b1111111110110100;
    end else if (value == 7 && count == 9)begin
        huff_code = 16'b1111111110110101;
    end else if (value == 7 && count == 10)begin
        huff_code = 16'b1111111110110110;
    end else if (value == 8 && count == 1)begin
        huff_code = 8'b11111001;
    end else if (value == 8 && count == 2)begin
        huff_code = 16'b1111111110110111;
    end else if (value == 8 && count == 3)begin
        huff_code = 16'b1111111110111000;
    end else if (value == 8 && count == 4)begin
        huff_code = 16'b1111111110111001;
    end else if (value == 8 && count == 5)begin
        huff_code = 16'b1111111110111010;
    end else if (value == 8 && count == 6)begin
        huff_code = 16'b1111111110111011;
    end else if (value == 8 && count == 7)begin
        huff_code = 16'b1111111110111100;
    end else if (value == 8 && count == 8)begin
        huff_code = 16'b1111111110111101;
    end else if (value == 8 && count == 9)begin
        huff_code = 16'b1111111110111110;
    end else if (value == 8 && count == 10)begin
        huff_code = 16'b1111111110111111;
    end else if (value == 9 && count == 1)begin
        huff_code = 9'b111110111;
    end else if (value == 9 && count == 2)begin
        huff_code = 16'b1111111111000000;
    end else if (value == 9 && count == 3)begin
        huff_code = 16'b1111111111000001;
    end else if (value == 9 && count == 4)begin
        huff_code = 16'b1111111111000010;
    end else if (value == 9 && count == 5)begin
        huff_code = 16'b1111111111000011;
    end else if (value == 9 && count == 6)begin
        huff_code = 16'b1111111111000100;
    end else if (value == 9 && count == 7)begin
        huff_code = 16'b1111111111000101;
    end else if (value == 9 && count == 8)begin
        huff_code = 16'b1111111111000110;
    end else if (value == 9 && count == 9)begin
        huff_code = 16'b1111111111000111;
    end else if (value == 9 && count == 10)begin
        huff_code = 16'b1111111111001000;
   
    end else if (value == 10 && count == 1)begin
        huff_code = 9'b111111000;
    end else if (value == 10 && count == 2)begin
        huff_code = 16'b1111111; 
    end else if (value == 12 && count == 6)begin
        huff_code = 16'b1111111111011111;
    end else if (value == 12 && count == 7)begin
        huff_code = 16'b1111111111100000;
    end else if (value == 12 && count == 8)begin
        huff_code = 16'b1111111111100001;
    end else if (value == 12 && count == 9)begin
        huff_code = 16'b1111111111100010;
    end else if (value == 12 && count == 10)begin
        huff_code = 16'b1111111111100011;
    end else if (value == 13 && count == 1)begin
        huff_code = 11'b11111111001;
    end else if (value == 13 && count == 2)begin
        huff_code = 16'b1111111111100100;
    end else if (value == 13 && count == 3)begin
        huff_code = 16'b1111111111100101;
    end else if (value == 13 && count == 4)begin
        huff_code = 16'b1111111111100110;
    end else if (value == 13 && count == 5)begin
        huff_code = 16'b1111111111100111;
    end else if (value == 13 && count == 6)begin
        huff_code = 16'b1111111111101000;
    end else if (value == 13 && count == 7)begin
        huff_code = 16'b1111111111101001;
    end else if (value == 13 && count == 8)begin
        huff_code = 16'b1111111111101010;
    end else if (value == 13 && count == 9)begin
        huff_code = 16'b1111111111101011;
    end else if (value == 13 && count == 10)begin
        huff_code = 16'b1111111111101100;
    end else if (value == 14 && count == 1)begin
        huff_code = 14'b11111111100000;
    end else if (value == 14 && count == 2)begin
        huff_code = 16'b1111111111101101;
    end else if (value == 14 && count == 3)begin
        huff_code = 16'b1111111111101110;
    end else if (value == 14 && count == 4)begin
        huff_code = 16'b1111111111101111;
    end else if (value == 14 && count == 5)begin
        huff_code = 16'b1111111111110000;
    end else if (value == 14 && count == 6)begin
        huff_code = 16'b1111111111110001;
    end else if (value == 14 && count == 7)begin
        huff_code = 16'b1111111111110010;
    end else if (value == 14 && count == 8)begin
        huff_code = 16'b1111111111110011;
    end else if (value == 14 && count == 9)begin
        huff_code = 16'b1111111111110100;
    end else if (value == 14 && count == 10)begin
        huff_code = 16'b1111111111110101;
    end else if (value == 15 && count == 0)begin
        huff_code = 10'b1111111010;
    end else if (value == 15 && count == 1)begin
        huff_code = 16'b111111111000011;
    end else if (value == 15 && count == 2)begin
        huff_code = 16'b1111111111110110;
    end else if (value == 15 && count == 3)begin
        huff_code = 16'b1111111111110111;
    end else if (value == 15 && count == 4)begin
        huff_code = 16'b1111111111111000;
    end else if (value == 15 && count == 5)begin
        huff_code = 16'b1111111111111001;
    end else if (value == 15 && count == 6)begin
        huff_code = 16'b1111111111111010;
    end else if (value == 15 && count == 7)begin
        huff_code = 16'b1111111111111011;
    end else if (value == 15 && count == 8)begin
        huff_code = 16'b1111111111111100;
    end else if (value == 15 && count == 9)begin
        huff_code = 16'b1111111111111101;
    end else if (value == 15 && count == 10)begin
        huff_code = 16'b1111111111111110;
    end else
        huff_code = 16'b0; 
end 
endmodule
