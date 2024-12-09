`timescale 1ns / 1ps
`default_nettype none

module bricksort #(parameter TABLE_SIZE = 256, DATA_WIDTH = 16)
(
    input logic clk_in,
    input logic rst_in,
    input logic [DATA_WIDTH-1:0] freq_table_in [TABLE_SIZE-1:0],
    output logic [DATA_WIDTH-1:0] sorted_table [TABLE_SIZE-1:0],
    output logic done
);

logic [DATA_WIDTH-1:0] temp [TABLE_SIZE-1:0];
logic [7:0] i, j;
logic is_done;

typedef enum logic [1:0] {
    IDLE = 2'b00,
    SORT = 2'b01,
    DONE = 2'b10
} state_t;

state_t state, next_state;
logic swapped;

// O(n^2) where N is the size of the list... yikes
always_ff @(posedge clk_in) begin
    if (rst_in) begin // Reset the system
        next_state <= IDLE;
        i <= 0;
        j <= 0;
        done <= 1'b0;
        swapped <= 1'b0;
        for (int k = 0; k < TABLE_SIZE; k++) begin
            sorted_table[k] <= 0;
        end
    end else begin
        state <= next_state;
        case (state)
            IDLE: begin
                // Copy freq_table_in to temp
                for (int k = 0; k < TABLE_SIZE; k++) begin
                    temp[k] <= freq_table_in[k];
                end
                next_state <= SORT;
            end 

            SORT: begin
                swapped <= 0; 
                // Odd indices pass
                for (int i = 1; i < TABLE_SIZE - 1; i = i + 2) begin
                    if (temp[i] > temp[i + 1]) begin
                        logic [DATA_WIDTH-1:0] temp_val;
                        temp_val = temp[i]; 
                        temp[i] = temp[i + 1]; 
                        temp[i + 1] = temp_val; 
                        swapped <= 1;
                    end
                end

                // Even indices pass
                for (int j = 0; j < TABLE_SIZE - 1; j = j + 2) begin
                    if (temp[j] > temp[j + 1]) begin
                        logic [DATA_WIDTH-1:0] temp_val;
                        temp_val = temp[j]; 
                        temp[j] = temp[j + 1]; 
                        temp[j + 1] = temp_val; 
                        swapped <= 1;
                    end
                end

                if (!swapped) 
                    next_state <= DONE;
                else 
                    next_state <= SORT;
            end

            DONE: begin
                // Copy sorted data into sorted_table
                for (int k = 0; k < TABLE_SIZE; k++) begin
                    sorted_table[k] <= temp[k];
                end
                done <= 1'b1; 
                next_state <= DONE;
            end   
        endcase
    end
end

`default_nettype wire
endmodule