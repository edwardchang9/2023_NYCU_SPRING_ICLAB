`include "AFIFO.v"

module CDC #(parameter DSIZE = 8,
			   parameter ASIZE = 4)(
	//Input Port
	rst_n,
	clk1,
    clk2,
	in_valid,
    doraemon_id,
    size,
    iq_score,
    eq_score,
    size_weight,
    iq_weight,
    eq_weight,
    //Output Port
	ready,
    out_valid,
	out,
    
); 
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
output reg  [7:0] out;
output reg	out_valid,ready;

input rst_n, clk1, clk2, in_valid;
input  [4:0]doraemon_id;
input  [7:0]size;
input  [7:0]iq_score;
input  [7:0]eq_score;
input [2:0]size_weight,iq_weight,eq_weight;
//---------------------------------------------------------------------
//   STATE DECLARATION
//---------------------------------------------------------------------
parameter S_INIT = 'd0;
parameter S_DO = 'd1;
parameter S_STALL_1 = 'd2;
parameter S_WAIT = 'd3;

//---------------------------------------------------------------------
//   REG DECLARATION
//---------------------------------------------------------------------
reg [1:0] current_state;
reg [1:0] next_state;

reg [2:0] size_weight_buf;
reg [2:0] iq_weight_buf;
reg [2:0] eq_weight_buf;

reg [12:0] count;
reg [2:0] stall_count;


reg [28:0] doraemons[4:0];
reg [28:0] next_doraemons[4:0];
// fifo port declaration
//Input Port (read)
wire read_enable;
//Input Port (write)
reg write_enable;
reg [7:0] write_data;

//Output Port (read)
wire read_is_empty;
wire [7:0] read_data;
//Output Port (write)
wire write_is_full;


wire [20:0] max;
reg [7:0] max_buff_1;
reg [7:0] max_buff_2;
reg [7:0] max_buff_3;

reg in_valid_buff;

always@(posedge clk1) begin
	in_valid_buff <= in_valid;
end


//---------------------------------------------------------------------
//   INPUT
//---------------------------------------------------------------------

always@(posedge clk1) begin
	if(in_valid)
		size_weight_buf <= size_weight;
	else
		size_weight_buf <= size_weight_buf;
end
always@(posedge clk1) begin
	if(in_valid)
		iq_weight_buf <= iq_weight;
	else
		iq_weight_buf <= iq_weight_buf;
end
always@(posedge clk1) begin
	if(in_valid)
		eq_weight_buf <= eq_weight;
	else
		eq_weight_buf <= eq_weight_buf;
end

always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		count <= 0;
	end
	else if(in_valid)
		count <= count + 1;
	else
		count <= count;
end

always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		stall_count <= 0;
	end
	else if(current_state == S_STALL_1)
		stall_count <= stall_count + 1;
	else
		stall_count <= 0;
end

reg [2:0] bias;
wire [2:0] next_bias;
assign next_bias = max[15:13];
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		bias <= 3'd5;
	end
	else if(in_valid)
		bias <= next_bias;
	else
		bias <= bias;
end

always@(posedge clk1) begin
	doraemons[4] <= next_doraemons[4];
	doraemons[3] <= next_doraemons[3];
	doraemons[2] <= next_doraemons[2];
	doraemons[1] <= next_doraemons[1];
	doraemons[0] <= next_doraemons[0];
end

always@(*) begin
	case(current_state)
	S_INIT: begin
	next_doraemons[4] = {iq_score,eq_score,size,doraemon_id};
	next_doraemons[3] = doraemons[4];
	next_doraemons[2] = doraemons[3];
	next_doraemons[1] = doraemons[2];
	next_doraemons[0] = doraemons[1];
	end
	S_DO: 
	if(in_valid) begin
	next_doraemons[4] = (next_bias == 3'd4) ? {iq_score,eq_score,size,doraemon_id} : doraemons[4];
	next_doraemons[3] = (next_bias == 3'd3) ? {iq_score,eq_score,size,doraemon_id} : doraemons[3];
	next_doraemons[2] = (next_bias == 3'd2) ? {iq_score,eq_score,size,doraemon_id} : doraemons[2];
	next_doraemons[1] = (next_bias == 3'd1) ? {iq_score,eq_score,size,doraemon_id} : doraemons[1];
	next_doraemons[0] = (next_bias == 3'd0) ? {iq_score,eq_score,size,doraemon_id} : doraemons[0];
	end
	else begin
	next_doraemons[4] = doraemons[4];
	next_doraemons[3] = doraemons[3];
	next_doraemons[2] = doraemons[2];
	next_doraemons[1] = doraemons[1];
	next_doraemons[0] = doraemons[0];
	end
	default: begin
	next_doraemons[4] = doraemons[4];
	next_doraemons[3] = doraemons[3];
	next_doraemons[2] = doraemons[2];
	next_doraemons[1] = doraemons[1];
	next_doraemons[0] = doraemons[0];
	end
	endcase
end

wire [12:0] score[4:0];
assign score[0] = (doraemons[0][12:5] * size_weight_buf) + (doraemons[0][20:13] * eq_weight_buf) + (doraemons[0][28:21] * iq_weight_buf);
assign score[1] = (doraemons[1][12:5] * size_weight_buf) + (doraemons[1][20:13] * eq_weight_buf) + (doraemons[1][28:21] * iq_weight_buf);
assign score[2] = (doraemons[2][12:5] * size_weight_buf) + (doraemons[2][20:13] * eq_weight_buf) + (doraemons[2][28:21] * iq_weight_buf);
assign score[3] = (doraemons[3][12:5] * size_weight_buf) + (doraemons[3][20:13] * eq_weight_buf) + (doraemons[3][28:21] * iq_weight_buf);
assign score[4] = (doraemons[4][12:5] * size_weight_buf) + (doraemons[4][20:13] * eq_weight_buf) + (doraemons[4][28:21] * iq_weight_buf);

wire [20:0] n1;
wire [20:0] n2;
wire [20:0] n3;
assign n1 = (score[1] > score[0]) ? {doraemons[1][4:0],3'd1,score[1]} : {doraemons[0][4:0],3'd0,score[0]};
assign n2 = (score[3] > score[2]) ? {doraemons[3][4:0],3'd3,score[3]} : {doraemons[2][4:0],3'd2,score[2]};
assign n3 = (score[4] > n2[12:0]) ? {doraemons[4][4:0],3'd4,score[4]} : n2;
assign max = (n3[12:0] > n1[12:0]) ? n3 : n1;


//---------------------------------------------------------------------
//   TO FIFO
//---------------------------------------------------------------------
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		ready <= 0;
	end else begin
	case(current_state)
	S_INIT: ready <= 1;
	S_DO:
		if(count != 'd6000)
			ready <= !write_is_full;
		else
			ready <= 0;
	S_STALL_1: ready <= 0;
	default: ready <= 0;
	endcase
	end
end

always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		write_enable <= 0;
	end else begin
	case(current_state)
	S_DO: write_enable <= in_valid_buff;
	S_STALL_1: write_enable <= 1;
	default: write_enable <= 0;
	endcase
	end
end



//---------------------------------------------------------------------
//   AFIFO
//---------------------------------------------------------------------

AFIFO #(.DSIZE(8), .ASIZE(4)) A1(
	//Input Port
	.rst_n(rst_n),
    //Input Port (read)
    .rclk(clk2),
    .rinc(read_enable),
	//Input Port (write)
    .wclk(clk1),
    .winc(write_enable),
	.wdata(write_data),

    //Output Port (read)
    .rempty(read_is_empty),
	.rdata(read_data),
    //Output Port (write)
    .wfull(write_is_full)
); 

always@(posedge clk1) begin
	if(current_state == S_DO && !write_is_full)
		write_data <= {max[15:13],max[20:16]};
	else
		write_data <= max_buff_1;
end

always@(posedge clk1) begin
	max_buff_1 <= {max[15:13],max[20:16]};
	max_buff_2 <= max_buff_1;
	max_buff_3 <= max_buff_2;
end

//---------------------------------------------------------------------
//   FSM
//---------------------------------------------------------------------
always@(posedge clk1 or negedge rst_n) begin
	if(!rst_n) begin
		current_state <= S_INIT;
	end else begin
		current_state <= next_state;
	end
end

always@(*) begin
	case(current_state)
	S_INIT: begin
		if(count == 'd4)
			next_state = S_DO;
		else
			next_state = S_INIT;
	end
	S_DO:
		if(write_is_full) begin
			next_state = S_STALL_1;
		end
		else
			next_state = S_DO;
	S_STALL_1:
		if(stall_count == 'd1)
			next_state = S_DO;
		else
			next_state = S_STALL_1;
	S_WAIT:
	if(in_valid)
		next_state = S_DO;
	else
		next_state = S_WAIT;
	default: next_state = S_DO;
	endcase
end


//---------------------------------------------------------------------
//   OUT
//---------------------------------------------------------------------
assign read_enable = !read_is_empty;
wire [7:0] next_out;
assign next_out = (!read_is_empty) ? read_data : 0; 

always@(posedge clk2 or negedge rst_n) begin
	if(!rst_n) begin
		out_valid <= 0;
	end else begin
		out_valid <= !read_is_empty;
	end
end

always@(posedge clk2 or negedge rst_n) begin
	if(!rst_n) begin
		out <= 0;
	end else begin
		out <= next_out;
	end
end

endmodule