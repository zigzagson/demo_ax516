module ddr3_test(

    input                                       sys_clk,
	 input                                       rst_n,
		
   /*ddr3接口信号*/	 
  	 inout  [15:0]                                mcb3_dram_dq,
	 output [13:0]                                mcb3_dram_a,
	 output [2:0]                                 mcb3_dram_ba,
	 output                                       mcb3_dram_ras_n,
	 output                                       mcb3_dram_cas_n,
	 output                                       mcb3_dram_we_n,
	 output                                       mcb3_dram_odt,
	 output                                       mcb3_dram_reset_n,
	 output                                       mcb3_dram_cke,
	 output                                       mcb3_dram_dm,
	 inout                                        mcb3_dram_udqs,
	 inout                                        mcb3_dram_udqs_n,
	 inout                                        mcb3_rzq,
	 inout                                        mcb3_zio,
	 output                                       mcb3_dram_udm,
	 inout                                        mcb3_dram_dqs,
	 inout                                        mcb3_dram_dqs_n,
	 output                                       mcb3_dram_ck,
	 output                                       mcb3_dram_ck_n,
	 
	 output                                       init_calib_complete,
	 output                                       error                     //led1, 灯亮DDR读写正常, 灯灭DDR读写出错	 
	 
);

parameter DATA_WIDTH = 64;           //总线数据宽度
parameter ADDR_WIDTH = 24;           //总线地址宽度

wire phy_clk;
wire wr_burst_data_req;
wire wr_burst_finish;
wire rd_burst_finish;
wire rd_burst_req;
wire wr_burst_req;
wire[9:0] rd_burst_len;
wire[9:0] wr_burst_len;
wire[ADDR_WIDTH - 1 :0] rd_burst_addr;
wire[ADDR_WIDTH - 1 :0] wr_burst_addr;
wire rd_burst_data_valid;
wire[DATA_WIDTH - 1 : 0] rd_burst_data;
wire[DATA_WIDTH - 1 : 0] wr_burst_data;


mem_test
#(
	.DATA_WIDTH(DATA_WIDTH),
	.ADDR_WIDTH(ADDR_WIDTH)
)
mem_test_m0
(                         
	.phy_clk                    (phy_clk), 
   .init_calib_complete        (init_calib_complete),	
	.rd_burst_req               (rd_burst_req),                         
	.wr_burst_req               (wr_burst_req),                         
	.rd_burst_len               (rd_burst_len),                     
	.wr_burst_len               (wr_burst_len),                    
	.rd_burst_addr              (rd_burst_addr),        
	.wr_burst_addr              (wr_burst_addr),        
	.rd_burst_data_valid        (rd_burst_data_valid),                 
	.wr_burst_data_req          (wr_burst_data_req),                   
	.rd_burst_data              (rd_burst_data),   
	.wr_burst_data              (wr_burst_data),    
	.rd_burst_finish            (rd_burst_finish),                     
	.wr_burst_finish            (wr_burst_finish),                      

	.error                      (error)
);

//实例化mem_ctrl
mem_ctrl		
#(
	.MEM_DATA_BITS(DATA_WIDTH),
	.ADDR_BITS(ADDR_WIDTH)
)
mem_ctrl_inst
(
	//global clock
   .source_clk                      (sys_clk),
	.phy_clk  			               (phy_clk),		         //ddr control clock	
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

/***************************/
//chipscope icon和ila, 用于观察信号//
/***************************/	
wire [35:0]   CONTROL0;
wire [255:0]  TRIG0;
chipscope_icon icon_debug (
    .CONTROL0(CONTROL0) // INOUT BUS [35:0]
);

chipscope_ila ila_filter_debug (
    .CONTROL(CONTROL0), // INOUT BUS [35:0]
    .CLK(phy_clk),      // IN, chipscope的采样时钟
    .TRIG0(TRIG0)       // IN BUS [255:0], 采样的信号
    //.TRIG_OUT(TRIG_OUT0)
);                                                     

assign  TRIG0[0]=wr_burst_req;    
assign  TRIG0[24:1]=wr_burst_addr;    
assign  TRIG0[25]=wr_burst_data_req;    
assign  TRIG0[89:26]=wr_burst_data;    
assign  TRIG0[90]=wr_burst_finish; 
   
assign  TRIG0[91]=rd_burst_req;    	
assign  TRIG0[115:92]=rd_burst_addr; 
assign  TRIG0[116]=rd_burst_data_valid;
assign  TRIG0[180:117]=rd_burst_data;	
assign  TRIG0[181]=rd_burst_finish;	

assign  TRIG0[182]=error;	
assign  TRIG0[183]=init_calib_complete;	
	
endmodule 

