// synopsys translate_off
`include "/usr/synthesis/dw/sim_ver/DW_fp_add.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_mult.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_exp.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_recip.v"
// synopsys translate_on

module NN(
	// Input signals
	clk,
	rst_n,
	in_valid,
	weight_u,
	weight_w,
	weight_v,
	data_x,
	data_h,
	// Output signals
	out_valid,
	out
);

//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------

// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input  clk, rst_n, in_valid;
input [inst_sig_width+inst_exp_width:0] weight_u, weight_w, weight_v;
input [inst_sig_width+inst_exp_width:0] data_x,data_h;
output reg	out_valid;
output reg [inst_sig_width+inst_exp_width:0] out;

//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
integer i;


//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg [5:0] count;

reg [31:0] U[8:0];
reg [31:0] V[8:0];
reg [31:0] W[8:0];
reg [31:0] X[8:0];
reg [31:0] H[2:0];

reg [31:0] mult_1_in_1;
reg [31:0] mult_1_in_2;
reg [31:0] mult_2_in_1;
reg [31:0] mult_2_in_2;
reg [31:0] mult_3_in_1;
reg [31:0] mult_3_in_2;

wire [31:0] mult_1_out;
wire [31:0] mult_2_out;
wire [31:0] mult_3_out;

reg [31:0] mult_1_out_buffer;
reg [31:0] mult_2_out_buffer;
reg [31:0] mult_3_out_buffer;

reg [31:0] add_1_in_1;
reg [31:0] add_1_in_2;
reg [31:0] add_2_in_1;
reg [31:0] add_2_in_2;
reg [31:0] add_3_in_1;
reg [31:0] add_3_in_2;

wire [31:0] add_1_out;
wire [31:0] add_2_out;
wire [31:0] add_3_out;

reg [31:0] matrix_out_buffer[2:0];

reg [31:0] add_out_buffer[2:0];

reg [31:0] leaky_relu_out[2:0];

reg [31:0] y_temp[2:0];

wire [31:0] exp_in;
wire [31:0] exp_out;
reg [31:0] exp_out_buffer;

wire [31:0] recip_out;

reg [31:0] next_output;
reg next_outvalid;

//---------------------------------------------------------------------
//   STORE INPUT
//---------------------------------------------------------------------
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
		for(i=0;i<9;i=i+1) begin
			U[i] <= 0;
		end
    end  
    else begin
		if(in_valid) begin
			for(i=0;i<8;i=i+1) begin
				U[i+1] <= U[i];
			end
			U[0] <= weight_u;
		end
		else begin
			for(i=0;i<9;i=i+1) begin
				U[i] <= U[i];
			end
		end
	end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
		for(i=0;i<9;i=i+1) begin
			V[i] <= 0;
		end
    end  
    else begin
		if(in_valid) begin
			for(i=0;i<8;i=i+1) begin
				V[i+1] <= V[i];
			end
			V[0] <= weight_v;
		end
		else begin
			for(i=0;i<9;i=i+1) begin
				V[i] <= V[i];
			end
		end
	end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
		for(i=0;i<9;i=i+1) begin
			W[i] <= 0;
		end
    end  
    else begin
		if(in_valid) begin
		for(i=0;i<8;i=i+1) begin
			W[i+1] <= W[i];
		end
		W[0] <= weight_w;
		end
		else begin
			for(i=0;i<9;i=i+1) begin
				W[i] <= W[i];
			end
		end
	end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
		for(i=0;i<9;i=i+1) begin
			X[i] <= 0;
		end
    end  
    else begin
		case(count)
			'd0, 'd1, 'd2, 'd3, 'd4, 'd5, 'd6, 'd7, 'd8: begin
				for(i=0;i<8;i=i+1) begin
					X[i+1] <= X[i];
				end
				X[0] <= data_x;
			end
			'd17, 'd27: begin
				X[5] <= matrix_out_buffer[2];
				X[4] <= matrix_out_buffer[0];
				X[3] <= add_2_out;
			end
			'd31: begin
				X[2] <= leaky_relu_out[2];
				X[1] <= leaky_relu_out[1];
				X[0] <= leaky_relu_out[0];
			end
			default: begin
				for(i=0;i<9;i=i+1) begin
					X[i] <= X[i];
				end
			end
		endcase
	end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
		for(i=0;i<3;i=i+1) begin
			H[i] <= 0;
		end
    end  
    else begin
		case(count)
		'd0, 'd1, 'd2: begin
			for(i=0;i<2;i=i+1) begin
				H[i+1] <= H[i];
			end
			H[0] <= data_h;
		end
		'd10: begin
			H[2] <= matrix_out_buffer[1];
			H[1] <= matrix_out_buffer[0];
			H[0] <= add_2_out;
		end
		'd14: begin
			H[2] <= leaky_relu_out[2];
			H[1] <= leaky_relu_out[1];
			H[0] <= leaky_relu_out[0];
		end
		'd24: begin
			H[2] <= leaky_relu_out[2];
			H[1] <= leaky_relu_out[1];
			H[0] <= leaky_relu_out[0];
		end
		default: begin
			for(i=0;i<3;i=i+1) begin
				H[i] <= H[i];
			end
		end
		endcase
	end
end


//---------------------------------------------------------------------
//   COUNT
//---------------------------------------------------------------------
wire [9:0] next_count;
assign next_count = count + 1;
always @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		count <= 0;
	end
	else begin
		if(in_valid || (count > 0 && count < 42))
			count <= next_count;
		else
			count <= 0;
	end
end

//---------------------------------------------------------------------
//   DESIGN WARE
//---------------------------------------------------------------------
fp_mult M1 (.a(mult_1_in_1), .b(mult_1_in_2), .out(mult_1_out));
fp_mult M2 (.a(mult_2_in_1), .b(mult_2_in_2), .out(mult_2_out));
fp_mult M3 (.a(mult_3_in_1), .b(mult_3_in_2), .out(mult_3_out));

fp_add  A1 (.a(add_1_in_1), .b(add_1_in_2), .out(add_1_out));
fp_add  A2 (.a(add_2_in_1), .b(add_2_in_2), .out(add_2_out));
fp_add  A3 (.a(add_3_in_1), .b(add_3_in_2), .out(add_3_out));

fp_exp   E1(.a(exp_in), .out(exp_out));
fp_recip R1(.a(add_out_buffer[0]), .out(recip_out));

//---------------------------------------------------------------------
//   DESIGN WARE INPUT CONTROL
//---------------------------------------------------------------------

//   multiplier input
always@(*)  begin
	case(count)
	'd7,  'd8,  'd9, 'd17, 'd18, 'd19, 'd20, 'd21, 'd22, 'd27, 'd28, 'd29, 'd30, 'd32, 'd33: mult_1_in_1 = H[2];
	'd10, 'd11, 'd12: mult_1_in_1 = X[8];
	'd14, 'd24, 'd31: mult_1_in_1 = 'b00111101110011001100110011001101;
	'd13, 'd15, 'd16: mult_1_in_1 = X[5];
	'd23, 'd25, 'd26, 'd34, 'd35, 'd36: mult_1_in_1 = X[2];
	default: mult_1_in_1 = 0;
	endcase
end

always@(*)  begin
	case(count)
	'd7: mult_1_in_2 = W[6];
	'd8: mult_1_in_2 = W[4];
	'd9: mult_1_in_2 = W[2];
	'd10, 'd13, 'd23: mult_1_in_2 = U[8];
	'd11, 'd15, 'd25: mult_1_in_2 = U[5];
	'd12, 'd16, 'd26: mult_1_in_2 = U[2];
	'd14, 'd24, 'd31: mult_1_in_2 = add_out_buffer[2];
	'd17, 'd30, 'd34: mult_1_in_2 = V[8];
	'd18, 'd32, 'd35: mult_1_in_2 = V[5];
	'd19, 'd33, 'd36: mult_1_in_2 = V[2];
	'd20, 'd27: mult_1_in_2 = W[8];
	'd21, 'd28: mult_1_in_2 = W[5];
	'd22, 'd29: mult_1_in_2 = W[2];
	default: mult_1_in_2 = 0;
	endcase
end

always@(*)  begin
	case(count)
		'd7,  'd8,  'd9, 'd17, 'd18, 'd19, 'd20, 'd21, 'd22, 'd27, 'd28, 'd29, 'd30, 'd32, 'd33: mult_2_in_1 = H[1];
		'd10, 'd11, 'd12: mult_2_in_1 = X[7];
		'd14, 'd24, 'd31: mult_2_in_1 = 'b00111101110011001100110011001101;
		'd13, 'd15, 'd16: mult_2_in_1 = X[4];
		'd23, 'd25, 'd26, 'd34, 'd35, 'd36: mult_2_in_1 = X[1];
		default: mult_2_in_1 = 0;
	endcase
end

always@(*)  begin
	case(count)
	'd7: mult_2_in_2 = W[5];
	'd8: mult_2_in_2 = W[3];
	'd9: mult_2_in_2 = W[1];
	'd10, 'd13, 'd23: mult_2_in_2 = U[7];
	'd11, 'd15, 'd25: mult_2_in_2 = U[4];
	'd12, 'd16, 'd26: mult_2_in_2 = U[1];
	'd14, 'd24, 'd31: mult_2_in_2 = add_out_buffer[1];
	'd17, 'd30, 'd34: mult_2_in_2 = V[7];
	'd18, 'd32, 'd35: mult_2_in_2 = V[4];
	'd19, 'd33, 'd36: mult_2_in_2 = V[1];
	'd20, 'd27: mult_2_in_2 = W[7];
	'd21, 'd28: mult_2_in_2 = W[4];
	'd22, 'd29: mult_2_in_2 = W[1];
	default: mult_2_in_2 = 0;
	endcase
end

always@(*)  begin
	case(count)
	'd7,  'd8,  'd9, 'd17, 'd18, 'd19, 'd20, 'd21, 'd22, 'd27, 'd28, 'd29, 'd30, 'd32, 'd33: mult_3_in_1 = H[0];
	'd10, 'd11, 'd12: mult_3_in_1 = X[6];
	'd14, 'd24, 'd31: mult_3_in_1 = 'b00111101110011001100110011001101;
	'd13, 'd15, 'd16: mult_3_in_1 = X[3];
	'd23, 'd25, 'd26, 'd34, 'd35, 'd36: mult_3_in_1 = X[0];
	default: mult_3_in_1 = 0;
	endcase
end

always@(*)  begin
	case(count)
	'd7: mult_3_in_2 = W[4];
	'd8: mult_3_in_2 = W[2];
	'd9: mult_3_in_2 = W[0];
	'd10, 'd13, 'd23: mult_3_in_2 = U[6];
	'd11, 'd15, 'd25: mult_3_in_2 = U[3];
	'd12, 'd16, 'd26: mult_3_in_2 = U[0];
	'd14, 'd24, 'd31: mult_3_in_2 = add_out_buffer[0];
	'd17, 'd30, 'd34: mult_3_in_2 = V[6];
	'd18, 'd32, 'd35: mult_3_in_2 = V[3];
	'd19, 'd33, 'd36: mult_3_in_2 = V[0];
	'd20, 'd27: mult_3_in_2 = W[6];
	'd21, 'd28: mult_3_in_2 = W[3];
	'd22, 'd29: mult_3_in_2 = W[0];
	default: mult_3_in_2 = 0;
	endcase
end

// multiplier output buffer
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		mult_1_out_buffer <= 0;
	else begin
		mult_1_out_buffer <= mult_1_out;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		mult_2_out_buffer <= 0;
	else begin
		mult_2_out_buffer <= mult_2_out;
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		mult_3_out_buffer <= 0;
	else begin
		mult_3_out_buffer <= mult_3_out;
	end
end

// adder input control
always@(*) begin
	add_1_in_1 = mult_1_out_buffer;
end

always@(*) begin
	add_1_in_2 = mult_2_out_buffer;
end

always@(*) begin
	add_2_in_1 = mult_3_out_buffer;
end

always@(*) begin
	case(count)
		'd11: add_2_in_2 = H[2];
		'd12: add_2_in_2 = H[1];
		'd13: add_2_in_2 = H[0];
		'd21, 'd28: add_2_in_2 = X[5];
		'd22, 'd29: add_2_in_2 = X[4];
		'd23, 'd30: add_2_in_2 = X[3];
		default: add_2_in_2 = add_1_out;
	endcase
end

always@(*) begin
	case(count)
		'd24, 'd25, 'd26: add_3_in_1 = y_temp[2];
		'd33, 'd34, 'd35, 'd36, 'd37, 'd38, 'd39: add_3_in_1 = exp_out_buffer;
		default: add_3_in_1 = add_1_out;
	endcase
end

always@(*) begin
	case(count)
		'd24, 'd25, 'd26, 'd33, 'd34, 'd35, 'd36, 'd37, 'd38, 'd39: add_3_in_2 = 'b00111111100000000000000000000000;
		default: add_3_in_2 = add_2_out;
	endcase
end

// matrix_out_buffer
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		matrix_out_buffer[0] <= 0;
		matrix_out_buffer[1] <= 0;
		matrix_out_buffer[2] <= 0;
	end
	else begin
		matrix_out_buffer[0] <= add_2_out;
		matrix_out_buffer[1] <= matrix_out_buffer[0];
		matrix_out_buffer[2] <= matrix_out_buffer[1];
	end
end

// add_out_buffer
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		add_out_buffer[0] <= 0;
		add_out_buffer[1] <= 0;
		add_out_buffer[2] <= 0;
	end
	else begin
		add_out_buffer[0] <= add_3_out;
		add_out_buffer[1] <= add_out_buffer[0];
		add_out_buffer[2] <= add_out_buffer[1];
	end
end

// leaky relu out
always@(*) begin
	if(add_out_buffer[0][31] == 'd1) begin
		leaky_relu_out[0] = mult_3_out;
	end
	else begin
		leaky_relu_out[0] = add_out_buffer[0];
	end
end

always@(*) begin
	if(add_out_buffer[1][31] == 'd1) begin
		leaky_relu_out[1] = mult_2_out;
	end
	else begin
		leaky_relu_out[1] = add_out_buffer[1];
	end
end

always@(*) begin
	if(add_out_buffer[2][31] == 'd1) begin
		leaky_relu_out[2] = mult_1_out;
	end
	else begin
		leaky_relu_out[2] = add_out_buffer[2];
	end
end

// y temp
always@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		y_temp[2] <= 0;
		y_temp[1] <= 0;
		y_temp[0] <= 0;
	end
	else begin
		case(count)
		'd19, 'd20, 'd21: begin
			y_temp[2] <= y_temp[1];
			y_temp[1] <= y_temp[0];
			y_temp[0] <= exp_out;
		end
		'd24, 'd25, 'd26, 'd27, 'd34, 'd36, 'd37, 'd38, 'd39, 'd40: begin
			y_temp[2] <= y_temp[1];
			y_temp[1] <= y_temp[0];
			y_temp[0] <= recip_out;
		end
		default: begin
			y_temp[2] <= y_temp[2];
			y_temp[1] <= y_temp[1];
			y_temp[0] <= y_temp[0];
		end
		endcase
	end
end

// exp in control
assign exp_in = {~matrix_out_buffer[0][31],matrix_out_buffer[0][30:0]};

// exp out buffer
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)
		exp_out_buffer <= 0;
	else begin
		exp_out_buffer <= exp_out;
	end
end


//---------------------------------------------------------------------
//   OUTPUT
//---------------------------------------------------------------------
always@(*) begin
	case(count)
	'd33: next_output = y_temp[2];
	'd34: next_output = y_temp[1];
	'd35: next_output = y_temp[1];
	'd36: next_output = y_temp[0];
	'd37: next_output = y_temp[0];
	'd38: next_output = y_temp[0];
	'd39: next_output = y_temp[0];
	'd40: next_output = y_temp[0];
	'd41: next_output = y_temp[0];
	default: next_output = 'd0;
	endcase
end

always@(*) begin
	case(count)
	'd33, 'd34, 'd35, 'd36, 'd37, 'd38, 'd39, 'd40, 'd41: next_outvalid = 'd1;
	default: next_outvalid = 'd0;
	endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
		out_valid <= 0;
    end  
    else begin
		out_valid <= next_outvalid;
	end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        out <= 0;
    end  
    else begin
		out <= next_output;
	end
end

endmodule

//---------------------------------------------------------------------
//   Design ware
//---------------------------------------------------------------------
module fp_mult(
	a,
	b,
	out
);
// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

input  [inst_sig_width+inst_exp_width:0] a, b;
output [inst_sig_width+inst_exp_width:0] out;

DW_fp_mult #(inst_sig_width, inst_exp_width, inst_ieee_compliance) M1(.a(a), .b(b), .rnd(3'b000), .z(out));

// synopsys dc_script_begin
// set_implementation rtl M1
// synopsys dc_script_end

endmodule

module fp_add(
	a,
	b,
	out
);
// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;

input  [inst_sig_width+inst_exp_width:0] a, b;
output [inst_sig_width+inst_exp_width:0] out;

DW_fp_add #(inst_sig_width, inst_exp_width, inst_ieee_compliance) A1(.a(a), .b(b), .rnd(3'b000), .z(out));

// synopsys dc_script_begin
// set_implementation rtl A1
// synopsys dc_script_end

endmodule

module fp_exp(
	a,
	out
);
// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;
parameter inst_arch = 2;

input  [inst_sig_width+inst_exp_width:0] a;
output [inst_sig_width+inst_exp_width:0] out;

DW_fp_exp #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) E1(.a(a), .z(out));

// synopsys dc_script_begin
// set_implementation rtl E1
// synopsys dc_script_end

endmodule

module fp_recip(
	a,
	out
);
// IEEE floating point paramenters
parameter inst_sig_width = 23;
parameter inst_exp_width = 8;
parameter inst_ieee_compliance = 0;

input  [inst_sig_width+inst_exp_width:0] a;
output [inst_sig_width+inst_exp_width:0] out;

DW_fp_recip #(inst_sig_width, inst_exp_width, inst_ieee_compliance) R1(.a(a), .rnd(3'b000), .z(out));

// synopsys dc_script_begin
// set_implementation rtl R1
// synopsys dc_script_end

endmodule