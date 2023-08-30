// synopsys translate_off
`include "/usr/synthesis/dw/sim_ver/DW02_mult.v"
`include "/usr/synthesis/dw/sim_ver/DW01_add.v"
// synopsys translate_on
module MMT(
// input signals
    clk,
    rst_n,
    in_valid,
	in_valid2,
    matrix,
	matrix_size,
    matrix_idx,
    mode,
	
// output signals
    out_valid,
    out_value
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input        clk, rst_n, in_valid, in_valid2;
input [7:0]  matrix;
input [1:0]  matrix_size,mode;
input [4:0]  matrix_idx;

output reg       	     out_valid;
output reg signed [49:0] out_value;
//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
parameter S_IDLE = 4'b0000;
parameter S_INPUT = 4'b0001;
parameter S_INPUT2 = 4'b0011;
parameter S_LOAD_B = 4'b0010;
parameter S_LOAD_A = 4'b0110;
parameter S_NOTHING = 4'b0111;
parameter S_LOAD_C = 4'b0101;
parameter S_OUT = 4'b0100;
parameter S_NOTHING2 = 4'b1100;
parameter S_NOTHING3 = 4'b1101;
parameter S_NOTHING4 = 4'b1111;
parameter S_NOTHING5 = 4'b1110;
integer i;
integer k;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg [3:0] current_state;
reg [3:0] next_state;

reg [1:0] size;
reg [3:0] next_size;

reg [7:0] row_temp_reg[17:0];

reg [12:0] count;
reg [2:0] count_x;
reg [2:0] count_y;
reg [4:0] count_matrix;

wire [31:0] mem_out;
reg [31:0] mem_in;
reg [10:0] mem_addr;
reg mem_cen;
reg mem_wen;

reg [4:0] save_matrix_id[2:0];
reg [2:0] save_who_transpose;
reg [2:0] who_transpose;

reg [2:0] load_x;
reg [2:0] load_y;
reg [6:0] load_count;

reg [31:0] matrix_reg[7:0][7:0];
reg [31:0] next_save_matrix;
reg change_state_trigger;

reg [31:0] load_small_matrix;
reg signed [19:0] A_B [15:0][15:0];

//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------

//---------------------------------------------------------------------
//   SRAM
//---------------------------------------------------------------------
MY_MEM_2048 M1(.CLK(clk), .OEN(1'b0), .CEN(mem_cen), .WEN(mem_wen), .A(mem_addr), .D(mem_in), .Q(mem_out));

//---------------------------------------------------------------------
//   INPUT
//---------------------------------------------------------------------
// matrix isze
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count <= 'd0;
	end
	else begin
		case(current_state)
		S_IDLE: count <= 'd0;
		S_INPUT:count <= count + 1;
		default: count <= 0;
		endcase
	end
end

always@(*) begin
	case(size)
	'd0: count_x = 'd0;
	'd1: count_x = {2'd0, count[1]};
	'd2: count_x = {1'd0, count[2:1]};
	'd3: count_x = count[3:1];
	default: count_x = 'd0;
	endcase
end

always@(*) begin
	case(size)
	'd0: count_y = 'd0;
	'd1: count_y = {2'd0, count[3]};
	'd2: count_y = {1'd0, count[5:4]};
	'd3: count_y = count[7:5];
	default: count_y = 0;
	endcase
end

always@(*) begin
	case(size)
	'd0: count_matrix = count[6:2];
	'd1: count_matrix = count[8:4];
	'd2: count_matrix = count[10:6];
	'd3: count_matrix = count[12:8];
	default: count_matrix = 0;
	endcase
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		size <= 0;
	end
	else begin
		if(current_state == S_IDLE && in_valid)
			size <= matrix_size;
		else
			size <= size;
	end
end

// row temp reg
always@(posedge clk) begin
	for(i = 0; i < 17; i = i+1)
		row_temp_reg[i + 1] <= row_temp_reg[i];
	row_temp_reg[0] <= matrix;
end

//---------------------------------------------------------------------
//   INPUT2
//---------------------------------------------------------------------
// input matrix index and transpose mode
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		save_matrix_id[0] <= 0;
		save_matrix_id[1] <= 0;
		save_matrix_id[2] <= 0;
	end
	else begin
		if(in_valid2) begin
			save_matrix_id[0] <= matrix_idx;
			save_matrix_id[1] <= save_matrix_id[0];
			save_matrix_id[2] <= save_matrix_id[1];
		end
		else begin
			save_matrix_id[0] <= save_matrix_id[0];
			save_matrix_id[1] <= save_matrix_id[1];
			save_matrix_id[2] <= save_matrix_id[2];
		end
	end
end

always@(*) begin
	case(mode)
	'd0: who_transpose = 'd0;
	'd1: who_transpose = 3'b100;
	'd2: who_transpose = 3'b010;
	'd3: who_transpose = 3'b001;
	endcase
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		save_who_transpose <= 0;
	end
	else begin
		if(current_state == S_IDLE && in_valid2) begin
			save_who_transpose <= who_transpose;
		end
		else begin
			save_who_transpose <= save_who_transpose;
		end
	end
end

//---------------------------------------------------------------------
//   LOAD MATRIX
//---------------------------------------------------------------------

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		load_count <= 0;
	end
	else begin
		if(current_state == S_LOAD_A || current_state == S_LOAD_C || current_state == S_NOTHING || current_state == S_NOTHING3 || current_state == S_NOTHING4)
			load_count <= load_count + 1;
		else if(change_state_trigger)
		begin
			load_count <= 0;
		end
		else if(current_state == S_LOAD_B)begin
			load_count <= load_count + 1;
		end
		else
			load_count <= 0;
	end
end

always@(*) begin
	case(size)
	'd0: load_x = 0;
	'd1: load_x = load_count[0];
	'd2: load_x = load_count[1:0];
	'd3: load_x = load_count[2:0];
	default: load_x = 0;
	endcase
end

always@(*) begin
	case(size)
	'd0: load_y = 0;
	'd1: load_y = load_count[1];
	'd2: load_y = load_count[3:2];
	'd3: load_y = load_count[5:3];
	default: load_y = 0;
	endcase
end

always@(*) begin
	case(size)
	'd0: change_state_trigger = load_count[0];
	'd1: change_state_trigger = load_count[2];
	'd2: change_state_trigger = load_count[4];
	'd3: change_state_trigger = load_count[6];
	default: change_state_trigger = 0;
	endcase
end

reg [2:0] delay_load_x[2:0];
reg [2:0] delay_load_y[2:0];

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		delay_load_x[0] <= 0;
		delay_load_x[1] <= 0;
		delay_load_x[2] <= 0;
		delay_load_y[0] <= 0;
		delay_load_y[1] <= 0;
		delay_load_y[2] <= 0;
	end
	else begin
	delay_load_x[2] <= delay_load_x[1];
	delay_load_y[2] <= delay_load_y[1];
	delay_load_x[1] <= delay_load_x[0];
	delay_load_y[1] <= delay_load_y[0];
	delay_load_x[0] <= load_x;
	delay_load_y[0] <= load_y;
	end
end

always@(*) begin
	case(current_state)
	S_LOAD_B: if(save_who_transpose[1])
				next_save_matrix = mem_out;
			  else
				next_save_matrix = {mem_out[31:24],mem_out[15:8],mem_out[23:16],mem_out[7:0]};
	S_LOAD_A: if(save_who_transpose[2])
				next_save_matrix = {mem_out[31:24],mem_out[15:8],mem_out[23:16],mem_out[7:0]};
			  else
				next_save_matrix = mem_out;
	S_LOAD_C: if(save_who_transpose[0])
				next_save_matrix = {mem_out[31:24],mem_out[15:8],mem_out[23:16],mem_out[7:0]};
			  else
				next_save_matrix = mem_out;
	default: next_save_matrix = 0;
	endcase
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 8;i = i+1)
			for(k = 0; k < 8;k = k+1)
				matrix_reg[i][k] <= 0;
	end
	else begin
		case(current_state)
		S_LOAD_B: begin
		matrix_reg[delay_load_x[0]][delay_load_y[0]] <= next_save_matrix;
		end
		default: begin 
			for(i = 0; i < 8;i = i+1)
				for(k = 0; k < 8;k = k+1)
					matrix_reg[i][k] <= matrix_reg[i][k];
		end
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		load_small_matrix <= 0;
	end
	else begin
		load_small_matrix <= next_save_matrix;
	end
end

//---------------------------------------------------------------------
//   MULTIPLIER
//---------------------------------------------------------------------

wire signed [16:0] sum_row1[15:0];
wire signed [16:0] sum_row2[15:0];
genvar j;
generate
for (j = 0; j < 8; j=j+1) begin
	my_mac m1(load_small_matrix[31:24],load_small_matrix[23:16], matrix_reg[delay_load_y[1]][j][31:24], matrix_reg[delay_load_y[1]][j][23:16], sum_row1[2*j]);
	my_mac m2(load_small_matrix[31:24],load_small_matrix[23:16], matrix_reg[delay_load_y[1]][j][15:8], matrix_reg[delay_load_y[1]][j][7:0], sum_row1[2*j+1]);
	my_mac m3(load_small_matrix[15:8],load_small_matrix[7:0], matrix_reg[delay_load_y[1]][j][31:24], matrix_reg[delay_load_y[1]][j][23:16], sum_row2[2*j]);
	my_mac m4(load_small_matrix[15:8],load_small_matrix[7:0], matrix_reg[delay_load_y[1]][j][15:8], matrix_reg[delay_load_y[1]][j][7:0], sum_row2[2*j+1]);
end
endgenerate

reg signed [16:0] sum_row1_buf[15:0];
reg signed [16:0] sum_row2_buf[15:0];
always@(posedge clk) begin
	for(i = 0; i < 16; i = i +1) begin
		sum_row1_buf[i] <= sum_row1[i];
		sum_row2_buf[i] <= sum_row2[i];
	end
end


always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(i = 0; i < 16; i=i+1)
			for(k = 0; k < 16; k = k+1)
				A_B[i][k] <= 0;
	end
	else begin
		case(current_state)
		S_LOAD_A, S_NOTHING, S_NOTHING2: begin
			if(load_count > 2)
			for(i = 0; i < 16;i=i+1) begin
				A_B[delay_load_x[2]*2][i] <= A_B[delay_load_x[2]*2][i] + sum_row1_buf[i];
				A_B[delay_load_x[2]*2+1][i] <= A_B[delay_load_x[2]*2+1][i] + sum_row2_buf[i];
			end
			else begin
				for(i = 0; i < 16; i=i+1)
					for(k = 0; k < 16; k = k+1)
						A_B[i][k] <= 0;
			end
		end
		S_LOAD_C: for(i = 0; i < 16; i=i+1)
					for(k = 0; k < 16; k = k+1)
						A_B[i][k] <= A_B[i][k];
		default: for(i = 0; i < 16; i=i+1)
					for(k = 0; k < 16; k = k+1)
						A_B[i][k] <= 0;
		endcase
	end
end

//---------------------------------------------------------------------
//   *C
//---------------------------------------------------------------------
wire signed [27:0] out_trace1_1;
wire signed [27:0] out_trace1_2;
wire signed [27:0] out_trace2_1;
wire signed [27:0] out_trace2_2;
wire signed [29:0] sum_trace;

my_bigger_mac BM1(A_B[delay_load_y[1]*2][delay_load_x[1]*2],A_B[delay_load_y[1]*2][delay_load_x[1]*2+1],load_small_matrix[31:24],load_small_matrix[15:8], out_trace1_1, out_trace1_2);
my_bigger_mac BM2(A_B[delay_load_y[1]*2+1][delay_load_x[1]*2],A_B[delay_load_y[1]*2+1][delay_load_x[1]*2+1],load_small_matrix[23:16],load_small_matrix[7:0], out_trace2_1, out_trace2_2);
reg signed [27:0] out_trace1_1_buf;
reg signed [27:0] out_trace1_2_buf;
reg signed [27:0] out_trace2_1_buf;
reg signed [27:0] out_trace2_2_buf;
always@(posedge clk) begin
	out_trace1_1_buf <= out_trace1_1;
	out_trace1_2_buf <= out_trace1_2;
	out_trace2_1_buf <= out_trace2_1;
	out_trace2_2_buf <= out_trace2_2;
end

wire w1, w2;
wire signed [28:0] add_out_1;
wire signed [28:0] add_out_2;
reg signed [28:0] add_out_1_buf;
reg signed [28:0] add_out_2_buf;
DW01_add #(29) A1(.A({out_trace1_1_buf[27],out_trace1_1_buf}),.B({out_trace1_2_buf[27],out_trace1_2_buf}),.CI(1'd0),.SUM(add_out_1), .CO(w1));
// synopsys dc_script_begin
// set_implementation pparch A1
// synopsys dc_script_end

DW01_add #(29) A2(.A({out_trace2_1_buf[27],out_trace2_1_buf}),.B({out_trace2_2_buf[27],out_trace2_2_buf}),.CI(1'd0),.SUM(add_out_2), .CO(w2));
// synopsys dc_script_begin
// set_implementation pparch A2
// synopsys dc_script_end

always@(posedge clk) begin
	add_out_1_buf <= add_out_1;
	add_out_2_buf <= add_out_2;
end

assign sum_trace = add_out_1_buf + add_out_2_buf;


reg signed [35:0] all_trace;
wire signed [35:0] next_all_trace;
assign next_all_trace = sum_trace + all_trace;
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		all_trace <= 0;
	end
	else begin
		case(current_state)
		S_LOAD_C, S_NOTHING3, S_NOTHING4, S_NOTHING5: begin
			if(load_count > 3)
				all_trace <= next_all_trace;
			else begin
				all_trace <= 0;
			end
		end
		default: all_trace <= 0;
		endcase
	end
end


//---------------------------------------------------------------------
//   SRAM INPUT CONTROLL
//---------------------------------------------------------------------
// mem_cen
always@(*) begin
	case(current_state)
	S_IDLE: mem_cen = 'd1;
	S_INPUT: mem_cen = 'd0;
	S_LOAD_B: mem_cen = 'd0;
	S_LOAD_A: mem_cen = 'd0;
	S_LOAD_C: mem_cen = 'd0;
	default: mem_cen = 'd1;
	endcase
end

// mem_wen
always@(*) begin
	case(current_state)
	S_IDLE: mem_wen = 1;
	S_INPUT: mem_wen = 0;
	S_LOAD_B: mem_wen = 1;
	S_LOAD_A: mem_wen = 1;
	S_LOAD_C: mem_wen = 1;
	default: mem_wen = 1;
	endcase
end

// mem_addr
always@(*) begin
	case(current_state)
	S_INPUT: mem_addr = {count_matrix, count_y, count_x};
	S_LOAD_B:   if(save_who_transpose[1])
					mem_addr = {save_matrix_id[1], load_y, load_x};
				else
					mem_addr = {save_matrix_id[1], load_x, load_y};
	S_LOAD_A:   if(!save_who_transpose[2])
					mem_addr = {save_matrix_id[2], load_x, load_y};
				else
					mem_addr = {save_matrix_id[2], load_y, load_x};
	S_LOAD_C:   if(!save_who_transpose[0])
					mem_addr = {save_matrix_id[0], load_x, load_y};
				else
					mem_addr = {save_matrix_id[0], load_y, load_x};
	default: mem_addr = 0;
	endcase
end

// mem_in
reg [4:0] bias;
always@(*) begin
	case(size)
	'd0: bias = 2;
	'd1: bias = 4;
	'd2: bias = 8;
	'd3: bias = 16;
	default: bias = 0;
	endcase
end

always@(*) begin
	case(current_state)
	S_INPUT: mem_in = {row_temp_reg[bias + 1], row_temp_reg[bias],row_temp_reg[1],row_temp_reg[0]};
	default: mem_in = 0;
	endcase
end


//---------------------------------------------------------------------
//   OUT
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_value <= 0;
	end
	else begin
		if(current_state == S_OUT)
		out_value <= all_trace;
		else
		out_value <= 0;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
	end
	else begin
		if(current_state == S_OUT)
			out_valid <= 1;
		else
			out_valid <= 0;
	end
end


//---------------------------------------------------------------------
//   FSM
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		current_state <= S_IDLE;
	else
		current_state <= next_state;
end

always@(*) begin
	case(current_state)
	S_IDLE: if(in_valid)
				next_state = S_INPUT;
			else if(in_valid2)
				next_state = S_INPUT2;
			else
				next_state = S_IDLE;
	S_INPUT: 
			if(in_valid)
				next_state = S_INPUT;
			else
				next_state = S_IDLE;
	S_INPUT2: 
			if(in_valid2)
				next_state = S_INPUT2;
			else
				next_state = S_LOAD_B;	
	S_LOAD_B: 
			if(change_state_trigger)
				next_state = S_LOAD_A;
			else
				next_state = S_LOAD_B;
	S_LOAD_A: 
			if(change_state_trigger)
				next_state = S_NOTHING;
			else
				next_state = S_LOAD_A;
	S_NOTHING: next_state = S_NOTHING2;
	S_NOTHING2: next_state = S_LOAD_C;
	S_LOAD_C: if(change_state_trigger)
				next_state = S_NOTHING3;
			else
				next_state = S_LOAD_C;
	S_NOTHING3: next_state = S_NOTHING4;
	S_NOTHING4: next_state = S_NOTHING5;
	S_NOTHING5: next_state = S_OUT;
	default: next_state = S_IDLE;
	endcase
end

endmodule


module my_mult(
	input signed [7:0] in1,
	input signed [7:0] in2,
	output signed [15:0] out
	);
DW02_mult #(8, 8) D1(.A(in1),.B(in2),.TC(1'd1),.PRODUCT(out));
// synopsys dc_script_begin
// set_implementation pparch D1
// synopsys dc_script_end
//assign out = in1 * in2;
endmodule

module my_bigger_mult(
	input signed [19:0] in1,
	input signed [7:0] in2,
	output signed [27:0] out
	);
DW02_mult #(20, 8) D1(.A(in1),.B(in2),.TC(1'd1),.PRODUCT(out));
// synopsys dc_script_begin
// set_implementation pparch D1
// synopsys dc_script_end
//assign out = in1 * in2;
endmodule

module my_mac(
	input signed [7:0] in1_1,
	input signed [7:0] in1_2,
	input signed [7:0] in2_1,
	input signed [7:0] in2_2,
	output signed [16:0] out
	);
wire signed [15:0] w1, w2;
wire w3;
my_mult M1(in1_1, in2_1, w1);
my_mult M2(in1_2, in2_2, w2);
DW01_add #(17) A1(.A({w1[15],w1}),.B({w2[15],w2}),.CI(1'd0),.SUM(out), .CO(w3));
// synopsys dc_script_begin
// set_implementation pparch A1
// synopsys dc_script_end
//assign out = w1 + w2;
endmodule

module my_bigger_mac(
	input signed [19:0] in1_1,
	input signed [19:0] in1_2,
	input signed [7:0] in2_1,
	input signed [7:0] in2_2,
	output signed [27:0] out1,
	output signed [27:0] out2
	);
my_bigger_mult M1(in1_1, in2_1, out1);
my_bigger_mult M2(in1_2, in2_2, out2);
endmodule