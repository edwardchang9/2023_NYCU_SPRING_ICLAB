//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   ICLAB 2023 Final Project: Customized ISA Processor 
//   Author              : Hsi-Hao Huang
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//
//   File Name   : CPU.v
//   Module Name : CPU.v
//   Release version : V1.0 (Release Date: 2023-May)
//
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
//synopsys translate_off
`include "DW02_mult_2_stage.v"
//synopsys translate_on
module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

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
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;
// axi parameter
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/
// -----------------------------
// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;

//----------------------------------------------------
//               state parameter
//----------------------------------------------------
// RISC 5 state fsm cpu

// ADD: 				S_INST_FETCH -> S_EXECUTE
// SUB: 				S_INST_FETCH -> S_EXECUTE
// SET LESS THAN: 		S_INST_FETCH -> S_EXECUTE
// MULT:  				S_INST_FETCH -> S_EXECUTE    ->  S_MULT
// LOAD:  				S_INST_FETCH -> S_DATA_DRAM
// STORE:  				S_INST_FETCH -> S_DATA_DRAM
// BRANCH ON EQUAL:		S_INST_FETCH -> S_JUMP
// JUMP:  				S_INST_FETCH -> S_JUMP

parameter S_INIT 			= 'd7;
parameter S_INST_FETCH 		= 'd0;
parameter S_EXECUTE 		= 'd1;
parameter S_MULT	 		= 'd2;
parameter S_STORE_RESULT 	= 'd3;
parameter S_DATA_DRAM 		= 'd4;
parameter S_JUMP	 		= 'd6;
//----------------------------------------------------
//               reg & wire
//----------------------------------------------------
// fsm
reg [2:0] current_state;
reg [2:0] next_state;

// inst dram signal
reg inst_in_valid;
reg signed [15:0] inst_in_addr;
reg signed [15:0] next_inst_in_addr;
wire inst_out_valid;
wire [15:0] inst_out_data;
// data dram signal
reg data_in_valid;
wire data_read;
wire [10:0] data_in_addr;
wire data_out_valid;
wire [15:0] data_out_data;

// inst decode
wire [2:0] opcode;
wire [3:0] rs;
wire [3:0] rt;
wire [3:0] rd;
wire funct;
wire [12:0] address;
wire signed [4:0] immediate;
assign opcode = inst_out_data[15:13];
assign rs = inst_out_data[12:9];
assign rt = inst_out_data[8:5];
assign rd = inst_out_data[4:1];
assign funct = inst_out_data[0];
assign address = inst_out_data[11:0];
assign immediate = inst_out_data[4:0];

// operand
reg signed [15:0] rs_data;
reg signed [15:0] rt_data;
reg signed [15:0] rd_data;
reg signed [15:0] next_rt_data;
reg signed [15:0] next_rd_data;

// execute
wire signed [15:0] 	add_out;
wire signed [15:0] 	sub_out;
wire signed [15:0] 	mult_out;
wire 				comp_out;
wire 				equal_out;
wire signed [15:0] 	cal_data_addr;
wire signed [15:0] 	cal_jump_addr;

//----------------------------------------------------
//               dram dealer
//----------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		inst_in_valid <= 0;
	else
		inst_in_valid <= current_state != S_INST_FETCH && next_state == S_INST_FETCH;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		inst_in_addr <= 'h1000;
	else
		inst_in_addr <= next_inst_in_addr;
end

always@(*) begin
	case(current_state)
	S_JUMP: begin
		if(equal_out && opcode[0])
			next_inst_in_addr = inst_in_addr + 2 + immediate*2;
		else if(~opcode[0])
			next_inst_in_addr = cal_jump_addr;
		else
			next_inst_in_addr = inst_in_addr + 2;
	end
	S_EXECUTE: begin
		next_inst_in_addr = inst_in_addr + 2;
	end
	S_DATA_DRAM:
		if(data_out_valid)
			next_inst_in_addr = inst_in_addr + 2;
		else
			next_inst_in_addr = inst_in_addr;
	default: next_inst_in_addr = inst_in_addr;
	endcase
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		data_in_valid <= 0;
	else
		data_in_valid <= (current_state != S_DATA_DRAM && next_state == S_DATA_DRAM);
end

assign data_in_addr = cal_data_addr[11:1];
assign data_read = opcode[0];



wire [15:0] sram_out_data;
reg [15:0] sram_actual_in_data;
reg [7:0] sram_actual_in_addr;
reg sram_actual_read_write;

// data
wire [6:0] data_sram_addr;
wire data_sram_read_write;
wire [15:0] data_sram_in_data;
// inst
wire [6:0] inst_sram_addr;
wire inst_sram_read_write;

always@(*) begin
	if(current_state == S_INST_FETCH) begin
		sram_actual_in_data = rdata_m_inf[2*DATA_WIDTH-1:DATA_WIDTH];
	end else begin
		sram_actual_in_data = data_sram_in_data;
	end
end

always@(*) begin
	if(current_state == S_INST_FETCH) begin
		sram_actual_in_addr = {1'b1,inst_sram_addr};
	end else begin
		sram_actual_in_addr = {1'b0,data_sram_addr};
	end
end

always@(*) begin
	if(current_state == S_INST_FETCH) begin
		sram_actual_read_write = inst_sram_read_write;
	end else begin
		sram_actual_read_write = data_sram_read_write;
	end
end

FINAL_SRAM_BIG inst_dram_cache(.Q(sram_out_data), .CLK(clk), .CEN(1'd0), .WEN(sram_actual_read_write), .A(sram_actual_in_addr), .D(sram_actual_in_data), .OEN(1'd0));

Inst_Dram_Dealer inst_dram_dealer(
	.clk(clk), .rst_n(rst_n),
	.in_valid(inst_in_valid),
	.in_addr(inst_in_addr[11:1]),
	.out_valid(inst_out_valid),.out_data(inst_out_data),
	   
         .arid_m_inf(arid_m_inf[2*ID_WIDTH-1:ID_WIDTH]),
       .araddr_m_inf(araddr_m_inf[2*ADDR_WIDTH-1:ADDR_WIDTH]),
        .arlen_m_inf(arlen_m_inf[13:7]),
       .arsize_m_inf(arsize_m_inf[5:3]),
      .arburst_m_inf(arburst_m_inf[3:2]),
      .arvalid_m_inf(arvalid_m_inf[1]),
      .arready_m_inf(arready_m_inf[1]), 
                 
          .rid_m_inf(rid_m_inf[2*ID_WIDTH-1:ID_WIDTH]),
        .rdata_m_inf(rdata_m_inf[2*DATA_WIDTH-1:DATA_WIDTH]),
        .rresp_m_inf(rresp_m_inf[3:2]),
        .rlast_m_inf(rlast_m_inf[1]),
       .rvalid_m_inf(rvalid_m_inf[1]),
       .rready_m_inf(rready_m_inf[1]) ,
	   .sram_out_data(sram_out_data),
	   .sram_read_write(inst_sram_read_write),
	   .sram_addr(inst_sram_addr)
		
);

Data_Dram_Dealer data_dram_dealer(
	.clk(clk), .rst_n(rst_n),
	.in_valid(data_in_valid), .read(data_read),
	.in_data(next_rt_data), .in_addr(data_in_addr),
	.out_valid(data_out_valid),.out_data(data_out_data),
		
		 .awid_m_inf(awid_m_inf),
       .awaddr_m_inf(awaddr_m_inf),
       .awsize_m_inf(awsize_m_inf),
      .awburst_m_inf(awburst_m_inf),
        .awlen_m_inf(awlen_m_inf),
      .awvalid_m_inf(awvalid_m_inf),
      .awready_m_inf(awready_m_inf),
                    
        .wdata_m_inf(wdata_m_inf),
        .wlast_m_inf(wlast_m_inf),
       .wvalid_m_inf(wvalid_m_inf),
       .wready_m_inf(wready_m_inf),
                    
          .bid_m_inf(bid_m_inf),
        .bresp_m_inf(bresp_m_inf),
       .bvalid_m_inf(bvalid_m_inf),
       .bready_m_inf(bready_m_inf),
	   
         .arid_m_inf(arid_m_inf[ID_WIDTH-1:0]),
       .araddr_m_inf(araddr_m_inf[ADDR_WIDTH-1:0]),
        .arlen_m_inf(arlen_m_inf[6:0]),
       .arsize_m_inf(arsize_m_inf[2:0]),
      .arburst_m_inf(arburst_m_inf[1:0]),
      .arvalid_m_inf(arvalid_m_inf[0]),
      .arready_m_inf(arready_m_inf[0]), 
                 
          .rid_m_inf(rid_m_inf[ID_WIDTH-1:0]),
        .rdata_m_inf(rdata_m_inf[DATA_WIDTH-1:0]),
        .rresp_m_inf(rresp_m_inf[1:0]),
        .rlast_m_inf(rlast_m_inf[0]),
       .rvalid_m_inf(rvalid_m_inf[0]),
       .rready_m_inf(rready_m_inf[0]) ,
	   	.sram_out_data(sram_out_data),
		.sram_addr(data_sram_addr),
		.sram_read_write(data_sram_read_write),
		.sram_in_data(data_sram_in_data)
);

//----------------------------------------------------
//               fetch operand
//----------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rs_data <= 0;
	end
	else if(inst_out_valid)
		case(rs)
		'd0:  rs_data <= core_r0;
		'd1:  rs_data <= core_r1;
		'd2:  rs_data <= core_r2;
		'd3:  rs_data <= core_r3;
		'd4:  rs_data <= core_r4;
		'd5:  rs_data <= core_r5;
		'd6:  rs_data <= core_r6;
		'd7:  rs_data <= core_r7;
		'd8:  rs_data <= core_r8;
		'd9:  rs_data <= core_r9;
		'd10: rs_data <= core_r10;
		'd11: rs_data <= core_r11;
		'd12: rs_data <= core_r12;
		'd13: rs_data <= core_r13;
		'd14: rs_data <= core_r14;
		'd15: rs_data <= core_r15;
		endcase
	else
		rs_data <= rs_data;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rt_data <= 0;
	end
	else
		rt_data <= next_rt_data;
end

always@(*) begin
	case(rt)
	'd0:  next_rt_data = core_r0;
	'd1:  next_rt_data = core_r1;
	'd2:  next_rt_data = core_r2;
	'd3:  next_rt_data = core_r3;
	'd4:  next_rt_data = core_r4;
	'd5:  next_rt_data = core_r5;
	'd6:  next_rt_data = core_r6;
	'd7:  next_rt_data = core_r7;
	'd8:  next_rt_data = core_r8;
	'd9:  next_rt_data = core_r9;
	'd10: next_rt_data = core_r10;
	'd11: next_rt_data = core_r11;
	'd12: next_rt_data = core_r12;
	'd13: next_rt_data = core_r13;
	'd14: next_rt_data = core_r14;
	'd15: next_rt_data = core_r15;
	endcase
end

//----------------------------------------------------
//               execute
//----------------------------------------------------
assign add_out = rs_data + rt_data;
assign sub_out = rs_data - rt_data;
assign mult_out = rs_data * rt_data;
assign comp_out = (rs_data < rt_data);
assign equal_out = (rs_data == rt_data);
assign cal_data_addr = (rs_data+immediate)*2 + $signed('h1000);
assign cal_jump_addr = {3'b0,inst_out_data[12:0]};

wire signed [31:0] multiplier_out;
DW02_mult_2_stage #(16, 16)
U1 ( .A(rs_data),
.B(rt_data),
.TC(1'd1),
.CLK(clk),
.PRODUCT(multiplier_out) );

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		rd_data <= 0;
	end else begin
		rd_data <= multiplier_out[15:0];
	end
end

always@(*) begin
	case({opcode[0],funct})
	'b01: next_rd_data = add_out;
	'b00: next_rd_data = sub_out;
	'b11: next_rd_data = comp_out;
	default: next_rd_data = comp_out;
	endcase
end

//----------------------------------------------------
//               register
//----------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r0 <= 0;
	end else if(data_read && data_out_valid && rt == 0) begin
		core_r0 <= data_out_data;
	end else if(current_state == S_MULT && rd == 0) begin
		core_r0 <= multiplier_out[15:0];
	end else if(current_state == S_EXECUTE && rd == 0) begin
		core_r0 <= next_rd_data;
	end else begin
		core_r0 <= core_r0;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r1 <= 0;
	end else if(data_read && data_out_valid && rt == 'd1) begin
		core_r1 <= data_out_data;
	end else if(current_state == S_MULT && rd == 'd1) begin
		core_r1 <= multiplier_out[15:0];
	end else if(current_state == S_EXECUTE && rd == 'd1) begin
		core_r1 <= next_rd_data;
	end else begin
		core_r1 <= core_r1;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r2 <= 0;
	end else if(data_read && data_out_valid && rt == 'd2) begin
		core_r2 <= data_out_data;
	end else if(current_state == S_MULT && rd == 'd2) begin
		core_r2 <= multiplier_out[15:0];
	end else if(current_state == S_EXECUTE && rd == 'd2) begin
		core_r2 <= next_rd_data;
	end else begin
		core_r2 <= core_r2;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r3 <= 0;
	end else if(data_read && data_out_valid && rt == 'd3) begin
		core_r3 <= data_out_data;
	end else if(current_state == S_MULT && rd == 'd3) begin
		core_r3 <= multiplier_out[15:0];
	end else if(current_state == S_EXECUTE && rd == 'd3) begin
		core_r3 <= next_rd_data;
	end else begin
		core_r3 <= core_r3;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r4 <= 0;
	end else if(data_read && data_out_valid && rt == 'd4) begin
		core_r4 <= data_out_data;
	end else if(current_state == S_MULT && rd == 'd4) begin
		core_r4 <= multiplier_out[15:0];
	end else if(current_state == S_EXECUTE && rd == 'd4) begin
		core_r4 <= next_rd_data;
	end else begin
		core_r4 <= core_r4;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r5 <= 0;
	end else if(data_read && data_out_valid && rt == 'd5) begin
		core_r5 <= data_out_data;
	end else if(current_state == S_MULT && rd == 'd5) begin
		core_r5 <= multiplier_out[15:0];
	end else if(current_state == S_EXECUTE && rd == 'd5) begin
		core_r5 <= next_rd_data;
	end else begin
		core_r5 <= core_r5;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r6 <= 0;
	end else if(data_read && data_out_valid && rt == 'd6) begin
		core_r6 <= data_out_data;
	end else if(current_state == S_MULT && rd == 'd6) begin
		core_r6 <= multiplier_out[15:0];
	end else if(current_state == S_EXECUTE && rd == 'd6) begin
		core_r6 <= next_rd_data;
	end else begin
		core_r6 <= core_r6;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r7 <= 0;
	end else if(data_read && data_out_valid && rt == 'd7) begin
		core_r7 <= data_out_data;
	end else if(current_state == S_MULT && rd == 'd7) begin
		core_r7 <= multiplier_out[15:0];
	end else if(current_state == S_EXECUTE && rd == 'd7) begin
		core_r7 <= next_rd_data;
	end else begin
		core_r7 <= core_r7;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r8 <= 0;
	end else if(data_read && data_out_valid && rt == 'd8) begin
		core_r8 <= data_out_data;
	end else if(current_state == S_MULT && rd == 'd8) begin
		core_r8 <= multiplier_out[15:0];
	end else if(current_state == S_EXECUTE && rd == 'd8) begin
		core_r8 <= next_rd_data;
	end else begin
		core_r8 <= core_r8;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r9 <= 0;
	end else if(data_read && data_out_valid && rt == 'd9) begin
		core_r9 <= data_out_data;
	end else if(current_state == S_MULT && rd == 'd9) begin
		core_r9 <= multiplier_out[15:0];
	end else if(current_state == S_EXECUTE && rd == 'd9) begin
		core_r9 <= next_rd_data;
	end else begin
		core_r9 <= core_r9;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r10 <= 0;
	end else if(data_read && data_out_valid && rt == 'd10) begin
		core_r10 <= data_out_data;
	end else if(current_state == S_MULT && rd == 'd10) begin
		core_r10 <= multiplier_out[15:0];
	end else if(current_state == S_EXECUTE && rd == 'd10) begin
		core_r10 <= next_rd_data;
	end else begin
		core_r10 <= core_r10;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r11 <= 0;
	end else if(data_read && data_out_valid && rt == 'd11) begin
		core_r11 <= data_out_data;
	end else if(current_state == S_MULT && rd == 'd11) begin
		core_r11 <= multiplier_out[15:0];
	end else if(current_state == S_EXECUTE && rd == 'd11) begin
		core_r11 <= next_rd_data;
	end else begin
		core_r11 <= core_r11;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r12 <= 0;
	end else if(data_read && data_out_valid && rt == 'd12) begin
		core_r12 <= data_out_data;
	end else if(current_state == S_MULT && rd == 'd12) begin
		core_r12 <= multiplier_out[15:0];
	end else if(current_state == S_EXECUTE && rd == 'd12) begin
		core_r12 <= next_rd_data;
	end else begin
		core_r12 <= core_r12;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r13 <= 0;
	end else if(data_read && data_out_valid && rt == 'd13) begin
		core_r13 <= data_out_data;
	end else if(current_state == S_MULT && rd == 'd13) begin
		core_r13 <= multiplier_out[15:0];
	end else if(current_state == S_EXECUTE && rd == 'd13) begin
		core_r13 <= next_rd_data;
	end else begin
		core_r13 <= core_r13;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r14 <= 0;
	end else if(data_read && data_out_valid && rt == 'd14) begin
		core_r14 <= data_out_data;
	end else if(current_state == S_MULT && rd == 'd14) begin
		core_r14 <= multiplier_out[15:0];
	end else if(current_state == S_EXECUTE && rd == 'd14) begin
		core_r14 <= next_rd_data;
	end else begin
		core_r14 <= core_r14;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		core_r15 <= 0;
	end else if(data_read && data_out_valid && rt == 'd15) begin
		core_r15 <= data_out_data;
	end else if(current_state == S_MULT && rd == 'd15) begin
		core_r15 <= multiplier_out[15:0];
	end else if(current_state == S_EXECUTE && rd == 'd15) begin
		core_r15 <= next_rd_data;
	end else begin
		core_r15 <= core_r15;
	end
end

//----------------------------------------------------
//               FSM
//----------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		current_state <= S_INIT;
	end else begin
		current_state <= next_state;
	end
end

always@(*) begin
	case(current_state)
	S_INIT:
		next_state = S_INST_FETCH;
	S_INST_FETCH:
		if(inst_out_valid) begin
			if(opcode[1])
				next_state = S_DATA_DRAM;
			else if(opcode[2])
				next_state = S_JUMP;
			else
				next_state = S_EXECUTE;
		end
		else begin
			next_state = S_INST_FETCH;
		end
	S_JUMP:
		next_state = S_INST_FETCH;
	S_DATA_DRAM:
		if(data_out_valid)
			next_state = S_INST_FETCH;
		else
			next_state = S_DATA_DRAM;
	S_EXECUTE:
		if(opcode[0] && ~funct)
			next_state = S_MULT;
		else
			next_state = S_INST_FETCH;
	S_MULT:
		next_state = S_INST_FETCH;
	default: next_state = S_INST_FETCH;
	endcase
end


//----------------------------------------------------
//               output
//----------------------------------------------------
// IO_stall
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		IO_stall <= 1;
	end else if(current_state != S_INST_FETCH && next_state == S_INST_FETCH && current_state != S_INIT) begin
		IO_stall <= 0;
	end else
		IO_stall <= 1;
end
endmodule

//----------------------------------------------------
//               submodule
//----------------------------------------------------

module Data_Dram_Dealer(
		clk,
		rst_n,
		in_valid,
		read,
		in_data,
		in_addr,
		out_valid,
		out_data,
		
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
       rready_m_inf,
		sram_out_data,
		sram_addr,
		sram_read_write,
		sram_in_data
);
// -----------------------------
// axi parameter
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=1, WRIT_NUMBER=1;
// input clk and reset signal
input clk;
input rst_n;
// valid signal
input in_valid;
input read;
input [15:0] in_data;
input [10:0] in_addr;
output wire out_valid;
output reg [15:0] out_data;
// sram signal
input wire [15:0] sram_out_data;
output reg [6:0] sram_addr;
output reg sram_read_write;
output reg [15:0] sram_in_data;
// -----------------------------
// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------
// axi assign
// write
assign awid_m_inf = 'd0;
assign awsize_m_inf = 3'b001;
assign awburst_m_inf = 2'b01;
assign awlen_m_inf = 7'd0;

// read
assign arid_m_inf = 'd0;
assign arlen_m_inf = 7'b111_1111;
assign arsize_m_inf = 3'b001;
assign arburst_m_inf = 2'b01;

// -----------------------------

//----------------------------------------------------
//               state parameter
//----------------------------------------------------
parameter S_IDLE = 'd0;
parameter S_REQUEST = 'd1;
parameter S_WAIT = 'd2;
parameter S_HIT = 'd3;
parameter S_HIT_1 = 'd4;
parameter S_WRITE_REQUEST = 'd5;
parameter S_WRITE_SEND = 'd6;
parameter S_WRITE_WAIT = 'd7;
//----------------------------------------------------
//               reg
//----------------------------------------------------
reg [2:0] current_state;
reg [2:0] next_state;

reg sram_data_is_valid;


reg [6:0] count_addr;
reg [3:0] save_addr;



reg [15:0] save_out_data;

wire hit;
assign hit = sram_data_is_valid && (save_addr == in_addr[10:7]);

//FINAL_SRAM data_dram_cache(.Q(sram_out_data), .CLK(clk), .CEN(1'd0), .WEN(sram_read_write), .A(sram_addr), .D(sram_in_data), .OEN(1'd0));

//----------------------------------------------------
//               save info
//----------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		sram_data_is_valid <= 0;
	end else if(rlast_m_inf) begin
		sram_data_is_valid <= 1;
	end else begin
		sram_data_is_valid <= sram_data_is_valid;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count_addr <= 0;
	end else if(rvalid_m_inf)
		count_addr <= count_addr + 1;
	else
		count_addr <= count_addr;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		save_addr <= 0;
	end else if(in_valid && read) begin
		save_addr <= in_addr[10:7];
	end else begin
		save_addr <= save_addr;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		save_out_data <= 0;
	end else if(rvalid_m_inf && in_addr[6:0] == sram_addr) begin
		save_out_data <= rdata_m_inf;
	end else if(current_state == S_HIT) begin
		save_out_data <= sram_out_data;
	end else begin
		save_out_data <= save_out_data;
	end
end

//----------------------------------------------------
//               sram input control
//----------------------------------------------------
always@(*) begin
	case(current_state)
	S_WAIT: sram_read_write = 'd0;
	S_WRITE_REQUEST:
		if(hit)
			sram_read_write = 'd0;
		else
			sram_read_write = 'd1;
	default: sram_read_write = 'd1;
	endcase
end

always@(*) begin
	case(current_state)
	S_WAIT: sram_in_data = rdata_m_inf;
	default: sram_in_data = in_data;
	endcase
end

always@(*) begin
	case(current_state)
	S_WAIT: sram_addr = count_addr;
	S_IDLE: sram_addr = in_addr;
	default: sram_addr = in_addr;
	endcase
end

//----------------------------------------------------
//               out
//----------------------------------------------------
assign araddr_m_inf = (in_valid || current_state == S_REQUEST) ? {20'h00001 , in_addr[10:7] , 8'd0} : 0;
assign arvalid_m_inf = ( in_valid && read && ~hit ) || current_state == S_REQUEST; // current_state == S_REQUEST -> slower but looser
assign rready_m_inf = current_state == S_REQUEST || current_state == S_WAIT;

assign awaddr_m_inf = (in_valid || current_state == S_WRITE_REQUEST) ? {20'h00001 , in_addr[10:0], 1'd0} : 0;
assign awvalid_m_inf = (in_valid && ~read) || current_state == S_WRITE_REQUEST; // current_state == S_REQUEST -> slower but looser
assign bready_m_inf = current_state == S_WRITE_SEND || current_state == S_WRITE_WAIT;

assign wlast_m_inf = current_state == S_WRITE_SEND;
assign wvalid_m_inf = current_state == S_WRITE_SEND;
assign wdata_m_inf = (wvalid_m_inf) ? in_data : 0;

assign out_valid = (current_state == S_HIT_1) || bvalid_m_inf;

always@(*) begin
	out_data = save_out_data;
end

//----------------------------------------------------
//               FSM
//----------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		current_state <= S_IDLE;
	end else begin
		current_state <= next_state;
	end
end

always@(*) begin
	case(current_state)
	S_IDLE:
		if(in_valid) begin
			if(hit && read)
				next_state = S_HIT;
			else if(read)
				next_state = S_REQUEST;
			else
				next_state = S_WRITE_REQUEST;
		end
		else
			next_state = S_IDLE;
	S_REQUEST:
		if(arready_m_inf)
			next_state = S_WAIT;
		else
			next_state = S_REQUEST;
	S_WAIT:
		if(rlast_m_inf)
			next_state = S_HIT_1;
		else
			next_state = S_WAIT;
	S_HIT: next_state = S_HIT_1;
	S_HIT_1: next_state = S_IDLE;
	S_WRITE_REQUEST:
		if(awready_m_inf)
			next_state = S_WRITE_SEND;
		else
			next_state = S_WRITE_REQUEST;
	S_WRITE_SEND:
		if(wready_m_inf)
			next_state = S_WRITE_WAIT;
		else
			next_state = S_WRITE_SEND;
	S_WRITE_WAIT:
		if(bvalid_m_inf)
			next_state = S_IDLE;
		else
			next_state = S_WRITE_WAIT;
	default: next_state = S_IDLE;
	endcase
end

endmodule

module Inst_Dram_Dealer(
		clk,
		rst_n,
		in_valid,
		in_addr,
		out_valid,
		out_data,
	   
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
       rready_m_inf ,
	   sram_out_data,
	   sram_read_write,
	   sram_addr
	   
);
// -----------------------------
// axi parameter
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=1;
// input clk and reset signal
input clk;
input rst_n;
// valid signal
input in_valid;
input [10:0] in_addr;
output wire out_valid;
output reg [15:0] out_data;
// sram signal
input wire [15:0] sram_out_data;
output reg [6:0] sram_addr;
output reg sram_read_write;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire [DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------
// axi assign
// write
assign awid_m_inf = 'd0;
// read
assign arid_m_inf = 'd0;
assign arlen_m_inf = 7'b111_1111;
assign arsize_m_inf = 3'b001;
assign arburst_m_inf = 2'b01;
// -----------------------------

//----------------------------------------------------
//               state parameter
//----------------------------------------------------
parameter S_IDLE = 'd0;
parameter S_REQUEST = 'd1;
parameter S_WAIT = 'd2;
parameter S_HIT = 'd3;
parameter S_HIT_1 = 'd4;
//----------------------------------------------------
//               reg
//----------------------------------------------------
reg [2:0] current_state;
reg [2:0] next_state;

reg sram_data_is_valid;


reg [6:0] count_addr;
reg [3:0] save_addr;


reg [6:0] save_in_addr;
reg [15:0] save_out_data;


wire hit;
assign hit = sram_data_is_valid && (save_addr == in_addr[10:7]);

//FINAL_SRAM inst_dram_cache(.Q(sram_out_data), .CLK(clk), .CEN(1'd0), .WEN(sram_read_write), .A(sram_addr), .D(rdata_m_inf), .OEN(1'd0));

//----------------------------------------------------
//               save info
//----------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		sram_data_is_valid <= 0;
	end else if(rlast_m_inf) begin
		sram_data_is_valid <= 1;
	end else begin
		sram_data_is_valid <= sram_data_is_valid;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count_addr <= 0;
	end else if(rvalid_m_inf)
		count_addr <= count_addr + 1;
	else
		count_addr <= count_addr;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		save_addr <= 0;
	end else if(in_valid) begin
		save_addr <= in_addr[10:7];
	end else begin
		save_addr <= save_addr;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		save_out_data <= 0;
	end else if(rvalid_m_inf && in_addr[6:0] == sram_addr) begin
		save_out_data <= rdata_m_inf;
	end else if(current_state == S_HIT) begin
		save_out_data <= sram_out_data;
	end else begin
		save_out_data <= save_out_data;
	end
end

//----------------------------------------------------
//               sram input control
//----------------------------------------------------
always@(*) begin
	case(current_state)
	S_WAIT: sram_read_write = 'd0;
	default: sram_read_write = 'd1;
	endcase
end

always@(*) begin
	case(current_state)
	S_WAIT: sram_addr = count_addr;
	S_IDLE: sram_addr = in_addr;
	default: sram_addr = in_addr;
	endcase
end

//----------------------------------------------------
//               out
//----------------------------------------------------
assign araddr_m_inf = (in_valid || current_state == S_REQUEST) ? {20'h0001 , in_addr[10:7] , 8'd0} : 0;
assign arvalid_m_inf = ( in_valid && ~hit ) || current_state == S_REQUEST; // current_state == S_REQUEST -> slower but looser
assign rready_m_inf = current_state == S_REQUEST || current_state == S_WAIT;

assign out_valid = (current_state == S_HIT_1);

always@(*) begin
	out_data = save_out_data;
end

//----------------------------------------------------
//               FSM
//----------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		current_state <= S_IDLE;
	end else begin
		current_state <= next_state;
	end
end

always@(*) begin
	case(current_state)
	S_IDLE:
		if(in_valid) begin
			if(hit)
				next_state = S_HIT;
			else
				next_state = S_REQUEST;
		end
		else
			next_state = S_IDLE;
	S_REQUEST:
		if(arready_m_inf)
			next_state = S_WAIT;
		else
			next_state = S_REQUEST;
	S_WAIT:
		if(rlast_m_inf)
			next_state = S_HIT_1;
		else
			next_state = S_WAIT;
	S_HIT: next_state = S_HIT_1;
	S_HIT_1: next_state = S_IDLE;
	default: next_state = S_IDLE;
	endcase
end

endmodule
