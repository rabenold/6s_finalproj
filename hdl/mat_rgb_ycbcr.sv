`timescale 1ns/1ps

// module for 8x8 rgb to ycbcr conversion 
module rgb_to_ycbcr_8x8(
    input wire clk_in,
    input wire reset, 
    input wire [9:0] r_in [0:7][0:7], // R vals 
    input wire [9:0] g_in [0:7][0:7],  //G 
    input wire [9:0] b_in [0:7][0:7], //B
    output logic [9:0] y_out [0:7][0:7],  //Y 
    output logic [9:0] cr_out [0:7][0:7], //Cr
    output logic [9:0] cb_out [0:7][0:7], //Cb
    output logic ready
);


	// calculate Y
  logic [19:0] yr, yg, yb;

  always_ff @(posedge clk_in) begin
			yr <= 10'h132 * r_in;
			yg <= 10'h259 * g_in;
			yb <= 10'h074 * b_in;
			y1 <= yr + yg + yb;
  end

	/* calculate Cr */
	logic [19:0] crr, crg, crb;
  always_ff @(posedge clk_in) begin
			crr <=  r_in << 9;
			crg <=  10'h1ad * g_in;
			crb <=  10'h053 * b_in;
			cr1 <=  crr - crg - crb;
  end

	/* calculate Cb */
	logic [19:0] cbr, cbg, cbb;
  always_ff @(posedge clk_in) begin
			cbr <=  10'h0ad * r_in;
			cbg <=  10'h153 * g_in;
			cbb <=  b_in << 9;
			cb1 <=  cbb - cbr - cbg;
  end

	/* Step 2: Check Boundaries */
  always_ff @(posedge clk_in) begin
		 y_out <= y1[19:10];
		 cr_out <= cr1[19:10];
		 cb_out <= cb1[19:10];
  end














    // logic [21:0] y1 [0:7][0:7], cr1 [0:7][0:7], cb1 [0:7][0:7];
    // logic done; 
    // // Counters for row and column indices
    // logic [2:0] row_counter;  // 3-bit counter for rows (0 to 7)
    // logic [2:0] col_counter;  // 3-bit counter for columns (0 to 7)


    // Step 1: Calculate Y, Cr, and Cb for each pixel


    //takes 64 cycles ewww
    // always_ff @(posedge clk_in) begin
    //     if (reset) begin
    //         ready<=1; 
    //         done <= 0; 
    //         row_counter <= 3'b0;  // Reset row counter
    //         col_counter <= 3'b0;  // Reset column counter
    //     end else begin
    //         // Calculate Y, Cr, and Cb for the current pixel
    //         logic [19:0] yr, yg, yb;
    //         logic [19:0] crr, crg, crb;
    //         logic [19:0] cbr, cbg, cbb;

    //         // Calculate Y (luminance)
    //         yr = 10'h132 * r_in[row_counter][col_counter];  // 0.299 * R
    //         yg = 10'h259 * g_in[row_counter][col_counter];  // 0.587 * G
    //         yb = 10'h074 * b_in[row_counter][col_counter];  // 0.114 * B
    //         y1[row_counter][col_counter] = yr + yg + yb;

    //         // Calculate Cr (chrominance red)
    //         crr = r_in[row_counter][col_counter] << 9;  // R >> 1
    //         crg = 10'h1ad * g_in[row_counter][col_counter];  // -0.419 * G
    //         crb = 10'h053 * b_in[row_counter][col_counter];  // -0.0813 * B
    //         cr1[row_counter][col_counter] = crr - crg - crb;

    //         // Calculate Cb (chrominance blue)
    //         cbr = 10'h0ad * r_in[row_counter][col_counter];  // -0.169 * R
    //         cbg = 10'h153 * g_in[row_counter][col_counter];  // -0.332 * G
    //         cbb = b_in[row_counter][col_counter] << 9;  // B >> 1
    //         cb1[row_counter][col_counter] = cbb - cbr - cbg;

    //         // Output the Y, Cr, and Cb values (truncated to 10 bits)
    //         y_out[row_counter][col_counter] = y1[row_counter][col_counter][19:10];   // 10-bit Y value
    //         cr_out[row_counter][col_counter] = cr1[row_counter][col_counter][19:10]; // 10-bit Cr value
    //         cb_out[row_counter][col_counter] = cb1[row_counter][col_counter][19:10]; // 10-bit Cb value
    //     end
    // end

    // // Step 2: Increment the counters
    // always_ff @(posedge clk_in) begin
    //         // Increment column counter
    //         if (col_counter < 3'b111) begin
    //             col_counter <= col_counter + 1;  // Increment column index
    //         end else begin
    //             col_counter <= 3'b0;  // Reset column counter when it reaches 7
    //             // Increment row counter
    //             if (row_counter < 3'b111) begin
    //                 row_counter <= row_counter + 1;  // Increment row index
    //                 done<=0; 
    //             end else begin
    //                 done<=1; 
    //                 ready<=0; 
    //                 row_counter <= 3'b0;  // Reset row counter when it reaches 7
    //             end
    //         end
    //     end

endmodule

