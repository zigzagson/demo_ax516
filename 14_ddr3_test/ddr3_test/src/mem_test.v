module mem_test
#(
	parameter DATA_WIDTH = 64,
	parameter ADDR_WIDTH = 24
)
(
	input phy_clk,                                     /*接口时钟*/
	input init_calib_complete,                         /*初始化完成*/
	output reg rd_burst_req,                           /*读请求*/
	output reg wr_burst_req,                           /*写请求*/
	output reg[9:0] rd_burst_len,                      /*读数据长度*/
	output reg[9:0] wr_burst_len,                      /*写数据长度*/
	output [ADDR_WIDTH - 1:0] rd_burst_addr,           /*读首地址*/
	output reg[ADDR_WIDTH - 1:0] wr_burst_addr,        /*写首地址*/
	input rd_burst_data_valid,                         /*读出数据有效*/
	input wr_burst_data_req,                           /*写数据信号*/
	input[DATA_WIDTH - 1:0] rd_burst_data,             /*读出的数据*/
	output[DATA_WIDTH - 1:0] wr_burst_data,            /*写入的数据*/
	input rd_burst_finish,                             /*读完成*/
	input wr_burst_finish,                             /*写完成*/
	output error
);
//-----------------------------------------------
parameter IDLE = 3'd0;
parameter MEM_READ = 3'd1;
parameter MEM_WRITE  = 3'd2; 
reg[2:0] state;
reg[2:0] next_state;

reg   [9:0]  wr_cnt;
reg   [9:0]  rd_cnt;


//////////状态锁存///////////////
always@(posedge	phy_clk)
	begin
		if(~init_calib_complete)          //等待初始化成功
			state <= IDLE;
		else	
			state <= next_state;
	end
	
//////循环产生DDR Burst读,Burst写状态///////////
always@(*)
	begin 
		case(state)
			IDLE:
				next_state <= MEM_WRITE;  
			MEM_WRITE:                    //写入数据到DDR3
				if(wr_burst_finish)          
					next_state <= MEM_READ;
				else
					next_state <= MEM_WRITE;
			MEM_READ:                    //读出数据从DDR3
				if(rd_burst_finish)
					next_state <= MEM_WRITE;
				else
					next_state <= MEM_READ;
			default:
				next_state <= IDLE;
		endcase
end



//DDR的读写地址和DDR测试数据//
always@(posedge phy_clk)
	begin
		if(state == IDLE && next_state == MEM_WRITE)
			wr_burst_addr <= {ADDR_WIDTH{1'b0}};     //地址清零
		else if(state == MEM_READ && next_state == MEM_WRITE)                //一次Burst读写完成
			wr_burst_addr <= wr_burst_addr + {{(ADDR_WIDTH-8){1'b0}},8'd255}; //地址加burst长度255         
		else
			wr_burst_addr <= wr_burst_addr;           //锁存地址
	end
assign rd_burst_addr = wr_burst_addr;     
assign wr_burst_data = {(DATA_WIDTH/8){wr_cnt[7:0]}};     //写入DDR的数据

//产生burst写请求信号
always@(posedge phy_clk)
	begin
		if(next_state == MEM_WRITE && state != MEM_WRITE)
			begin
				wr_burst_req <= 1'b1;      //产生ddr burst写请求       
				wr_burst_len <= 10'd255;
				wr_cnt <= 10'd0;
			end
		else if(wr_burst_data_req)       //写入burst数据请求 
			begin
				wr_burst_req <= 1'b0;
				wr_burst_len <= 10'd255;
				wr_cnt <= wr_cnt + 10'd1;  //测试数据(每字节)加1
			end
		else
			begin
				wr_burst_req <= wr_burst_req;
				wr_burst_len <= 10'd255;
				wr_cnt <= wr_cnt;
			end
	end

//产生burst读请求信号	
always@(posedge phy_clk)
	begin
		if(next_state == MEM_READ && state != MEM_READ)
			begin
				rd_burst_req <= 1'b1;      //产生ddr burst读请求  
				rd_burst_len <= 10'd255;
				rd_cnt <= 10'd1;
			end
		else if(rd_burst_data_valid)     //检测到data_valid信号,burst读请求变0
			begin
				rd_burst_req <= 1'b0;
				rd_burst_len <= 10'd255;
				rd_cnt <= rd_cnt + 10'd1;
			end
		else
			begin
				rd_burst_req <= rd_burst_req;
				rd_burst_len <= 10'd255;
				rd_cnt <= rd_cnt;
			end
	end
	
assign error = rd_burst_data_valid &(rd_burst_data != {(DATA_WIDTH/8){rd_cnt[7:0]}});       //检查DDR读出的数据是否正确



endmodule
