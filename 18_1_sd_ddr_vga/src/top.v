//////////////////////////////////////////////////////////////////////////////////
//  sd bmp vga display                                                          //
//                                                                              //
//  Author: meisq                                                               //
//          msq@qq.com                                                          //
//          ALINX(shanghai) Technology Co.,Ltd                                  //
//          heijin                                                              //
//     WEB: http://www.alinx.cn/                                                //
//     BBS: http://www.heijin.org/                                              //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////
//                                                                              //
// Copyright (c) 2017,ALINX(shanghai) Technology Co.,Ltd                        //
//                    All rights reserved                                       //
//                                                                              //
// This source file may be used and distributed without restriction provided    //
// that this copyright statement is not removed from the file and that any      //
// derivative work contains the original copyright notice and the associated    //
// disclaimer.                                                                  //
//                                                                              //
//////////////////////////////////////////////////////////////////////////////////

//================================================================================
//  Revision History:
//  Date          By            Revision    Change Description
//--------------------------------------------------------------------------------
//  2017/6/21    meisq         1.0         Original
//*******************************************************************************/
module top(
	input                       clk,
	input                       rst_n,
	input                       key1,
	output[3:0]                 led,
	
   /*VGA接口信号*/	 	
	output                      vga_out_hs,        //vga horizontal synchronization
	output                      vga_out_vs,        //vga vertical synchronization
	output[4:0]                 vga_out_r,         //vga red
	output[5:0]                 vga_out_g,         //vga green
	output[4:0]                 vga_out_b,         //vga blue
	
   /*SD接口信号*/	 		
	output                      sd_ncs,            //SD card chip select (SPI mode)
	output                      sd_dclk,           //SD card clock
	output                      sd_mosi,           //SD card controller data output
	input                       sd_miso,           //SD card controller data input
	
   /*ddr3接口信号*/	 
  	 inout  [15:0]               mcb3_dram_dq,
	 output [13:0]               mcb3_dram_a,
	 output [2:0]                mcb3_dram_ba,
	 output                      mcb3_dram_ras_n,
	 output                      mcb3_dram_cas_n,
	 output                      mcb3_dram_we_n,
	 output                      mcb3_dram_odt,
	 output                      mcb3_dram_reset_n,
	 output                      mcb3_dram_cke,
	 output                      mcb3_dram_dm,
	 inout                       mcb3_dram_udqs,
	 inout                       mcb3_dram_udqs_n,
	 inout                       mcb3_rzq,
	 inout                       mcb3_zio,
	 output                      mcb3_dram_udm,
	 inout                       mcb3_dram_dqs,
	 inout                       mcb3_dram_dqs_n,
	 output                      mcb3_dram_ck,
	 output                      mcb3_dram_ck_n
);


parameter MEM_DATA_BITS         = 64  ;                 //external memory user interface data width
parameter ADDR_BITS             = 24  ;                 //external memory user interface address width
parameter BUSRT_BITS            = 10  ;                 //external memory user interface burst width
wire                            wr_burst_data_req;
wire                            wr_burst_finish;
wire                            rd_burst_finish;
wire                            rd_burst_req;
wire                            wr_burst_req;
wire[BUSRT_BITS - 1:0]          rd_burst_len;
wire[BUSRT_BITS - 1:0]          wr_burst_len;
wire[ADDR_BITS - 1:0]           rd_burst_addr;
wire[ADDR_BITS - 1:0]           wr_burst_addr;
wire                            rd_burst_data_valid;
wire[MEM_DATA_BITS - 1 : 0]     rd_burst_data;
wire[MEM_DATA_BITS - 1 : 0]     wr_burst_data;
wire                            read_req;
wire                            read_req_ack;  
wire                            read_en;
wire[63:0]                      read_data;
wire                            write_en;
wire[63:0]                      write_data;
wire                            write_req;
wire                            write_req_ack;

wire                            phy_clk;
wire                            init_calib_complete;
wire                            clk_bufg;
wire                            sd_card_clk;       //SD card controller clock
wire                            video_clk;         //video pixel clock
wire                            hs;
wire                            vs;
wire[15:0]                      vout_data;
wire[3:0]                       state_code;

//with a digital display of state_code
// 0:SD card is initializing
// 1:wait for the button to press
// 2:looking for the BMP file
// 3:reading

assign led = ~state_code;

assign vga_out_hs = hs;
assign vga_out_vs = vs;
assign vga_out_r  = vout_data[15:11];
assign vga_out_g  = vout_data[10:5];
assign vga_out_b  = vout_data[4:0];

assign sd_card_clk = clk_bufg;

//generate video pixel clock	
video_pll video_pll_m0
(
	.clk_video                  (clk_bufg  ),
	.clk_out1                   (video_clk  ),
	.RESET                      (~rst_n     ),
	.LOCKED                     (           )
);
	
	
//SD card BMP file read
sd_card_bmp  sd_card_bmp_m0(
	.clk                        (sd_card_clk              ),
	.rst                        (~rst_n                   ),
	.key                        (key1                     ),
	.state_code                 (state_code               ),
	.bmp_width                  (16'd1024                 ),  //image width
	.write_req                  (write_req                ),
	.write_req_ack              (write_req_ack            ),
	.write_en                   (write_en                 ),
	.write_data                 (write_data               ),
	.SD_nCS                     (sd_ncs                   ),
	.SD_DCLK                    (sd_dclk                  ),
	.SD_MOSI                    (sd_mosi                  ),
	.SD_MISO                    (sd_miso                  )
);

video_timing_data video_timing_data_m0
(
	.video_clk                  (video_clk                ),
	.rst                        (~rst_n                   ),
	.read_req                   (read_req                 ),
	.read_req_ack               (read_req_ack             ),
	.read_en                    (read_en                  ),
	.read_data                  (read_data                ),
	.hs                         (hs                       ),
	.vs                         (vs                       ),
	.de                         (                         ),
	.vout_data                  (vout_data                )
);
//video frame data read-write control
frame_read_write frame_read_write_m0
(
	.rst                        (~rst_n                   ),
	.mem_clk                    (phy_clk                  ),
	.rd_burst_req               (rd_burst_req             ),
	.rd_burst_len               (rd_burst_len             ),
	.rd_burst_addr              (rd_burst_addr            ),
	.rd_burst_data_valid        (rd_burst_data_valid      ),
	.rd_burst_data              (rd_burst_data            ),
	.rd_burst_finish            (rd_burst_finish          ),
	.read_clk                   (video_clk                ),
	.read_req                   (read_req                 ),
	.read_req_ack               (read_req_ack             ),
	.read_finish                (                         ),
	.read_addr_0                (24'd0                    ), //first frame base address is 0
	.read_addr_1                (24'd0                    ),
	.read_addr_2                (24'd0                    ),
	.read_addr_3                (24'd0                    ),
	.read_addr_index            (2'd0                     ), //use only read_addr_0
	.read_len                   (24'd786432               ), //frame size 1024 * 768 * 16 / 16
	.read_en                    (read_en                  ),
	.read_data                  (read_data                ),

	.wr_burst_req               (wr_burst_req             ),
	.wr_burst_len               (wr_burst_len             ),
	.wr_burst_addr              (wr_burst_addr            ),
	.wr_burst_data_req          (wr_burst_data_req        ),
	.wr_burst_data              (wr_burst_data            ),
	.wr_burst_finish            (wr_burst_finish          ),
	.write_clk                  (sd_card_clk              ),
	.write_req                  (write_req                ),
	.write_req_ack              (write_req_ack            ),
	.write_finish               (                         ),
	.write_addr_0               (24'd0                    ),
	.write_addr_1               (24'd0                    ),
	.write_addr_2               (24'd0                    ),
	.write_addr_3               (24'd0                    ),
	.write_addr_index           (2'd0                     ), //use only write_addr_0
	.write_len                  (24'd786432               ), //frame size 1024 * 768 * 16 / 16
	.write_en                   (write_en                 ),
	.write_data                 (write_data               )
);

//实例化mem_ctrl
mem_ctrl		
#(
	.MEM_DATA_BITS(MEM_DATA_BITS),
	.ADDR_BITS(ADDR_BITS)
)
mem_ctrl_inst
(
	//global clock
   .source_clk                      (clk),
	.phy_clk                         (phy_clk), 	            //ddr control clock	
	.clk_bufg  			               (clk_bufg),		               //50Mhz ref clock, not use 	
	.rst_n			                  (rst_n),			         //global reset

	//ddr read&write internal interface		
	.wr_burst_req		               (wr_burst_req), 	      //ddr write request
	.wr_burst_addr		               (wr_burst_addr),      	//ddr write address 	
	.wr_burst_data_req               (wr_burst_data_req), 	//ddr write data request
	.wr_burst_data		               (wr_burst_data),     	//fifo 2 ddr data input	
	.wr_burst_finish	               (wr_burst_finish),      //ddr write burst finish	
	
	.rd_burst_req		               (rd_burst_req), 	      //ddr read request
	.rd_burst_addr		               (rd_burst_addr), 	      //ddr read address
	.rd_burst_data_valid             (rd_burst_data_valid),  //ddr read data valid
	.rd_burst_data		               (rd_burst_data),   	   //ddr 2 fifo data input
	.rd_burst_finish	               (rd_burst_finish),      //ddr read burst finish	
	
	.calib_done                      (init_calib_complete), 

	//burst length
	.wr_burst_len		               (wr_burst_len),	            //ddr write burst length
	.rd_burst_len		               (rd_burst_len),		         //ddr read burst length
	
	//ddr interface
	.mcb3_dram_dq                    (mcb3_dram_dq       ),
	.mcb3_dram_a                     (mcb3_dram_a        ),
	.mcb3_dram_ba                    (mcb3_dram_ba       ),
	.mcb3_dram_ras_n                 (mcb3_dram_ras_n    ),
	.mcb3_dram_cas_n                 (mcb3_dram_cas_n    ),
	.mcb3_dram_we_n                  (mcb3_dram_we_n     ),
	.mcb3_dram_odt                   (mcb3_dram_odt      ),
	.mcb3_dram_reset_n               (mcb3_dram_reset_n  ),
	.mcb3_dram_cke                   (mcb3_dram_cke      ),
	.mcb3_dram_dm                    (mcb3_dram_dm       ),
	.mcb3_dram_udqs                  (mcb3_dram_udqs     ),
	.mcb3_dram_udqs_n                (mcb3_dram_udqs_n   ),
	.mcb3_rzq                        (mcb3_rzq           ),
	.mcb3_zio                        (mcb3_zio           ),
	.mcb3_dram_udm                   (mcb3_dram_udm      ),
	.mcb3_dram_dqs                   (mcb3_dram_dqs      ),
	.mcb3_dram_dqs_n                 (mcb3_dram_dqs_n    ),
	.mcb3_dram_ck                    (mcb3_dram_ck       ),
	.mcb3_dram_ck_n                  (mcb3_dram_ck_n     )

);


endmodule