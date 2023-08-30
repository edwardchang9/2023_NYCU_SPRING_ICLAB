module bridge(input clk, INF.bridge_inf inf);

// parameters
parameter S_IDLE = 3'd0;
parameter S_READ_REQUEST = 3'd1;
parameter S_READ_WAIT = 3'd2;
parameter S_WRITE_REQUEST = 3'd3;
parameter S_WRITE_SEND = 3'd4;
parameter S_WRITE_WAIT = 3'd5;
parameter S_OUT = 3'd6;

logic [2:0] current_state;
logic [2:0] next_state;

logic [63:0] save_data;
logic [7:0] save_addr;

// address 1 people 8 * 8bits
// total 256 people, start from 17'h_1_0_0_0_0
// read assign
assign inf.R_READY  = (current_state == S_READ_WAIT);
assign inf.AR_ADDR  = (current_state == S_READ_REQUEST) ? {6'b1_0000_0, save_addr, 3'b000} : 0;
assign inf.AR_VALID = (current_state == S_READ_REQUEST);
// write assign
assign inf.AW_ADDR  = (current_state == S_WRITE_REQUEST) ? {6'b1_0000_0, save_addr, 3'b000} : 0;
assign inf.AW_VALID = (current_state == S_WRITE_REQUEST);
assign inf.W_DATA   = (current_state == S_WRITE_SEND) ? save_data : 0;
assign inf.W_VALID  = (current_state == S_WRITE_SEND);
assign inf.B_READY  = (current_state == S_WRITE_WAIT);


//input  
// Pattern
//rst_n,
// Bridge
//C_addr, C_data_w, C_in_valid, C_r_wb, 
// DRAM
//AR_READY, R_VALID, R_RESP, R_DATA, AW_READY, W_READY, B_VALID, B_RESP,

always_ff @(posedge clk) begin
	if(inf.C_in_valid)
		save_data <= inf.C_data_w;
	else
		save_data <= save_data;
end

always_ff @(posedge clk) begin
	if(inf.C_in_valid)
		save_addr <= inf.C_addr;
	else
		save_addr <= save_addr;
end

//output 
// Bridge
//C_out_valid, C_data_r, 
// DRAM
//AR_VALID, AR_ADDR, R_READY, AW_VALID, AW_ADDR, W_VALID, W_DATA, B_READY

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		current_state <= S_IDLE;
	else
		current_state <= next_state;
end

always_comb begin
	case(current_state)
	S_IDLE:
		if(inf.C_in_valid && inf.C_r_wb)
			next_state = S_READ_REQUEST;
		else if(inf.C_in_valid && !inf.C_r_wb)
			next_state = S_WRITE_REQUEST;
		else
			next_state = S_IDLE;
	S_READ_REQUEST:
		if(inf.AR_READY)
			next_state = S_READ_WAIT;
		else
			next_state = S_READ_REQUEST;
	S_READ_WAIT:
		if(inf.R_VALID)
			next_state = S_OUT;
		else
			next_state = S_READ_WAIT;
	S_WRITE_REQUEST:
		if(inf.AW_READY)
			next_state = S_WRITE_SEND;
		else
			next_state = S_WRITE_REQUEST;
	S_WRITE_SEND:
		if(inf.W_READY)
			next_state = S_WRITE_WAIT;
		else
			next_state = S_WRITE_SEND;
	S_WRITE_WAIT:
		if(inf.B_VALID)
			next_state = S_OUT;
		else
			next_state = S_WRITE_WAIT;
	S_OUT:
		next_state = S_IDLE;
	default: next_state = S_IDLE;
	endcase
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.C_out_valid <= 0;
	else
		inf.C_out_valid <= next_state == S_OUT;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		inf.C_data_r <= 0;
	else if(next_state == S_OUT && current_state == S_READ_WAIT)
		inf.C_data_r <= inf.R_DATA;
	else
		inf.C_data_r <= 0;
end

endmodule