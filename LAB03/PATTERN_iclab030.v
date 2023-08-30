`ifdef RTL
    `define CYCLE_TIME 10.0
`endif
`ifdef GATE
    `define CYCLE_TIME 10.0
`endif
`define PATNUM 250

module PATTERN(
    // Output Signals
    clk,
    rst_n,
    in_valid,
    init,
    in0,
    in1,
    in2,
    in3,
    // Input Signals
    out_valid,
    out
);
/* Input for design */
output reg       clk, rst_n;
output reg       in_valid;
output reg [1:0] init;
output reg [1:0] in0, in1, in2, in3; 


/* Output for pattern */
input            out_valid;
input      [1:0] out; 

//================================================================
// parameter
//================================================================
integer seed = 36;
integer patcount = 1;
integer is_train;
integer i, j, k, l;
integer random_number;
integer actual_init;
integer map[0:3][0:63];
integer latency = 0;
integer total_latency = 0;
integer col = 0;
integer cycle_count = 0;
integer current_col = 0;
integer current_row = 0;

//================================================================
// clock
//================================================================
real	CYCLE = `CYCLE_TIME;
always	#(CYCLE/2.0) clk = ~clk;
initial	clk = 0;

//================================================================
// initial
//================================================================
initial begin
	reset_task;
	for (patcount = 0; patcount < `PATNUM; patcount = patcount + 1) begin
		input_task;
		wait_out_valid_task;
		check_ans_task;
	end
	$finish;
end

task check_spec_4_and_5; begin
	if(out_valid === 1'b0 && out !=='b0) begin
        $display("SPEC 4 IS FAIL!");
        $finish;
    end
	if(out_valid === 1'b1 && in_valid === 1'b1)
	begin
		$display("SPEC 5 IS FAIL!");
		$finish;
	end
end
endtask

always@(negedge clk or posedge clk) begin
	check_spec_4_and_5;
end

task reset_task; begin 
    rst_n = 'b1;
    in_valid = 'b0;
    init = 2'bxx;
	in0 = 2'bxx;
	in1 = 2'bxx;
	in2 = 2'bxx;
	in3 = 2'bxx;
    //total_latency = 0;
    force clk = 0;
    #CYCLE; rst_n = 0;
    #CYCLE; rst_n = 1;
    if(out_valid !== 1'b0 || out !=='b0) begin
        $display("SPEC 3 IS FAIL!");
        $finish;
    end
	#CYCLE; release clk;
end endtask


// generate pattern
task generatee_pattern_task;
begin
	// initial
	for (i = 0; i < 64; i =i+1) begin
		map[0][i] = 0;
		map[1][i] = 0;
		map[2][i] = 0;
		map[3][i] = 0;
	end
	// add obstacle
	for (i = 0; i < 64; i =i+1) begin
		for (j = 0; j < 4; j =j+1) begin
			if( (i % 8 == 2) || (i % 8 == 4) || (i % 8 == 6) ) begin
				map[j][i] = $urandom_range(0,2);
			end
		end
	end
	// add train
	for (i = 0; i < 8; i=i+1) begin
		is_train = $urandom_range(1,14);
		for (j = 0; j < 4; j=j+1) begin
			if(is_train[j]) begin
				map[j][8*i] = 3;
				map[j][8*i+1] = 3;
				map[j][8*i+2] = 3;
				map[j][8*i+3] = 3;
			end
		end
	end
end
endtask

task input_task; 
begin
	generatee_pattern_task;
	@(negedge clk);
	@(negedge clk);
	@(negedge clk);
	// first input cycle
	in_valid = 1'b1;
	random_number = $random(seed) % 'd4;
	if(map[random_number][0] != 3)
		actual_init = random_number;
	else if(map[(random_number+1) % 'd4][0] != 3)
		actual_init = (random_number+1) % 'd4;
	else if(map[(random_number+2) % 'd4][0] != 3)
		actual_init = (random_number+2) % 'd4;
	else
		actual_init = (random_number+3) % 'd4;
	
	init = actual_init;
	in0 = map[0][0];
	in1 = map[1][0];
	in2 = map[2][0];
	in3 = map[3][0];
	@(negedge clk);
	init = 'bx;
	// else cycles
	for (i = 1; i < 64; i=i+1) begin
		in0 = map[0][i];
		in1 = map[1][i];
		in2 = map[2][i];
		in3 = map[3][i];
		@(negedge clk);
	end
	// Disable input
	in_valid = 1'b0;
	in0 = 2'bxx;
	in1 = 2'bxx;
	in2 = 2'bxx;
	in3 = 2'bxx;
	@(negedge clk);
end
endtask


task wait_out_valid_task; begin
    latency = -1;
    while(out_valid !== 1'b1) begin
	latency = latency + 1;
		if( latency == 3000) begin
			$display("SPEC 6 IS FAIL!");
			$finish;
		end
		 @(negedge clk);
   end
   total_latency = total_latency + latency;
end endtask

task check_ans_task; begin
    current_row = actual_init;
	current_col = 0;
	cycle_count = 0;
	while(out_valid === 1'b1 && cycle_count < 63 && (out === 'd0 || out === 'd1 || out === 'd2 || out === 'd3)) begin
	cycle_count = cycle_count + 1;
	if(out === 2'd0)
	begin
		current_col = current_col + 1;
		if(map[current_row][current_col] == 1)
		begin
			$display("SPEC 8-2 IS FAIL!");
			$finish;
		end
		else if(map[current_row][current_col] == 3)
		begin
			$display("SPEC 8-4 IS FAIL!");
			$finish;
		end
	end
	else if(out === 2'd1)
	begin
		current_col = current_col + 1;
		current_row = current_row + 1;
		if(current_row == 4)
		begin
			$display("SPEC 8-1 IS FAIL!");
			$finish;
		end
		else if(map[current_row][current_col] == 1)
		begin
			$display("SPEC 8-2 IS FAIL!");
			$finish;
		end
		else if(map[current_row][current_col] == 2)
		begin
			$display("SPEC 8-3 IS FAIL!");
			$finish;
		end
		else if(map[current_row][current_col] == 3)
		begin
			$display("SPEC 8-4 IS FAIL!");
			$finish;
		end
	end
	else if(out === 2'd2)
	begin
		if(current_row == 0)
		begin
			$display("SPEC 8-1 IS FAIL!");
			$finish;
		end
		current_col = current_col + 1;
		current_row = current_row - 1;
		if(map[current_row][current_col] == 1)
		begin
			$display("SPEC 8-2 IS FAIL!");
			$finish;
		end
		else if(map[current_row][current_col] == 2)
		begin
			$display("SPEC 8-3 IS FAIL!");
			$finish;
		end
		else if(map[current_row][current_col] == 3)
		begin
			$display("SPEC 8-4 IS FAIL!");
			$finish;
		end
	end
	else
	begin
		current_col = current_col + 1;
		if(map[current_row][current_col] == 2)
		begin
			$display("SPEC 8-3 IS FAIL!");
			$finish;
		end
		else if(map[current_row][current_col] == 3)
		begin
			$display("SPEC 8-4 IS FAIL!");
			$finish;
		end
		if(current_col != 0) begin
			if(map[current_row][current_col - 1] == 1)
			begin
				$display("SPEC 8-5 IS FAIL!");
				$finish;
			end
		end
	end
     @(negedge clk);
	end
	if(out_valid === 1'b1 || cycle_count < 63) begin
		begin
			$display("SPEC 7 IS FAIL!");
			$finish;
		end
	end
end endtask


endmodule