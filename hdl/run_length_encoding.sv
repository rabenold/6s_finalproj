// run length encoding on the zig zag array
// zig zag is a 1D array of size 64

//[5, 0, 0, 0, 4, 0, 0, 0, 0, 0, ...]  // A zigzag-ordered 1D array
//[(1, 5), (3, 0), (1, 4), (4, 0), ...]
module rle_encoder (
    input logic clk_in,
    input logic valid_in, 
    input logic rst_in,
    input logic [7:0] data_in[0:63],       // 64 elements
    output logic [7:0] run_value [0:63],   // Store up to 64 elements in 8-bit wide
    output logic [7:0] run_count [0:63],   // Store up to 64 counts in 8-bit wide
    output logic done,                      // Done signal
    output logic [6:0] indiv_elms   //for counting how many unique elements 
);
    // Internal variables
    logic [7:0] count;                     // Counter for indexing data_in
    logic [7:0] run_len;                   // Length of the current run
    logic [7:0] prev_value;                // Previous value for comparison
    logic [7:0] current_value;             // Current value for comparison
    logic [7:0] run_index;                 // Index for run_value and run_count output arrays
    logic first; 
    logic [5:0] local_ct; 
    always_ff @(posedge clk_in or posedge rst_in) begin
        if (rst_in) begin
            // Reset the variables on reset
            count <= 0;
            run_len <= 1;
            prev_value <= 8'b0;            // Reset to zero
            done <= 0;                     // Encoding not done
            run_index <= 0;
            first <=1;                 // Reset run_index
            // Clear the output arrays on reset
            indiv_elms<=0;
            local_ct <= 0;  
            for (int i = 0; i < 64; i++) begin
                run_value[i] <= 8'b0;
                run_count[i] <= 8'b0;
            end
        end else if (valid_in) begin
            current_value <= data_in[count];  // Fetch the current value
            
            if (first) begin
                // Special handling for the first element
                prev_value <= data_in[count];
                run_value[run_index] <= prev_value;
                run_count[run_index] <= 0;
                run_len <= 0; // Start the first run
                count<=count+1; 
                first<=0; 
                local_ct<=1; 
            end else if (prev_value == current_value) begin
                // Continue the current run (increment the length)
                run_len <= run_len + 1;
            end else begin
                // Store the previous run (value and count)
                local_ct<=local_ct+1; 
                run_value[run_index] <= prev_value;
                run_count[run_index] <= run_len;
                run_index <= run_index + 1;  // Increment the run index

                // Start a new run for the current value
                prev_value <= current_value;
                run_len <= 1;
            end

            //last element 
            if (count == 63) begin
                run_value[run_index] <= prev_value;
                run_count[run_index] <= run_len+2;
                done <= 1;  
                indiv_elms<=local_ct;
            end else begin
                count <= count + 1;
            end
        end
    end
endmodule




//     // Initialize outputs
//     always_comb begin
//         // Initialize output variables
//         data_out_elements = 512'b0;         // Initialize the 512-bit output for elements
//         data_out_counts = 512'b0;           // Initialize the 512-bit output for counts
//         count = 1;                          // Start counting from 1
//         prev_value = data_in[0];            // Initialize the previous value as the first element
//         idx = 0;                            // Start index at 0
//         done = 0;                           // Done signal starts off as 0
        
//         // Loop through all elements in data_in (starting from the second element)
//         for (int i = 1; i < 64; i = i + 1) begin
//             current_value = data_in[i];     // Get the current element

//             // If the current value is the same as the previous one, increment the count
//             if (current_value == prev_value) begin
//                 count = count + 1;
//             end else begin
//                 // Store the previous value and count in the temporary outputs
//                 temp_elements[(idx * 8) +: 8] = prev_value;  // Store 8 bits for value
//                 temp_counts[(idx * 8) +: 8] = count;         // Store 8 bits for count

//                 // Increment index
//                 idx = idx + 1;

//                 // Reset count and update the previous value
//                 count = 1;
//                 prev_value = current_value;
//             end
//         end

//         // Store the last element and its count
//         temp_elements[(idx * 8) +: 8] = prev_value;  // Store the last value
//         temp_counts[(idx * 8) +: 8] = count;         // Store the last count

//         // Finalize the outputs (truncate if necessary)
//         data_out_elements = temp_elements;
//         data_out_counts = temp_counts;
//         done = 1; // Set done signal to 1 when the operation is complete
//     end
// endmodule
