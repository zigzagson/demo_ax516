`timescale 1ns / 1ps  
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    ethernet_test 
//////////////////////////////////////////////////////////////////////////////////
module ethernet_test(
    input       clk,
    input       rst_n,
    output [3:0]   led,
    output      e_mdc,
    inout       e_mdio,
	 output      e_reset,
	 input	    e_rxc,                     //125Mhz ethernet gmii rx clock
    input       e_rxdv,                    //GMII 接收数据有效信号
    input       e_rxer,                    //GMII 接收数据错误信号                    
    input [7:0] e_rxd,                     //GMII 接收数据          

    input       e_txc,                     //25Mhz ethernet mii tx clock         
    output      e_gtxc,                    //125Mhz ethernet gmii tx clock  
    output      e_txen,                    //GMII 发送数据有效信号    
    output      e_txer,                    //GMII 发送数据错误信号                    
    output[7:0] e_txd                      //GMII 发送数据 
    );
	 
wire  [31:0]    pack_total_len ;
wire [1:0]      speed;
wire            link;
wire            erxdv;
wire [7:0]      erxd;
wire            e_tx_en;
wire [7:0]      etxd;
wire            e_rst_n;

assign e_gtxc = e_rxc;	 
assign e_reset = 1'b1; 
assign e_txer = 1'b0;


mac_test mac_test0
(
.gmii_tx_clk          (e_gtxc         ),
.gmii_rx_clk          (e_rxc          ),
.rst_n                (e_rst_n        ),
.pack_total_len       (pack_total_len ),
.gmii_rx_dv           (erxdv          ),
.gmii_rxd             (erxd           ),
.gmii_tx_en           (e_tx_en        ),
.gmii_txd             (etxd           )

); 

//GMII, MII 选择
gmii_arbi arbi_inst
(
.clk                (e_gtxc           ),
.rst_n              (rst_n            ),
.speed              (speed            ),  
.link               (link             ), 
.pack_total_len     (pack_total_len   ), 
.e_rst_n            (e_rst_n          ),
.gmii_rx_dv         (e_rxdv           ),
.gmii_rxd           (e_rxd            ),
.gmii_tx_en         (e_tx_en          ),
.gmii_txd           (etxd             ), 
.e_rx_dv            (erxdv            ),
.e_rxd              (erxd             ),
.e_tx_en            (e_txen           ),
.e_txd              (e_txd            ) 
);

 //MDIO寄存器配置
smi_config  smi_config_inst
(
.clk                (clk            ),
.rst_n              (rst_n              ),		 
.mdc                (e_mdc              ),
.mdio               (e_mdio             ),
.speed              (speed              ),
.link               (link               ),
.led                (led                )	
);	

endmodule
