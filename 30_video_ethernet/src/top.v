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
	
   /*GMII接口信号*/	 	
	output                      e_reset,
	input                       e_rxc,             //125Mhz ethernet gmii rx clock
	input                       e_rxdv,            //GMII 接收数据有效信号
	input                       e_rxer,            //GMII 接收数据错误信号                    
	input [7:0]                 e_rxd,             //GMII 接收数据          

	input                       e_txc,             //25Mhz ethernet mii tx clock         
	output                      e_gtxc,            //125Mhz ethernet gmii tx clock  
	output                      e_txen,            //GMII 发送数据有效信号    
	output                      e_txer,            //GMII 发送数据错误信号                    
	output[7:0]                 e_txd,             //GMII 发送数据 
	
   /*OV5640接口信号*/	 		
	inout                       cmos_scl,          //cmos i2c clock
	inout                       cmos_sda,          //cmos i2c data
	input                       cmos_vsync,        //cmos vsync
	input                       cmos_href,         //cmos hsync refrence,data valid
	input                       cmos_pclk,         //cmos pxiel clock
	output                      cmos_xclk,         //cmos externl clock
	input   [7:0]               cmos_db,           //cmos data
	output                      cmos_rst_n,        //cmos reset
	output                      cmos_pwdn          //cmos power down
	

);


wire[9:0]                       lut_index;
wire[31:0]                      lut_data;

assign e_gtxc=e_rxc;	 
assign e_reset = 1'b1;   
assign e_txer = 1'b0;

assign cmos_rst_n = 1'b1;
assign cmos_pwdn  = 1'b0;

//generate video pixel clock	
wire clk_50;
cmos_pll cmos_pll_m0
(
	.clk_in1                    (clk        ),
	.clk_out1                   (clk_50     ),      //50Mhz
	.clk_out2                   (cmos_xclk  ),	   //24Mhz  
	.RESET                      (~rst_n     ),
	.LOCKED                     (           )
);
	
	
//I2C master controller
i2c_config i2c_config_m0
(
	.rst                        (~rst_n                   ),
	.clk                        (clk_50                   ),
	.clk_div_cnt                (16'd500                  ),
	.i2c_addr_2byte             (1'b1                     ),
	.lut_index                  (lut_index                ),
	.lut_dev_addr               (lut_data[31:24]          ),
	.lut_reg_addr               (lut_data[23:8]           ),
	.lut_reg_data               (lut_data[7:0]            ),
	.error                      (                         ),
	.done                       (                         ),
	.i2c_scl                    (cmos_scl                 ),
	.i2c_sda                    (cmos_sda                 )
);
//configure look-up table
lut_ov5640_rgb565_800_600 lut_ov5640_rgb565_800_600_m0(
	.lut_index                  (lut_index          ),
	.lut_data                   (lut_data           )
);

//CMOS caputre delay
wire       cmos_vsync_delay;
wire       cmos_href_delay;
wire [7:0] cmos_data_delay;

camera_delay camera_delay_inst
(
   .cmos_pclk          (cmos_pclk),              //cmos pxiel clock
   .cmos_href          (cmos_href),              //cmos hsync refrence
   .cmos_vsync         (cmos_vsync),             //cmos vsync
   .cmos_data          (cmos_db),              //cmos data

   .cmos_href_delay    (cmos_href_delay),              //cmos hsync refrence
   .cmos_vsync_delay   (cmos_vsync_delay),             //cmos vsync
   .cmos_data_delay    (cmos_data_delay)             //cmos data
) ;

// CMOS FIFO
wire [10 : 0] fifo_data_count;
wire [7:0] fifo_data;
wire fifo_rd_en;

camera_fifo camera_fifo_inst (
  .rst                      (cmos_vsync     ),   // input rst
  .wr_clk                   (cmos_pclk      ),   // input wr_clk
  .din                      (cmos_data_delay),   // input [7 : 0] din
  .wr_en                    (cmos_href_delay),   // input wr_en
  
  .rd_clk                   (e_rxc          ),   // input rd_clk
  .rd_en                    (fifo_rd_en     ),   // input rd_en
  .dout                     (fifo_data      ),   // output [7 : 0] dout
  .full                     (               ),   // output full
  .empty                    (               ),   // output empty
  .rd_data_count            (fifo_data_count)    // output [10 : 0] rd_data_count
);

mac_test mac_test0
(
 .gmii_tx_clk            (e_gtxc             ),
 .gmii_rx_clk            (e_rxc              ) ,
 .rst_n                  (rst_n              ),
 
 .cmos_vsync              (cmos_vsync        ),
 .cmos_href               (cmos_href         ),
 .reg_conf_done           (1'b1              ),
 .fifo_data               (fifo_data         ),  //FIFO read data
 .fifo_data_count         (fifo_data_count   ),  //fifo remained data count
 .fifo_rd_en              (fifo_rd_en),          //FIFO read enable
 
 
 .udp_send_data_length   (16'd1024), 
 .gmii_rx_dv             (e_rxdv),
 .gmii_rxd               (e_rxd  ),
 .gmii_tx_en             (e_txen ),
 .gmii_txd               (e_txd)
 
);


endmodule
