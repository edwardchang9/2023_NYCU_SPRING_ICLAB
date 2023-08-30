//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//
//   File Name   : CHECKER.sv
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
//`include "Usertype_PKG.sv"

module Checker(input clk, INF.CHECKER inf);
import usertype::*;

//covergroup Spec1 @();
//	
//       finish your covergroup here
//	
//	
//endgroup


//declare other cover group

//declare the cover group 
//Spec1 cov_inst_1 = new();

covergroup Spec1 @(posedge clk iff(inf.amnt_valid));
	coverpoint inf.D.d_money {
		option.at_least = 10;
		bins bin_1 = {[0 : 12000]};
		bins bin_2 = {[12001 : 24000]};
		bins bin_3 = {[24001 : 36000]};
		bins bin_4 = {[36001 : 48000]};
		bins bin_5 = {[48001 : 60000]};
	}
endgroup
Spec1 cov_inst_1 = new();

covergroup Spec2 @(posedge clk iff(inf.id_valid));
   	coverpoint inf.D.d_id[0] {
   		option.auto_bin_max = 256;
   		option.at_least     = 2;
   	}
endgroup
Spec2 cov_inst_2 = new();

covergroup Spec3 @(posedge clk iff(inf.act_valid));
   	coverpoint inf.D.d_act[0] {
   		option.at_least = 10;
   		bins bins_1[]   = (Buy, Check, Deposit, Return => Buy, Check, Deposit, Return);
   	}
endgroup
Spec3 cov_inst_3 = new();

covergroup Spec4 @(posedge clk iff(inf.item_valid));
   	coverpoint inf.D.d_item[0] {
   		option.at_least = 20;
   		bins bin_1[]   = {Large, Medium, Small};
   	}
endgroup
Spec4 cov_inst_4 = new();

covergroup Spec5 @(negedge clk iff(inf.out_valid));
   	coverpoint inf.err_msg {
   		option.at_least = 20;
   		bins bin_1[]    = {
			INV_Not_Enough,
			Out_of_money,
			INV_Full,
			Wallet_is_Full,
			Wrong_ID,
			Wrong_Num,
			Wrong_Item,
			Wrong_act
		};
	}
endgroup
Spec5 cov_inst_5 = new();

covergroup Spec6 @(negedge clk iff(inf.out_valid));
   	coverpoint inf.complete {
   		option.at_least = 200;
   		bins bin_1[]   = {0, 1};
   	}
endgroup
Spec6 cov_inst_6 = new();

//************************************ below assertion is to check your pattern ***************************************** 
//                                          Please finish and hand in it
// This is an example assertion given by TA, please write other assertions at the below
// assert_interval : assert property ( @(posedge clk)  inf.out_valid |=> inf.id_valid == 0)
// else
// begin
// 	$display("Assertion X is violated");
// 	$fatal; 
// end

//write other assertions

logic no_in_valid;
assign no_in_valid = !inf.id_valid && !inf.act_valid && !inf.amnt_valid && !inf.item_valid && !inf.num_valid;

logic is_in_valid_without_id;
assign is_in_valid_without_id = inf.act_valid || inf.amnt_valid || inf.item_valid || inf.num_valid;

logic is_in_valid;
assign is_in_valid = inf.act_valid || inf.amnt_valid || inf.item_valid || inf.num_valid || inf.id_valid;

logic action_is_send;
logic need_id_in;
logic doing_check;
logic [2:0] check_lat_count;
Action save_act;
logic input_seller_ID;

always@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		action_is_send <= 0;
	else if(inf.act_valid)
		action_is_send <= 1;
	else if(inf.out_valid)
		action_is_send <= 0;
	else
		action_is_send <= action_is_send;
end

always@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		need_id_in <= 0;
	else if(inf.act_valid && (inf.D.d_act == Return || inf.D.d_act == Buy || inf.D.d_act == Check) )
		need_id_in <= 1;
	else if(need_id_in) begin
		if(inf.out_valid)
			need_id_in <= 0;
		else
			need_id_in <= 1;
	end
	else
		need_id_in <= 0;
end

always@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		doing_check <= 0;
	else if(inf.act_valid && inf.D.d_act == Check)
		doing_check <= 1;
	else if(check_lat_count == 'd5 || inf.id_valid) begin
		doing_check <= 0;
	end
	else
		doing_check <= doing_check;
end

always@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		input_seller_ID <= 0;
	else if( action_is_send && save_act == Check && inf.id_valid)
		input_seller_ID <= 1;
	else if(inf.out_valid) begin
		input_seller_ID <= 0;
	end
	else
		input_seller_ID <= input_seller_ID;
end

always@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		check_lat_count <= 0;
	else if(doing_check)
		check_lat_count <= check_lat_count + 1;
	else if(inf.out_valid)
		check_lat_count <= 0;
	else
		check_lat_count <= check_lat_count;
end

always_ff@(posedge clk) begin
	if(inf.act_valid)
		save_act <= inf.D.d_act;
	else
		save_act <= save_act;
end

typedef enum logic [5:0] {
 S_IDLE = 'd0,
 S_BUY_IN_ITEM = 'd1,
 S_BUY_IN_NUM = 'd2,
 S_BUY_IN_ID = 'd3,
 S_CHECK_IN = 'd4,
 S_DEPOSIT = 'd5,
 S_WAIT_OUT = 'd6,
 S_INIT = 'd7,
 S_DONE_IN_USER = 'd8
}	Pattern_state ;



Pattern_state current_state;
Pattern_state next_state;

always@(posedge clk or negedge inf.rst_n) begin
	if(!inf.rst_n)
		current_state <= S_INIT;
	else
		current_state <= next_state;
end

always@(*) begin
	case(current_state)
	S_IDLE:
		if(inf.id_valid)
			next_state = S_DONE_IN_USER;
		else if(inf.act_valid)
			if(inf.D.d_act == Buy || inf.D.d_act == Return)
				next_state = S_BUY_IN_ITEM;
			else if(inf.D.d_act == Deposit)
				next_state = S_DEPOSIT;
			else if(inf.D.d_act == Check)
				next_state = S_CHECK_IN;
			else
				next_state = S_IDLE;
		else
			next_state = S_IDLE;
	S_DONE_IN_USER:
		if(inf.act_valid)
			if(inf.D.d_act == Buy || inf.D.d_act == Return)
				next_state = S_BUY_IN_ITEM;
			else if(inf.D.d_act == Deposit)
				next_state = S_DEPOSIT;
			else if(inf.D.d_act == Check)
				next_state = S_CHECK_IN;
			else
				next_state = S_DONE_IN_USER;
		else
			next_state = S_DONE_IN_USER;
	S_BUY_IN_ITEM:
		if(inf.item_valid)
			next_state = S_BUY_IN_NUM;
		else
			next_state = S_BUY_IN_ITEM;
	S_BUY_IN_NUM:
		if(inf.num_valid)
			next_state = S_BUY_IN_ID;
		else
			next_state = S_BUY_IN_NUM;
	S_BUY_IN_ID:
		if(inf.id_valid)
			next_state = S_WAIT_OUT;
		else
			next_state = S_BUY_IN_ID;
	S_DEPOSIT:
		if(inf.amnt_valid)
			next_state = S_WAIT_OUT;
		else
			next_state = S_DEPOSIT;
	S_CHECK_IN:
		if(check_lat_count == 'd5 || inf.id_valid)
			next_state = S_WAIT_OUT;
		else
			next_state = S_CHECK_IN;
	S_WAIT_OUT:
		if(inf.out_valid)
			next_state = S_IDLE;
		else
			next_state = S_WAIT_OUT;
	S_INIT:
		if(inf.id_valid)
			next_state = S_DONE_IN_USER;
		else
			next_state = S_INIT;
	default: next_state = S_IDLE;
	endcase
end


// All outputs signals (including OS.sv and bridge.sv) should be zero after reset.
// assert property ( @(posedge inf.rst_n) inf.rst_n == 0 |->
always@(negedge inf.rst_n) begin
	// wait a little bit or will be wrong
	#0.1;
	assert_1 : assert property ( @(inf.rst_n === 0) inf.rst_n === 0 |-> (
		// OS.sv
		inf.out_valid === 0 && inf.err_msg === No_Err && inf.complete === 0 && inf.out_info === 0 && inf.C_addr === 0 && inf.C_data_w === 0 && inf.C_in_valid === 0 && inf.C_r_wb === 0 &&
		// bridge.sv
		inf.C_out_valid === 0 && inf.C_data_r === 0 && inf.AR_VALID === 0 && inf.AR_ADDR === 0 && inf.R_READY === 0 && inf.AW_VALID === 0 && inf.AW_ADDR === 0 && inf.W_VALID === 0 && inf.W_DATA === 0 && inf.B_READY === 0
	))
	else
	begin
		$display("Assertion 1 is violated");
		$fatal;
	end
end

// If action is completed, err_msg must be 4’b0.
assert_2 : assert property ( @(negedge clk) (inf.complete === 1) |-> (inf.err_msg === No_Err) )
else
begin
	$display("Assertion 2 is violated");
	$fatal;
end

// If action is not completed, out_info should be 32’b0.
assert_3 : assert property ( @(negedge clk) (inf.complete === 0) |-> (inf.out_info === 0) )
else
begin
	$display("Assertion 3 is violated");
	$fatal;
end

// All input valid can only be high for exactly one cycle.
assert_4_act : assert property ( @(posedge clk) ( inf.act_valid === 1 ) |=> ( inf.act_valid === 0 ) )
else
begin
	$display("Assertion 4 is violated");
	$fatal;
end

assert_4_amnt : assert property ( @(posedge clk) ( inf.amnt_valid === 1 ) |=> ( inf.amnt_valid === 0 ) )
else
begin
	$display("Assertion 4 is violated");
	$fatal;
end

assert_4_id : assert property ( @(posedge clk) ( inf.id_valid === 1 ) |=> ( inf.id_valid === 0 ) )
else
begin
	$display("Assertion 4 is violated");
	$fatal;
end

assert_4_item : assert property ( @(posedge clk) ( inf.item_valid === 1 ) |=> ( inf.item_valid === 0 ) )
else
begin
	$display("Assertion 4 is violated");
	$fatal;
end

assert_4_num : assert property ( @(posedge clk) ( inf.num_valid === 1 ) |=> ( inf.num_valid === 0 ) )
else
begin
	$display("Assertion 4 is violated");
	$fatal;
end

// The five valid signals won’t overlap with each other.( id_valid, act_valid, amnt_valid, item_valid , num_valid )
assert_5 :assert property ( @(posedge clk) $onehot( { inf.id_valid, inf.act_valid, inf.amnt_valid, inf.item_valid , inf.num_valid, no_in_valid } ) )  
else
begin
 	$display("Assertion 5 is violated");
 	$fatal;
end

//  The gap between each input valid is at least 1 cycle and at most 5 cycles(including the correct input sequence).
// at least 1 cycle
assert_6_at_least_1_cycle : assert property ( @(posedge clk) ( is_in_valid |=> !is_in_valid ) )
else
begin
	$display("Assertion 6 is violated");
	$fatal;
end

// input user ID -> act or input user ID
assert_6_check_id_idle : assert property ( @(posedge clk) ( current_state == S_IDLE && inf.id_valid |-> ( ##[2:6] inf.act_valid ) ) )
else
begin
	$display("Assertion 6 is violated");
	$fatal;
end

assert_6_check_id_init : assert property ( @(posedge clk) ( current_state == S_INIT && inf.id_valid |-> ( ##[2:6] inf.act_valid ) ) )
else
begin
	$display("Assertion 6 is violated");
	$fatal;
end

// Buy
// act -> item
assert_6_item : assert property ( @(posedge clk) ( ( inf.D.d_act == Buy || inf.D.d_act == Return ) && inf.act_valid) |-> ##[2:6] inf.item_valid )
else
begin
	$display("Assertion 6 is violated");
	$fatal;
end

// item -> num
assert_6_num : assert property ( @(posedge clk) (current_state == S_BUY_IN_ITEM && inf.item_valid) |-> ##[2:6] inf.num_valid )
else
begin
	$display("Assertion 6 is violated");
	$fatal;
end

// num -> seller id
assert_6_seller_id : assert property ( @(posedge clk) (current_state == S_BUY_IN_NUM && inf.num_valid) |-> ##[2:6] inf.id_valid )
else
begin
	$display("Assertion 6 is violated");
	$fatal;
end

// Deposit
// act -> amnt
assert_6_amnt : assert property ( @(posedge clk) ( inf.D.d_act == Deposit && inf.act_valid) |-> ##[2:6] inf.amnt_valid )
else
begin
	$display("Assertion 6 is violated");
	$fatal;
end

// other valid can't be 1
assert_6_other_init : assert property ( @(posedge clk) (current_state == S_INIT) |-> ( inf.act_valid == 0 && inf.num_valid == 0 && inf.amnt_valid == 0 && inf.item_valid == 0 ) )
else
begin
	$display("Assertion 6 is violated");
	$fatal;
end

assert_6_other_idle : assert property ( @(posedge clk) (current_state == S_IDLE) |-> ( inf.item_valid == 0 && inf.amnt_valid == 0 && inf.num_valid == 0 ) )
else
begin
	$display("Assertion 6 is violated");
	$fatal;
end

assert_6_other_done_in_user : assert property ( @(posedge clk) (current_state == S_DONE_IN_USER) |-> ( inf.id_valid == 0 && inf.num_valid == 0 && inf.amnt_valid == 0 && inf.item_valid == 0 ) )
else
begin
	$display("Assertion 6 is violated");
	$fatal;
end

assert_6_other_buy_in_item : assert property ( @(posedge clk) (current_state == S_BUY_IN_ITEM) |-> ( inf.act_valid == 0 && inf.id_valid == 0 && inf.amnt_valid == 0 && inf.num_valid == 0 ) )
else
begin
	$display("Assertion 6 is violated");
	$fatal;
end

assert_6_other_buy_in_num : assert property ( @(posedge clk) (current_state == S_BUY_IN_NUM) |-> ( inf.act_valid == 0 && inf.id_valid == 0 && inf.amnt_valid == 0 && inf.item_valid == 0 ) )
else
begin
	$display("Assertion 6 is violated");
	$fatal;
end

assert_6_other_buy_in_id : assert property ( @(posedge clk) (current_state == S_BUY_IN_ID) |-> ( inf.act_valid == 0 && inf.num_valid == 0 && inf.amnt_valid == 0 && inf.item_valid == 0 ) )
else
begin
	$display("Assertion 6 is violated");
	$fatal;
end

assert_6_other_deposit : assert property ( @(posedge clk) (current_state == S_DEPOSIT) |-> ( inf.act_valid == 0 && inf.num_valid == 0 && inf.id_valid == 0 && inf.item_valid == 0 ) )
else
begin
	$display("Assertion 6 is violated");
	$fatal;
end

assert_6_other_check : assert property ( @(posedge clk) (current_state == S_CHECK_IN) |-> ( inf.act_valid == 0 && inf.num_valid == 0 && inf.amnt_valid == 0 && inf.item_valid == 0 ) )
else
begin
	$display("Assertion 6 is violated");
	$fatal;
end

assert_6_other_wait_out : assert property ( @(posedge clk) (current_state == S_WAIT_OUT) |-> ( inf.act_valid == 0 && inf.num_valid == 0 && inf.id_valid == 0 && inf.item_valid == 0 && inf.amnt_valid == 0) )
else
begin
	$display("Assertion 6 is violated");
	$fatal;
end

// Out_valid will be high for one cycle.
// finish
assert_7 : assert property ( @(negedge clk) ( inf.out_valid === 1 ) |=> ( inf.out_valid === 0 ) )
else
begin
	$display("Assertion 7 is violated");
	$fatal;
end

// Next operation will be valid 2-10 cycles after out_valid fall.
assert_8 : assert property ( @(posedge clk) ( inf.out_valid === 1 ) |-> ##[2:10] ( inf.id_valid === 1 || inf.act_valid === 1 ) )
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

assert_8_at_least_two_0 : assert property ( @(posedge clk iff(inf.out_valid) ) (no_in_valid) )
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

assert_8_at_least_two_1 : assert property ( @(posedge clk) ( inf.out_valid === 1 ) |=> no_in_valid)
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

//  Latency should be less than 10000 cycle for each operation.
assert_9_Buy : assert property ( @(posedge clk) ( ( save_act == Return || save_act == Buy ) && action_is_send && inf.id_valid ) |-> ##[0:10000] ( inf.out_valid ) )
else
begin
	$display("Assertion 9 is violated");
	$fatal; 
end

assert_9_Deposit : assert property ( @(posedge clk) ( inf.amnt_valid ) |-> ##[0:10000] ( inf.out_valid ) )
else
begin
	$display("Assertion 9 is violated");
	$fatal; 
end

assert_9_Check_1 : assert property ( @(posedge clk ) ( inf.act_valid && inf.D.d_act == Check ) |-> ##[0:10000] ( inf.out_valid || input_seller_ID ) )
else
begin
	$display("Assertion 9 is violated");
	$fatal; 
end

assert_9_Check_2 : assert property ( @(posedge clk ) ( save_act == Check && action_is_send && inf.id_valid ) |-> ##[0:10000] ( inf.out_valid  ) )
else
begin
	$display("Assertion 9 is violated");
	$fatal; 
end

endmodule