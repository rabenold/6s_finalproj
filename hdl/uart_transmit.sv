`timescale 1ns / 1ps
`default_nettype none

module uart_transmit
  #(parameter BAUD_RATE = 25_000_000,
    parameter INPUT_CLOCK_FREQ = 100_000_000)
   (
    input wire 	     clk_in,
    input wire 	     rst_in,
    input wire [7:0] data_byte_in,
    input wire 	     trigger_in,
    output logic     busy_out,
    output logic     tx_wire_out);

   localparam PERIOD_CYCLES = INPUT_CLOCK_FREQ / BAUD_RATE;

   typedef enum      {IDLE, TRANSMIT} uart_tx_state;
   uart_tx_state state;

   logic [7:0] 	     current_data;
   logic [9:0] 	     frame;
   assign frame[0] = 1'b0; // START bit
   assign frame[8:1] = current_data;
   assign frame[9] = 1'b1; // STOP big

   logic [3:0] 	     index;
   logic [$clog2(PERIOD_CYCLES):0] cycle_count;

   assign tx_wire_out = (state == TRANSMIT) ? frame[index] : 1'b1; // idle high
   assign busy_out = (state != IDLE);

   always_ff @(posedge clk_in) begin
      if (rst_in) begin
	 current_data <= 8'b0;
	 state <= IDLE;
	 index <= 0;
	 cycle_count <= 0;
      end else begin
	 case(state)
	   IDLE: begin
	      if (trigger_in) begin
		 current_data <= data_byte_in;
		 state <= TRANSMIT;
		 index <= 0;
		 cycle_count <= PERIOD_CYCLES-1;
	      end
	   end
	   TRANSMIT: begin
	      if (cycle_count == 0) begin
		 if (index == 9) begin
		    state <= IDLE;
		 end else begin
		    cycle_count <= PERIOD_CYCLES-1;
		    index <= index + 1;
		 end
	      end else begin
		 cycle_count <= cycle_count - 1;
	      end
	   end
	 endcase
      end
   end

endmodule
`default_nettype wire
