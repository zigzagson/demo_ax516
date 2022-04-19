//*************************************************************************\
//Copyright (c) 2017,ALINX(shanghai) Technology Co.,Ltd,All rights reserved
//
//                   File Name  :  uart_test.v
//                Project Name  :  
//                      Author  :  meisq
//                       Email  :  msq@qq.com
//                     Company  :  ALINX(shanghai) Technology Co.,Ltd
//                         WEB  :  http://www.alinx.cn/
//==========================================================================
//   Description:  uart test model 
//
//
//==========================================================================
//  Revision History:
//	Date		  By			Revision	Change Description
//--------------------------------------------------------------------------
//  2017/5/9     meisq		    1.0			Original
//*************************************************************************/
module uart_send(
	input      clk,
	input      rst_n,
	input[7:0] read_second,
	input[7:0] read_minute,
	input[7:0] read_hour,
	input[7:0] read_date,
	input[7:0] read_month,
	input[7:0] read_week,
	input[7:0] read_year,
	input      uart_rx,
	output     uart_tx	
);

parameter CLK_FRE = 50;//Mhz

localparam IDLE =  0;
localparam SEND =  1; //send "time is..."
localparam WAIT =  2; //wait 1 second and send uart received data
reg[7:0] tx_data;    
reg[7:0] tx_str;
reg tx_data_valid;
wire tx_data_ready;
reg[5:0] tx_cnt;
wire[7:0] rx_data;
wire rx_data_valid;
wire rx_data_ready;

reg[3:0] state;
reg[31:0] wait_cnt;

reg[7:0] read_second_d0;
reg[7:0] read_second_d1;

assign rx_data_ready = 1'b1;//Always ready to receive uart data 

always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
	begin
		read_second_d0 <= 8'd0;
		read_second_d1 <= 8'd0;
	end
	else
	begin
		read_second_d0 <= read_second;
		read_second_d1 <= read_second_d0;
	end	
end

always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)        //initial setting up
	begin
		wait_cnt <= 32'd0;
		tx_data <= 8'd0;
		state <= IDLE;
		tx_cnt <= 5'd0;
		tx_data_valid <= 1'b0;
	end
	else
	case(state)
		IDLE:
			state <= SEND;
		SEND:
		begin
			wait_cnt <= 32'd0;
			tx_data <= tx_str;
			
			if(tx_data_valid && tx_data_ready && tx_cnt < 5'd29)        //sending  byte is finish
			begin
				tx_cnt <= tx_cnt + 5'd1;	
			end
			else if(tx_data_valid && tx_data_ready)       //sending last byte is finish
			begin
				tx_cnt <= 5'd0;
				tx_data_valid <= 1'b0;
				state <= WAIT;
			end
			else if(~tx_data_valid)
			begin
				tx_data_valid <= 1'b1;
			end
		end
		WAIT:
		begin
			wait_cnt <= wait_cnt + 32'd1;
			
			if(rx_data_valid)
			begin
				tx_data_valid <= 1'b1;
				tx_data <= rx_data;   // send uart received data
			end
			else if(tx_data_valid && tx_data_ready)
			begin
				tx_data_valid <= 1'b0;
			end
			else if(read_second_d1 != read_second_d0) // wait for 1 second
				state <= SEND;
		end
		default:
			state <= IDLE;
	endcase
end


always@(*)
begin
	case(tx_cnt)
		5'd0 :  tx_str <= "t";
		5'd1 :  tx_str <= "i";
		5'd2 :  tx_str <= "m";
		5'd3 :  tx_str <= "e";
		5'd4 :  tx_str <= " ";
		5'd5 :  tx_str <= "i";
		5'd6 :  tx_str <= "s";
		5'd7 :  tx_str <= " ";
		5'd8 :  tx_str <= "2";
		5'd9 :  tx_str <= "0"; 
		5'd10:  tx_str <= read_year[7:4] + 8'd48; 
		5'd11:  tx_str <= read_year[3:0] + 8'd48; 
		5'd12:  tx_str <= "-";
		5'd13:  tx_str <= read_month[7:4] + 8'd48;
		5'd14:  tx_str <= read_month[3:0] + 8'd48;
		5'd15:  tx_str <= "-";
		5'd16:  tx_str <= read_date[7:4] + 8'd48;
		5'd17:  tx_str <= read_date[3:0] + 8'd48;		
		5'd18:  tx_str <= " ";
		5'd19:  tx_str <= read_hour[7:4] + 8'd48; 
		5'd20:  tx_str <= read_hour[3:0] + 8'd48; 
		5'd21:  tx_str <= ":";
		5'd22:  tx_str <= read_minute[7:4] + 8'd48;
		5'd23:  tx_str <= read_minute[3:0] + 8'd48;
		5'd24:  tx_str <= ":";
		5'd25:  tx_str <= read_second[7:4] + 8'd48;
		5'd26:  tx_str <= read_second[3:0] + 8'd48;		
		5'd27:  tx_str <= "\r";
		5'd28:  tx_str <= "\n";		
		default:tx_str <= 8'd0;
	endcase
end

uart_rx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(115200)
) uart_rx_inst
(
	.clk(clk),
	.rst_n(rst_n),
	.rx_data(rx_data),
	.rx_data_valid(rx_data_valid),
	.rx_data_ready(rx_data_ready),
	.rx_pin(uart_rx)
);

uart_tx#
(
	.CLK_FRE(CLK_FRE),
	.BAUD_RATE(115200)
) uart_tx_inst
(
	.clk(clk),
	.rst_n(rst_n),
	.tx_data(tx_data),
	.tx_data_valid(tx_data_valid),
	.tx_data_ready(tx_data_ready),
	.tx_pin(uart_tx)
);
endmodule 