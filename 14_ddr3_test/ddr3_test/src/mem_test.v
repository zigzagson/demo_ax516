module mem_test
#(
	parameter DATA_WIDTH = 64,
	parameter ADDR_WIDTH = 24
)
(
	input phy_clk,                                     /*�ӿ�ʱ��*/
	input init_calib_complete,                         /*��ʼ�����*/
	output reg rd_burst_req,                           /*������*/
	output reg wr_burst_req,                           /*д����*/
	output reg[9:0] rd_burst_len,                      /*�����ݳ���*/
	output reg[9:0] wr_burst_len,                      /*д���ݳ���*/
	output [ADDR_WIDTH - 1:0] rd_burst_addr,           /*���׵�ַ*/
	output reg[ADDR_WIDTH - 1:0] wr_burst_addr,        /*д�׵�ַ*/
	input rd_burst_data_valid,                         /*����������Ч*/
	input wr_burst_data_req,                           /*д�����ź�*/
	input[DATA_WIDTH - 1:0] rd_burst_data,             /*����������*/
	output[DATA_WIDTH - 1:0] wr_burst_data,            /*д�������*/
	input rd_burst_finish,                             /*�����*/
	input wr_burst_finish,                             /*д���*/
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


//////////״̬����///////////////
always@(posedge	phy_clk)
	begin
		if(~init_calib_complete)          //�ȴ���ʼ���ɹ�
			state <= IDLE;
		else	
			state <= next_state;
	end
	
//////ѭ������DDR Burst��,Burstд״̬///////////
always@(*)
	begin 
		case(state)
			IDLE:
				next_state <= MEM_WRITE;  
			MEM_WRITE:                    //д�����ݵ�DDR3
				if(wr_burst_finish)          
					next_state <= MEM_READ;
				else
					next_state <= MEM_WRITE;
			MEM_READ:                    //�������ݴ�DDR3
				if(rd_burst_finish)
					next_state <= MEM_WRITE;
				else
					next_state <= MEM_READ;
			default:
				next_state <= IDLE;
		endcase
end



//DDR�Ķ�д��ַ��DDR��������//
always@(posedge phy_clk)
	begin
		if(state == IDLE && next_state == MEM_WRITE)
			wr_burst_addr <= {ADDR_WIDTH{1'b0}};     //��ַ����
		else if(state == MEM_READ && next_state == MEM_WRITE)                //һ��Burst��д���
			wr_burst_addr <= wr_burst_addr + {{(ADDR_WIDTH-8){1'b0}},8'd255}; //��ַ��burst����255         
		else
			wr_burst_addr <= wr_burst_addr;           //�����ַ
	end
assign rd_burst_addr = wr_burst_addr;     
assign wr_burst_data = {(DATA_WIDTH/8){wr_cnt[7:0]}};     //д��DDR������

//����burstд�����ź�
always@(posedge phy_clk)
	begin
		if(next_state == MEM_WRITE && state != MEM_WRITE)
			begin
				wr_burst_req <= 1'b1;      //����ddr burstд����       
				wr_burst_len <= 10'd255;
				wr_cnt <= 10'd0;
			end
		else if(wr_burst_data_req)       //д��burst�������� 
			begin
				wr_burst_req <= 1'b0;
				wr_burst_len <= 10'd255;
				wr_cnt <= wr_cnt + 10'd1;  //��������(ÿ�ֽ�)��1
			end
		else
			begin
				wr_burst_req <= wr_burst_req;
				wr_burst_len <= 10'd255;
				wr_cnt <= wr_cnt;
			end
	end

//����burst�������ź�	
always@(posedge phy_clk)
	begin
		if(next_state == MEM_READ && state != MEM_READ)
			begin
				rd_burst_req <= 1'b1;      //����ddr burst������  
				rd_burst_len <= 10'd255;
				rd_cnt <= 10'd1;
			end
		else if(rd_burst_data_valid)     //��⵽data_valid�ź�,burst�������0
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
	
assign error = rd_burst_data_valid &(rd_burst_data != {(DATA_WIDTH/8){rd_cnt[7:0]}});       //���DDR�����������Ƿ���ȷ



endmodule
