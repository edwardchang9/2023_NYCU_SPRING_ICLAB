module SUBWAY(
    //Input Port
    clk,
    rst_n,
    in_valid,
    init,
    in0,
    in1,
    in2,
    in3,
    //Output Port
    out_valid,
    out
);


input clk, rst_n;
input in_valid;
input [1:0] init;
input [1:0] in0, in1, in2, in3; 
output reg       out_valid;
output reg [1:0] out;


//==============================================//
//       parameter & integer declaration        //
//==============================================//
parameter S_IDLE = 2'd0;
parameter S_INPUT = 2'd1;
parameter S_OUTPUT = 2'd2;
integer i;


//==============================================//
//           reg & wire declaration             //
//==============================================//
reg [1:0] current_state;
reg [1:0] next_state;

reg [1:0] start;
reg [1:0] target;
reg [5:0] count;

reg [1:0] row1;
reg [1:0] row2;
reg [7:0] ans_step2;
reg [7:0] ans_step4;
reg [1:0] ans_step5 [7:0];
reg [7:0] ans_step6;
reg [1:0] ans_step7 [7:0];
reg [1:0] ans_step8 [7:0];

//==============================================//
//                  design                      //
//==============================================//


//==============================================//
//                    DFF                       //
//==============================================//
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        current_state <= S_IDLE;
    else
        current_state <= next_state;
end

//==============================================//
//                  calculate                   //
//==============================================//
// next target comb
reg [1:0] next_target;
always@(*) begin
	if(in_valid)
		if(in0==0)
			next_target = 2'd0;
		else if(in1==0)
			next_target = 2'd1;
		else if(in2==0)
			next_target = 2'd2;
		else
			next_target = 2'd3;
	else
		next_target = 2'd1;
end

// start position
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        start <= 0;
    end  
    else begin
    case(current_state)
    S_IDLE: begin
		if(in_valid)
			start <= init;
		else
			start <= 0;
	end
	S_INPUT: begin
		if(count[2:0] == 3'd7)
			start <= next_target;
		else
			start <= start;
	end
    default: begin
        start <= start;
    end
    endcase end
end

// target position
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        target <= 0;
    end  
    else begin
    case(current_state)
    S_IDLE: if(in_valid)
			target <= init;
		else
			target <= 0;
	S_INPUT: begin
		if(count[2:0] == 3'd7)
			target <= next_target;
	end
    default: begin
        target <= target;
    end
    endcase end
end

// count
wire [5:0] next_count;
assign next_count = count + 1;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        count <= 0;
    end  
    else begin
    case(current_state)
    S_IDLE: begin
		count <= 0;
	end
    default: begin
		count <= next_count;
	end
    endcase end
end

// row shift register
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		row1 <= 0;
		row2 <= 0;
    end 
	else if(count[0]) begin
		row1 <= in1;
		row2 <= in2;
	end
	else begin
		row1 <= row1;
		row2 <= row2;
	end
end

// now row
reg [1:0] now_row;
always@(*) begin
	case(start)
	'd0: now_row = in0;
	'd1: now_row = in1;
	'd2: now_row = in2;
	'd3: now_row = in3;
	endcase
end

// now row jump
wire now_row_jump;
assign now_row_jump = (now_row == 'd1) ? 'd1 : 'd0;

// step2 shift register
wire step2_trigger;
assign step2_trigger = (count[2:0] == 'd1);
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		ans_step2 <= 0;
    end 
	else if(step2_trigger) begin
		for (i=0;i<8;i=i+1)
			ans_step2[i+1] <= ans_step2[i];
		// ans_step2[7:1] <= ans_step2[6:0];
		ans_step2[0] <= now_row_jump;
	end
	else begin
		ans_step2 <= ans_step2;
	end
end

// step4 shift register
wire step4_trigger;
assign step4_trigger = (count[2:0] == 'd3);
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		ans_step4 <= 0;
    end 
	else if(step4_trigger) begin
		for (i=0;i<8;i=i+1)
			ans_step4[i+1] <= ans_step4[i];
		// ans_step4[7:1] <= ans_step4[6:0];
		ans_step4[0] <= now_row_jump;
	end
	else begin
		ans_step4 <= ans_step4;
	end
end

// next target jump
reg [1:0] step6_row;
wire step6_jump;
wire [1:0] step6_value;
assign step6_value = (step6_row == 2'd1) ? row1 : row2;
assign step6_jump = (step6_value == 'd1) ? 'd1 : 'd0;

// step6 shift register
wire step6_trigger;
assign step6_trigger = (count[2:0] == 'd7);
always@(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		ans_step6 <= 0;
    end
	else if(step6_trigger) begin
		for (i=0;i<8;i=i+1)
			ans_step6[i+1] <= ans_step6[i];
		// ans_step4[7:1] <= ans_step4[6:0];
		ans_step6[0] <= step6_jump;
	end
	else begin
		ans_step6 <= ans_step6;
	end
end

// step 5 logic
reg [1:0] step5_direct;
always@(*) begin
	case(start)
	2'd0: begin
		step5_direct = 2'd1;
		step6_row = 2'd1;
	end
	2'd1: begin
		step5_direct = 2'd0;
		step6_row = 2'd1;
	end
	2'd2: begin
		step5_direct = 2'd0;
		step6_row = 2'd2;
	end
	2'd3: begin
		step5_direct = 2'd2;
		step6_row = 2'd2;
	end
	endcase
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		for (i=0;i<8;i=i+1)
			ans_step5[i] <= 0;
    end
	else if(step4_trigger) begin
		for (i=0;i<7;i=i+1)
			ans_step5[i+1] <= ans_step5[i];
		// ans_step4[7:1] <= ans_step4[6:0];
		ans_step5[0] <= step5_direct;
	end
	else begin
		for (i=0;i<8;i=i+1)
			ans_step5[i] <= ans_step5[i];
	end
end

// step 7 & 8 logic
reg [1:0] step7_direct;
reg [1:0] step8_direct;
always@(*) begin
	case({start,next_target})
	4'b00_00: begin
		step7_direct = 2'd2;
		step8_direct = 2'd0;
	end
	4'b00_01: begin
		step7_direct = 2'd0;
		step8_direct = 2'd0;
	end
	4'b00_10: begin
		step7_direct = 2'd1;
		step8_direct = 2'd0;
	end
	4'b00_11: begin
		step7_direct = 2'd1;
		step8_direct = 2'd1;
	end
	4'b01_00: begin
		step7_direct = 2'd2;
		step8_direct = 2'd0;
	end
	4'b01_01: begin
		step7_direct = 2'd0;
		step8_direct = 2'd0;
	end
	4'b01_10: begin
		step7_direct = 2'd1;
		step8_direct = 2'd0;
	end
	4'b01_11: begin
		step7_direct = 2'd1;
		step8_direct = 2'd1;
	end
	4'b10_00: begin
		step7_direct = 2'd2;
		step8_direct = 2'd2;
	end
	4'b10_01: begin
		step7_direct = 2'd2;
		step8_direct = 2'd0;
	end
	4'b10_10: begin
		step7_direct = 2'd0;
		step8_direct = 2'd0;
	end
	4'b10_11: begin
		step7_direct = 2'd1;
		step8_direct = 2'd0;
	end
	4'b11_00: begin
		step7_direct = 2'd2;
		step8_direct = 2'd2;
	end
	4'b11_01: begin
		step7_direct = 2'd2;
		step8_direct = 2'd0;
	end
	4'b11_10: begin
		step7_direct = 2'd0;
		step8_direct = 2'd0;
	end
	4'b11_11: begin
		step7_direct = 2'd1;
		step8_direct = 2'd0;
	end
	endcase
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		for (i=0;i<8;i=i+1)
			ans_step7[i] <= 0;
    end
	else if(step6_trigger) begin
		for (i=0;i<7;i=i+1)
			ans_step7[i+1] <= ans_step7[i];
		// ans_step4[7:1] <= ans_step7[6:0];
		ans_step7[0] <= step7_direct;
	end
	else begin
		for (i=0;i<8;i=i+1)
			ans_step7[i] <= ans_step7[i];
	end
end

always@(posedge clk or negedge rst_n) begin
	if(!rst_n)begin
		for (i=0;i<8;i=i+1)
			ans_step8[i] <= 0;
    end
	else if(step6_trigger) begin
		for (i=0;i<7;i=i+1)
			ans_step8[i+1] <= ans_step8[i];
		// ans_step4[7:1] <= ans_step7[6:0];
		ans_step8[0] <= step8_direct;
	end
	else begin
		for (i=0;i<8;i=i+1)
			ans_step8[i] <= ans_step8[i];
	end
end

//==============================================//
//                    Output                    //
//==============================================//
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
		out_valid <= 1;
		case(count[2:0])
		3'd0: out <= {ans_step2[7],ans_step2[7]};
		3'd2: out <= {ans_step4[7],ans_step4[7]};
		3'd3: out <= ans_step5[7];
		3'd4: out <= {ans_step6[7],ans_step6[7]};
		3'd5: out <= ans_step7[7];
		3'd6: out <= ans_step8[7];
		default: out <= 0;
	endcase
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
    S_IDLE: if(in_valid)
				next_state = S_INPUT;
            else
				next_state = S_IDLE;
	S_INPUT: begin
			if(count == 'd62)
				next_state = S_OUTPUT;
			else
				next_state = S_INPUT;
	end
	S_OUTPUT: begin
			if(count == 'd61)
				next_state = S_IDLE;
			else
				next_state = S_OUTPUT;
	end
    default: next_state = current_state;
    endcase
end

endmodule