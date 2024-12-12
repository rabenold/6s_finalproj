`timescale 1ns / 1ps
`default_nettype none

module top_level
  (
   input wire          clk_100mhz,
   output logic [15:0] led,
   // camera bus
   input wire [7:0]    camera_d, // 8 parallel data wires
   output logic        cam_xclk, // XC driving camera
   input wire          cam_hsync, // camera hsync wire
   input wire          cam_vsync, // camera vsync wire
   input wire          cam_pclk, // camera pixel clock
   inout wire          i2c_scl, // i2c inout clock
   inout wire          i2c_sda, // i2c inout data
//    input wire [15:0]   sw,
   input wire [3:0]    btn,
   );

  // Clock and Reset Signals
  logic          sys_rst_camera;
  logic          sys_rst_pixel;
  logic          clk_camera;
  logic          clk_pixel;
  logic          clk_5x;
  logic          clk_xc;
  logic          clk_100_passthrough;

  // clocking wizards to generate the clock speeds we need for our different domains
  // clk_camera: 200MHz, fast enough to comfortably sample the cameera's PCLK (50MHz)
  cw_hdmi_clk_wiz wizard_hdmi
    (.sysclk(clk_100_passthrough),
     .clk_pixel(clk_pixel),
     .clk_tmds(clk_5x),
     .reset(0));

  cw_fast_clk_wiz wizard_migcam
    (.clk_in1(clk_100mhz),
     .clk_camera(clk_camera),
     .clk_xc(clk_xc),
     .clk_100(clk_100_passthrough),
     .reset(0));

  // assign camera's xclk to pmod port: drive the operating clock of the camera!
  // this port also is specifically set to high drive by the XDC file.
  assign cam_xclk = clk_xc;

  assign sys_rst_camera = btn[0]; //use for resetting camera side of logic
  assign sys_rst_pixel = btn[0]; //use for resetting hdmi/draw side of logic

  // rgb output values
  logic [7:0]          red,green,blue;

  // ** Handling input from the camera **
  // synchronizers to prevent metastability
  logic [7:0]    camera_d_buf [1:0];
  logic          cam_hsync_buf [1:0];
  logic          cam_vsync_buf [1:0];
  logic          cam_pclk_buf [1:0];

  always_ff @(posedge clk_camera) begin
     camera_d_buf <= {camera_d, camera_d_buf[1]};
     cam_pclk_buf <= {cam_pclk, cam_pclk_buf[1]};
     cam_hsync_buf <= {cam_hsync, cam_hsync_buf[1]};
     cam_vsync_buf <= {cam_vsync, cam_vsync_buf[1]};
  end

  logic [10:0] camera_hcount;
  logic [9:0]  camera_vcount;
  logic [15:0] camera_pixel;
  logic        camera_valid;

  // hook it up to buffered inputs.
  pixel_reconstruct pixel_reconstruct(
    .clk_in(clk_camera),
     .rst_in(sys_rst_camera),
     .camera_pclk_in(cam_pclk_buf[0]),
     .camera_hs_in(cam_hsync_buf[0]),
     .camera_vs_in(cam_vsync_buf[0]),
     .camera_data_in(camera_d_buf[0]),
     .pixel_valid_out(camera_valid),
     .pixel_hcount_out(camera_hcount),
     .pixel_vcount_out(camera_vcount),
     .pixel_data_out(camera_pixel));

  //two-port BRAM used to hold image from camera.
  //The camera is producing video at 720p and 30fps, but we can't store all of that
  //we're going to down-sample by a factor of 4 in both dimensions
  //so we have 320 by 180.  this is kinda a bummer, but we'll fix it
  //in future weeks by using off-chip DRAM.
  //even with the down-sample, because our camera is producing data at 30fps
  //and  our display is running at 720p at 60 fps, there's no hope to have the
  //production and consumption of information be synchronized in this system.
  //even if we could line it up once, the clocks of both systems will drift over time
  //so to avoid this sync issue, we use a conflict-resolution device...the frame buffer
  //instead we use a frame buffer as a go-between. The camera sends pixels in at
  //its own rate, and we pull them out for display at the 720p rate/requirement
  //this avoids the whole sync issue. It will however result in artifacts when you
  //introduce fast motion in front of the camera. These lines/tears in the image
  //are the result of unsynced frame-rewriting happening while displaying. It won't
  //matter for slow movement

  localparam FB_DEPTH = 320*180;
  localparam FB_SIZE = $clog2(FB_DEPTH);
  logic [FB_SIZE-1:0] addra; //used to specify address to write to in frame buffer

  logic valid_camera_mem; //used to enable writing pixel data to frame buffer
  logic [15:0] camera_mem; //used to pass pixel data into frame buffer

  logic start_save;
  
//writes every fourth pixel 
  always_ff @(posedge clk_camera)begin
    if (sys_rst_camera) begin
      addra <= 0;
      camera_mem <= 0;
      valid_camera_mem <= 0;
      start_save <= 0;
    end else begin
      if (~cam_hsync_buf[0] && ~cam_vsync_buf[0]) begin
        start_save <= 1;
      end
      if (start_save) begin
        if (camera_valid && (camera_hcount[1:0] == 2'b00) && (camera_vcount[1:0] == 2'b00)) begin
          valid_camera_mem <= 1;
          camera_mem <= camera_pixel;
        end else begin
          camera_mem <= 0;
          valid_camera_mem <= 0;
        end
        if (valid_camera_mem) begin
          if (addra < FB_DEPTH-1) begin
            addra <= addra + 1;
          end else begin
            addra <= 0;
          end
        end
      end
    end
  end

  //frame buffer from IP
  blk_mem_gen_0 frame_buffer (
    .addra(addra), //pixels are stored using this math
    .clka(clk_camera),
    .wea(valid_camera_mem),
    .dina(camera_mem),
    .ena(1'b1),
    .douta(), //never read from this side
    .addrb(addrb),//transformed lookup pixel
    .dinb(16'b0),
    .clkb(clk_pixel),
    .web(1'b0),
    .enb(1'b1),
    .doutb(frame_buff_raw)
  );

  //clocking off clk_pixel, whatever that is 

  //convert to y channel... ideal
  //now do we want to separate into ycbcr? or into matrices first? 

  logic [15:0] frame_buff_raw; //data out of frame buffer (565)
  logic [FB_SIZE-1:0] addrb; //used to lookup address in memory for reading from buffer
  
  logic good_addrb; //used to indicate within valid frame for scaling
  logic current_btn, prev_btn;
  assign current_btn = btn[3] | btn[2] | btn[1];

  always_ff @(posedge clk_pixel) begin
    if (sys_rst_pixel) begin
      prev_btn <= 0;
    end else begin
      prev_btn <= current_btn;
    end
  end

  logic state;
  logic [8:0] x_in, x_pixel;
  logic [7:0] y_in, y_pixel;


  logic [5:0] dct_block;
  logic [2:0] dct_block_x, dct_block_y;
  assign dct_block_x = dct_block[2:0];
  assign dct_block_y = dct_block[5:3];

  logic [5:0] x_dct; //0-39
  logic [4:0] y_dct; //0-22

  always_comb begin
    dct_block_x = dct_block[2:0];
    dct_block_y = dct_block[5:3];
    x_in <= 8*x_dct+dct_block_x;
    y_in <= 8*y_dct+dct_block_y;
    x_pixel = x_in ? x_in < 320 : 319;
    y_pixel = y_in ? y_in < 180 : 179;
    addrb <= x_pixel + 320*y_pixel;
  end
  
  always_ff @(posedge clk_pixel) begin
    if (sys_rst_pixel) begin
      state <= 0;
      x_dct <= 0;
      y_dct <= 0;
      dct_block <= 0;
      good_addrb <= 0;
    end else begin
      if (encoder_ready) begin
        if (state==0) begin
          if (prev_btn && ~current_btn) begin
            state <= 1;
            good_addrb <= 1;
          end
        end else begin

          dct_block <= dct_block+1;
          
          if (dct_block == 63) begin
            if (x_dct == 39) begin
              x_dct <= 0;
              if (y_dct == 22) begin
                y_dct <= 0;
                state <= 0;
                good_addrb <= 0;
              end else begin
                y_dct <= y_dct + 1;
              end
            end else begin
              x_dct <= x_dct+1;
            end
          end
        end
      end
    end
  end

  logic good_addrb_pipe [1:0];
  always_ff @(posedge clk_pixel)begin
    good_addrb_pipe[0] <= good_addrb;
    for (int i=1; i<2; i = i+1)begin
      good_addrb_pipe[i] <= good_addrb_pipe[i-1];
    end
  end

  //split frame_buff into 3 8 bit color channels (5:6:5 adjusted accordingly)
  //remapped frame_buffer outputs with 8 bits for r, g, b
  logic [7:0] fb_red, fb_green, fb_blue;
  always_ff @(posedge clk_pixel)begin
    fb_red <= good_addrb_pipe[1]?{frame_buff_raw[15:11],3'b0}:8'b0;
    fb_green <= good_addrb_pipe[1]?{frame_buff_raw[10:5], 2'b0}:8'b0;
    fb_blue <= good_addrb_pipe[1]?{frame_buff_raw[4:0],3'b0}:8'b0;
  end

  logic [23:0] encoder_data_in;
  assign encoder_data_in = {fb_red, fb_green, fb_blue};
  logic encoder_ready;

  jpeg_encoder
  (
    .C_S00_AXIS_TDATA_WIDTH(24),
    .C_M00_AXIS_TDATA_WIDTH(16)
  )
  encoder (
  // Ports of Axi Slave Bus Interface S00_AXIS
  .s00_axis_aclk(clk_pixel), 
  .s00_axis_aresetn(~sys_rst_pixel),
  .s00_axis_tlast(), 
  .s00_axis_tvalid(good_addrb_pipe[1]),
  .s00_axis_tdata(encoder_data_in),
  .s00_axis_tstrb(16'hFFFF),
  .s00_axis_tready(encoder_ready),
 
  // Ports of Axi Master Bus Interface M00_AXIS
  .m00_axis_aclk(clk_pixel), 
  .m00_axis_aresetn(~sys_rst_pixel),
  .m00_axis_tready(),
  .m00_axis_tvalid(), 
  .m00_axis_tlast(),
  .m00_axis_tdata(),
  .m00_axis_tstrb(),

  );

  uart_transmit
  #(.BAUD_RATE(25_000_000),
    .INPUT_CLOCK_FREQ(50_000_000))
   transmitter (
    .clk_in(clk_pixel),
    .rst_in(sys_rst_pixel),
    .data_byte_in(),
    .trigger_in(),
    .busy_out(),
    .tx_wire_out());


   // Nothing To Touch Down Here:
   // register writes to the camera

   // The OV5640 has an I2C bus connected to the board, which is used
   // for setting all the hardware settings (gain, white balance,
   // compression, image quality, etc) needed to start the camera up.
   // We've taken care of setting these all these values for you:
   // "rom.mem" holds a sequence of bytes to be sent over I2C to get
   // the camera up and running, and we've written a design that sends
   // them just after a reset completes.

   // If the camera is not giving data, press your reset button.

   logic  busy, bus_active;
   logic  cr_init_valid, cr_init_ready;

   logic  recent_reset;
   always_ff @(posedge clk_camera) begin
      if (sys_rst_camera) begin
         recent_reset <= 1'b1;
         cr_init_valid <= 1'b0;
      end
      else if (recent_reset) begin
         cr_init_valid <= 1'b1;
         recent_reset <= 1'b0;
      end else if (cr_init_valid && cr_init_ready) begin
         cr_init_valid <= 1'b0;
      end
   end

   logic [23:0] bram_dout;
   logic [7:0]  bram_addr;

   // ROM holding pre-built camera settings to send
   xilinx_single_port_ram_read_first
     #(
       .RAM_WIDTH(24),
       .RAM_DEPTH(256),
       .RAM_PERFORMANCE("HIGH_PERFORMANCE"),
       .INIT_FILE("rom.mem")
       ) registers
       (
        .addra(bram_addr),     // Address bus, width determined from RAM_DEPTH
        .dina(24'b0),          // RAM input data, width determined from RAM_WIDTH
        .clka(clk_camera),     // Clock
        .wea(1'b0),            // Write enable
        .ena(1'b1),            // RAM Enable, for additional power savings, disable port when not in use
        .rsta(sys_rst_camera), // Output reset (does not affect memory contents)
        .regcea(1'b1),         // Output register enable
        .douta(bram_dout)      // RAM output data, width determined from RAM_WIDTH
        );

   logic [23:0] registers_dout;
   logic [7:0]  registers_addr;
   assign registers_dout = bram_dout;
   assign bram_addr = registers_addr;

   logic       con_scl_i, con_scl_o, con_scl_t;
   logic       con_sda_i, con_sda_o, con_sda_t;

   // NOTE these also have pullup specified in the xdc file!
   // access our inouts properly as tri-state pins
   IOBUF IOBUF_scl (.I(con_scl_o), .IO(i2c_scl), .O(con_scl_i), .T(con_scl_t) );
   IOBUF IOBUF_sda (.I(con_sda_o), .IO(i2c_sda), .O(con_sda_i), .T(con_sda_t) );

   // provided module to send data BRAM -> I2C
   camera_registers crw
     (.clk_in(clk_camera),
      .rst_in(sys_rst_camera),
      .init_valid(cr_init_valid),
      .init_ready(cr_init_ready),
      .scl_i(con_scl_i),
      .scl_o(con_scl_o),
      .scl_t(con_scl_t),
      .sda_i(con_sda_i),
      .sda_o(con_sda_o),
      .sda_t(con_sda_t),
      .bram_dout(registers_dout),
      .bram_addr(registers_addr));

   // a handful of debug signals for writing to registers
  //  assign led[0] = crw.bus_active;
  //  assign led[1] = cr_init_valid;
  //  assign led[2] = cr_init_ready;
  //  assign led[15:3] = 0;

endmodule // top_level


`default_nettype wire

