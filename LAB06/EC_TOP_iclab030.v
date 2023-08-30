//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright Optimum Application-Specific Integrated System Laboratory
//    All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : EC_TOP.v
//   	Module Name : EC_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "INV_IP.v"
//synopsys translate_on

module EC_TOP(
    // Input signals
    clk, rst_n, in_valid,
    in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a,
    // Output signals
    out_valid, out_Rx, out_Ry
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [6-1:0] in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a;
output reg out_valid;
output reg [6-1:0] out_Rx, out_Ry;
// ===============================================================
// Parameter
// ===============================================================
integer i;
// ===============================================================
// Design
// ===============================================================
reg [5:0] Px_reg;
reg [5:0] Py_reg;
reg [5:0] Qx_reg;
reg [5:0] Qy_reg;
reg [5:0] prime_reg;
reg [5:0] a_reg;
reg [5:0] in_valid_reg[10:0];

always@(posedge clk) begin
	if(in_valid)
		Px_reg <= in_Px;
	else
		Px_reg <= Px_reg;
end

always@(posedge clk) begin
	if(in_valid)
		Py_reg <= in_Py;
	else
		Py_reg <= Py_reg;
end

always@(posedge clk) begin
	if(in_valid)
		Qx_reg <= in_Qx;
	else
		Qx_reg <= Qx_reg;
end

always@(posedge clk) begin
	if(in_valid)
		Qy_reg <= in_Qy;
	else
		Qy_reg <= Qy_reg;
end

always@(posedge clk) begin
	if(in_valid)
		prime_reg <= in_prime;
	else
		prime_reg <= prime_reg;
end

always@(posedge clk) begin
	if(in_valid)
		a_reg <= in_a;
	else
		a_reg <= a_reg;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
	begin
		for(i = 0; i < 10; i=i+1)
			in_valid_reg[i] <= 0;
	end
	else begin
	for(i = 0; i < 9; i=i+1)
		in_valid_reg[i+1] <= in_valid_reg[i];
	in_valid_reg [0] <= in_valid;
	end
end

// doubling or addition trigger
wire same;
assign same = (Qy_reg == Py_reg) && (Qx_reg == Px_reg);

// ===============================================================
// Stage 1
// ===============================================================
// addition
// up
wire [5:0] addition_up;
assign addition_up = (Qy_reg > Py_reg) ? Qy_reg - Py_reg : Qy_reg - Py_reg + prime_reg;
// down
wire [5:0] addition_down;
assign addition_down = (Qx_reg > Px_reg) ? Qx_reg - Px_reg : Qx_reg - Px_reg + prime_reg;

// doubling
// up
wire [11:0] doubling_up_mult_out;
assign doubling_up_mult_out = Px_reg * Px_reg;
wire [5:0] doubling_up;
assign doubling_up = doubling_up_mult_out % prime_reg;
// down
wire [6:0] doubling_down_mult_out;
assign doubling_down_mult_out = 2 * Py_reg;
wire [5:0] doubling_down;
assign doubling_down = doubling_down_mult_out % prime_reg;

// stage 1 buff
reg [5:0] stage_1_up_buff;
always@(*) begin
	if(same)
		stage_1_up_buff = doubling_up;
	else
		stage_1_up_buff = addition_up;
end
reg [5:0] stage_1_down_buff;
always@(*) begin
	if(same)
		stage_1_down_buff = doubling_down;
	else
		stage_1_down_buff = addition_down;
end

// ===============================================================
// INV_IP
// ===============================================================
wire [5:0] inv_out;
INV_IP #(.IP_WIDTH(6)) I_INV_IP ( .IN_1(stage_1_down_buff), .IN_2(prime_reg), .OUT_INV(inv_out));

// ===============================================================
// stage 2
// ===============================================================
// up
reg [5:0] stage_2_up_buff;
wire [7:0] doubling_up_mult_stage_2;
assign doubling_up_mult_stage_2 = ( stage_1_up_buff * 3 ) + a_reg;
wire [5:0] doubling_up_stage2;
assign doubling_up_stage2 = doubling_up_mult_stage_2 % prime_reg;
always@(posedge clk) begin
	if(same)
		stage_2_up_buff <= doubling_up_stage2;
	else
		stage_2_up_buff <= stage_1_up_buff;
end
// down
reg [5:0] stage_2_down_buff;
always@ (posedge clk) begin
	stage_2_down_buff <= inv_out;
end

// ===============================================================
// stage 3
// ===============================================================

wire [11:0] mult_up_down;
assign mult_up_down = stage_2_up_buff * stage_2_down_buff;
wire [5:0] mult_up_down_result;
assign mult_up_down_result = mult_up_down % prime_reg;

reg [5:0] s;
always@ (*) begin
	s = mult_up_down_result;
end

// ===============================================================
// Calculate Rx
// ===============================================================
wire [11:0] cal_Rx;
assign cal_Rx = (s * s) + ( prime_reg - Px_reg ) + ( prime_reg - Qx_reg );
wire [5:0] Rx;
assign Rx = cal_Rx % prime_reg;

// ===============================================================
// Calculate Ry
// ===============================================================
wire [12:0] cal_Ry;
assign cal_Ry = s * (Px_reg + ( prime_reg - Rx ) ) + ( prime_reg - Py_reg);
wire [5:0] Ry;
assign Ry = cal_Ry % prime_reg;

// ===============================================================
// OUTPUT
// ===============================================================


always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		out_Rx <= 0;
	else if(in_valid_reg[1])
		out_Rx <= Rx;
	else
		out_Rx <= 0;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		out_Ry <= 0;
	else if(in_valid_reg[1])
		out_Ry <= Ry;
	else
		out_Ry <= 0;
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		out_valid <= 0;
	else
		out_valid <= in_valid_reg[1];
end

endmodule

