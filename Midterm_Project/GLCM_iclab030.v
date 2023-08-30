//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Si2 LAB @NCTU ED415
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 spring
//   Midterm Proejct            : GLCM 
//   Author                     : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : GLCM.v
//   Module Name : GLCM
//   Release version : V1.0 (Release Date: 2023-04)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module GLCM(
				clk,	
			  rst_n,	
	
			in_addr_M,
			in_addr_G,
			in_dir,
			in_dis,
			in_valid,
			out_valid,
	

         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 
);
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 32;
input			  clk,rst_n;
   
// -----------------------------
parameter S_IDLE          = 3'b000;
parameter S_IN            = 3'b001;
parameter S_REQUEST_READ  = 3'b010;
parameter S_READ          = 3'b011;
parameter S_CAL           = 3'b100;
parameter S_REQUEST_WRITE = 3'b101;
parameter S_WRITE         = 3'b110;
parameter S_OUT           = 3'b111;

// -----------------------------
// IO port
input [ADDR_WIDTH-1:0]      in_addr_M;
input [ADDR_WIDTH-1:0]      in_addr_G;
input [1:0]  	  		in_dir;
input [3:0]	    		in_dis;
input 			    	in_valid;
output reg 	              out_valid;
// -----------------------------
// axi write address channel 
output  wire [ID_WIDTH-1:0]        awid_m_inf;
output  wire [ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [2:0]            awsize_m_inf;
output  wire [1:0]           awburst_m_inf;
output  wire [3:0]             awlen_m_inf;
output  wire                 awvalid_m_inf;
input   wire                 awready_m_inf;
// axi write data channel 
output  wire [ DATA_WIDTH-1:0]     wdata_m_inf;
output  wire                   wlast_m_inf;
output  wire                  wvalid_m_inf;
input   wire                  wready_m_inf;
// axi write response channel
input   wire [ID_WIDTH-1:0]         bid_m_inf;
input   wire [1:0]             bresp_m_inf;
input   wire              	   bvalid_m_inf;
output  wire                  bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [ID_WIDTH-1:0]       arid_m_inf;
output  wire [ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [3:0]            arlen_m_inf;
output  wire [2:0]           arsize_m_inf;
output  wire [1:0]          arburst_m_inf;
output  wire                arvalid_m_inf;
input   wire               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [ID_WIDTH-1:0]         rid_m_inf;
input   wire [DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [1:0]             rresp_m_inf;
input   wire                   rlast_m_inf;
input   wire                  rvalid_m_inf;
output  wire                  rready_m_inf;
// -----------------------------
// AXI read parameter
assign arid_m_inf = 'd0;
assign arlen_m_inf = 4'b1111;
assign arsize_m_inf = 3'b010;
assign arburst_m_inf = 2'b01;
assign rready_m_inf = 1'b1;
// -----------------------------
// AXI write parameter
// axi write address channel 
assign awid_m_inf = 'd0;
assign awsize_m_inf = 3'b010;   
assign awburst_m_inf = 2'b01;
assign awlen_m_inf = 'd15;
// axi write data channel 
// axi write response channel
assign bready_m_inf = 1'b1;
// -----------------------------

//--------------------FSM--------------------
reg [2:0] current_state;
reg [2:0] next_state;


// -----------------------------
// input
reg [ADDR_WIDTH-1:0] addr_M;
reg [ADDR_WIDTH-1:0] addr_G;
reg [1:0] dir;
reg [3:0] dis;

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		addr_M <= 0;
	end
	else if(in_valid)
		addr_M <= in_addr_M;
	else
		addr_M <= addr_M;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		addr_G <= 0;
	end
	else if(in_valid)
		addr_G <= in_addr_G;
	else
		addr_G <= addr_G;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		dir <= 0;
	end
	else if(in_valid)
		dir <= in_dir;
	else
		dir <= dir;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		dis <= 0;
	end
	else if(in_valid)
		dis <= in_dis;
	else
		dis <= dis;
end

// count for read DRAM
reg [3:0] count_rvalid;
reg [1:0] count_read;
reg [1:0] next_count_read;

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count_rvalid <= 0;
	end else if(rvalid_m_inf)
		count_rvalid <= count_rvalid + 1;
	else
		count_rvalid <= count_rvalid;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count_read <= 0;
	end else if(count_rvalid == 'd15)
		count_read <= count_read + 1;
	else
		count_read <= count_read;
end

always@(*) begin
	if(count_rvalid == 'd15)
		next_count_read = count_read + 1;
	else
		next_count_read = count_read;
end

// DRAM input control
reg [ADDR_WIDTH-1:0] dram_read_addr;
reg dram_read_enable;
reg [ADDR_WIDTH-1:0] next_dram_read_addr;
reg next_dram_read_enable;
assign araddr_m_inf = dram_read_addr; 
assign arvalid_m_inf = next_dram_read_enable;

always@(*) begin
	next_dram_read_addr = addr_M + {next_count_read,6'd0};
end

always@(*) begin
	case(current_state)
	S_REQUEST_READ: next_dram_read_enable = 1;
	default: next_dram_read_enable = 0;
	endcase
end

always@(posedge clk) begin
	dram_read_addr <= next_dram_read_addr;
end

always@(posedge clk) begin
	dram_read_enable <= next_dram_read_enable;
end


// buff dram output
reg [4:0] dram_out_buff[19:0];
integer i, j;

// calculation address
reg [1:0] cal_x;
reg [3:0] cal_y;
reg [2:0] count_cal;
wire [1:0] target_cal_x;
wire [3:0] target_cal_y;
assign target_cal_x = cal_x + dir[1]*(dis/4);
assign target_cal_y = cal_y + dir[0]*dis;


always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		count_cal <= 0;
	else if(current_state == S_CAL && !(target_cal_x == 3 && count_cal % 2 == 1))
		count_cal <= count_cal + 1;
	else
		count_cal <= 0;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		cal_x <= 0;
	else if(current_state == S_IDLE || (target_cal_x == 3 && count_cal % 2 == 1))
		cal_x <= 0;
	else if(current_state == S_CAL && count_cal % 2 == 1)
		cal_x <= cal_x + 1;
	else
		cal_x <= cal_x;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		cal_y <= 0;
	else if(current_state == S_IDLE)
		cal_y <= 0;
	else if(current_state == S_CAL && (target_cal_x == 3 && count_cal % 2 == 1))
		cal_y <= cal_y + 1;
	else
		cal_y <= cal_y;
end

// -----------------SRAM---------------------------
wire [19:0] mem_out;
wire [19:0] mem_in;
reg [5:0] mem_addr;
reg mem_wen;
assign mem_in = {rdata_m_inf[28:24],rdata_m_inf[20:16],rdata_m_inf[12:8],rdata_m_inf[4:0]};

always@(*) begin
	if(current_state == S_READ)
		mem_addr = {count_read, count_rvalid};
	else if(current_state == S_CAL) begin
		if(count_cal % 2 == 1)
			mem_addr = {cal_y, cal_x};
		else
			mem_addr = {target_cal_y, target_cal_x};
	end else
		mem_addr = 0;
end
always@(*) begin
	case(current_state)
	S_READ: mem_wen = 0;
	default: mem_wen = 1;
	endcase
end
MEM_64_20 my_mem(.CLK(clk), .CEN(1'b0), .OEN(1'b0), .WEN(mem_wen), .A(mem_addr), .D(mem_in), .Q(mem_out));

// mem out buff
reg [19:0] mem_buff1;
reg [19:0] mem_buff2;
reg [19:0] mem_buff3;
reg [59:0] mem_buff;
always@(posedge clk) begin
	mem_buff1 <= mem_out;
	mem_buff2 <= mem_buff1;
	mem_buff3 <= mem_buff2;
end

wire [4:0] judge_x_1;
wire [4:0] judge_x_2;
wire [4:0] judge_x_3;
wire [4:0] judge_x_4;
reg [4:0] judge_y_1;
reg [4:0] judge_y_2;
reg [4:0] judge_y_3;
reg [4:0] judge_y_4;

assign judge_x_4 = (~count_cal[0]) ? mem_buff2[19:15] : mem_buff1[19:15];
assign judge_x_3 = (~count_cal[0]) ? mem_buff2[14:10] : mem_buff1[14:10];
assign judge_x_2 = (~count_cal[0]) ? mem_buff2[9:5] : mem_buff1[9:5];
assign judge_x_1 = (~count_cal[0]) ? mem_buff2[4:0] : mem_buff1[4:0];

wire [1:0] bias;
assign bias = (dir == 1) ? 2'd0 : (dis%'d4);
always@(*) begin
	if(((dis%'d4) == 'd0) || ( dir == 1) )
		judge_y_1 = (~count_cal[0]) ? mem_buff3[4:0] : mem_buff2[4:0];
	else if((dis%'d4) == 'd1)
		judge_y_1 = (~count_cal[0]) ? mem_buff3[9:5] : mem_buff2[9:5];
	else if((dis%'d4) == 'd2)
		judge_y_1 = (~count_cal[0]) ? mem_buff3[14:10] : mem_buff2[14:10];
	else
		judge_y_1 = (~count_cal[0]) ? mem_buff3[19:15] : mem_buff2[19:15];
	
end
always@(*) begin
	if(bias == 'd0)
		judge_y_2 = (~count_cal[0]) ? mem_buff3[9:5] : mem_buff2[9:5];
	else if(bias == 'd1)
		judge_y_2 = (~count_cal[0]) ? mem_buff3[14:10] : mem_buff2[14:10];
	else if(bias == 'd2)
		judge_y_2 = (~count_cal[0]) ? mem_buff3[19:15] : mem_buff2[19:15];
	else
		judge_y_2 = mem_buff1[4:0];
end
always@(*) begin
	if(bias == 'd0)
		judge_y_3 = (~count_cal[0]) ? mem_buff3[14:10] : mem_buff2[14:10];
	else if(bias == 'd1)
		judge_y_3 = (~count_cal[0]) ? mem_buff3[19:15] : mem_buff2[19:15];
	else if(bias == 'd2)
		judge_y_3 = mem_buff1[4:0];
	else
		judge_y_3 = mem_buff1[9:5];
end
always@(*) begin
	if(bias == 'd0)
		judge_y_4 = (~count_cal[0]) ? mem_buff3[19:15] : mem_buff2[19:15];
	else if(bias == 'd1)
		judge_y_4 = mem_buff1[4:0];
	else if(bias == 'd2)
		judge_y_4 = mem_buff1[9:5];
	else
		judge_y_4 = mem_buff1[14:10];
end

reg [4:0] judge_x_1_buf;
reg [4:0] judge_x_2_buf;
reg [4:0] judge_x_3_buf;
reg [4:0] judge_x_4_buf;
reg [4:0] judge_y_1_buf;
reg [4:0] judge_y_2_buf;
reg [4:0] judge_y_3_buf;
reg [4:0] judge_y_4_buf;

always@(posedge clk) begin
	judge_x_1_buf <= judge_x_1;
end
always@(posedge clk) begin
	judge_x_2_buf <= judge_x_2;
end
always@(posedge clk) begin
	judge_x_3_buf <= judge_x_3;
end
always@(posedge clk) begin
	judge_x_4_buf <= judge_x_4;
end
always@(posedge clk) begin
	judge_y_1_buf <= judge_y_1;
end
always@(posedge clk) begin
	judge_y_2_buf <= judge_y_2;
end
always@(posedge clk) begin
	judge_y_3_buf <= judge_y_3;
end
always@(posedge clk) begin
	judge_y_4_buf <= judge_y_4;
end

reg compare_enable_1;
reg compare_enable_2;
reg compare_enable_3;
reg compare_enable_4;
always@(posedge clk) begin
	if( (count_cal != 0 && ~count_cal[0]) || (target_cal_x == 3 && count_cal % 2 == 1) )
		compare_enable_1 <= 1;
	else if(dir == 1 && (target_cal_x == 3 && count_cal % 2 == 1))
		compare_enable_1 <= 1;
	else
		compare_enable_1 <= 0;
end
always@(posedge clk) begin
	if(count_cal != 0 && ~count_cal[0])
		compare_enable_2 <= 1;
	else if( (dis % 4 != 3) && (target_cal_x == 3 && count_cal % 2 == 1))
		compare_enable_2 <= 1;
	else if(dir == 1 && (target_cal_x == 3 && count_cal % 2 == 1))
		compare_enable_2 <= 1;
	else
		compare_enable_2 <= 0;
end
always@(posedge clk) begin
	if(count_cal != 0 && ~count_cal[0])
		compare_enable_3 <= 1;
	else if( (dis % 4 != 3) && (dis % 4 != 2) && (target_cal_x == 3 && count_cal % 2 == 1))
		compare_enable_3 <= 1;
	else if(dir == 1 && (target_cal_x == 3 && count_cal % 2 == 1))
		compare_enable_3 <= 1;
	else
		compare_enable_3 <= 0;
end
always@(posedge clk) begin
	if(count_cal != 0 && ~count_cal[0])
		compare_enable_4 <= 1;
	else if( (dis % 4 == 0) && (target_cal_x == 3 && count_cal % 2 == 1))
		compare_enable_4 <= 1;
	else if(dir == 1 && (target_cal_x == 3 && count_cal % 2 == 1))
		compare_enable_4 <= 1;
	else
		compare_enable_4 <= 0;
end

reg compare_enable_1_delay_1;
reg compare_enable_2_delay_1;
reg compare_enable_3_delay_1;
reg compare_enable_4_delay_1;
always@(posedge clk) begin
	compare_enable_1_delay_1 <= compare_enable_1;
end
always@(posedge clk) begin
	compare_enable_2_delay_1 <= compare_enable_2;
end
always@(posedge clk) begin
	compare_enable_3_delay_1 <= compare_enable_3;
end
always@(posedge clk) begin
	compare_enable_4_delay_1 <= compare_enable_4;
end

reg compare_enable_1_delay_2;
reg compare_enable_2_delay_2;
reg compare_enable_3_delay_2;
reg compare_enable_4_delay_2;
always@(posedge clk) begin
	compare_enable_1_delay_2 <= compare_enable_1_delay_1;
end
always@(posedge clk) begin
	compare_enable_2_delay_2 <= compare_enable_2_delay_1;
end
always@(posedge clk) begin
	compare_enable_3_delay_2 <= compare_enable_3_delay_1;
end
always@(posedge clk) begin
	compare_enable_4_delay_2 <= compare_enable_4_delay_1;
end

// get GLCM
reg glcm_plus_1 [31:0][31:0];
reg glcm_plus_2 [31:0][31:0];
reg glcm_plus_3 [31:0][31:0];
reg glcm_plus_4 [31:0][31:0];
reg glcm_plus_1_buf [31:0][31:0];
reg glcm_plus_2_buf [31:0][31:0];
reg glcm_plus_3_buf [31:0][31:0];
reg glcm_plus_4_buf [31:0][31:0];
genvar gen_x;
genvar gen_y;
generate
for(gen_x = 0;gen_x<32;gen_x=gen_x+1) begin
	for(gen_y = 0;gen_y<32;gen_y=gen_y+1) begin
		always@(*) begin
			glcm_plus_1[gen_y][gen_x] = ( compare_enable_1_delay_2 && (gen_x == judge_x_1_buf) && (gen_y == judge_y_1_buf) );
		end
	end
end
for(gen_x = 0;gen_x<32;gen_x=gen_x+1) begin
	for(gen_y = 0;gen_y<32;gen_y=gen_y+1) begin
		always@(*) begin
			glcm_plus_2[gen_y][gen_x] = ( compare_enable_2_delay_2 && (gen_x == judge_x_2_buf) && (gen_y == judge_y_2_buf) );
		end
	end
end
for(gen_x = 0;gen_x<32;gen_x=gen_x+1) begin
	for(gen_y = 0;gen_y<32;gen_y=gen_y+1) begin
		always@(*) begin
			glcm_plus_3[gen_y][gen_x] = ( compare_enable_3_delay_2 && (gen_x == judge_x_3_buf) && (gen_y == judge_y_3_buf) );
		end
	end
end
for(gen_x = 0;gen_x<32;gen_x=gen_x+1) begin
	for(gen_y = 0;gen_y<32;gen_y=gen_y+1) begin
		always@(*) begin
			glcm_plus_4[gen_y][gen_x] = ( compare_enable_4_delay_2 && (gen_x == judge_x_4_buf) && (gen_y == judge_y_4_buf) );
		end
	end
end

for(gen_x = 0;gen_x<32;gen_x=gen_x+1) begin
	for(gen_y = 0;gen_y<32;gen_y=gen_y+1) begin
		always@(posedge clk) begin
			glcm_plus_1_buf[gen_y][gen_x] = glcm_plus_1[gen_y][gen_x];
		end
	end
end
for(gen_x = 0;gen_x<32;gen_x=gen_x+1) begin
	for(gen_y = 0;gen_y<32;gen_y=gen_y+1) begin
		always@(posedge clk) begin
			glcm_plus_2_buf[gen_y][gen_x] = glcm_plus_2[gen_y][gen_x];
		end
	end
end
for(gen_x = 0;gen_x<32;gen_x=gen_x+1) begin
	for(gen_y = 0;gen_y<32;gen_y=gen_y+1) begin
		always@(posedge clk) begin
			glcm_plus_3_buf[gen_y][gen_x] = glcm_plus_3[gen_y][gen_x];
		end
	end
end
for(gen_x = 0;gen_x<32;gen_x=gen_x+1) begin
	for(gen_y = 0;gen_y<32;gen_y=gen_y+1) begin
		always@(posedge clk) begin
			glcm_plus_4_buf[gen_y][gen_x] = glcm_plus_4[gen_y][gen_x];
		end
	end
end

endgenerate




reg [7:0] glcm_matrix [31:0][31:0];
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i=0;i<32;i=i+1)
			for(j=0;j<32;j=j+1)
				glcm_matrix[i][j] <= 0; 
	end
	else if (current_state == S_CAL) begin
		for(i=0;i<32;i=i+1)
			for(j=0;j<32;j=j+1)
				glcm_matrix[i][j] <= glcm_matrix[i][j] + glcm_plus_1_buf[i][j] + glcm_plus_2_buf[i][j] + glcm_plus_3_buf[i][j] + glcm_plus_4_buf[i][j];
	end
	else if (current_state == S_REQUEST_WRITE || current_state == S_WRITE) begin
		for(i=0;i<32;i=i+1)
			for(j=0;j<32;j=j+1)
				glcm_matrix[i][j] <= glcm_matrix[i][j];
	end
	else begin
		for(i=0;i<32;i=i+1)
			for(j=0;j<32;j=j+1)
				glcm_matrix[i][j] <= 0;
	end
end

// calculate done signal
reg cal_done;
always@(posedge clk) begin
	cal_done <= target_cal_y == 'd15 && target_cal_x == 3 && count_cal % 2 == 1;
end
reg cal_done_delay_1;
always@(posedge clk) begin
	cal_done_delay_1 <= cal_done;
end
reg cal_done_delay_2;
always@(posedge clk) begin
	cal_done_delay_2 <= cal_done_delay_1;
end
reg cal_done_delay_3;
always@(posedge clk) begin
	cal_done_delay_3 <= cal_done_delay_2;
end

// write DRAM
// count for read DRAM
reg [3:0] count_wready;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count_wready <= 0;
	end else if(wready_m_inf)
		count_wready <= count_wready + 1;
	else
		count_wready <= count_wready;
end

reg [3:0] count_write;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count_write <= 0;
	end else if(bvalid_m_inf)
		count_write <= count_write + 1;
	else
		count_write <= count_write;
end

reg [ADDR_WIDTH-1:0] next_dram_write_addr;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		next_dram_write_addr <= 0;
	end else if(current_state == S_REQUEST_WRITE)
		next_dram_write_addr <= addr_G + {count_write,6'd0};
	else
		next_dram_write_addr <= next_dram_write_addr;
end

// DRAM output control
reg [ADDR_WIDTH-1:0] dram_write_addr;
reg dram_write_enable;
assign awaddr_m_inf = dram_write_addr; 
assign awvalid_m_inf = dram_write_enable;
assign wlast_m_inf = (count_wready == 'd15);
assign wvalid_m_inf = (current_state == S_WRITE);

always@(*) begin
	dram_write_addr = next_dram_write_addr;
end

always@(*) begin
	case(current_state)
	S_REQUEST_WRITE: dram_write_enable = 1;
	default: dram_write_enable = 0;
	endcase
end

// select dram write input
reg [DATA_WIDTH-1:0] who_to_write;
assign wdata_m_inf = who_to_write;
reg [4:0] to_write_x;
reg [4:0] to_write_y;
wire [3:0] next_count_wready;
assign next_count_wready = count_wready + 1;
always@(*) begin
	to_write_x = {next_count_wready[2:0],2'b0};
end
always@(*) begin
	to_write_y = {count_write, next_count_wready[3]};
end

reg [4:0] init_to_write_y;
always@(*) begin
	init_to_write_y = {count_write, 1'd0};
end

reg [DATA_WIDTH-1:0] next_who_to_write;
always@(posedge clk) begin
	who_to_write <= next_who_to_write;
end
always@(*) begin
	if(wready_m_inf)
		next_who_to_write = {glcm_matrix[to_write_x+3][to_write_y],glcm_matrix[to_write_x+2][to_write_y],glcm_matrix[to_write_x+1][to_write_y],glcm_matrix[to_write_x][to_write_y]};
	else if(current_state == S_REQUEST_WRITE)
		next_who_to_write = {glcm_matrix[3][init_to_write_y],glcm_matrix[2][init_to_write_y],glcm_matrix[1][init_to_write_y],glcm_matrix[0][init_to_write_y]};
	else
		next_who_to_write = who_to_write;
end



// -----------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		current_state <= S_IDLE;
	end
	else
		current_state <= next_state;
end

always@(*) begin
	case(current_state)
	S_IDLE:
		if(in_valid)
			next_state = S_IN;
		else
			next_state = S_IDLE;
	S_IN: next_state = S_REQUEST_READ;
	S_REQUEST_READ:
	if(arready_m_inf)
		next_state = S_READ;
	else
		next_state = S_REQUEST_READ;
	S_READ:
		if(count_read == 'd3 && rlast_m_inf)
			next_state = S_CAL;
		else if(rlast_m_inf)
			next_state = S_REQUEST_READ;
		else
			next_state = S_READ;
	S_CAL:
		if(cal_done_delay_3)
			next_state = S_REQUEST_WRITE;
		else
			next_state = S_CAL;
	S_REQUEST_WRITE:
		if(awready_m_inf)
			next_state = S_WRITE;
		else
			next_state = S_REQUEST_WRITE;
	S_WRITE:
		if(count_write == 'd15 && bvalid_m_inf)
			next_state = S_OUT;
		else if(bvalid_m_inf)
			next_state = S_REQUEST_WRITE;
		else
			next_state = S_WRITE;
	default: next_state = S_IDLE;
	endcase
end

// -----------------------------
// out_valid
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
	end
	else if(current_state == S_OUT)
		out_valid <= 1;
	else
		out_valid <= 0;
end

endmodule








