module QUEEN(
    //Input Port
    clk,
    rst_n,

    in_valid,
    col,
    row,

    in_valid_num,
    in_num,

    out_valid,
    out

    );

input               clk, rst_n, in_valid,in_valid_num;
input       [3:0]   col,row;
input       [2:0]   in_num;

output reg          out_valid;
output reg  [3:0]   out;

//==============================================//
//             Parameter and Integer            //
//==============================================//
parameter S_IDLE = 3'd0; 
parameter S_INPUT = 3'd1;
parameter S_FORWARD = 3'd2;
parameter S_BACKWARD = 3'd3;
parameter S_OUTPUT = 3'd4; 

integer i;

//==============================================//
//                 reg declaration              //
//==============================================//
reg [2:0] current_state;
reg [2:0] next_state;

// for input
reg [2:0] input_cnt;
reg is_input [11:0];
reg [3:0] all_row[11:0];

// iteration
reg [3:0] current_col;

// judge
reg legal;
reg [3:0] next_row;

// output
reg [3:0] output_cnt;


//==============================================//
//                    FSM DFF                   //
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        current_state <= S_IDLE;
    else
        current_state <= next_state;
end

//==============================================//
//                  Store Input                 //
//==============================================//
// store input
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        for (i=0;i<12;i=i+1) begin: is_input_reset_loop
			is_input[i] <= 0;
		end
    end  
    else
    case(current_state)
    S_IDLE: begin
		if(in_valid) begin
			is_input[col] <= 1;
		end
		else begin
			for (i=0;i<12;i=i+1) begin: is_input_input_loop
				is_input[i] <= 0;
			end
		end
	end
    S_INPUT: is_input[col] <= 1;
    default: 
		for (i=0;i<12;i=i+1) begin: is_input_default_loop
			is_input[i] <= is_input[i];
		end
	/*begin
		for (i=0;i<12;i=i+1) begin: is_input_default_loop
			is_input[i] <= is_input[i];
		end
	end
	*/
    endcase
end

// input count
wire [2:0] next_input_cnt;
assign next_input_cnt = input_cnt - 1;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        input_cnt <= 0;
    end  
    else
    case(current_state)
    S_IDLE: if(in_valid_num)
				input_cnt <= in_num;
			else
				input_cnt <= input_cnt;
    S_INPUT: begin 
		input_cnt <= next_input_cnt;
	end
    default: input_cnt <= 0;
    endcase
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        for (i=0;i<12;i=i+1) begin: all_row_reset_loop
			all_row[i] <= 12;
		end
    end  
    else
    case(current_state)
    S_IDLE: begin
		if(in_valid) begin
			all_row[col] <= row;
		end
		else begin
			for (i=0;i<12;i=i+1) begin: all_row_input_loop
				all_row[i] <= 12;
			end
		end
	end
    S_INPUT: begin
		all_row[col] <= row;
	end
    S_FORWARD: 
		if(legal)
			all_row[current_col] <= next_row;
		else if(is_input[current_col])
			all_row[current_col] <= all_row[current_col];
		else 
			all_row[current_col] <= 12;
	S_BACKWARD:
		if(legal)
			all_row[current_col] <= next_row;
		else if(is_input[current_col])
			all_row[current_col] <= all_row[current_col];
		else 
			all_row[current_col] <= 12;
	default: all_row[current_col] <= all_row[current_col];
    endcase
end

//==============================================//
//             Forward and Backward             //
//==============================================//
// current row
wire [3:0] next_col;
wire [3:0] last_col;
assign next_col = current_col + 1;
assign last_col = current_col - 1;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        current_col <= 0;
    end
    else
    case(current_state)
    S_IDLE:     current_col <= 0;
    S_INPUT:    current_col <= 0;
	S_FORWARD: begin
		if(is_input[current_col])
			current_col <= next_col;
		else if(~legal)
			current_col <= last_col;
		else
			current_col <= next_col;
	end
	S_BACKWARD: begin
		if(~legal)
			current_col <= last_col;
		else
			current_col <= next_col;
	end
    default: current_col <= 0;
    endcase
end


//==============================================//
//              Judge Legal or not              //
//==============================================//
genvar gen_col;
genvar gen_row;

generate
reg [11:0] gen_row_legal;
for (gen_row = 0; gen_row < 12; gen_row = gen_row + 1) begin: gen_row_loop
	reg [11:0] gen_col_legal;
	for (gen_col = 0; gen_col < 12; gen_col = gen_col + 1) begin: gen_col_loop
		
		reg [3:0] row_diff;
		reg [3:0] col_diff;
		always@(*) begin
			if(gen_row > all_row[gen_col])
				row_diff = gen_row - all_row[gen_col];
			else
				row_diff = all_row[gen_col] - gen_row;
		end
		always@(*) begin
			if(current_col > gen_col)
				col_diff = current_col - gen_col;
			else
				col_diff = gen_col - current_col;
		end
		always@(*) begin
			if(gen_col == current_col || all_row[gen_col] == 12)
				gen_col_legal[gen_col] = 1;
			else if(row_diff == col_diff || gen_row == all_row[gen_col])
				gen_col_legal[gen_col] = 0;
			else if(gen_row > all_row[current_col] || all_row[current_col] == 12)
				gen_col_legal[gen_col] = 1;
			else
				gen_col_legal[gen_col] = 0;
		end
	end
	always@(*) begin
		gen_row_legal[gen_row] = gen_col_legal[0] && gen_col_legal[1] && gen_col_legal[2] && gen_col_legal[3] && gen_col_legal[4] && gen_col_legal[5] && gen_col_legal[6] && gen_col_legal[7] && gen_col_legal[8] && gen_col_legal[9] && gen_col_legal[10] && gen_col_legal[11];
	end
end


always@(*) begin
	if(gen_row_legal[0])
		next_row = 4'd0;
	else if(gen_row_legal[1])
		next_row = 4'd1;
	else if(gen_row_legal[2])
		next_row = 4'd2;
	else if(gen_row_legal[3])
		next_row = 4'd3;
	else if(gen_row_legal[4])
		next_row = 4'd4;
	else if(gen_row_legal[5])
		next_row = 4'd5;
	else if(gen_row_legal[6])
		next_row = 4'd6;
	else if(gen_row_legal[7])
		next_row = 4'd7;
	else if(gen_row_legal[8])
		next_row = 4'd8;
	else if(gen_row_legal[9])
		next_row = 4'd9;
	else if(gen_row_legal[10])
		next_row = 4'd10;
	else if(gen_row_legal[11])
		next_row = 4'd11;
	else
		next_row = 4'd12;
end

// to do finish next state and all DFF


always@(*) begin
	if(gen_row_legal == 0 || is_input[current_col] == 1)
		legal = 0;
	else
		legal = 1;
end

endgenerate

//==============================================//
//                    Output                    //
//==============================================//
// output
// count 12 cycles
wire [3:0] next_output_cnt;
assign next_output_cnt = output_cnt + 1;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        output_cnt <= 0;
    else begin
    case(current_state)
    S_IDLE: output_cnt <= 0;
	S_OUTPUT: output_cnt <= next_output_cnt;
    default: output_cnt <= 0;
    endcase end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        out <= 0;
		out_valid <= 0;
    end  
    else begin
    case(current_state)
    S_IDLE: begin
		out <= 0;
		out_valid <= 0;
	end
    S_INPUT: begin
		out <= 0;
		out_valid <= 0;
	end
	S_OUTPUT: begin
		out <= all_row[output_cnt];
		out_valid <= 1;
	end
    default: begin
        out <= 0;
		out_valid <= 0;
    end
    endcase end
end

//==============================================//
//               Next State Logic               //
//==============================================//
//next_state
always @(*) begin
    case(current_state)
    S_IDLE: 
			if (in_valid && in_num == 1)
				next_state = S_FORWARD;
			else if(in_valid)
				next_state = S_INPUT;
            else
				next_state = S_IDLE;
    S_INPUT:if(input_cnt == 2)
				next_state = S_FORWARD;
			else
				next_state = S_INPUT;
	S_FORWARD: begin
		if(current_col == 12)
			next_state = S_OUTPUT;
		else if(is_input[current_col])
			next_state = S_FORWARD;
		else if(~legal)
			next_state = S_BACKWARD;
		else
			next_state = S_FORWARD;
	end
	S_BACKWARD: begin
		if(~legal)
			next_state = S_BACKWARD;
		else
			next_state = S_FORWARD;
	end
	S_OUTPUT: begin
		if(output_cnt == 11)
			next_state = S_IDLE;
		else
			next_state = S_OUTPUT;
	end
    default: next_state = current_state;
    endcase
end






//GOOD LUCKY

endmodule 